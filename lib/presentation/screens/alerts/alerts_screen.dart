import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/alert.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertsProvider);

    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(
        title: const Text('Security Alerts'),
        actions: [
          if (alerts.any((a) => a.isUnread))
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 18, color: NcColors.primary),
              label: const Text(
                'Read All',
                style: TextStyle(color: NcColors.primary, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                for (final alert in alerts) {
                  if (alert.isUnread) {
                    ref.read(alertsProvider.notifier).markRead(alert.id);
                  }
                }
              },
            ),
        ],
      ),
      body: alerts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 64, color: NcColors.textMuted),
                  SizedBox(height: 16),
                  Text(
                    'All systems clear',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: NcColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'No security threats or anomalies detected.',
                    style: TextStyle(color: NcColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                return _AlertCard(alert: alert);
              },
            ),
    );
  }
}

class _AlertCard extends ConsumerWidget {
  const _AlertCard({required this.alert});
  final Alert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Color severityColor;
    IconData icon;

    switch (alert.severity.toLowerCase()) {
      case 'critical':
        severityColor = NcColors.unprotected;
        icon = Icons.gpp_bad_outlined;
        break;
      case 'warning':
        severityColor = NcColors.partial;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        severityColor = NcColors.primary;
        icon = Icons.info_outline;
    }

    return GestureDetector(
      onTap: () {
        if (alert.isUnread) {
          ref.read(alertsProvider.notifier).markRead(alert.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: alert.isUnread
              ? NcColors.surfaceElevated
              : NcColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alert.isUnread ? severityColor.withValues(alpha: 0.5) : NcColors.border,
            width: alert.isUnread ? 1.5 : 1.0,
          ),
          boxShadow: alert.isUnread
              ? [
                  BoxShadow(
                    color: severityColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: severityColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: alert.isUnread ? FontWeight.bold : FontWeight.w600,
                            color: NcColors.textPrimary,
                          ),
                        ),
                      ),
                      if (alert.isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: severityColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    alert.body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: NcColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (alert.appId != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: NcColors.bg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: NcColors.border),
                      ),
                      child: Text(
                        alert.appId!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: NcColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _formatTime(alert.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: NcColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
