import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/usage_provider.dart';
import '../widgets/stat_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UsageProvider>().simulateTodayData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usage = context.watch<UsageProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('使用时长统计'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => usage.refreshUsage(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今日总览
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    title: '今日',
                    value: _formatMinutes(usage.todayTotalMinutes),
                    subtitle: '总时长',
                    icon: Icons.today,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    title: '7日平均',
                    value: _formatMinutes(_avgWeek(usage.weekUsage)),
                    subtitle: '日均',
                    icon: Icons.trending_flat,
                    color: const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 本周柱状图
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '本周使用时长',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: _buildWeekChart(usage.weekUsage),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 目标进度
            if (usage.todayUsage != null) ...[
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
                            '今日目标进度',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showGoalPicker(context),
                            child: const Text('修改目标'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildGoalRing(usage),
                      const SizedBox(height: 16),
                      _buildGoalTips(usage),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 应用排行
            if (usage.todayUsage != null &&
                usage.todayUsage!.apps.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '应用使用排行',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...usage.todayUsage!.apps.map((app) {
                        final total = usage.todayUsage!.totalMinutes;
                        final pct = total > 0
                            ? (app.usageMinutes / total * 100)
                            : 0.0;
                        return _AppUsageTile(
                          appName: app.appName,
                          category: app.category,
                          minutes: app.usageMinutes,
                          pct: pct,
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 分类统计
            if (usage.todayUsage != null &&
                usage.todayUsage!.apps.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '分类使用统计',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _buildCategoryChart(usage),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 权限说明
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFFFFF8E1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          '关于使用时长统计',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '获取应用使用时长需要「usage stats」权限。\n'
                      '首次使用会跳转到系统设置页面，请在「允许访问使用记录应用」中开启授权。\n'
                      '部分国产ROM（如小米、华为）可能有额外限制。',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        height: 1.5,
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

  Widget _buildWeekChart(List<DayUsage> week) {
    final maxMins = week.map((d) => d.totalMinutes).fold(1, (a, b) => a > b ? a : b);
    final goalMins = week.isNotEmpty ? week.first.goalMinutes : 240;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxMins.toDouble() * 1.2,
        barGroups: List.generate(7, (i) {
          final d = week[i];
          final isToday = i == 6;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: d.totalMinutes.toDouble(),
                color: isToday
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF81C784),
                width: 28,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text('');
                return Text(
                  '${(value / 60).toInt()}h',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final dayNames = ['一', '二', '三', '四', '五', '六', '日'];
                final i = value.toInt();
                if (i >= 0 && i < week.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '${DateFormat('M/d').format(week[i].date)} ${dayNames[i]}',
                      style: TextStyle(
                        fontSize: 10,
                        color: i == 6 ? const Color(0xFF4CAF50) : Colors.grey,
                        fontWeight: i == 6 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: 60,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey[200]!,
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildGoalRing(UsageProvider usage) {
    final total = usage.todayUsage!.totalMinutes;
    final goal = usage.todayUsage!.goalMinutes;
    final progress = (total / goal).clamp(0.0, 1.0);

    return Center(
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 14,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(
                  total > goal ? Colors.red : const Color(0xFF4CAF50),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatMinutes(total),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: total > goal ? Colors.red : const Color(0xFF4CAF50),
                  ),
                ),
                Text(
                  '/ ${_formatMinutes(goal)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTips(UsageProvider usage) {
    final total = usage.todayUsage!.totalMinutes;
    final goal = usage.todayUsage!.goalMinutes;
    final remaining = goal - total;

    if (remaining > 0) {
      return Center(
        child: Text(
          '今日还可使用 ${_formatMinutes(remaining)}',
          style: const TextStyle(color: Color(0xFF4CAF50)),
        ),
      );
    } else {
      return Center(
        child: Text(
          '已超过目标 ${_formatMinutes(-remaining)}',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
  }

  Widget _buildCategoryChart(UsageProvider usage) {
    final apps = usage.todayUsage!.apps;
    final categoryMins = <String, int>{};
    for (final app in apps) {
      categoryMins[app.category] =
          (categoryMins[app.category] ?? 0) + app.usageMinutes;
    }

    if (categoryMins.isEmpty) return const SizedBox();

    final total = categoryMins.values.fold(0, (a, b) => a + b);
    final colors = {
      '社交': const Color(0xFF4CAF50),
      '视频': const Color(0xFFE91E63),
      '游戏': const Color(0xFFFF9800),
      '阅读': const Color(0xFF2196F3),
      '其他': const Color(0xFF9E9E9E),
    };

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: categoryMins.entries.map((e) {
                final pct = total > 0 ? e.value / total * 100 : 0;
                return PieChartSectionData(
                  value: e.value.toDouble(),
                  title: '${pct.toInt()}%',
                  color: colors[e.key] ?? Colors.grey,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: categoryMins.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[e.key] ?? Colors.grey,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    e.key,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatMinutes(e.value),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showGoalPicker(BuildContext context) async {
    final usage = context.read<UsageProvider>();
    final current = usage.todayUsage?.goalMinutes ?? 240;
    final result = await showDialog<int>(
      context: context,
      builder: (context) => _GoalDialog(current: current),
    );
    if (result != null) {
      await usage.setGoalMinutes(result);
    }
  }

  int _avgWeek(List<DayUsage> week) {
    if (week.isEmpty) return 0;
    final total = week.fold(0, (sum, d) => sum + d.totalMinutes);
    return (total / week.length).round();
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) return '${minutes}分钟';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m > 0 ? '${h}h${m}m' : '${h}h';
  }
}

class _AppUsageTile extends StatelessWidget {
  final String appName;
  final String category;
  final int minutes;
  final double pct;

  const _AppUsageTile({
    required this.appName,
    required this.category,
    required this.minutes,
    required this.pct,
  });

  @override
  Widget build(BuildContext context) {
    final colors = {
      '社交': const Color(0xFF4CAF50),
      '视频': const Color(0xFFE91E63),
      '游戏': const Color(0xFFFF9800),
      '阅读': const Color(0xFF2196F3),
      '其他': const Color(0xFF9E9E9E),
    };
    final color = colors[category] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconOf(category),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 6,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${minutes}m',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '${pct.toInt()}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconOf(String category) {
    switch (category) {
      case '社交':
        return Icons.chat_bubble;
      case '视频':
        return Icons.play_circle;
      case '游戏':
        return Icons.games;
      case '阅读':
        return Icons.menu_book;
      default:
        return Icons.apps;
    }
  }
}

class _GoalDialog extends StatefulWidget {
  final int current;
  _GoalDialog({required this.current});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
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
      title: const Text('设置每日目标'),
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
