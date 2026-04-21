import 'package:flutter/material.dart';

/// 软件色温滤镜服务
/// 在应用内覆盖一层半透明暖色图层实现滤蓝光效果
class BlueLightService {
  static OverlayEntry? _overlayEntry;

  /// intensity: 0.0(无) ~ 1.0(最强暖色)
  static void setFilter(double intensity, BuildContext context) {
    removeFilter();

    if (intensity <= 0) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Color.fromRGBO(
            255,
            ((200 * intensity).clamp(0, 200)).toInt(),
            0,
            intensity * 0.35,
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  static void removeFilter() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 根据色温强度获取预设颜色
  static Color getFilterColor(double intensity) {
    return Color.fromRGBO(
      255,
      ((200 * intensity).clamp(0, 200)).toInt(),
      0,
      intensity * 0.35,
    );
  }
}
