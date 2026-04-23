import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

final reminderProviderProvider = ChangeNotifierProvider<ReminderProvider>((ref) {
  return ReminderProvider();
});

/// 静态工厂：初始化 ReminderProvider 并等待数据加载完成
Future<ReminderProvider> initializeReminder() async {
  final instance = ReminderProvider();
  await instance.load();
  return instance;
}

class ReminderRecord {
  final DateTime time;
  final String type;

  ReminderRecord({required this.time, required this.type});
}

class ReminderProvider extends ChangeNotifier {
  static Database? _db;
  static const String _tableName = 'reminder_records';

  List<ReminderRecord> _todayRecords = [];
  int _todayEyeRestCount = 0;
  int _todayUsageLimitCount = 0;

  // 倒计时状态
  Timer? _timer;
  bool _isRunning = false;
  int _elapsedSeconds = 0;
  int _intervalMinutes = 20;

  List<ReminderRecord> get todayRecords => _todayRecords;
  int get todayEyeRestCount => _todayEyeRestCount;
  int get todayUsageLimitCount => _todayUsageLimitCount;
  bool get isRunning => _isRunning;
  int get elapsedSeconds => _elapsedSeconds;
  int get intervalMinutes => _intervalMinutes;

  int get remainingSeconds => _intervalMinutes * 60 - _elapsedSeconds;
  double get progress => (_elapsedSeconds / (_intervalMinutes * 60)).clamp(0.0, 1.0);

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      path.join(dbPath, 'eye_care_reminder.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            time TEXT NOT NULL,
            type TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 未来版本可在此添加字段迁移
      },
    );
    return _db!;
  }

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> load() async {
    await loadToday();
  }

  Future<void> loadToday() async {
    final today = DateTime.now();
    final key = _dateKey(today);
    final database = await db;
    final rows = await database.query(
      _tableName,
      where: "time LIKE ?",
      whereArgs: ['$key%'],
    );
    _todayRecords = rows.map((r) => ReminderRecord(
      time: DateTime.parse(r['time'] as String),
      type: r['type'] as String,
    )).toList();
    _todayEyeRestCount = _todayRecords.where((r) => r.type == 'eye_rest').length;
    _todayUsageLimitCount = _todayRecords.where((r) => r.type == 'usage_limit').length;
    notifyListeners();
  }

  Future<void> addReminder(String type) async {
    final now = DateTime.now();
    final database = await db;
    await database.insert(_tableName, {
      'time': now.toIso8601String(),
      'type': type,
    });
    await loadToday();
  }

  Future<void> clearToday() async {
    final today = DateTime.now();
    final key = _dateKey(today);
    final database = await db;
    await database.delete(_tableName, where: "time LIKE ?", whereArgs: ['$key%']);
    await loadToday();
  }

  void startTimer(int intervalMinutes) {
    _timer?.cancel();
    _intervalMinutes = intervalMinutes;
    _elapsedSeconds = 0;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      _elapsedSeconds++;
      if (_elapsedSeconds >= _intervalMinutes * 60) {
        await addReminder('eye_rest');
        _elapsedSeconds = 0;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  void updateInterval(int minutes) {
    _intervalMinutes = minutes;
    notifyListeners();
  }
}