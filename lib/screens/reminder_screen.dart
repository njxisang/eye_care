import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/notification_service.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen> {
  Timer? _timer;
  int _elapsed = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    NotificationService.init();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int intervalMinutes) {
    _timer?.cancel();
    _elapsed = 0;
    _isRunning = true;
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _elapsed++;
      if (_elapsed >= intervalMinutes) {
        _triggerReminder();
        _elapsed = 0;
      }
      setState(() {});
    });
    setState(() {});
  }

  void _stopTimer() {
    _timer?.cancel();
    _isRunning = false;
    _elapsed = 0;
    setState(() {});
  }

  Future<void> _triggerReminder() async {
    await NotificationService.showEyeRestReminder();
    if (mounted) {
      final reminder = ref.read(reminderProviderProvider);
      await reminder.addReminder('eye_rest');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProviderProvider);
    final reminder = ref.watch(reminderProviderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('护眼提醒'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 20-20-20法则说明
            Card(
              color: const Color(0xFFE8F5E9),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.visibility,
                      size: 48,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '20-20-20 法则',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '每工作 20 分钟，远眺 20 英尺（约6米）\n持续 20 秒，让眼睛放松',
                            style: TextStyle(
                              color: Colors.grey[700],
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
            const SizedBox(height: 16),

            // 提醒开关
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.notifications_active,
                        color: Color(0xFF4CAF50),
                        size: 32,
                      ),
                      title: const Text(
                        '护眼提醒',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('开启后自动定时提醒'),
                      trailing: Switch(
                        value: settings.reminderEnabled,
                        onChanged: (v) => settings.setReminderEnabled(v),
                        activeColor: const Color(0xFF4CAF50),
                      ),
                    ),
                    if (settings.reminderEnabled) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        '提醒间隔',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [10, 15, 20, 25, 30, 45, 60].map((mins) {
                          final selected = settings.reminderInterval == mins;
                          return ChoiceChip(
                            label: Text('$mins 分钟'),
                            selected: selected,
                            selectedColor: const Color(0xFF4CAF50),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : Colors.black87,
                            ),
                            onSelected: (v) {
                              if (v) settings.setReminderInterval(mins);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 计时器
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      '下次提醒倒计时',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 160,
                          child: CircularProgressIndicator(
                            value: _isRunning
                                ? (_elapsed / settings.reminderInterval)
                                    .clamp(0.0, 1.0)
                                : 0,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF4CAF50),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Text(
                              _isRunning
                                  ? '${settings.reminderInterval - _elapsed}'
                                  : '--',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4CAF50),
                              ),
                            ),
                            Text(
                              '分钟',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_isRunning)
                          ElevatedButton.icon(
                            onPressed: () => _startTimer(
                                settings.reminderInterval),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('开始计时'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                          ))
                        else
                          OutlinedButton.icon(
                            onPressed: _stopTimer,
                            icon: const Icon(Icons.stop),
                            label: const Text('停止'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '今日提醒统计',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await reminder.clearToday();
                          },
                          child: const Text('清除'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatTile(
                            icon: Icons.visibility,
                            count: reminder.todayEyeRestCount,
                            label: '护眼提醒',
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            icon: Icons.timer,
                            count: reminder.todayUsageLimitCount,
                            label: '时长提醒',
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (reminder.todayRecords.isNotEmpty) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      ...reminder.todayRecords.take(5).map((r) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(
                                  r.type == 'eye_rest'
                                      ? Icons.visibility
                                      : Icons.timer,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(r.time),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  r.type == 'eye_rest' ? '护眼提醒' : '时长提醒',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ] else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '暂无提醒记录',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ),
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

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
