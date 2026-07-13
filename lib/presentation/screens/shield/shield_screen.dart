import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/enums/network_trust_level.dart';

class ShieldScreen extends StatelessWidget {
  const ShieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            trailing: Switch(value: true, onChanged: (v) {}),
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
                const _NetworkStatusRow(
                    label: 'Network', value: 'Scanning...'),
                const _NetworkStatusRow(
                    label: 'Security', value: 'WPA2-PSK'),
                _NetworkStatusRow(
                    label: 'Status',
                    value: NetworkTrustLevel.unknown.plainLabel),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.favorite_outline, size: 18),
                  label: const Text('Trust this network'),
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NcColors.protected.withValues(alpha: 0.15),
                    foregroundColor: NcColors.protected,
                    side: const BorderSide(color: NcColors.protected),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text('Trusted Networks',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Container(
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
          ),

          const SizedBox(height: 16),

          // Roaming auto-block
          _SectionCard(
            title: 'Roaming Auto-Block',
            subtitle:
                'Automatically activates Travel mode when you\'re roaming to protect your data.',
            trailing: Switch(value: true, onChanged: (v) {}),
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
