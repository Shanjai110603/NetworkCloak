import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class CloakComingSoonScreen extends StatelessWidget {
  const CloakComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(title: const Text('Cloak')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: NcColors.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.blur_on_outlined,
                  size: 64,
                  color: NcColors.accent,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cloak Engine',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: NcColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming in Version 2.0',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: NcColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cloak will prevent LAN network exposure, blocking mDNS, local SMB discovery, and hiding your device fingerprint from local subnet scanners automatically on untrusted networks.',
                style: TextStyle(
                  fontSize: 14,
                  color: NcColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
