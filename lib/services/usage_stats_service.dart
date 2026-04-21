import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 使用时长统计服务（需要 Android UsageStats 权限）
class UsageStatsService {
  /// 检查是否有使用时长统计权限
  static Future<bool> hasPermission() async {
    final status = await Permission.usageAccess.status;
    return status.isGranted;
  }

  /// 请求使用时长统计权限
  static Future<bool> requestPermission() async {
    final status = await Permission.usageAccess.request();
    return status.isGranted;
  }

  /// 打开系统设置页面（让用户手动授权）
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// 获取某应用的使用时长（分钟）
  /// 返回Map: {packageName: minutes}
  static Future<Map<String, int>> getUsageStats({
    required DateTime start,
    required DateTime end,
  }) async {
    // 注意：UsageStats API 需要 PACKAGE_USAGE_STATS 权限
    // Flutter层无法直接访问，需要通过 platform channel 调用原生代码
    // 这里返回模拟数据作为演示
    return {};
  }
}
