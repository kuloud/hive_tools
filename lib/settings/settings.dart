// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hive_tools/constants.dart';
import 'package:hive_tools/data/options.dart';
import 'package:hive_tools/home.dart';
import 'package:hive_tools/layout/adaptive.dart';
import 'package:hive_tools/settings/settings_list_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive_tools/about/about.dart' as about;

enum _ExpandableSetting {
  platform,
  theme,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  static const routeName = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  _ExpandableSetting? _expandedSettingId;

  void onTapSetting(_ExpandableSetting settingId) {
    setState(() {
      if (_expandedSettingId == settingId) {
        _expandedSettingId = null;
      } else {
        _expandedSettingId = settingId;
      }
    });
  }

  void _closeSettingId(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      setState(() {
        _expandedSettingId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final options = HiveOptions.of(context);
    final isDesktop = isDisplayDesktop(context);

    final settingsListItems = [
      SettingsListItem<ThemeMode?>(
        title: '主题',
        selectedOption: options.themeMode,
        optionsMap: LinkedHashMap.of({
          ThemeMode.system: DisplayOption(
            '系统',
          ),
          ThemeMode.dark: DisplayOption(
            '深色',
          ),
          ThemeMode.light: DisplayOption(
            '浅色',
          ),
        }),
        onOptionChanged: (newThemeMode) => HiveOptions.update(
          context,
          options.copyWith(themeMode: newThemeMode),
        ),
        onTapSetting: () => onTapSetting(_ExpandableSetting.theme),
        isExpanded: _expandedSettingId == _ExpandableSetting.theme,
      ),
      ToggleSetting(
        text: '慢镜头',
        value: options.timeDilation != 1.0,
        onChanged: (isOn) => HiveOptions.update(
          context,
          options.copyWith(timeDilation: isOn ? 5.0 : 1.0),
        ),
      ),
    ];

    return Material(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: isDesktop
            ? EdgeInsets.zero
            : const EdgeInsets.only(
                bottom: galleryHeaderHeight,
              ),
        // Remove ListView top padding as it is already accounted for.
        child: MediaQuery.removePadding(
          removeTop: isDesktop,
          context: context,
          child: ListView(
            children: [
              if (isDesktop)
                const SizedBox(height: firstHeaderDesktopTopPadding),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ExcludeSemantics(
                  child: Header(
                    color: Theme.of(context).colorScheme.onSurface,
                    text: '设置',
                  ),
                ),
              ),
              if (isDesktop)
                ...settingsListItems
              else ...[
                _AnimateSettingsListItems(
                  children: settingsListItems,
                ),
                const SizedBox(height: 16),
                Divider(thickness: 2, height: 0, color: colorScheme.outline),
                const SizedBox(height: 12),
                const SettingsAbout(),
                const SettingsFeedback(),
                const SizedBox(height: 12),
                Divider(thickness: 2, height: 0, color: colorScheme.outline),
                const SettingsAttribution(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsAbout extends StatelessWidget {
  const SettingsAbout({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsLink(
      title: '关于 Flutter Gallery',
      icon: Icons.info_outline,
      onTap: () {
        about.showAboutDialog(context: context);
      },
    );
  }
}

class SettingsFeedback extends StatelessWidget {
  const SettingsFeedback({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsLink(
      title: '发送反馈',
      icon: Icons.feedback,
      onTap: () async {
        final url =
            Uri.parse('https://github.com/flutter/gallery/issues/new/choose/');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      },
    );
  }
}

class SettingsAttribution extends StatelessWidget {
  const SettingsAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);
    final verticalPadding = isDesktop ? 0.0 : 28.0;
    return MergeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: isDesktop ? 24 : 32,
          end: isDesktop ? 0 : 32,
          top: verticalPadding,
          bottom: verticalPadding,
        ),
        child: SelectableText(
          '由伦敦的 TOASTER 设计',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
          textAlign: isDesktop ? TextAlign.end : TextAlign.start,
        ),
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  final String title;
  final IconData? icon;
  final GestureTapCallback? onTap;

  const _SettingsLink({
    required this.title,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = isDisplayDesktop(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 32,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: colorScheme.onSecondary.withOpacity(0.5),
              size: 24,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 16,
                  top: 12,
                  bottom: 12,
                ),
                child: Text(
                  title,
                  style: textTheme.titleSmall!.apply(
                    color: colorScheme.onSecondary,
                  ),
                  textAlign: isDesktop ? TextAlign.end : TextAlign.start,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animate the settings list items to stagger in from above.
class _AnimateSettingsListItems extends StatelessWidget {
  const _AnimateSettingsListItems({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const dividingPadding = 4.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        children: children,
      ),
    );
  }
}
