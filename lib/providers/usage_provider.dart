import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../services/usage_stats_service.dart';

final usageProviderProvider = ChangeNotifierProvider<UsageProvider>((ref) {
  return UsageProvider();
});

/// 静态工厂：初始化 UsageProvider 并等待数据加载完成
Future<UsageProvider> initializeUsage() async {
  final instance = UsageProvider();
  await instance.loadToday();
  return instance;
}

class AppUsage {
  final String packageName;
  final String appName;
  final int usageMinutes;
  final String category;

  AppUsage({
    required this.packageName,
    required this.appName,
    required this.usageMinutes,
    required this.category,
  });
}

class DayUsage {
  final DateTime date;
  final int totalMinutes;
  final List<AppUsage> apps;
  final int goalMinutes;

  DayUsage({
    required this.date,
    required this.totalMinutes,
    required this.apps,
    this.goalMinutes = 240,
  });

  double get goalProgress => (totalMinutes / goalMinutes).clamp(0.0, 2.0);
  bool get goalExceeded => totalMinutes > goalMinutes;
}

class UsageProvider extends ChangeNotifier {
  // Completer 保证数据库只初始化一次，避免懒加载竞态
  static Future<Database>? _dbCompleter;
  static const String _tableName = 'usage_records';
  static const String _tableName2 = 'app_usage';

  DayUsage? _todayUsage;
  List<DayUsage> _weekUsage = [];
  int _todayTotalMinutes = 0;

  DayUsage? get todayUsage => _todayUsage;
  List<DayUsage> get weekUsage => _weekUsage;
  int get todayTotalMinutes => _todayTotalMinutes;

  Future<Database> get db async {
    if (_dbCompleter != null) return _dbCompleter!;
    _dbCompleter = _initDb();
    return _dbCompleter!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      path.join(dbPath, 'eye_care.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE,
            total_minutes INTEGER NOT NULL,
            goal_minutes INTEGER NOT NULL DEFAULT 240
          )
        ''');
        await db.execute('''
          CREATE TABLE $_tableName2 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL,
            package_name TEXT NOT NULL,
            app_name TEXT NOT NULL,
            usage_minutes INTEGER NOT NULL,
            category TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 未来版本可在此添加字段迁移
        // 例：if (oldVersion < 2) { await db.execute('ALTER TABLE ...'); }
      },
    );
  }

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> loadToday() async {
    final today = DateTime.now();
    _todayTotalMinutes = await _getDayMinutes(today);

    final database = await db;
    final dayRow = await database.query(
      _tableName,
      where: 'date = ?',
      whereArgs: [_dateKey(today)],
    );

    if (dayRow.isNotEmpty) {
      final apps = await _getDayApps(today);
      _todayUsage = DayUsage(
        date: today,
        totalMinutes: dayRow[0]['total_minutes'] as int,
        apps: apps,
        goalMinutes: dayRow[0]['goal_minutes'] as int,
      );
    } else {
      _todayUsage = DayUsage(
        date: today,
        totalMinutes: _todayTotalMinutes,
        apps: [],
        goalMinutes: 240,
      );
    }

    await _loadWeek();
    notifyListeners();
  }

  Future<void> _loadWeek() async {
    _weekUsage = [];
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final mins = await _getDayMinutes(d);
      final database = await db;
      final row = await database.query(_tableName, where: 'date = ?', whereArgs: [_dateKey(d)]);
      _weekUsage.add(DayUsage(
        date: d,
        totalMinutes: mins,
        apps: [],
        goalMinutes: row.isNotEmpty ? row[0]['goal_minutes'] as int : 240,
      ));
    }
  }

  Future<int> _getDayMinutes(DateTime day) async {
    final database = await db;
    final row = await database.query(_tableName, where: 'date = ?', whereArgs: [_dateKey(day)]);
    if (row.isNotEmpty) return row[0]['total_minutes'] as int;
    return 0;
  }

  Future<List<AppUsage>> _getDayApps(DateTime day) async {
    final database = await db;
    final rows = await database.query(_tableName2, where: 'date = ?', whereArgs: [_dateKey(day)]);
    return rows.map((r) => AppUsage(
      packageName: r['package_name'] as String,
      appName: r['app_name'] as String,
      usageMinutes: r['usage_minutes'] as int,
      category: r['category'] as String,
    )).toList();
  }

  Future<void> addMinutes(int minutes) async {
    final today = DateTime.now();
    final database = await db;
    final key = _dateKey(today);
    final existing = await database.query(_tableName, where: 'date = ?', whereArgs: [key]);

    if (existing.isEmpty) {
      await database.insert(_tableName, {
        'date': key,
        'total_minutes': minutes,
        'goal_minutes': 240,
      });
    } else {
      await database.rawUpdate(
        'UPDATE $_tableName SET total_minutes = total_minutes + ? WHERE date = ?',
        [minutes, key],
      );
    }
    _todayTotalMinutes += minutes;
    await loadToday();
  }

  Future<void> setGoalMinutes(int minutes) async {
    final today = DateTime.now();
    final database = await db;
    final key = _dateKey(today);
    await database.update(
      _tableName,
      {'goal_minutes': minutes},
      where: 'date = ?',
      whereArgs: [key],
    );
    await loadToday();
  }

  Future<void> refreshUsage() async {
    await loadToday();
  }

  /// 从原生服务同步屏幕使用时间到数据库
  /// 当前版本通过 UsageStatsService 调用原生（需配合 Android 原生代码）
  /// 若原生服务不可用，则跳过同步，保留本地数据
  Future<void> syncScreenTimeFromNative() async {
    try {
      final screenMinutes = await UsageStatsService.getTodayScreenMinutes();
      if (screenMinutes > 0) {
        final today = DateTime.now();
        final database = await db;
        final key = _dateKey(today);
        final existing = await database.query(_tableName, where: 'date = ?', whereArgs: [key]);
        if (existing.isEmpty) {
          await database.insert(_tableName, {
            'date': key,
            'total_minutes': screenMinutes,
            'goal_minutes': 240,
          });
        } else {
          // 如果本地记录比原生更少，则用原生数据覆盖
          final local = existing[0]['total_minutes'] as int;
          if (screenMinutes > local) {
            await database.update(
              _tableName,
              {'total_minutes': screenMinutes},
              where: 'date = ?',
              whereArgs: [key],
            );
          }
        }
        await loadToday();
      }
    } catch (e) {
      // 原生服务不可用（未授权/无原生实现），静默跳过
      debugPrint('syncScreenTimeFromNative skipped: $e');
    }
  }

  /// 计算 7 日平均使用时长（分钟）
  int avgWeekMinutes() {
    if (_weekUsage.isEmpty) return 0;
    final total = _weekUsage.fold(0, (sum, d) => sum + d.totalMinutes);
    return (total / _weekUsage.length).round();
  }

  /// 填充今日模拟数据（仅在数据库无今日数据时调用一次）
  /// 不再内部调用 loadToday()，由调用方负责刷新 UI
  Future<void> populateSimulatedData() async {
    final today = DateTime.now();
    final database = await db;
    final key = _dateKey(today);

    // 检查是否已有今日数据，如果有就不再填充模拟数据
    final existing = await database.query(_tableName, where: 'date = ?', whereArgs: [key]);
    if (existing.isNotEmpty) return;

    // 无数据时才填充模拟演示数据
    await database.insert(_tableName, {
      'date': key,
      'total_minutes': 0,
      'goal_minutes': 240,
    });

    final apps = [
      ('com.tencent.mm', '微信', 0, '社交'),
      ('com.tencent.mobileqq', 'QQ', 0, '社交'),
      ('com.zhihu', '知乎', 0, '阅读'),
      ('com.ss.android.ugc.aweme', '抖音', 0, '视频'),
      ('com.spotify', '音乐', 0, '其他'),
    ];

    for (final app in apps) {
      final existingApp = await database.query(
        _tableName2,
        where: 'date = ? AND package_name = ?',
        whereArgs: [key, app.$1],
      );
      if (existingApp.isEmpty) {
        await database.insert(_tableName2, {
          'date': key,
          'package_name': app.$1,
          'app_name': app.$2,
          'usage_minutes': app.$3,
          'category': app.$4,
        });
      }
    }
  }

  /// 刷新今日数据（供外部调用）
  Future<void> refreshToday() async {
    await loadToday();
  }
}
