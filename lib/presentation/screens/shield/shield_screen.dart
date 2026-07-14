import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/enums/network_trust_level.dart';
import '../../../data/database/app_database.dart';

class ShieldScreen extends ConsumerWidget {
  const ShieldScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoSwitch = ref.watch(autoSwitchEnabledProvider);
    final roamingAutoBlock = ref.watch(roamingAutoBlockProvider);
    final networkAsync = ref.watch(networkStatusProvider);
    final trustedAsync = ref.watch(trustedNetworksProvider);
    final db = ref.watch(databaseProvider);

    final network = networkAsync.valueOrNull;

    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(title: const Text('Shield')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Auto-switch toggle
          _SectionCard(
            title: 'Auto Profile Switching',
            subtitle:
                'Automatically activates the right protection level when your network changes.',
            trailing: Switch(
              value: autoSwitch,
              onChanged: (v) {
                ref.read(autoSwitchEnabledProvider.notifier).setEnabled(v);
              },
            ),
          ),
          const SizedBox(height: 12),

          // Current network status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: NcColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NcColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Network',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _NetworkStatusRow(
                    label: 'Network Name (SSID)',
                    value: network?.ssid ?? 'Scanning...'),
                _NetworkStatusRow(
                    label: 'Access Point (BSSID)',
                    value: network?.bssid ?? 'Unknown'),
                _NetworkStatusRow(
                    label: 'Security Type',
                    value: network?.authType ?? 'Unknown'),
                _NetworkStatusRow(
                    label: 'Trust Level',
                    value: network?.trustLevel.plainLabel ?? NetworkTrustLevel.unknown.plainLabel),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.favorite_outline, size: 18),
                  label: const Text('Trust this network'),
                  onPressed: (network != null && network.ssid != null)
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            final id = 'trusted_${network.ssid}_${network.bssid}';
                            await db.into(db.trustedNetworks).insertOnConflictUpdate(
                              TrustedNetworksCompanion.insert(
                                id: id,
                                ssid: network.ssid!,
                                bssid: network.bssid ?? '00:00:00:00:00:00',
                                trustLevel: 'trusted',
                                profileId: 'default',
                              )
                            );
                            messenger.showSnackBar(
                              SnackBar(content: Text('Network "${network.ssid}" is now trusted!')),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to trust network: $e')),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NcColors.protected.withValues(alpha: 0.15),
                    foregroundColor: NcColors.protected,
                    side: const BorderSide(color: NcColors.protected),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text('Trusted Networks',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),

          trustedAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading trusted networks: $e')),
            data: (networks) {
              if (networks.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NcColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: NcColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'No trusted networks yet.\nConnect to a network and tap "Trust this network".',
                      style: TextStyle(color: NcColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: NcColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: NcColors.border),
                ),
                child: Column(
                  children: networks.map((net) {
                    return ListTile(
                      title: Text(net.ssid, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(net.bssid, style: const TextStyle(color: NcColors.textSecondary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: NcColors.unprotected),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await (db.delete(db.trustedNetworks)..where((t) => t.id.equals(net.id))).go();
                            messenger.showSnackBar(
                              SnackBar(content: Text('Removed "${net.ssid}" from trusted networks')),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Failed to remove network: $e')),
                            );
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Roaming auto-block
          _SectionCard(
            title: 'Roaming Auto-Block',
            subtitle:
                'Automatically activates Travel mode when you\'re roaming to protect your data.',
            trailing: Switch(
              value: roamingAutoBlock,
              onChanged: (v) {
                ref.read(roamingAutoBlockProvider.notifier).setEnabled(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
  final String title, subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NcColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _NetworkStatusRow extends StatelessWidget {
  const _NetworkStatusRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
