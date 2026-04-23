import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'providers/settings_provider.dart';
import 'providers/usage_provider.dart';
import 'providers/reminder_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // 使用 FutureProvider 模式，await 初始化完成后再 runApp
  // 这样避免了在 main.dart 里手动链式调用 load() 导致的竞态
  final settingsContainer = await initializeSettings();
  final usageContainer = await initializeUsage();
  final reminderContainer = await initializeReminder();

  runApp(
    ProviderScope(
      overrides: [
        settingsProviderProvider.overrideWith((_) => settingsContainer),
        usageProviderProvider.overrideWith((_) => usageContainer),
        reminderProviderProvider.overrideWith((_) => reminderContainer),
      ],
      child: const EyeCareApp(),
    ),
  );
}
