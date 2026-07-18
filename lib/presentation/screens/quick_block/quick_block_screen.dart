import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/firewall_rule.dart';

class QuickBlockScreen extends ConsumerWidget {
  const QuickBlockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(firewallRulesProvider);
    final quickBlockState = ref.watch(quickBlockProvider);

    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(
        title: const Text('Quick Block'),
      ),
      body: Column(
        children: [
          // Master switch card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
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
                          'Enable Quick Block',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: NcColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Instantly sever all internet access for toggled apps, bypassing standard firewall policy rules.',
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
                    value: quickBlockState.masterEnabled,
                    onChanged: (val) {
                      ref.read(quickBlockProvider.notifier).setMasterEnabled(val);
                    },
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'SELECT APPS TO BLOCK',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // App list
          Expanded(
            child: rulesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Could not load apps: $e',
                    style: TextStyle(color: NcColors.textSecondary)),
              ),
              data: (rulesData) {
                // Get list of unique appIds from firewall rules
                final rules = rulesData.cast<FirewallRule>();
                final appIds = rules
                    .map((r) => r.appId)
                    .where((id) => id != null && id != 'system_process')
                    .toSet()
                    .toList();

                if (appIds.isEmpty) {
                  return Center(
                    child: Text(
                      'No applications available.',
                      style: TextStyle(color: NcColors.textSecondary),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: appIds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final appId = appIds[i]!;
                    final isBlocked = quickBlockState.apps.contains(appId);
                    final rule = rules.firstWhere((r) => r.appId == appId);
                    final label = (rule.displayName?.isNotEmpty == true) ? rule.displayName! : appId;

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NcColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: NcColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: NcColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: rule.iconBytes != null && rule.iconBytes!.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.memory(
                                      Uint8List.fromList(rule.iconBytes!),
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.apps_outlined,
                                        color: NcColors.textMuted,
                                        size: 22,
                                      ),
                                    ),
                                  )
                                : Icon(Icons.apps_outlined,
                                    color: NcColors.textMuted, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: Theme.of(context).textTheme.titleMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (label != appId)
                                  Text(
                                    appId,
                                    style: TextStyle(
                                      color: NcColors.textMuted,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isBlocked,
                            activeThumbColor: NcColors.chipBlock,
                            onChanged: (val) {
                              ref.read(quickBlockProvider.notifier).toggle(appId);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
