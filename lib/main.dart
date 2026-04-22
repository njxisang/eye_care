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

  final settingsProvider = SettingsProvider()..load();
  final usageProvider = UsageProvider()..loadToday();
  final reminderProvider = ReminderProvider()..load();

  runApp(
    ProviderScope(
      overrides: [
        settingsProviderProvider.overrideWith((_) => settingsProvider),
        usageProviderProvider.overrideWith((_) => usageProvider),
        reminderProviderProvider.overrideWith((_) => reminderProvider),
      ],
      child: const EyeCareApp(),
    ),
  );
}
