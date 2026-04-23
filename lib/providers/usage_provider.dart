import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

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
  static Database? _db;
  static const String _tableName = 'usage_records';
  static const String _tableName2 = 'app_usage';

  DayUsage? _todayUsage;
  List<DayUsage> _weekUsage = [];
  int _todayTotalMinutes = 0;

  DayUsage? get todayUsage => _todayUsage;
  List<DayUsage> get weekUsage => _weekUsage;
  int get todayTotalMinutes => _todayTotalMinutes;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
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
    return _db!;
  }

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> loadToday() async {
    final today = DateTime.now();
    _todayTotalMinutes = await _getDayMinutes(today);

    final db = await this.db;
    final dayRow = await db.query(
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
      final db = await this.db;
      final row = await db.query(_tableName, where: 'date = ?', whereArgs: [_dateKey(d)]);
      _weekUsage.add(DayUsage(
        date: d,
        totalMinutes: mins,
        apps: [],
        goalMinutes: row.isNotEmpty ? row[0]['goal_minutes'] as int : 240,
      ));
    }
  }

  Future<int> _getDayMinutes(DateTime day) async {
    final db = await this.db;
    final row = await db.query(_tableName, where: 'date = ?', whereArgs: [_dateKey(day)]);
    if (row.isNotEmpty) return row[0]['total_minutes'] as int;
    return 0;
  }

  Future<List<AppUsage>> _getDayApps(DateTime day) async {
    final db = await this.db;
    final rows = await db.query(_tableName2, where: 'date = ?', whereArgs: [_dateKey(day)]);
    return rows.map((r) => AppUsage(
      packageName: r['package_name'] as String,
      appName: r['app_name'] as String,
      usageMinutes: r['usage_minutes'] as int,
      category: r['category'] as String,
    )).toList();
  }

  Future<void> addMinutes(int minutes) async {
    final today = DateTime.now();
    final db = await this.db;
    final key = _dateKey(today);
    final existing = await db.query(_tableName, where: 'date = ?', whereArgs: [key]);

    if (existing.isEmpty) {
      await db.insert(_tableName, {
        'date': key,
        'total_minutes': minutes,
        'goal_minutes': 240,
      });
    } else {
      await db.rawUpdate(
        'UPDATE $_tableName SET total_minutes = total_minutes + ? WHERE date = ?',
        [minutes, key],
      );
    }
    _todayTotalMinutes += minutes;
    await loadToday();
  }

  Future<void> setGoalMinutes(int minutes) async {
    final today = DateTime.now();
    final db = await this.db;
    final key = _dateKey(today);
    await db.update(
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

  String _categoryOf(String packageName) {
    final p = packageName.toLowerCase();
    if (p.contains('weibo') || p.contains('weixin') || p.contains('qq') ||
        p.contains('telegram') || p.contains('whatsapp') || p.contains('discord')) {
      return '社交';
    }
    if (p.contains('douyin') || p.contains('youtube') || p.contains('bilibili') ||
        p.contains('netflix') || p.contains('video') || p.contains('腾讯视频') ||
        p.contains('爱奇艺') || p.contains('优酷')) {
      return '视频';
    }
    if (p.contains('game') || p.contains('游戏')) {
      return '游戏';
    }
    if (p.contains('read') || p.contains('阅读') || p.contains('book') ||
        p.contains('知乎') || p.contains('今日头条')) {
      return '阅读';
    }
    return '其他';
  }

  String _appNameOf(String packageName) {
    const _appNameMap = {
      'com.tencent.mm': '微信',
      'com.tencent.mobileqq': 'QQ',
      'com.zhihu': '知乎',
      'cn.jingwei': '今日头条',
      'com.sina.weibo': '微博',
      'com.ishumei': '输入法',
      'com.ss.android.ugc.aweme': '抖音',
      'com.baidu.input': '百度输入法',
      'com.iflytek.inputmethod': '讯飞输入法',
    };
    for (final entry in _appNameMap.entries) {
      if (packageName.contains(entry.key)) {
        return entry.value;
      }
    }
    // 兜底：取最后一段，清理掉可能的数字后缀
    final last = packageName.split('.').last;
    final cleaned = last.replaceAll(RegExp(r'\d+$'), '');
    return cleaned.isEmpty ? last : cleaned;
  }

  /// 填充今日模拟数据（仅在数据库无今日数据时调用一次）
  /// 不再内部调用 loadToday()，由调用方负责刷新 UI
  Future<void> populateSimulatedData() async {
    final today = DateTime.now();
    final db = await this.db;
    final key = _dateKey(today);

    // 检查是否已有今日数据，如果有就不再填充模拟数据
    final existing = await db.query(_tableName, where: 'date = ?', whereArgs: [key]);
    if (existing.isNotEmpty) return;

    // 无数据时才填充模拟演示数据
    await db.insert(_tableName, {
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
      final existingApp = await db.query(
        _tableName2,
        where: 'date = ? AND package_name = ?',
        whereArgs: [key, app.$1],
      );
      if (existingApp.isEmpty) {
        await db.insert(_tableName2, {
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

  /// 从原生服务同步屏幕使用时间
  Future<void> syncScreenTimeFromNative() async {
    // 使用 MethodChannel 调用原生代码获取屏幕时间
    // 这会触发 ScreenTimeService 返回当前累计的分钟数
    // 然后存入数据库
  }
}