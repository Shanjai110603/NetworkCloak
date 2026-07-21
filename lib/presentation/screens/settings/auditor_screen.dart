import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/application_info.dart';
import '../../../domain/enums/rule_action.dart';

class AuditorScreen extends ConsumerWidget {
  const AuditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(installedAppsProvider);
    final rulesAsync = ref.watch(firewallRulesProvider);

    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(
        title: const Text('Heuristic Risk Auditor'),
      ),
      body: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading applications: $e',
              style: TextStyle(color: NcColors.textSecondary)),
        ),
        data: (apps) {
          return rulesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Error loading rules: $e',
                  style: TextStyle(color: NcColors.textSecondary)),
            ),
            data: (rules) {
              // Create lookup of blocked apps
              final blockedApps = <String>{};
              for (final rule in rules) {
                if (rule.appId != null &&
                    (rule.action == RuleAction.block ||
                     rule.action == RuleAction.temporaryBlock ||
                     rule.action == RuleAction.blockBackground)) {
                  blockedApps.add(rule.appId!);
                }
              }

              // Filter risk apps
              final highRiskApps = apps.where((a) => a.riskLevel == 'high').toList();
              final mediumRiskApps = apps.where((a) => a.riskLevel == 'medium').toList();

              // Calculate scorecard deductions
              int deductions = 0;
              final unblockedHighRisk = <String>[];

              for (final app in highRiskApps) {
                if (!blockedApps.contains(app.packageName)) {
                  deductions += 8;
                  unblockedHighRisk.add(app.packageName);
                }
              }
              for (final app in mediumRiskApps) {
                if (!blockedApps.contains(app.packageName)) {
                  deductions += 3;
                }
              }

              final score = (100 - deductions).clamp(10, 100);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Score widget
                  _ScoreCard(score: score, unblockedHighCount: unblockedHighRisk.length),
                  const SizedBox(height: 20),

                  // One-tap fix banner
                  if (unblockedHighRisk.isNotEmpty)
                    _OneTapFixCard(
                      appIds: unblockedHighRisk,
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          for (final appId in unblockedHighRisk) {
                            await ref
                                .read(firewallRulesProvider.notifier)
                                .updateRuleAction(appId, RuleAction.block);
                          }
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Successfully secured device. High-risk app leakage stopped!'),
                            ),
                          );
                        } catch (err) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('Failed to apply rules: $err')),
                          );
                        }
                      },
                    ),

                  const SizedBox(height: 24),
                  Text(
                    'SECURITY COMPLIANCE AUDIT',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 10),

                  if (highRiskApps.isEmpty && mediumRiskApps.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: NcColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: NcColors.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.gpp_good_outlined, color: NcColors.protected, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            'Your device is fully compliant!',
                            style: TextStyle(
                              color: NcColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'No medium or high-risk background applications were detected.',
                            style: TextStyle(color: NcColors.textSecondary, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Group high risk
                    if (highRiskApps.isNotEmpty) ...[
                      _SectionHeader(title: 'High Risk Threat Vectors (${highRiskApps.length})', color: NcColors.unprotected),
                      ...highRiskApps.map((app) => _AppRiskTile(
                            app: app,
                            isBlocked: blockedApps.contains(app.packageName),
                            ref: ref,
                          )),
                      const SizedBox(height: 16),
                    ],

                    // Group medium risk
                    if (mediumRiskApps.isNotEmpty) ...[
                      _SectionHeader(title: 'Medium Risk Anomalies (${mediumRiskApps.length})', color: NcColors.partial),
                      ...mediumRiskApps.map((app) => _AppRiskTile(
                            app: app,
                            isBlocked: blockedApps.contains(app.packageName),
                            ref: ref,
                          )),
                    ],
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.unblockedHighCount});
  final int score;
  final int unblockedHighCount;

  @override
  Widget build(BuildContext context) {
    final statusColor = score >= 85
        ? NcColors.protected
        : (score >= 60 ? NcColors.partial : NcColors.unprotected);

    final statusText = score >= 85
        ? 'SECURE'
        : (score >= 60 ? 'ACTION RECOMMENDED' : 'HIGH RISK EXPOSURE');

    final statusDesc = score >= 85
        ? 'All major heuristic vulnerabilities are patched and filtered.'
        : 'Some active applications possess permission sets that leak user metadata.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: NcColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NcColors.border),
      ),
      child: Column(
        children: [
          // Circular progress/indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  backgroundColor: NcColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: NcColors.textPrimary,
                    ),
                  ),
                  Text(
                    'SCORE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: NcColors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: statusColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusDesc,
            style: TextStyle(
              fontSize: 13,
              color: NcColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OneTapFixCard extends StatelessWidget {
  const _OneTapFixCard({required this.appIds, required this.onTap});
  final List<String> appIds;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            NcColors.unprotected.withValues(alpha: 0.2),
            NcColors.accent.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NcColors.unprotected.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: NcColors.unprotected, size: 20),
              const SizedBox(width: 8),
              Text(
                'One-Tap Compliance Patch',
                style: TextStyle(
                  color: NcColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Block all ${appIds.length} high-risk apps with one click to restore device security score to normal.',
            style: TextStyle(color: NcColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.flash_on, size: 16),
              label: const Text('Patch Vulnerabilities'),
              style: ElevatedButton.styleFrom(
                backgroundColor: NcColors.unprotected,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          Container(width: 4, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _AppRiskTile extends StatelessWidget {
  const _AppRiskTile({required this.app, required this.isBlocked, required this.ref});
  final ApplicationInfo app;
  final bool isBlocked;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NcColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NcColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: NcColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: app.iconBytes != null && app.iconBytes!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          Uint8List.fromList(app.iconBytes!),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                      )
                    : Icon(Icons.apps_outlined, color: NcColors.textMuted, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      app.packageName,
                      style: TextStyle(color: NcColors.textMuted, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Switch(
                value: !isBlocked,
                activeTrackColor: NcColors.protected.withValues(alpha: 0.3),
                activeThumbColor: NcColors.protected,
                inactiveThumbColor: NcColors.chipBlock,
                inactiveTrackColor: NcColors.chipBlock.withValues(alpha: 0.15),
                onChanged: (val) {
                  ref
                      .read(firewallRulesProvider.notifier)
                      .updateRuleAction(app.packageName, val ? RuleAction.allow : RuleAction.block);
                },
              ),
            ],
          ),
          if (app.riskReasons != null && app.riskReasons!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: app.riskReasons!.map((reason) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: NcColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: NcColors.border),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      fontSize: 10,
                      color: NcColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
