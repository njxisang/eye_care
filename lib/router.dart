import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/blue_light_screen.dart';
import 'screens/reminder_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/knowledge_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/pomodoro_screen.dart';
import '../services/blue_light_service.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: RootNavigatorService.rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/blue-light',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BlueLightScreen(),
          ),
        ),
        GoRoute(
          path: '/reminders',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ReminderScreen(),
          ),
        ),
        GoRoute(
          path: '/stats',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: StatsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/knowledge',
      parentNavigatorKey: RootNavigatorService.rootNavigatorKey,
      builder: (context, state) => const KnowledgeScreen(),
    ),
    GoRoute(
      path: '/settings',
      parentNavigatorKey: RootNavigatorService.rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/pomodoro',
      parentNavigatorKey: RootNavigatorService.rootNavigatorKey,
      builder: (context, state) => const PomodoroScreen(),
    ),
  ],
);

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF4CAF50).withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF4CAF50)),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny, color: Color(0xFF4CAF50)),
            label: '色温',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: Color(0xFF4CAF50)),
            label: '提醒',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF4CAF50)),
            label: '统计',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/blue-light')) return 1;
    if (location.startsWith('/reminders')) return 2;
    if (location.startsWith('/stats')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/blue-light');
        break;
      case 2:
        context.go('/reminders');
        break;
      case 3:
        context.go('/stats');
        break;
    }
  }
}