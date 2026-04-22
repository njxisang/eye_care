import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../services/blue_light_service.dart';

class BlueLightScreen extends ConsumerStatefulWidget {
  const BlueLightScreen({super.key});

  @override
  ConsumerState<BlueLightScreen> createState() => _BlueLightScreenState();
}

class _BlueLightScreenState extends ConsumerState<BlueLightScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter();
    });
  }

  void _applyFilter() {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('色温调节'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 实时预览
            _buildPreview(settings),
            const SizedBox(height: 24),

            // 主滑动条
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '色温强度',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getPreviewColor(settings.blueLightIntensity)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(settings.blueLightIntensity * 100).toInt()}%',
                            style: TextStyle(
                              color: _getPreviewColor(
                                  settings.blueLightIntensity),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor:
                            _getPreviewColor(settings.blueLightIntensity),
                        thumbColor:
                            _getPreviewColor(settings.blueLightIntensity),
                        overlayColor: _getPreviewColor(settings.blueLightIntensity)
                            .withValues(alpha: 0.2),
                        trackHeight: 8,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 14,
                        ),
                      ),
                      child: Slider(
                        value: settings.blueLightIntensity,
                        min: 0.0,
                        max: 1.0,
                        divisions: 20,
                        onChanged: (v) async {
                          await settings.setBlueLightIntensity(v);
                          _applyFilter();
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('正常', style: TextStyle(color: Colors.grey[500])),
                        Text('暖黄',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 快捷预设
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '快速预设',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _PresetButton(
                            label: '日间模式',
                            subtitle: '0-20%',
                            intensity: 0.1,
                            color: Colors.grey[200]!,
                            onTap: () => _setPreset(0.1),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PresetButton(
                            label: '阅读模式',
                            subtitle: '20-50%',
                            intensity: 0.35,
                            color: const Color(0xFFFFF3E0),
                            onTap: () => _setPreset(0.35),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PresetButton(
                            label: '夜间模式',
                            subtitle: '50-75%',
                            intensity: 0.65,
                            color: const Color(0xFFFFE0B2),
                            onTap: () => _setPreset(0.65),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PresetButton(
                            label: '深夜模式',
                            subtitle: '75-100%',
                            intensity: 0.9,
                            color: const Color(0xFFFFCC80),
                            onTap: () => _setPreset(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 定时开关
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
                          '定时开关',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Switch(
                          value: settings.scheduledEnabled,
                          onChanged: (v) => settings.setScheduledEnabled(v),
                          activeColor: const Color(0xFF4CAF50),
                        ),
                      ],
                    ),
                    if (settings.scheduledEnabled) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _TimePickerTile(
                              label: '开始时间',
                              time: settings.scheduledStart,
                              onTap: () async {
                                final t = await _pickTime(
                                    context, settings.scheduledStart);
                                if (t != null) {
                                  await settings.setScheduledStart(t);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.arrow_forward, color: Colors.grey),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _TimePickerTile(
                              label: '结束时间',
                              time: settings.scheduledEnd,
                              onTap: () async {
                                final t = await _pickTime(
                                    context, settings.scheduledEnd);
                                if (t != null) {
                                  await settings.setScheduledEnd(t);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '在 ${settings.scheduledStart} - ${settings.scheduledEnd} 期间自动开启护眼模式',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(SettingsProvider settings) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: _getPreviewBgColor(settings.blueLightIntensity),
        border: Border.all(
          color: _getPreviewColor(settings.blueLightIntensity).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wb_sunny,
              size: 48,
              color: _getPreviewColor(settings.blueLightIntensity),
            ),
            const SizedBox(height: 8),
            Text(
              settings.getPresetLabel(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: settings.blueLightIntensity > 0.5
                    ? Colors.brown[700]
                    : Colors.brown[900],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getPreviewTip(settings.blueLightIntensity),
              style: TextStyle(
                color: Colors.brown[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPreviewColor(double intensity) {
    if (intensity < 0.3) return Colors.grey[700]!;
    if (intensity < 0.6) return Colors.orange[700]!;
    if (intensity < 0.8) return Colors.deepOrange[600]!;
    return Colors.deepOrange[800]!;
  }

  Color _getPreviewBgColor(double intensity) {
    if (intensity < 0.2) return Colors.grey[100]!;
    if (intensity < 0.5) return const Color(0xFFFFF8E1);
    if (intensity < 0.75) return const Color(0xFFFFF3E0);
    return const Color(0xFFFFE0B2);
  }

  String _getPreviewTip(double intensity) {
    if (intensity < 0.2) return '适合白天日常使用';
    if (intensity < 0.5) return '适合阅读、办公';
    if (intensity < 0.75) return '适合夜间娱乐';
    return '适合睡前使用，最大程度滤蓝光';
  }

  Future<void> _setPreset(double intensity) async {
    final settings = ref.read(settingsProviderProvider);
    await settings.setBlueLightIntensity(intensity);
    await settings.setBlueLightEnabled(true);
    _applyFilter();
  }

  Future<String?> _pickTime(BuildContext context, String current) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
    final result = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (result != null) {
      return '${result.hour.toString().padLeft(2, '0')}:${result.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final double intensity;
  final Color color;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.subtitle,
    required this.intensity,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.brown[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5DC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
