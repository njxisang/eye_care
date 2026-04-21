import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/usage_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/blue_light_service.dart';
import '../widgets/stat_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyBlueLight();
    });
  }

  void _applyBlueLight() {
    final settings = context.read<SettingsProvider>();
    if (settings.blueLightEnabled) {
      BlueLightService.setFilter(settings.blueLightIntensity, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final usage = context.watch<UsageProvider>();
    final reminder = context.watch<ReminderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('护眼宝'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 护眼状态卡片
            _buildStatusCard(settings),
            const SizedBox(height: 16),

            // 今日数据
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: '今日时长',
                    value: _formatMinutes(usage.todayTotalMinutes),
                    subtitle: '目标 ${usage.todayUsage?.goalMinutes ?? 240} 分钟',
                    icon: Icons.timer_outlined,
                    color: _getUsageColor(usage.todayUsage?.goalProgress ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: '护眼提醒',
                    value: '${reminder.todayEyeRestCount}',
                    subtitle: '次护眼提醒',
                    icon: Icons.visibility_outlined,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 快捷开关
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '快捷开关',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSwitchTile(
                      icon: Icons.wb_sunny,
                      title: '护眼滤光',
                      subtitle: settings.getPresetLabel(),
                      value: settings.blueLightEnabled,
                      onChanged: (v) async {
                        await settings.setBlueLightEnabled(v);
                        _applyBlueLight();
                      },
                    ),
                    const Divider(),
                    _buildSwitchTile(
                      icon: Icons.notifications,
                      title: '护眼提醒',
                      subtitle: '每${settings.reminderInterval}分钟提醒一次',
                      value: settings.reminderEnabled,
                      onChanged: (v) => settings.setReminderEnabled(v),
                    ),
                    const Divider(),
                    _buildSwitchTile(
                      icon: Icons.schedule,
                      title: '定时开关',
                      subtitle: settings.scheduledEnabled
                          ? '${settings.scheduledStart} - ${settings.scheduledEnd}'
                          : '未设置',
                      value: settings.scheduledEnabled,
                      onChanged: (v) => settings.setScheduledEnabled(v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 使用时长进度
            if (usage.todayUsage != null) _buildUsageProgress(usage),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(SettingsProvider settings) {
    final isActive = settings.blueLightEnabled;
    return Card(
      color: isActive ? const Color(0xFFFFF8E1) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.visibility : Icons.visibility_off,
              size: 48,
              color: isActive ? const Color(0xFFFF9800) : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? '护眼模式已开启' : '护眼模式已关闭',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isActive
                        ? '色温 ${(settings.blueLightIntensity * 100).toInt()}% | ${settings.getPresetLabel()}'
                        : '点击上方开关启用护眼模式',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(settings.blueLightIntensity * 100).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFFFF9800),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF4CAF50)),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4CAF50),
      ),
    );
  }

  Widget _buildUsageProgress(UsageProvider usage) {
    final progress = (usage.todayUsage!.goalProgress).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '今日使用时长',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_formatMinutes(usage.todayUsage!.totalMinutes)} / ${_formatMinutes(usage.todayUsage!.goalMinutes)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                  _getUsageColor(usage.todayUsage!.goalProgress),
                ),
              ),
            ),
            if (usage.todayUsage!.goalExceeded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '⚠️ 已超过今日目标 ${_formatMinutes(usage.todayUsage!.totalMinutes - usage.todayUsage!.goalMinutes)}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SettingsSheet(),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}小时${m}分钟' : '${h}小时';
  }

  Color _getUsageColor(double progress) {
    if (progress > 1.0) return Colors.red;
    if (progress > 0.8) return Colors.orange;
    return const Color(0xFF4CAF50);
  }
}

class _SettingsSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '设置',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('每日使用时长目标'),
            subtitle: Text('${settings.dailyGoalMinutes} 分钟'),
            onTap: () async {
              final result = await showDialog<int>(
                context: context,
                builder: (context) => _GoalPickerDialog(
                  current: settings.dailyGoalMinutes,
                ),
              );
              if (result != null) {
                await settings.setDailyGoalMinutes(result);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('提醒间隔'),
            subtitle: Text('每 ${settings.reminderInterval} 分钟'),
            onTap: () async {
              final result = await showDialog<int>(
                context: context,
                builder: (context) => _IntervalPickerDialog(
                  current: settings.reminderInterval,
                ),
              );
              if (result != null) {
                await settings.setReminderInterval(result);
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GoalPickerDialog extends StatefulWidget {
  final int current;
  _GoalPickerDialog({required this.current});

  @override
  State<_GoalPickerDialog> createState() => _GoalPickerDialogState();
}

class _GoalPickerDialogState extends State<_GoalPickerDialog> {
  late int _selected;
  final _options = [120, 180, 240, 300, 360, 480, 600];

  @override
  void initState() {
    super.initState();
    _selected = _options.contains(widget.current) ? widget.current : 240;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('每日使用时长目标'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _options.map((v) {
          final h = v ~/ 60;
          final label = h > 0 ? '${h}小时' : '${v}分钟';
          return RadioListTile<int>(
            title: Text(label),
            value: v,
            groupValue: _selected,
            onChanged: (val) => setState(() => _selected = val!),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _IntervalPickerDialog extends StatefulWidget {
  final int current;
  _IntervalPickerDialog({required this.current});

  @override
  State<_IntervalPickerDialog> createState() => _IntervalPickerDialogState();
}

class _IntervalPickerDialogState extends State<_IntervalPickerDialog> {
  late int _selected;
  final _options = [10, 15, 20, 25, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _selected = _options.contains(widget.current) ? widget.current : 20;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('提醒间隔'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: _options.map((v) {
          return RadioListTile<int>(
            title: Text('$v 分钟'),
            value: v,
            groupValue: _selected,
            onChanged: (val) => setState(() => _selected = val!),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selected),
          child: const Text('确定'),
        ),
      ],
    );
  }
}
