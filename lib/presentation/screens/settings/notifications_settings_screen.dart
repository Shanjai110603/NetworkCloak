import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';

class NotificationsSettingsScreen extends ConsumerWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NcColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NcColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Tray Alerts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: NcColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Show immediate system-tray notifications for critical firewall blocks and anomalies.',
                        style: TextStyle(
                          fontSize: 13,
                          color: NcColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: notificationsEnabled,
                  onChanged: (val) {
                    ref.read(notificationsEnabledProvider.notifier).setEnabled(val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'All alerts are always recorded in the Watchtower/Alerts log regardless of this system notification setting.',
              style: TextStyle(fontSize: 12, color: NcColors.textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
