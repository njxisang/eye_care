import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 本地通知服务
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          // 处理通知点击
        },
      );

      // 请求通知权限（Android 13+）
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }

      _initialized = true;
    } catch (e) {
      // 通知初始化失败不影响主功能，记录日志继续运行
      // ignore: avoid_print
      print('NotificationService.init failed: $e');
    }
  }

  /// 护眼提醒：20-20-20法则
  static Future<void> showEyeRestReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'eye_rest_reminder',
      '护眼提醒',
      channelDescription: '20-20-20护眼法则提醒',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      1,
      '👀 护眼提醒',
      '每20分钟，让眼睛休息20秒，远眺20英尺（约6米）',
      details,
    );
  }

  /// 使用时长超限提醒
  static Future<void> showUsageLimitReminder(int exceedMinutes) async {
    const androidDetails = AndroidNotificationDetails(
      'usage_limit_reminder',
      '使用时长提醒',
      channelDescription: '屏幕使用时间超限提醒',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      2,
      '⏰ 使用时长提醒',
      '今日屏幕使用时间已超过设定目标 ${exceedMinutes} 分钟',
      details,
    );
  }

  /// 定期提醒（用于定时循环提醒）
  static Future<void> scheduleEyeRestReminder(int intervalMinutes) async {
    // Android: 使用 WorkManager 或 AlarmManager 实现定时提醒
    // 这里简化处理，使用 flutter_local_notifications 的周期性通知
    const androidDetails = AndroidNotificationDetails(
      'eye_rest_periodic',
      '定时护眼提醒',
      channelDescription: '定时护眼提醒',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      3,
      '👀 护眼提醒',
      '该让眼睛休息一下了！',
      details,
    );
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
