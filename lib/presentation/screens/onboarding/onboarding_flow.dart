import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  final _page = ValueNotifier<int>(0);

  static const _pages = [
    _OnboardingPage(
      emoji: '🛡️',
      title: 'Welcome to\nNetwork Cloak',
      subtitle:
          'No account needed. No cloud.\nYour network, your rules.',
      isFirst: true,
    ),
    _OnboardingPage(
      emoji: '🔥',
      title: 'Firewall',
      subtitle:
          'Control which apps can access the internet. Block ads, trackers, and unwanted connections — automatically.',
    ),
    _OnboardingPage(
      emoji: '📡',
      title: 'Shield',
      subtitle:
          'Protects you on public Wi-Fi. Detects suspicious networks and hides your device automatically.',
    ),
    _OnboardingPage(
      emoji: '🔒',
      title: 'DNS Guard',
      subtitle:
          'Encrypts your DNS queries. Blocks ads, malware, and trackers at the DNS level before they reach your apps.',
    ),
    _OnboardingPage(
      emoji: '👁️',
      title: 'Watchtower',
      subtitle:
          'See every connection your device makes, in real time. Know exactly what your apps are doing.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NcColors.bg,
      body: Stack(
        children: [
          // Background glow
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    NcColors.primary.withValues(alpha: 0.1),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: ValueListenableBuilder<int>(
              valueListenable: _page,
              builder: (ctx, page, _) {
                return Column(
                  children: [
                    const SizedBox(height: 40),

                    // Page dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == page ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: i == page
                                ? NcColors.primary
                                : NcColors.border,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),

                    // Page content
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildPage(ctx, _pages[page], page),
                      ),
                    ),

                    // Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (page < _pages.length - 1) {
                                  _page.value = page + 1;
                                } else {
                                  context.go('/');
                                }
                              },
                              child: Text(
                                page == _pages.length - 1
                                    ? "Get Protected →"
                                    : "Continue",
                              ),
                            ),
                          ),
                          if (page > 0) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => _page.value = page - 1,
                              child: const Text('Back',
                                  style: TextStyle(
                                      color: NcColors.textSecondary)),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context.go('/'),
                              child: const Text('Skip setup',
                                  style: TextStyle(
                                      color: NcColors.textMuted)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext ctx, _OnboardingPage page, int idx) {
    return Padding(
      key: ValueKey(idx),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(page.emoji, style: const TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          Text(
            page.title,
            style: Theme.of(ctx).textTheme.headlineLarge?.copyWith(
                  color: NcColors.textPrimary,
                  height: 1.2,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            style: Theme.of(ctx)
                .textTheme
                .bodyLarge
                ?.copyWith(color: NcColors.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (page.isFirst) ...[
            const SizedBox(height: 32),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: NcColors.protected.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: NcColors.protected.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: NcColors.protected, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'No account required',
                    style: TextStyle(
                        color: NcColors.protected,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
  });
  final String emoji, title, subtitle;
  final bool isFirst;
}
