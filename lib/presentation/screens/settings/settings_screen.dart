import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SettingsGroup(
            title: 'Protection',
            items: [
              _SettingsTile(
                icon: Icons.dns_outlined,
                label: 'DNS Guard',
                subtitle: 'Cloudflare DoH · 8 categories active',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.shield_outlined,
                label: 'Shield',
                subtitle: 'Auto-switching on',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.lock_outline,
                label: 'Cloak',
                subtitle: 'LAN block active',
                onTap: () {},
              ),
            ],
          ),
          _SettingsGroup(
            title: 'App',
            items: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                subtitle: 'All alerts enabled',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.palette_outlined,
                label: 'Appearance',
                subtitle: 'Dark mode',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.storage_outlined,
                label: 'Data & Retention',
                subtitle: '30-day log retention',
                onTap: () {},
              ),
            ],
          ),
          _SettingsGroup(
            title: 'Advanced',
            items: [
              _SettingsTile(
                icon: Icons.developer_mode_outlined,
                label: 'Advanced Settings',
                subtitle: 'Debug mode, reset',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.info_outline,
                label: 'About',
                subtitle: 'Network Cloak v1.0.0',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: NcColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NcColors.border),
              ),
              child: const Column(
                children: [
                  Text(
                    'No account needed. No cloud.',
                    style: TextStyle(
                        color: NcColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'All your data stays on this device.\nNetwork Cloak never sends your information anywhere.',
                    style: TextStyle(
                        color: NcColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.items});
  final String title;
  final List<_SettingsTile> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: NcColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NcColors.border),
            ),
            child: Column(
              children: items
                  .asMap()
                  .entries
                  .map((e) => Column(
                        children: [
                          e.value,
                          if (e.key < items.length - 1)
                            const Divider(
                              height: 0,
                              indent: 56,
                              color: NcColors.border,
                            ),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: NcColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: NcColors.primary, size: 20),
      ),
      title: Text(label, style: Theme.of(context).textTheme.titleMedium),
      subtitle:
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      trailing: const Icon(Icons.chevron_right, color: NcColors.textMuted),
      onTap: onTap,
    );
  }
}
