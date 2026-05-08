import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../providers/usage_provider.dart';
import '../providers/reminder_provider.dart';
import '../services/blue_light_service.dart';
import '../widgets/stat_card.dart';
import '../utils/format_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyBlueLight();
    });
  }

  void _applyBlueLight() {
    final settings = ref.read(settingsProviderProvider);
    if (settings.blueLightEnabled) {
      BlueLightService.setFilter(settings.blueLightIntensity, context);
    } else {
      BlueLightService.removeFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProviderProvider);
    final usage = ref.watch(usageProviderProvider);
    final reminder = ref.watch(reminderProviderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('护眼宝'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => context.push('/knowledge'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
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
                    value: FormatUtils.formatMinutes(usage.todayTotalMinutes),
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

            // 番茄工作法入口
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/pomodoro'),
                icon: const Icon(Icons.timer),
                label: const Text('开始专注（番茄钟）'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(SettingsProvider settings) {
    final isActive = settings.blueLightEnabled;
    return Card(
      color: isActive ? const Color(0xFFFFF8E1) : Colors.white,
      child: InkWell(
        onTap: () {
          context.go('/blue-light');
        },
        borderRadius: BorderRadius.circular(16),
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
                  '${FormatUtils.formatMinutes(usage.todayUsage!.totalMinutes)} / ${FormatUtils.formatMinutes(usage.todayUsage!.goalMinutes)}',
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
                  '⚠️ 已超过今日目标 ${FormatUtils.formatMinutes(usage.todayUsage!.totalMinutes - usage.todayUsage!.goalMinutes)}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getUsageColor(double progress) {
    if (progress > 1.0) return Colors.red;
    if (progress > 0.8) return Colors.orange;
    return const Color(0xFF4CAF50);
  }
}
