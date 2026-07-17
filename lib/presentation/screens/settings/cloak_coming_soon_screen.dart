import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';

class CloakComingSoonScreen extends ConsumerWidget {
  const CloakComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cloakEnabled = ref.watch(cloakEnabledProvider);

    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(title: const Text('Cloak Engine')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header status card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NcColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NcColors.border),
            ),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cloakEnabled
                        ? NcColors.protected.withValues(alpha: 0.1)
                        : NcColors.textMuted.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: cloakEnabled
                        ? [
                            BoxShadow(
                              color: NcColors.protected.withValues(alpha: 0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    cloakEnabled ? Icons.shield : Icons.shield_outlined,
                    size: 64,
                    color: cloakEnabled ? NcColors.protected : NcColors.textMuted,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  cloakEnabled ? 'LAN Cloak Active' : 'LAN Cloak Disabled',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  cloakEnabled
                      ? 'Your device is hidden from local subnet scanners'
                      : 'Enable Cloak to prevent LAN network exposure',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: NcColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cloak Shield',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Block all local subnet discovery',
                          style: TextStyle(color: NcColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    Switch(
                      value: cloakEnabled,
                      activeThumbColor: NcColors.primary,
                      onChanged: (val) {
                        ref.read(cloakEnabledProvider.notifier).setEnabled(val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Shielded protocols header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'SHIELDED PROTOCOLS & PORTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: NcColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ),

          // Protocol cards
          _buildProtocolTile(
            title: 'mDNS (Multicast DNS)',
            subtitle: 'Blocks UDP port 5353 multicast. Prevents local hostname/service enumeration.',
            isActive: cloakEnabled,
          ),
          const SizedBox(height: 8),
          _buildProtocolTile(
            title: 'LLMNR (Link-Local Multicast)',
            subtitle: 'Blocks UDP port 5355. Prevents hostname lookup sniffing on the local subnet.',
            isActive: cloakEnabled,
          ),
          const SizedBox(height: 8),
          _buildProtocolTile(
            title: 'NetBIOS / SMB Discovery',
            subtitle: 'Blocks UDP 137-138 & TCP 139/445. Prevents local network file-sharing discovery.',
            isActive: cloakEnabled,
          ),
          const SizedBox(height: 8),
          _buildProtocolTile(
            title: 'SSDP / UPnP Multicast',
            subtitle: 'Blocks UDP port 1900 multicast. Disables local media and smart home scans.',
            isActive: cloakEnabled,
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolTile({
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NcColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NcColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? NcColors.protected.withValues(alpha: 0.1)
                  : NcColors.textMuted.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isActive ? Icons.lock : Icons.lock_open,
              size: 18,
              color: isActive ? NcColors.protected : NcColors.textMuted,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: NcColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
