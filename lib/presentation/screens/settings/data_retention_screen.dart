import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';

class DataRetentionScreen extends ConsumerWidget {
  const DataRetentionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retentionDays = ref.watch(retentionDaysProvider);
    final db = ref.watch(databaseProvider);

    final options = [
      (7, '7 Days', 'Keep history light and secure'),
      (14, '14 Days', 'Balance history and storage'),
      (30, '30 Days', 'Recommended standard logging'),
      (90, '90 Days', 'Extended log tracking'),
    ];

    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(title: const Text('Data & Retention')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'History Retention Window',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: NcColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NcColors.border),
            ),
            child: RadioGroup<int>(
              groupValue: retentionDays,
              onChanged: (val) {
                if (val != null) {
                  ref.read(retentionDaysProvider.notifier).setDays(val);
                }
              },
              child: Column(
                children: options.map((opt) {
                  return RadioListTile<int>(
                    title: Text(
                      opt.$2,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      opt.$3,
                      style: const TextStyle(color: NcColors.textSecondary),
                    ),
                    value: opt.$1,
                    activeColor: NcColors.primary,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Storage Management',
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
                const Text(
                  'Local Database',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: NcColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Instantly wipe all local connection logs, DNS queries, and security alerts from this device.',
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
                      backgroundColor: NcColors.unprotected,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _confirmClear(context, ref, db),
                    child: const Text('Clear All Logs & Data'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref, dynamic db) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NcColors.surface,
        title: const Text('Clear all data?'),
        content: const Text(
          'This will permanently delete all firewall logs, connection history, and alerts. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: NcColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: NcColors.unprotected),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              try {
                // Clear tables in background/concurrently
                await db.delete(db.dnsLogs).go();
                await db.delete(db.connectionHistory).go();
                await db.delete(db.alerts).go();
                ref.read(alertsProvider.notifier).refresh();

                messenger.showSnackBar(
                  const SnackBar(content: Text('Database cleared successfully!')),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Failed to clear database: $e')),
                );
              }
            },
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }
}
