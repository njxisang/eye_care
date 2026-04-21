import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class ReminderRecord {
  final DateTime time;
  final String type; // 'eye_rest', 'usage_limit'

  ReminderRecord({required this.time, required this.type});
}

class ReminderProvider extends ChangeNotifier {
  static Database? _db;
  static const String _tableName = 'reminder_records';

  List<ReminderRecord> _todayRecords = [];
  int _todayEyeRestCount = 0;
  int _todayUsageLimitCount = 0;

  List<ReminderRecord> get todayRecords => _todayRecords;
  int get todayEyeRestCount => _todayEyeRestCount;
  int get todayUsageLimitCount => _todayUsageLimitCount;

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
    final db = await this.db;
    final rows = await db.query(
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
    final db = await this.db;
    await db.insert(_tableName, {
      'time': now.toIso8601String(),
      'type': type,
    });
    await loadToday();
  }

  Future<void> clearToday() async {
    final today = DateTime.now();
    final key = _dateKey(today);
    final db = await this.db;
    await db.delete(_tableName, where: "time LIKE ?", whereArgs: ['$key%']);
    await loadToday();
  }
}
