import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProviderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 系统护眼引导
          Card(
            child: ListTile(
              leading: const Icon(Icons.brightness_6, color: Color(0xFF4CAF50)),
              title: const Text('系统护眼模式'),
              subtitle: const Text('引导开启系统级护眼设置'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showSystemEyeGuide(context),
            ),
          ),
          const SizedBox(height: 12),

          // 提醒设置
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications, color: Color(0xFF4CAF50)),
                  title: const Text('护眼提醒'),
                  trailing: Switch(
                    value: settings.reminderEnabled,
                    onChanged: (v) => settings.setReminderEnabled(v),
                    activeColor: const Color(0xFF4CAF50),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.timer, color: Colors.grey),
                  title: const Text('提醒间隔'),
                  trailing: DropdownButton<int>(
                    value: settings.reminderInterval,
                    items: [10, 15, 20, 25, 30, 45, 60]
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text('$v 分钟'),
                            ))
                        .toList(),
                    onChanged: (v) => settings.setReminderInterval(v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 番茄钟设置
          Card(
            child: ListTile(
              leading: const Icon(Icons.timer, color: Color(0xFF4CAF50)),
              title: const Text('番茄工作法'),
              subtitle: Text('工作${settings.pomodoroWorkMinutes}分钟，休息${settings.pomodoroBreakMinutes}分钟'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showPomodoroSettings(context, ref),
            ),
          ),
          const SizedBox(height: 12),

          // 外观
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode, color: Color(0xFF4CAF50)),
                  title: const Text('深色模式'),
                  trailing: Switch(
                    value: settings.darkMode,
                    onChanged: (v) => settings.setDarkMode(v),
                    activeColor: const Color(0xFF4CAF50),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.grey),
                  title: const Text('每日目标'),
                  trailing: DropdownButton<int>(
                    value: settings.dailyGoalMinutes,
                    items: [120, 180, 240, 300, 360, 480, 600]
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text('${v ~/ 60}小时'),
                            ))
                        .toList(),
                    onChanged: (v) => settings.setDailyGoalMinutes(v!),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 关于
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.grey),
                  title: const Text('关于护眼宝'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showAbout(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Colors.grey),
                  title: const Text('隐私政策'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showPrivacy(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSystemEyeGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '开启系统护眼模式',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '系统护眼模式可以在设备层面过滤蓝光，比应用内滤镜效果更好。',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Android
              const Text(
                'Android 设置',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _GuideStep(
                number: '1',
                title: '打开设置',
                desc: '点击下方按钮跳转，或手动打开手机「设置」应用',
              ),
              _GuideStep(
                number: '2',
                title: '找到护眼模式',
                desc: '在设置中搜索「护眼模式」或「夜间模式」',
              ),
              _GuideStep(
                number: '3',
                title: '开启并自定义',
                desc: '打开护眼模式，调整色温强度，可设置定时自动开启',
              ),
              const SizedBox(height: 24),

              // iOS
              const Text(
                'iOS 设置',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _GuideStep(
                number: '1',
                title: '打开设置',
                desc: '点击下方按钮跳转，或手动打开「设置」应用',
              ),
              _GuideStep(
                number: '2',
                title: '显示与亮度',
                desc: '找到并点击「显示与亮度」',
              ),
              _GuideStep(
                number: '3',
                title: '开启夜览',
                desc: '打开「夜览」功能，可设置自动开启时间',
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _openSystemSettings(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('打开系统设置'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSystemSettings(BuildContext context) async {
    const channel = MethodChannel('com.eyecare/system');

    try {
      if (Platform.isAndroid) {
        await channel.invokeMethod('openNightSettings');
      } else if (Platform.isIOS) {
        await channel.invokeMethod('openDisplaySettings');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请手动在系统设置中开启护眼模式')),
        );
      }
    }
  }

  void _showPomodoroSettings(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProviderProvider);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
            const SizedBox(height: 24),
            const Text(
              '番茄工作法设置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('工作时长'),
                const Spacer(),
                DropdownButton<int>(
                  value: settings.pomodoroWorkMinutes,
                  items: [15, 20, 25, 30, 45, 60]
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v 分钟'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    ref.read(settingsProviderProvider.notifier).setPomodoroWorkMinutes(v!);
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('休息时长'),
                const Spacer(),
                DropdownButton<int>(
                  value: settings.pomodoroBreakMinutes,
                  items: [5, 10, 15, 20]
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v 分钟'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    ref.read(settingsProviderProvider.notifier).setPomodoroBreakMinutes(v!);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '护眼宝',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 护眼宝\n保护眼睛，从现在开始。',
      children: [
        const SizedBox(height: 16),
        const Text('护眼宝是一款帮助您保护眼睛健康的应用程序。'),
        const Text('主要功能：'),
        const Text('• 色温调节（应用内滤蓝光）'),
        const Text('• 20-20-20 护眼提醒'),
        const Text('• 番茄工作法'),
        const Text('• 屏幕使用时长统计'),
      ],
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隐私政策'),
        content: const SingleChildScrollView(
          child: Text('''
护眼宝隐私政策

1. 数据收集
我们仅收集必要的使用统计数据，用于改善您的使用体验。我们不会收集任何个人信息。

2. 数据存储
所有数据均存储在您的设备本地，我们不会将任何数据上传至服务器。

3. 权限使用
- 通知权限：用于发送护眼提醒
- 使用统计权限：用于统计屏幕使用时长（需要您授权）

4. 第三方服务
本应用不包含任何第三方广告或追踪服务。

5. 联系我们
如有任何问题，请联系我们。
'''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String title;
  final String desc;

  const _GuideStep({
    required this.number,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  desc,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}