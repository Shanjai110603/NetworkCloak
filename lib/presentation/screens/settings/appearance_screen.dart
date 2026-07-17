import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../../app/theme/app_theme.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

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
                    color: Colors.white, // keep text readable in both modes on surface
                  ),
                ),
                const SizedBox(height: 12),
                RadioGroup<ThemeMode>(
                  groupValue: themeMode,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(themeModeProvider.notifier).setMode(val);
                    }
                  },
                  child: const Column(
                    children: [
                      RadioListTile<ThemeMode>(
                        title: Text('Dark (Stealth)', style: TextStyle(color: Colors.white)),
                        subtitle: Text('Default high-contrast battery saving mode', style: TextStyle(color: Colors.white70)),
                        value: ThemeMode.dark,
                        activeColor: NcColors.primary,
                      ),
                      RadioListTile<ThemeMode>(
                        title: Text('Light Mode', style: TextStyle(color: Colors.white)),
                        subtitle: Text('Clean UI for daylight visibility', style: TextStyle(color: Colors.white70)),
                        value: ThemeMode.light,
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
