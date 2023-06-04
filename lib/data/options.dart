import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart' show timeDilation;

class HiveOptions {
  const HiveOptions({
    required this.themeMode,
    required this.platform,
    required this.timeDilation,
  });

  final ThemeMode themeMode;
  final TargetPlatform? platform;
  final double timeDilation;

  /// Returns a [SystemUiOverlayStyle] based on the [ThemeMode] setting.
  /// In other words, if the theme is dark, returns light; if the theme is
  /// light, returns dark.
  SystemUiOverlayStyle resolvedSystemUiOverlayStyle() {
    Brightness brightness;
    switch (themeMode) {
      case ThemeMode.light:
        brightness = Brightness.light;
        break;
      case ThemeMode.dark:
        brightness = Brightness.dark;
        break;
      default:
        brightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }

    final overlayStyle = brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return overlayStyle;
  }

  HiveOptions copyWith({
    ThemeMode? themeMode,
    TargetPlatform? platform,
    double? timeDilation,
    bool? isTestMode,
  }) {
    return HiveOptions(
      themeMode: themeMode ?? this.themeMode,
      platform: platform ?? this.platform,
      timeDilation: timeDilation ?? this.timeDilation,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is HiveOptions &&
      themeMode == other.themeMode &&
      platform == other.platform &&
      timeDilation == other.timeDilation;

  @override
  int get hashCode => Object.hash(
        themeMode,
        platform,
        timeDilation,
      );

  static HiveOptions of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ModelBindingScope>()!;
    return scope.modelBindingState.currentModel;
  }

  static void update(BuildContext context, HiveOptions newModel) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_ModelBindingScope>()!;
    scope.modelBindingState.updateModel(newModel);
  }
}

class _ModelBindingScope extends InheritedWidget {
  const _ModelBindingScope({
    required this.modelBindingState,
    required super.child,
  });

  final _ModelBindingState modelBindingState;

  @override
  bool updateShouldNotify(_ModelBindingScope oldWidget) => true;
}

class ModelBinding extends StatefulWidget {
  const ModelBinding({
    super.key,
    required this.initialModel,
    required this.child,
  });

  final HiveOptions initialModel;
  final Widget child;

  @override
  State<ModelBinding> createState() => _ModelBindingState();
}

class _ModelBindingState extends State<ModelBinding> {
  late HiveOptions currentModel;
  Timer? _timeDilationTimer;

  @override
  void initState() {
    super.initState();
    currentModel = widget.initialModel;
  }

  @override
  void dispose() {
    _timeDilationTimer?.cancel();
    _timeDilationTimer = null;
    super.dispose();
  }

  void handleTimeDilation(HiveOptions newModel) {
    if (currentModel.timeDilation != newModel.timeDilation) {
      _timeDilationTimer?.cancel();
      _timeDilationTimer = null;
      if (newModel.timeDilation > 1) {
        // We delay the time dilation change long enough that the user can see
        // that UI has started reacting and then we slam on the brakes so that
        // they see that the time is in fact now dilated.
        _timeDilationTimer = Timer(const Duration(milliseconds: 150), () {
          timeDilation = newModel.timeDilation;
        });
      } else {
        timeDilation = newModel.timeDilation;
      }
    }
  }

  void updateModel(HiveOptions newModel) {
    if (newModel != currentModel) {
      handleTimeDilation(newModel);
      setState(() {
        currentModel = newModel;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ModelBindingScope(
      modelBindingState: this,
      child: widget.child,
    );
  }
}
