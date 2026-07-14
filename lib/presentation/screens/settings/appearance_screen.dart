import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NcColors.bg,
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                  'Theme Mode',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: NcColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<String>(
                  groupValue: 'dark',
                  onChanged: (_) {},
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        title: Text('Dark (Stealth)'),
                        subtitle: Text('Default high-contrast battery saving mode'),
                        value: 'dark',
                        activeColor: NcColors.primary,
                      ),
                      RadioListTile<String>(
                        title: Text('Light'),
                        subtitle: Text('Coming soon in a future update'),
                        value: 'light',
                        enabled: false,
                        activeColor: NcColors.primary,
                      ),
                    ],
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
