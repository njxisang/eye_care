# 护眼宝 (Eye Care)

一款帮助用户保护眼睛健康的 Android 应用，提供色温调节、护眼提醒、屏幕时长统计和番茄工作法等功能。

## 功能特性

| 模块 | 说明 |
|------|------|
| **护眼滤光** | 应用内蓝光过滤（0–100%强度），支持日间/阅读/夜间/深夜四种预设，定时自动开关 |
| **亮度控制** | 手动调节屏幕亮度，支持自动亮度跟随 |
| **护眼提醒** | 基于「20-20-20 法则」的定时提醒（每 20 分钟远眺 20 英尺持续 20 秒），可自定义间隔 |
| **时长统计** | 统计今日及本周各应用使用时长，环形进度图 + 分类饼图，支持设置每日目标 |
| **番茄钟** | 标准番茄工作法（默认 25 分钟工作 / 5 分钟休息），记录每日完成数 |
| **护眼知识** | 蓝光原理、护眼饮食、用眼疲劳信号等科普内容 |

## 项目结构

```
lib/
├── main.dart                          # 应用入口，初始化 providers
├── app.dart                           # MaterialApp，主题配置（支持深色模式）
├── router.dart                        # go_router 路由配置 + 底部导航框架
├── providers/                         # Riverpod ChangeNotifier providers
│   ├── settings_provider.dart         # 用户设置（色温/提醒/深色模式等），持久化到 SharedPreferences
│   ├── usage_provider.dart             # 屏幕时长数据，持久化到 SQLite
│   └── reminder_provider.dart          # 护眼提醒记录，持久化到 SQLite
├── screens/                            # 页面
│   ├── home_screen.dart                # 首页：状态总览 + 快捷开关 + 今日进度
│   ├── blue_light_screen.dart          # 色温调节：滑动条 + 四种预设 + 定时开关
│   ├── reminder_screen.dart            # 护眼提醒：20-20-20 说明 + 倒计时 + 今日统计
│   ├── stats_screen.dart               # 时长统计：本周柱状图 + 目标环形图 + 应用排行
│   ├── settings_screen.dart             # 设置：提醒间隔/番茄钟/深色模式/每日目标/关于
│   ├── knowledge_screen.dart           # 护眼知识：可展开的科普文章列表
│   └── pomodoro_screen.dart            # 番茄钟：计时器 + 今日完成数
├── services/                           # 平台服务封装
│   ├── blue_light_service.dart         # 应用内色温滤镜（Android MediaCodec / iOS CATransaction）
│   ├── brightness_service.dart          # 屏幕亮度调节
│   ├── notification_service.dart        # 本地通知（flutter_local_notifications）
│   └── usage_stats_service.dart         # 系统 UsageStats 权限封装（需 PACKAGE_USAGE_STATS）
└── widgets/                             # 通用 UI 组件
    ├── stat_card.dart                  # 数据展示卡片
    ├── slider_card.dart                # 带滑块的设置卡片
    └── preset_button.dart              # 快捷预设按钮
```

## 技术栈

- **Framework**: Flutter 3.x（Dart 3.x）
- **状态管理**: Riverpod 2.x（ChangeNotifierProvider）
- **路由**: go_router 14.x
- **本地存储**: SharedPreferences（设置） + sqflite（统计数据）
- **图表**: fl_chart 0.70.x
- **通知**: flutter_local_notifications 18.x
- **权限**: permission_handler 11.x
- **平台通道**: Android MediaCodec / MethodChannel

## 权限说明

| 权限 | 用途 |
|------|------|
| `POST_NOTIFICATIONS` | 发送护眼提醒通知 |
| `RECEIVE_BOOT_COMPLETED` | 开机自启 |
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | 精确闹钟定时 |
| `VIBRATE` | 通知振动 |
| `PACKAGE_USAGE_STATS` | 统计应用使用时长（需用户在系统设置中授权） |

> 注意：部分国产 ROM（小米、华为等）对 `PACKAGE_USAGE_STATS` 有额外限制，需引导用户在系统设置中手动开启「使用情况访问权限」。

## 环境要求

- Flutter SDK ^3.9.0 / Dart ^3.9.0
- Android SDK（API 21+）
- JDK 17

## 开发环境

项目使用 **FVM** 管理 Flutter SDK 版本：

```bash
# 安装依赖
flutter pub get

# 静态分析
flutter analyze

# 调试编译
flutter build apk --debug

# 发布编译
flutter build apk --release
```

> 本地 Java 环境路径（miniconda3 内嵌 JDK17）：
> ```bash
> export JAVA_HOME=/home/xisang/miniconda3/pkgs/openjdk-17.0.14-h1c92337_0
> export ANDROID_HOME=/home/xisang/Android/Sdk
> ```

## Git 工作流

```bash
# 从 master 创建修复分支
git checkout -b fix/review-issues-2026-04-23

# 开发、提交
git add .
git commit -m "fix: 修复 REVIEW.md 中的代码质量问题"

# 合并回 master
git checkout master
git merge --no-ff fix/review-issues-2026-04-23
git push origin master
```

## 最近提交

| Commit | 说明 |
|--------|------|
| `ded1a9a` | chore: 完善 .gitignore |
| `1e8fcf2` | chore: 添加 .gitignore 排除构建产物 |
| `04f10e7` | fix: 修复 REVIEW.md 中的 8 个代码质量问题 |
| `fa023d0` | Complete eye care app with all features |

### 本次修复内容（`04f10e7`）

- **P0** darkMode 主题跟随设置（`app.dart` 改为 ConsumerWidget + 动态 themeMode）
- **P0** Provider 初始化竞态问题（改用静态工厂 `initialize*()` 替代链式 load）
- **P1** `_appNameOf` 粗暴字符串切割（改用精确 Map 匹配）
- **P1** `simulateTodayData` 递归触发（拆分为 `populateSimulatedData` + `refreshToday`）
- **P1** 数据库无版本迁移（添加 `onUpgrade` 回调）
- **P2** 删除死代码 `_showSettingsSheet`（~160 行）
- **P2** 统一 `_formatMinutes` 格式（`${h}h${m}m`）
- **P2** 统计页空状态添加授权引导卡片
- **清理** `usage_stats_service.dart` 编译错误（`Permission.usageAccess` 改为 safe stub）
- **清理** 多文件未使用 imports

## 截图预览

> （请在 `assets/` 目录放置截图后替换下方路径）

```
┌─────────────────────────────────┐
│         护眼宝  [⚙] [📖]        │
├─────────────────────────────────┤
│  🟡 护眼模式已开启              │
│     色温 65% │ 夜间模式         │
├──────────────┬──────────────────┤
│  今日时长    │   护眼提醒       │
│  2h30m       │   8 次           │
├──────────────┴──────────────────┤
│  快捷开关                        │
│  [滤光] 🔛  [提醒] 🔛  [定时] 🔛 │
├─────────────────────────────────┤
│  今日使用时长        2h30m/4h   │
│  ████████████░░░░░░░░░░░░  62%  │
├─────────────────────────────────┤
│  [    开始专注（番茄钟）    ]    │
└─────────────────────────────────┘
```
