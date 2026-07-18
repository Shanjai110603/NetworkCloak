import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';

class AdvancedSettingsScreen extends ConsumerWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final debugLogging = ref.watch(debugLoggingProvider);

    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(title: const Text('Advanced Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Rule Management',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NcColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NcColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset Firewall Rules',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: NcColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Restore all application firewall rules to default factory settings. Your custom app rules will be overwritten.',
                  style: TextStyle(
                    fontSize: 13,
                    color: NcColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NcColors.chipBlock,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _confirmResetRules(context, ref, db),
                    child: const Text('Reset Rules to Default'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Diagnostics',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
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
                        'Stealth Debug Logging',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: NcColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Collect advanced stack traces and log UDP packet flows locally for connection troubleshooting.',
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
                  value: debugLogging,
                  onChanged: (val) async {
                    await ref.read(debugLoggingProvider.notifier).setEnabled(val);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Debug logging ${val ? 'enabled' : 'disabled'}')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmResetRules(BuildContext context, WidgetRef ref, dynamic db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NcColors.surface,
        title: const Text('Reset rules?'),
        content: const Text(
          'This will clear all manual application settings, restoring defaults (Chrome Allowed, WhatsApp Ask, Instagram Blocked, Spotify Allowed, System Allowed).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: NcColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: NcColors.chipBlock),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                await db.delete(db.firewallRules).go();
                await db.delete(db.temporaryRules).go();
                await ref.read(firewallRulesProvider.notifier).refresh();

                messenger.showSnackBar(
                  const SnackBar(content: Text('Rules reset to default successfully!')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to reset rules: $e')),
                );
              }
            },
            child: const Text('Reset Rules'),
          ),
        ],
      ),
    );
  }
}
