import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Hero(
                tag: 'app_logo',
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [NcColors.gradientStart, NcColors.gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: NcColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.security,
                    size: 48,
                    color: NcColors.bg,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Network Cloak',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: NcColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Stealth Connection Shield v1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: NcColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NcColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NcColors.border),
              ),
              child: Column(
                children: [
                  const _InfoRow(label: 'Developer', value: 'Security Team'),
                  Divider(height: 24, color: NcColors.border),
                  const _InfoRow(label: 'License', value: 'MIT Open Source'),
                  Divider(height: 24, color: NcColors.border),
                  const _InfoRow(label: 'Privacy', value: '100% On-Device'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Designed for complete data sovereignty. Network Cloak routes all packet filtration rules on-device and never communicates logs, alerts, or traffic packets to third-party cloud servers.',
                style: TextStyle(
                  fontSize: 13,
                  color: NcColors.textMuted,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              '© 2026 Network Cloak Contributors',
              style: TextStyle(
                fontSize: 11,
                color: NcColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: NcColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: NcColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
