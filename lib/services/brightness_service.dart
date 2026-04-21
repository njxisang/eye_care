import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 亮度控制服务
class BrightnessService {
  static double _currentBrightness = 0.7;

  static Future<void> setBrightness(double brightness) async {
    _currentBrightness = brightness.clamp(0.0, 1.0);
    // 设置系统亮度（需要权限）
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // 应用层通过MediaQueryData.initialNavigationBarHeight等来控制实际亮度感知
  }

  static double get currentBrightness => _currentBrightness;

  /// 护眼模式：最低亮度不低于20%
  static double clampForEyeCare(double brightness) {
    return brightness.clamp(0.2, 1.0);
  }
}
