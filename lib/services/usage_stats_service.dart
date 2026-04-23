import 'package:permission_handler/permission_handler.dart';

/// 使用时长统计服务（需要 Android UsageStats 权限）
///
/// 注意：真正获取系统级使用时长统计需要 Platform Channel + 原生 UsageStats API，
/// 当前实现为占位符，详细见 https://developer.android.com/reference/android/app/usage/UsageStatsManager
class UsageStatsService {
  /// 检查是否有使用时长统计权限
  /// [hasPermission] 返回 true 仅表示权限已被授权，不代表能获取到真实数据
  static Future<bool> hasPermission() async {
    // Permission.usageAccess 在 permission_handler 中不存在或尚未稳定，
    // 此处用 availablePermissions 近似判断，实际权限判断需原生代码实现
    return true;
  }

  /// 请求使用时长统计权限
  static Future<bool> requestPermission() async {
    // PACKAGE_USAGE_STATS 是 signature 级别权限，普通 request 无法获取。
    // 正确做法是引导用户跳转系统设置页面手动授权：
    // await openAppSettings();
    return false;
  }

  /// 打开系统设置页面（让用户手动授权）
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  /// 获取某应用的使用时长（分钟）
  /// 返回Map: {packageName: minutes}
  ///
  /// TODO(P0): 需要通过 Platform Channel 调用原生 UsageStatsManager API
  /// 原生实现参考: com.eyecare/system channel
  static Future<Map<String, int>> getUsageStats({
    required DateTime start,
    required DateTime end,
  }) async {
    // 返回空 Map，表示暂无真实数据
    return {};
  }
}
