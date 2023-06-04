// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dual_screen/dual_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_tools/constants.dart';
import 'package:hive_tools/data/options.dart';
import 'package:hive_tools/data/tools.dart';
import 'package:hive_tools/layout/adaptive.dart';
import 'package:hive_tools/themes/theme_data.dart';
import 'package:hive_tools/tools/feature_discovery/feature_discovery.dart';
import 'package:hive_tools/tools/splash.dart';
import 'package:url_launcher/url_launcher_string.dart';

enum _ToolState {
  normal,
  options,
  info,
  fullscreen,
}

class ToolPage extends StatefulWidget {
  const ToolPage({
    super.key,
    required this.slug,
  });

  static const String baseRoute = '/tool';
  final String? slug;

  @override
  State<ToolPage> createState() => _ToolPageState();
}

class _ToolPageState extends State<ToolPage> {
  late Map<String?, Tool> slugToDemoMap;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // To make sure that we do not rebuild the map for every update to the demo
    // page, we save it in a variable. The cost of running `slugToDemo` is
    // still only close to constant, as it's just iterating over all of the
    // demos.
    slugToDemoMap = Demos.asSlugToDemoMap(context);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slug == null || !slugToDemoMap.containsKey(widget.slug)) {
      // Return to root if invalid slug.
      Navigator.of(context).pop();
    }
    return ScaffoldMessenger(
        child: GalleryDemoPage(
      restorationId: widget.slug!,
      demo: slugToDemoMap[widget.slug]!,
    ));
  }
}

class GalleryDemoPage extends StatefulWidget {
  const GalleryDemoPage({
    super.key,
    required this.restorationId,
    required this.demo,
  });

  final String restorationId;
  final Tool demo;

  @override
  State<GalleryDemoPage> createState() => _GalleryDemoPageState();
}

class _GalleryDemoPageState extends State<GalleryDemoPage>
    with RestorationMixin, TickerProviderStateMixin {
  final RestorableInt _demoStateIndex = RestorableInt(_ToolState.normal.index);
  final RestorableInt _configIndex = RestorableInt(0);

  bool? _isDesktop;

  @override
  String get restorationId => widget.restorationId;

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_demoStateIndex, 'demo_state');
    registerForRestoration(_configIndex, 'configuration_index');
  }

  GalleryDemoConfiguration get _currentConfig {
    return widget.demo.configurations[_configIndex.value];
  }

  bool get _hasOptions => widget.demo.configurations.length > 1;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _demoStateIndex.dispose();
    _configIndex.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isDesktop ??= isDisplayDesktop(context);
  }

  /// Sets state and updates the background color for code.
  void setStateAndUpdate(VoidCallback callback) {
    setState(() {
      callback();
    });
  }

  void _handleTap(_ToolState newState) {
    var newStateIndex = newState.index;

    // Do not allow normal state for desktop.
    if (_demoStateIndex.value == newStateIndex && isDisplayDesktop(context)) {
      if (_demoStateIndex.value == _ToolState.fullscreen.index) {
        setStateAndUpdate(() {
          _demoStateIndex.value =
              _hasOptions ? _ToolState.options.index : _ToolState.info.index;
        });
      }
      return;
    }

    setStateAndUpdate(() {
      _demoStateIndex.value = _demoStateIndex.value == newStateIndex
          ? _ToolState.normal.index
          : newStateIndex;
    });
  }

  void _resolveState(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);
    final isFoldable = isDisplayFoldable(context);
    if (_ToolState.values[_demoStateIndex.value] == _ToolState.fullscreen &&
        !isDesktop) {
      // Do not allow fullscreen state for mobile.
      _demoStateIndex.value = _ToolState.normal.index;
    } else if (_ToolState.values[_demoStateIndex.value] == _ToolState.normal &&
        (isDesktop || isFoldable)) {
      // Do not allow normal state for desktop.
      _demoStateIndex.value =
          _hasOptions ? _ToolState.options.index : _ToolState.info.index;
    } else if (isDesktop != _isDesktop) {
      _isDesktop = isDesktop;
      // When going from desktop to mobile, return to normal state.
      if (!isDesktop) {
        _demoStateIndex.value = _ToolState.normal.index;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFoldable = isDisplayFoldable(context);
    final isDesktop = isDisplayDesktop(context);
    _resolveState(context);

    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = colorScheme.onSurface;
    final selectedIconColor = colorScheme.primary;
    final appBarPadding = isDesktop ? 20.0 : 0.0;
    final currentDemoState = _ToolState.values[_demoStateIndex.value];
    final options = HiveOptions.of(context);

    final appBar = AppBar(
      systemOverlayStyle: options.resolvedSystemUiOverlayStyle(),
      backgroundColor: Colors.transparent,
      leading: Padding(
        padding: EdgeInsetsDirectional.only(start: appBarPadding),
        child: IconButton(
          key: const ValueKey('Back'),
          icon: const BackButtonIcon(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),
      ),
      actions: [
        if (_hasOptions)
          IconButton(
            icon: FeatureDiscovery(
              title: 'demoOptionsFeatureTitle',
              description: 'demoOptionsFeatureDescription',
              showOverlay: !isDisplayDesktop(context),
              color: colorScheme.primary,
              onTap: () => _handleTap(_ToolState.options),
              child: Icon(
                Icons.tune,
                color: currentDemoState == _ToolState.options
                    ? selectedIconColor
                    : iconColor,
              ),
            ),
            tooltip: 'demoOptionsTooltip',
            onPressed: () => _handleTap(_ToolState.options),
          ),
        IconButton(
          icon: const Icon(Icons.info),
          tooltip: 'demoInfoTooltip',
          color: currentDemoState == _ToolState.info
              ? selectedIconColor
              : iconColor,
          onPressed: () => _handleTap(_ToolState.info),
        ),
        if (isDesktop)
          IconButton(
            icon: const Icon(Icons.fullscreen),
            tooltip: 'demoFullscreenTooltip',
            color: currentDemoState == _ToolState.fullscreen
                ? selectedIconColor
                : iconColor,
            onPressed: () => _handleTap(_ToolState.fullscreen),
          ),
        SizedBox(width: appBarPadding),
      ],
    );

    final mediaQuery = MediaQuery.of(context);
    final bottomSafeArea = mediaQuery.padding.bottom;
    final contentHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        appBar.preferredSize.height;
    final maxSectionHeight = isDesktop ? contentHeight : contentHeight - 64;
    final horizontalPadding = isDesktop ? mediaQuery.size.width * 0.12 : 0.0;
    const maxSectionWidth = 420.0;

    Widget section;
    switch (currentDemoState) {
      case _ToolState.options:
        section = _DemoSectionOptions(
          maxHeight: maxSectionHeight,
          maxWidth: maxSectionWidth,
          configurations: widget.demo.configurations,
          configIndex: _configIndex.value,
          onConfigChanged: (index) {
            setStateAndUpdate(() {
              _configIndex.value = index;
              if (!isDesktop) {
                _demoStateIndex.value = _ToolState.normal.index;
              }
            });
          },
        );
        break;
      case _ToolState.info:
        section = _DemoSectionInfo(
          maxHeight: maxSectionHeight,
          maxWidth: maxSectionWidth,
          title: _currentConfig.title,
          description: _currentConfig.description,
        );
        break;

      default:
        section = Container();
        break;
    }

    Widget body;
    Widget demoContent = ScaffoldMessenger(
      child: DemoWrapper(
        height: contentHeight,
        buildRoute: _currentConfig.buildRoute,
      ),
    );
    if (isDesktop) {
      final isFullScreen = currentDemoState == _ToolState.fullscreen;
      final Widget sectionAndDemo = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFullScreen) Expanded(child: section),
          SizedBox(width: !isFullScreen ? 48.0 : 0),
          Expanded(child: demoContent),
        ],
      );

      body = SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 56),
          child: sectionAndDemo,
        ),
      );
    } else if (isFoldable) {
      body = Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: TwoPane(
          startPane: demoContent,
          endPane: section,
        ),
      );
    } else {
      section = AnimatedSize(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.topCenter,
        curve: Curves.easeIn,
        child: section,
      );

      final isDemoNormal = currentDemoState == _ToolState.normal;
      // Add a tap gesture to collapse the currently opened section.
      demoContent = Semantics(
        label: 'tool, ${widget.demo.title}',
        child: MouseRegion(
          cursor: isDemoNormal ? MouseCursor.defer : SystemMouseCursors.click,
          child: GestureDetector(
            onTap: isDemoNormal
                ? null
                : () {
                    setStateAndUpdate(() {
                      _demoStateIndex.value = _ToolState.normal.index;
                    });
                  },
            child: Semantics(
              excludeSemantics: !isDemoNormal,
              child: demoContent,
            ),
          ),
        ),
      );

      body = SafeArea(
        bottom: false,
        child: ListView(
          // Use a non-scrollable ListView to enable animation of shifting the
          // demo offscreen.
          physics: const NeverScrollableScrollPhysics(),
          children: [
            section,
            demoContent,
            // Fake the safe area to ensure the animation looks correct.
            SizedBox(height: bottomSafeArea),
          ],
        ),
      );
    }

    Widget page;

    if (isDesktop || isFoldable) {
      page = Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Scaffold(
          appBar: appBar,
          body: body,
          backgroundColor: Colors.transparent,
        ),
      );
    } else {
      page = Scaffold(
        appBar: appBar,
        body: body,
        resizeToAvoidBottomInset: false,
      );
    }

    // Add the splash page functionality for desktop.
    if (isDesktop) {
      page = MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: SplashPage(
          child: page,
        ),
      );
    }

    return FeatureDiscoveryController(page);
  }
}

class _DemoSectionOptions extends StatelessWidget {
  const _DemoSectionOptions({
    required this.maxHeight,
    required this.maxWidth,
    required this.configurations,
    required this.configIndex,
    required this.onConfigChanged,
  });

  final double maxHeight;
  final double maxWidth;
  final List<GalleryDemoConfiguration> configurations;
  final int configIndex;
  final ValueChanged<int> onConfigChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 24,
                top: 12,
                end: 24,
              ),
              child: Text(
                'demoOptionsTooltip',
                style: textTheme.headlineMedium!.apply(
                  color: colorScheme.onSurface,
                  fontSizeDelta:
                      isDisplayDesktop(context) ? desktopDisplay1FontDelta : 0,
                ),
              ),
            ),
            Divider(
              thickness: 1,
              height: 16,
              color: colorScheme.onSurface,
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final configuration in configurations)
                    _DemoSectionOptionsItem(
                      title: configuration.title,
                      isSelected: configuration == configurations[configIndex],
                      onTap: () {
                        onConfigChanged(configurations.indexOf(configuration));
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DemoSectionOptionsItem extends StatelessWidget {
  const _DemoSectionOptionsItem({
    required this.title,
    required this.isSelected,
    this.onTap,
  });

  final String title;
  final bool isSelected;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.surface : null,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: double.infinity),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium!.apply(
                  color:
                      isSelected ? colorScheme.primary : colorScheme.onSurface,
                ),
          ),
        ),
      ),
    );
  }
}

class _DemoSectionInfo extends StatelessWidget {
  const _DemoSectionInfo({
    required this.maxHeight,
    required this.maxWidth,
    required this.title,
    required this.description,
  });

  final double maxHeight;
  final double maxWidth;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: AlignmentDirectional.topStart,
      child: Container(
        padding: const EdgeInsetsDirectional.only(
          start: 24,
          top: 12,
          end: 24,
          bottom: 32,
        ),
        constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: maxWidth),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                title,
                style: textTheme.headlineMedium!.apply(
                  color: colorScheme.onSurface,
                  fontSizeDelta:
                      isDisplayDesktop(context) ? desktopDisplay1FontDelta : 0,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                description,
                style: textTheme.bodyMedium!.apply(
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DemoWrapper extends StatelessWidget {
  const DemoWrapper({
    super.key,
    required this.height,
    required this.buildRoute,
  });

  final double height;
  final WidgetBuilder buildRoute;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      height: height,
      child: ClipRRect(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(10.0),
          bottom: Radius.circular(2.0),
        ),
        child: Theme(
          data: HiveThemeData.lightThemeData.copyWith(
            platform: HiveOptions.of(context).platform,
          ),
          child: CupertinoTheme(
            data: const CupertinoThemeData()
                .copyWith(brightness: Brightness.light),
            child: Builder(builder: buildRoute),
          ),
        ),
      ),
    );
  }
}
