import 'package:flutter/services.dart';

/// 屏幕时间统计服务
///
/// 通过 MethodChannel 与原生 Android 代码通信，
/// 监听 SCREEN_ON/SCREEN_OFF 广播来累计屏幕亮屏时间
class UsageStatsService {
  static const MethodChannel _channel = MethodChannel('com.eyecare/system');

  /// 启动屏幕时间追踪服务
  static Future<bool> startTracking() async {
    try {
      final result = await _channel.invokeMethod<bool>('startScreenTracking');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// 获取今日屏幕使用分钟数
  static Future<int> getTodayScreenMinutes() async {
    try {
      final result = await _channel.invokeMethod<int>('getScreenTimeMinutes');
      return result ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// 检查是否有使用时长统计权限
  /// Android 需要 PACKAGE_USAGE_STATS 权限才能获取应用级使用统计
  /// 但屏幕亮屏时间通过 SCREEN_ON/OFF 广播实现，不需要该权限
  static Future<bool> hasPermission() async {
    return true;
  }

  /// 请求使用时长统计权限（仅对应用级统计有意义）
  static Future<bool> requestPermission() async {
    return false;
  }

  /// 打开系统设置页面（让用户手动授权）
  static Future<void> openSettings() async {
    // 不需要了，屏幕时间统计不需要特殊权限
  }

  /// 获取某应用的使用时长（分钟）
  /// 注意：这个需要 PACKAGE_USAGE_STATS 权限，当前版本只支持屏幕总时间
  static Future<Map<String, int>> getUsageStats({
    required DateTime start,
    required DateTime end,
  }) async {
    // 返回屏幕总时间作为"手机使用时间"的近似值
    final minutes = await getTodayScreenMinutes();
    return {'screen_time': minutes};
  }
}
