import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/settings_provider.dart';
import 'providers/usage_provider.dart';
import 'providers/reminder_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 设置状态栏样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 初始化设置provider
  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  // 初始化使用时长provider
  final usageProvider = UsageProvider();
  await usageProvider.loadToday();

  // 初始化提醒provider
  final reminderProvider = ReminderProvider();
  await reminderProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: usageProvider),
        ChangeNotifierProvider.value(value: reminderProvider),
      ],
      child: const EyeCareApp(),
    ),
  );
}
