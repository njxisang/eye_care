import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'providers/settings_provider.dart';

class EyeCareApp extends ConsumerWidget {
  const EyeCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProviderProvider);
    final themeMode = settings.darkMode ? ThemeMode.dark : ThemeMode.light;

    return MaterialApp.router(
      title: '护眼宝',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
          surface: const Color(0xFFFFF8E1),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8E1),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFF4CAF50),
          thumbColor: Color(0xFF4CAF50),
          overlayColor: Color(0x294CAF50),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: Color(0xFF4CAF50),
          thumbColor: Color(0xFF4CAF50),
          overlayColor: Color(0x294CAF50),
        ),
      ),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
