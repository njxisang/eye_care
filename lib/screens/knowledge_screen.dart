import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class KnowledgeScreen extends ConsumerWidget {
  const KnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('护眼知识'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 护眼引导卡片
          Card(
            color: const Color(0xFFFFF8E1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.orange, size: 28),
                      SizedBox(width: 8),
                      Text(
                        '系统护眼模式',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '开启系统护眼模式可以在系统层面过滤蓝光，有效保护眼睛。',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => _openSystemEyeSettings(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('立即设置'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            '护眼知识',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          const _KnowledgeCard(
            icon: Icons.blur_on,
            title: '什么是蓝光？',
            subtitle: '了解蓝光对眼睛的影响',
            content: '''
蓝光是什么？
蓝光是一种波长在400-500纳米的高能可见光，广泛存在于手机、电脑、LED灯等电子设备中。

蓝光的影响：
1. 视网膜损伤：长期暴露在高强度蓝光下可能导致视网膜损伤
2. 睡眠干扰：蓝光会抑制褪黑素分泌，影响睡眠质量
3. 眼疲劳：长时间看屏幕会导致眼睛干涩、疲劳

如何防护：
- 开启护眼模式/夜间模式
- 佩戴防蓝光眼镜
- 保持适当观看距离
- 定时休息眼睛
            ''',
          ),
          const SizedBox(height: 12),

          const _KnowledgeCard(
            icon: Icons.visibility,
            title: '20-20-20法则',
            subtitle: '简单有效的护眼方法',
            content: '''
20-20-20法则是什么？
由美国验光协会提出的护眼建议：每使用电子产品20分钟，就把视线转向至少20英尺（约6米）远的物体，持续20秒。

为什么有效？
长时间近距离看屏幕会导致眼睛调节肌肉疲劳。远眺可以让眼睛的调节肌肉放松，缓解疲劳。

如何执行？
1. 设置计时器，每20分钟提醒一次
2. 站起来，看向窗外最远的物体
3. 保持20秒，尽量看清细节
4. 每天多次执行效果更佳
            ''',
          ),
          const SizedBox(height: 12),

          const _KnowledgeCard(
            icon: Icons.settings,
            title: '如何设置系统护眼模式',
            subtitle: 'Android / iOS 分步指南',
            content: '''
【Android 设置方法】
1. 打开「设置」
2. 找到「显示」或「屏幕」
3. 点击「护眼模式」或「夜间模式」
4. 开启并设置色温强度
5. 可设置定时自动开启

【iOS 设置方法】
1. 打开「设置」
2. 点击「显示与亮度」
3. 开启「夜览」功能
4. 设置自动开启时间（建议日落到日出）

【华为/小米等国产ROM】
1. 打开「设置」
2. 搜索「护眼模式」或「防蓝光」
3. 按照提示开启即可
            ''',
          ),
          const SizedBox(height: 12),

          const _KnowledgeCard(
            icon: Icons.restaurant,
            title: '护眼饮食建议',
            subtitle: '从内到外保护眼睛',
            content: '''
护眼营养素：
1. 维生素A：胡萝卜、菠菜、动物肝脏
2. 叶黄素：玉米、蛋黄、绿叶蔬菜
3. Omega-3：深海鱼、坚果、亚麻籽
4. 维生素C：柑橘类、草莓、 peppers

护眼食谱建议：
- 早餐：胡萝卜汁 + 鸡蛋
- 午餐：清炒菠菜 + 鱼肉
- 晚餐：玉米沙拉 + 坚果

饮食习惯注意：
- 多喝水保持眼睛湿润
- 少吃甜食和油炸食品
- 均衡饮食不挑食
            ''',
          ),
          const SizedBox(height: 12),

          const _KnowledgeCard(
            icon: Icons.warning,
            title: '用眼疲劳的信号',
            subtitle: '及时发现及时休息',
            content: '''
疲劳信号：
1. 眼睛干涩、刺痛
2. 视物模糊、重影
3. 眼睛发红、充血
4. 头痛、眉弓酸胀
5. 注意力难以集中

出现以上情况时：
- 立即停止使用电子产品
- 远眺放松眼睛
- 做眼保健操
- 使用人工泪液缓解干涩
- 如持续不缓解就医

预防措施：
- 保持正确的坐姿
- 屏幕与眼睛保持50-70cm
- 环境光线适中
- 定时让眼睛休息
            ''',
          ),
        ],
      ),
    );
  }

  Future<void> _openSystemEyeSettings(BuildContext context) async {
    const channel = MethodChannel('com.eyecare/system');

    try {
      if (Platform.isAndroid) {
        await channel.invokeMethod('openNightSettings');
      } else if (Platform.isIOS) {
        await channel.invokeMethod('openDisplaySettings');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请手动在系统设置中开启护眼模式'),
          ),
        );
      }
    }
  }
}

class _KnowledgeCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String content;

  const _KnowledgeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.content,
  });

  @override
  State<_KnowledgeCard> createState() => _KnowledgeCardState();
}

class _KnowledgeCardState extends State<_KnowledgeCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.icon, color: const Color(0xFF4CAF50), size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  widget.content,
                  style: const TextStyle(height: 1.6),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}