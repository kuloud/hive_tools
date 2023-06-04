import 'package:flutter/material.dart';
import 'package:hive_tools/tools/device/screen_test/screen_test_fullscreen.dart';

class ScreenTestPage extends StatelessWidget {
  const ScreenTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).restorablePushNamed<void>(
          ScreenTestFullScreenPage.secondPageRoute,
          arguments: {},
        );
      },
      child: Center(
        child: Text('屏幕会显示不同颜色，请检查是否有黑点或亮点，点击屏幕开始测试'),
      ),
    );
  }
}
