// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hive_tools/tools/deferred_widget.dart';
import 'package:hive_tools/tools/device/device_tools.dart'
    deferred as device_tools;

enum ToolCategory {
  device,
  other;

  @override
  String toString() {
    return name.toUpperCase();
  }

  String? displayTitle() {
    switch (this) {
      case ToolCategory.other:
      case ToolCategory.device:
        return toString();
    }
    return null;
  }
}

class Tool {
  const Tool({
    required this.title,
    required this.category,
    required this.subtitle,
    // Parameters below are required for non-study demos.
    this.slug,
    this.icon,
    this.configurations = const [],
  });

  final String title;
  final ToolCategory category;
  final String subtitle;
  final String? slug;
  final IconData? icon;
  final List<GalleryDemoConfiguration> configurations;

  String get describe => '${slug}@${category.name}';
}

class GalleryDemoConfiguration {
  const GalleryDemoConfiguration({
    required this.title,
    required this.description,
    required this.buildRoute,
  });

  final String title;
  final String description;
  final WidgetBuilder buildRoute;
}

/// Awaits all deferred libraries for tests.
Future<void> pumpDeferredLibraries() {
  final futures = <Future<void>>[
    DeferredWidget.preload(device_tools.loadLibrary),
  ];
  return Future.wait(futures);
}

class Demos {
  static Map<String?, Tool> asSlugToDemoMap(BuildContext context) {
    return LinkedHashMap<String?, Tool>.fromIterable(
      all(),
      key: (dynamic demo) => demo.slug as String?,
    );
  }

  static List<Tool> all() => studies().values.toList() + deviceTools();

  static List<String> allDescriptions() =>
      all().map((demo) => demo.describe).toList();

  static Map<String, Tool> studies() {
    return <String, Tool>{
      'device': const Tool(
        title: 'device',
        subtitle: 'deviceDescription',
        category: ToolCategory.device,
      ),
    };
  }

  static List<Tool> deviceTools() {
    LibraryLoader deviceToolsLibrary = device_tools.loadLibrary;
    return [
      Tool(
        title: '屏幕测试',
        icon: Icons.screen_share,
        slug: 'screen-test',
        subtitle: '检测屏幕坏点',
        configurations: [
          GalleryDemoConfiguration(
            title: '屏幕测试',
            description: '屏幕会显示不同颜色，请检查是否有黑点或亮点',
            buildRoute: (_) => DeferredWidget(
              deviceToolsLibrary,
              () => device_tools.ScreenTestPage(),
            ),
          ),
        ],
        category: ToolCategory.other,
      ),
    ];
  }
}
