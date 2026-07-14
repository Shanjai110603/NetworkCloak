import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/firewall/firewall_screen.dart';
import '../presentation/screens/watchtower/watchtower_screen.dart';
import '../presentation/screens/dns_guard/dns_guard_screen.dart';
import '../presentation/screens/shield/shield_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/onboarding/onboarding_flow.dart';

import '../presentation/screens/alerts/alerts_screen.dart';
import '../presentation/screens/settings/cloak_coming_soon_screen.dart';
import '../presentation/screens/settings/notifications_settings_screen.dart';
import '../presentation/screens/settings/appearance_screen.dart';
import '../presentation/screens/settings/data_retention_screen.dart';
import '../presentation/screens/settings/advanced_settings_screen.dart';
import '../presentation/screens/settings/about_screen.dart';
import '../presentation/screens/quick_block/quick_block_screen.dart';

final router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (ctx, state) => const OnboardingFlow(),
    ),
    GoRoute(
      path: '/alerts',
      builder: (ctx, state) => const AlertsScreen(),
    ),
    GoRoute(
      path: '/quick-block',
      builder: (ctx, state) => const QuickBlockScreen(),
    ),
    GoRoute(
      path: '/settings/cloak',
      builder: (ctx, state) => const CloakComingSoonScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (ctx, state) => const NotificationsSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/appearance',
      builder: (ctx, state) => const AppearanceScreen(),
    ),
    GoRoute(
      path: '/settings/data-retention',
      builder: (ctx, state) => const DataRetentionScreen(),
    ),
    GoRoute(
      path: '/settings/advanced',
      builder: (ctx, state) => const AdvancedSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/about',
      builder: (ctx, state) => const AboutScreen(),
    ),
    ShellRoute(
      builder: (ctx, state, child) => _MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (ctx, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/firewall',
          builder: (ctx, state) => const FirewallScreen(),
        ),
        GoRoute(
          path: '/watchtower',
          builder: (ctx, state) => const WatchtowerScreen(),
        ),
        GoRoute(
          path: '/dns',
          builder: (ctx, state) => const DnsGuardScreen(),
        ),
        GoRoute(
          path: '/shield',
          builder: (ctx, state) => const ShieldScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (ctx, state) => const SettingsScreen(),
        ),
      ],
    ),
  ],
);

class _MainShell extends StatelessWidget {
  const _MainShell({required this.child});
  final Widget child;

  static const _tabs = [
    ('/', Icons.shield_outlined, Icons.shield, 'Home'),
    ('/firewall', Icons.security_outlined, Icons.security, 'Firewall'),
    ('/watchtower', Icons.monitor_heart_outlined, Icons.monitor_heart, 'Monitor'),
    ('/dns', Icons.dns_outlined, Icons.dns, 'DNS'),
    ('/settings', Icons.settings_outlined, Icons.settings, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).location;
    final index = _tabs.indexWhere((t) => t.$1 == location).clamp(0, 4);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.$2),
                  selectedIcon: Icon(t.$3),
                  label: t.$4,
                ))
            .toList(),
      ),
    );
  }
}
