import 'package:flutter/material.dart';

/// 软件色温滤镜服务
///
/// 使用全局 OverlayEntry 策略：插入到 Root Navigator 的 Overlay 中，
/// 脱离 Screen 级别的 context 生命周期，不受路由切换影响。
class BlueLightService {
  static OverlayEntry? _overlayEntry;

  /// 当前滤镜强度（0.0 ~ 1.0），null 表示未启用
  static double? _currentIntensity;

  /// 静态颜色缓存，避免每次 rebuild 重复计算
  static Color? _cachedColor;

  static double? get currentIntensity => _currentIntensity;

  /// intensity: 0.0(无) ~ 1.0(最强暖色)
  /// 通过 RootNavigatorService.overlayKey 获取全局 Overlay，不受路由切换影响
  static void setFilter(double intensity, BuildContext context) {
    _currentIntensity = intensity;

    if (intensity <= 0) {
      removeFilter();
      return;
    }

    // 通过 GlobalKey<OverlayState> 获取全局 Overlay，不依赖 NavigatorState
    final overlayState = RootNavigatorService.overlayKey.currentState;
    if (overlayState == null) return;

    removeFilter();

    _cachedColor = Color.fromRGBO(
      255,
      ((200 * intensity).clamp(0, 200)).toInt(),
      0,
      intensity * 0.35,
    );

    _overlayEntry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _cachedColor,
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  static void removeFilter() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentIntensity = null;
    _cachedColor = null;
  }

  /// 根据色温强度获取预设颜色（供 UI 预览用）
  static Color getFilterColor(double intensity) {
    return Color.fromRGBO(
      255,
      ((200 * intensity).clamp(0, 200)).toInt(),
      0,
      intensity * 0.35,
    );
  }

  /// 更新滤镜（不改 intensity，只更新 Overlay 渲染）
  /// 用于 intensity 不变但需要刷新 Overlay 状态的场景
  static void refresh() {
    if (_overlayEntry != null && _overlayEntry!.mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }
}

/// 全局 Root Navigator Key + Overlay Key 访问器
/// 在 main.dart / app.dart 中赋值，供 BlueLightService 等不需要 context 也能访问 navigator/overlay 的场景使用
class RootNavigatorService {
  static GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'EyeCareRootNavigator');

  /// 用于在无 context 时访问全局 OverlayState
  static GlobalKey<OverlayState> overlayKey =
      GlobalKey<OverlayState>(debugLabel: 'EyeCareRootOverlay');
}
