import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final pomodoroProviderProvider = ChangeNotifierProvider<PomodoroProvider>((ref) {
  return PomodoroProvider();
});

class PomodoroProvider extends ChangeNotifier {
  bool _isRunning = false;
  bool _isWorkPhase = true;
  int _elapsedSeconds = 0;
  int _workMinutes = 25;
  int _breakMinutes = 5;
  int _todayCompleted = 0;

  bool get isRunning => _isRunning;
  bool get isWorkPhase => _isWorkPhase;
  int get elapsedSeconds => _elapsedSeconds;
  int get workMinutes => _workMinutes;
  int get breakMinutes => _breakMinutes;
  int get todayCompleted => _todayCompleted;

  int get remainingSeconds {
    final total = _isWorkPhase ? _workMinutes * 60 : _breakMinutes * 60;
    return total - _elapsedSeconds;
  }

  void setWorkMinutes(int minutes) {
    _workMinutes = minutes;
    notifyListeners();
  }

  void setBreakMinutes(int minutes) {
    _breakMinutes = minutes;
    notifyListeners();
  }

  void start() {
    _isRunning = true;
    _elapsedSeconds = 0;
    notifyListeners();
  }

  void tick() {
    if (_isRunning) {
      _elapsedSeconds++;
      if (remainingSeconds <= 0) {
        _isWorkPhase = !_isWorkPhase;
        _elapsedSeconds = 0;
        if (!_isWorkPhase) _todayCompleted++;
      }
      notifyListeners();
    }
  }

  void pause() {
    _isRunning = false;
    notifyListeners();
  }

  void reset() {
    _isRunning = false;
    _isWorkPhase = true;
    _elapsedSeconds = 0;
    notifyListeners();
  }
}

class PomodoroScreen extends ConsumerStatefulWidget {
  const PomodoroScreen({super.key});

  @override
  ConsumerState<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends ConsumerState<PomodoroScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(pomodoroProviderProvider.notifier).tick();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pomodoro = ref.watch(pomodoroProviderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('番茄工作法'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 说明卡片
            Card(
              color: const Color(0xFFE8F5E9),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.timer, size: 48, color: Color(0xFF4CAF50)),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '番茄工作法',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '专注25分钟工作，休息5分钟\n完成一个番茄钟后记录一次',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 计时器
            Text(
              pomodoro.isWorkPhase ? '专注时间' : '休息时间',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: pomodoro.isRunning
                        ? (pomodoro.elapsedSeconds /
                            (pomodoro.isWorkPhase
                                ? pomodoro.workMinutes * 60
                                : pomodoro.breakMinutes * 60))
                            .clamp(0.0, 1.0)
                        : 0,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(
                      pomodoro.isWorkPhase ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      _formatTime(pomodoro.remainingSeconds),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      pomodoro.isWorkPhase ? '工作中' : '休息中',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!pomodoro.isRunning)
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(pomodoroProviderProvider.notifier).start(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('开始'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(pomodoroProviderProvider.notifier).pause(),
                    icon: const Icon(Icons.pause),
                    label: const Text('暂停'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(pomodoroProviderProvider.notifier).reset(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('重置'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 设置
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '设置',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('工作时长'),
                        const Spacer(),
                        DropdownButton<int>(
                          value: pomodoro.workMinutes,
                          items: [15, 20, 25, 30, 45, 60]
                              .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text('$v 分钟'),
                                  ))
                              .toList(),
                          onChanged: (v) => ref
                              .read(pomodoroProviderProvider.notifier)
                              .setWorkMinutes(v!),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('休息时长'),
                        const Spacer(),
                        DropdownButton<int>(
                          value: pomodoro.breakMinutes,
                          items: [5, 10, 15, 20]
                              .map((v) => DropdownMenuItem(
                                    value: v,
                                    child: Text('$v 分钟'),
                                  ))
                              .toList(),
                          onChanged: (v) => ref
                              .read(pomodoroProviderProvider.notifier)
                              .setBreakMinutes(v!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 今日统计
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 32),
                    const SizedBox(width: 12),
                    Text(
                      '今日完成 ${pomodoro.todayCompleted} 个番茄钟',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}