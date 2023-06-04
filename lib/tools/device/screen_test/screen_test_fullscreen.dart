import 'package:flutter/material.dart';

class ScreenTestFullScreenPage extends StatelessWidget {
  const ScreenTestFullScreenPage({super.key});

  static const secondPageRoute = '/tool/device/screen-test-fullscreen';

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('屏幕会显示不同颜色，请检查是否有黑点或亮点，点击屏幕开始测试'),
    );
  }
}
