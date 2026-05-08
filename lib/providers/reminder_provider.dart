import 'dart:async';
import 'package:flutter/widgets.dart';
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
  bool _reminderEnabled = true;

  // App 生命周期标记：防止后台计时误差累积
  DateTime? _pausedAt;

  List<ReminderRecord> get todayRecords => _todayRecords;
  int get todayEyeRestCount => _todayEyeRestCount;
  int get todayUsageLimitCount => _todayUsageLimitCount;
  bool get isRunning => _isRunning;
  int get elapsedSeconds => _elapsedSeconds;
  int get intervalMinutes => _intervalMinutes;
  bool get reminderEnabled => _reminderEnabled;

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

  /// 设置提醒开关状态，关闭时停止计时器
  void setEnabled(bool enabled) {
    _reminderEnabled = enabled;
    if (!enabled) {
      _stopTimerInternal();
    }
    notifyListeners();
  }

  /// 设置提醒间隔，如果计时器正在运行则立即以新间隔重启
  void updateInterval(int minutes) {
    _intervalMinutes = minutes;
    final wasRunning = _isRunning;
    if (wasRunning) {
      // 重启以新间隔计时
      _stopTimerInternal();
      _elapsedSeconds = 0;
      _startTimerInternal();
    }
    notifyListeners();
  }

  void startTimer(int intervalMinutes) {
    _intervalMinutes = intervalMinutes;
    _elapsedSeconds = 0;
    _isRunning = true;
    _startTimerInternal();
    notifyListeners();
  }

  void stopTimer() {
    _stopTimerInternal();
    _isRunning = false;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  /// 内部计时器逻辑，不修改 isRunning 状态
  void _startTimerInternal() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      if (_elapsedSeconds >= _intervalMinutes * 60) {
        if (_reminderEnabled) {
          addReminder('eye_rest');
        }
        _elapsedSeconds = 0;
      }
      notifyListeners();
    });
  }

  void _stopTimerInternal() {
    _timer?.cancel();
    _timer = null;
  }

  // ========== App 生命周期 ==========

  /// 注册 App 生命周期监听（由 Consumer 在 Screen 层调用）
  void registerLifecycleCallbacks() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lifecycleObserver.attach(this);
      WidgetsBinding.instance.addObserver(_lifecycleObserver);
    });
  }

  static final _AppLifecycleObserver _lifecycleObserver =
      _AppLifecycleObserver._();

  /// 移除监听（Provider dispose 时调用）
  void unregisterLifecycleCallbacks() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    unregisterLifecycleCallbacks();
    _stopTimerInternal();
    super.dispose();
  }
}

typedef _LifecycleCallback = void Function(AppLifecycleState state);

class _AppLifecycleObserver with WidgetsBindingObserver {
  _AppLifecycleObserver._();

  _LifecycleCallback? _onStateChange;

  void attach(ReminderProvider provider) {
    _onStateChange = provider._handleLifecycleState;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _onStateChange?.call(state);
  }
}

extension _ReminderProviderLifecycle on ReminderProvider {
  void _handleLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _pausedAt = DateTime.now();
        _stopTimerInternal();
        break;
      case AppLifecycleState.resumed:
        if (_pausedAt != null && _isRunning) {
          final elapsed = DateTime.now().difference(_pausedAt!).inSeconds;
          _elapsedSeconds += elapsed;
          if (_elapsedSeconds >= _intervalMinutes * 60) {
            final cycles = _elapsedSeconds ~/ (_intervalMinutes * 60);
            for (int i = 0; i < cycles; i++) {
              if (_reminderEnabled) {
                addReminder('eye_rest');
              }
            }
            _elapsedSeconds = _elapsedSeconds % (_intervalMinutes * 60);
          }
          _pausedAt = null;
          _startTimerInternal();
        }
        break;
      default:
        break;
    }
  }
}
