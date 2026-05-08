import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final settingsProviderProvider = ChangeNotifierProvider<SettingsProvider>((ref) {
  return SettingsProvider();
});

/// 静态工厂：初始化 SettingsProvider 并等待数据加载完成
Future<SettingsProvider> initializeSettings() async {
  final instance = SettingsProvider();
  await instance.load();
  return instance;
}

class SettingsProvider extends ChangeNotifier {
  static const String _keyBlueLightEnabled = 'blue_light_enabled';
  static const String _keyBlueLightIntensity = 'blue_light_intensity';
  static const String _keyBrightness = 'brightness';
  static const String _keyAutoBrightness = 'auto_brightness';
  static const String _keyReminderEnabled = 'reminder_enabled';
  static const String _keyReminderInterval = 'reminder_interval';
  static const String _keyScheduledStart = 'scheduled_start';
  static const String _keyScheduledEnd = 'scheduled_end';
  static const String _keyScheduledEnabled = 'scheduled_enabled';
  static const String _keyDailyGoalMinutes = 'daily_goal_minutes';
  static const String _keyDarkMode = 'dark_mode';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyPomodoroWorkMinutes = 'pomodoro_work_minutes';
  static const String _keyPomodoroBreakMinutes = 'pomodoro_break_minutes';

  bool _blueLightEnabled = false;
  double _blueLightIntensity = 0.5;
  double _brightness = 0.7;
  bool _autoBrightness = false;
  bool _reminderEnabled = true;
  int _reminderInterval = 20;
  String _scheduledStart = "22:00";
  String _scheduledEnd = "07:00";
  bool _scheduledEnabled = false;
  int _dailyGoalMinutes = 240;
  bool _darkMode = false;
  bool _onboardingCompleted = false;
  int _pomodoroWorkMinutes = 25;
  int _pomodoroBreakMinutes = 5;

  bool get blueLightEnabled => _blueLightEnabled;
  double get blueLightIntensity => _blueLightIntensity;
  double get brightness => _brightness;
  bool get autoBrightness => _autoBrightness;
  bool get reminderEnabled => _reminderEnabled;
  int get reminderInterval => _reminderInterval;
  String get scheduledStart => _scheduledStart;
  String get scheduledEnd => _scheduledEnd;
  bool get scheduledEnabled => _scheduledEnabled;
  int get dailyGoalMinutes => _dailyGoalMinutes;
  bool get darkMode => _darkMode;
  bool get onboardingCompleted => _onboardingCompleted;
  int get pomodoroWorkMinutes => _pomodoroWorkMinutes;
  int get pomodoroBreakMinutes => _pomodoroBreakMinutes;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _blueLightEnabled = prefs.getBool(_keyBlueLightEnabled) ?? false;
      _blueLightIntensity = prefs.getDouble(_keyBlueLightIntensity) ?? 0.5;
      _brightness = prefs.getDouble(_keyBrightness) ?? 0.7;
      _autoBrightness = prefs.getBool(_keyAutoBrightness) ?? false;
      _reminderEnabled = prefs.getBool(_keyReminderEnabled) ?? true;
      _reminderInterval = prefs.getInt(_keyReminderInterval) ?? 20;
      _scheduledStart = prefs.getString(_keyScheduledStart) ?? "22:00";
      _scheduledEnd = prefs.getString(_keyScheduledEnd) ?? "07:00";
      _scheduledEnabled = prefs.getBool(_keyScheduledEnabled) ?? false;
      _dailyGoalMinutes = prefs.getInt(_keyDailyGoalMinutes) ?? 240;
      _darkMode = prefs.getBool(_keyDarkMode) ?? false;
      _onboardingCompleted = prefs.getBool(_keyOnboardingCompleted) ?? false;
      _pomodoroWorkMinutes = prefs.getInt(_keyPomodoroWorkMinutes) ?? 25;
      _pomodoroBreakMinutes = prefs.getInt(_keyPomodoroBreakMinutes) ?? 5;
    } catch (e) {
      debugPrint('SettingsProvider.load failed: $e');
      // 使用默认值继续运行，避免 app crash
    } finally {
      notifyListeners();
    }
  }

  /// 批量保存所有设置到 SharedPreferences
  /// SharedPreferences 没有真正的事务，用 try-catch 提供基本错误隔离
  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyBlueLightEnabled, _blueLightEnabled);
      await prefs.setDouble(_keyBlueLightIntensity, _blueLightIntensity);
      await prefs.setDouble(_keyBrightness, _brightness);
      await prefs.setBool(_keyAutoBrightness, _autoBrightness);
      await prefs.setBool(_keyReminderEnabled, _reminderEnabled);
      await prefs.setInt(_keyReminderInterval, _reminderInterval);
      await prefs.setString(_keyScheduledStart, _scheduledStart);
      await prefs.setString(_keyScheduledEnd, _scheduledEnd);
      await prefs.setBool(_keyScheduledEnabled, _scheduledEnabled);
      await prefs.setInt(_keyDailyGoalMinutes, _dailyGoalMinutes);
      await prefs.setBool(_keyDarkMode, _darkMode);
      await prefs.setBool(_keyOnboardingCompleted, _onboardingCompleted);
      await prefs.setInt(_keyPomodoroWorkMinutes, _pomodoroWorkMinutes);
      await prefs.setInt(_keyPomodoroBreakMinutes, _pomodoroBreakMinutes);
    } catch (e) {
      debugPrint('SettingsProvider._save failed: $e');
      rethrow;
    }
  }

  Future<void> setBlueLightEnabled(bool v) async {
    _blueLightEnabled = v;
    notifyListeners();
    await _save();
  }

  Future<void> setBlueLightIntensity(double v) async {
    _blueLightIntensity = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setBrightness(double v) async {
    _brightness = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setAutoBrightness(bool v) async {
    _autoBrightness = v;
    notifyListeners();
    await _save();
  }

  Future<void> setReminderEnabled(bool v) async {
    _reminderEnabled = v;
    notifyListeners();
    await _save();
  }

  Future<void> setReminderInterval(int v) async {
    _reminderInterval = v;
    notifyListeners();
    await _save();
  }

  Future<void> setScheduledStart(String v) async {
    _scheduledStart = v;
    notifyListeners();
    await _save();
  }

  Future<void> setScheduledEnd(String v) async {
    _scheduledEnd = v;
    notifyListeners();
    await _save();
  }

  Future<void> setScheduledEnabled(bool v) async {
    _scheduledEnabled = v;
    notifyListeners();
    await _save();
  }

  Future<void> setDailyGoalMinutes(int v) async {
    _dailyGoalMinutes = v;
    notifyListeners();
    await _save();
  }

  Future<void> setDarkMode(bool v) async {
    _darkMode = v;
    notifyListeners();
    await _save();
  }

  Future<void> setOnboardingCompleted(bool v) async {
    _onboardingCompleted = v;
    notifyListeners();
    await _save();
  }

  Future<void> setPomodoroWorkMinutes(int v) async {
    _pomodoroWorkMinutes = v;
    notifyListeners();
    await _save();
  }

  Future<void> setPomodoroBreakMinutes(int v) async {
    _pomodoroBreakMinutes = v;
    notifyListeners();
    await _save();
  }

  String getPresetLabel() {
    if (_blueLightIntensity < 0.2) return '日间模式';
    if (_blueLightIntensity < 0.5) return '阅读模式';
    if (_blueLightIntensity < 0.75) return '夜间模式';
    return '深夜模式';
  }
}
