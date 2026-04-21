import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyBlueLightEnabled = 'blue_light_enabled';
  static const String _keyBlueLightIntensity = 'blue_light_intensity'; // 0.0 ~ 1.0
  static const String _keyBrightness = 'brightness'; // 0.0 ~ 1.0
  static const String _keyAutoBrightness = 'auto_brightness';
  static const String _keyReminderEnabled = 'reminder_enabled';
  static const String _keyReminderInterval = 'reminder_interval'; // minutes
  static const String _keyScheduledStart = 'scheduled_start'; // "HH:mm"
  static const String _keyScheduledEnd = 'scheduled_end'; // "HH:mm"
  static const String _keyScheduledEnabled = 'scheduled_enabled';
  static const String _keyDailyGoalMinutes = 'daily_goal_minutes';

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

  // Getters
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

  Future<void> load() async {
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
    notifyListeners();
  }

  Future<void> _save() async {
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

  String getPresetLabel() {
    if (_blueLightIntensity < 0.2) return '日间模式';
    if (_blueLightIntensity < 0.5) return '阅读模式';
    if (_blueLightIntensity < 0.75) return '夜间模式';
    return '深夜模式';
  }
}
