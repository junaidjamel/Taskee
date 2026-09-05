import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class InstallAppScreen extends StatelessWidget {
  const InstallAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradient(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 4),
                      Text('Install Resource Memory', style: AppTypography.h3),
                    ]),
                    const SizedBox(height: 28),
                    Text('Put Resource Memory on your home screen.', style: AppTypography.h2),
                    const SizedBox(height: 8),
                    Text(
                      kIsWeb
                          ? 'The web version is installable. It opens in its own app window and uses the same synced library as desktop.'
                          : 'You are already running the native app. Sign in under Sync Devices to use the same library everywhere.',
                      style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    const _InstallCard(
                      icon: Icons.phone_iphone,
                      title: 'iPhone / iPad',
                      steps: [
                        'Open Resource Memory in Safari.',
                        'Tap the Share button.',
                        'Choose Add to Home Screen.',
                        'Tap Add. Resource Memory will appear with your other apps.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _InstallCard(
                      icon: Icons.android,
                      title: 'Android',
                      steps: [
                        'Open Resource Memory in Chrome.',
                        'Open the browser menu.',
                        'Choose Install app or Add to Home screen.',
                        'Confirm Install.',
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _InstallCard(
                      icon: Icons.sync,
                      title: 'After installing',
                      steps: [
                        'Open Sync Devices.',
                        'Sign in with the same Resource Memory account you use on desktop.',
                        'Tap Sync now.',
                        'Your links, screenshots, and voice memories should appear on both devices.',
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InstallCard extends StatelessWidget {
  const _InstallCard({
    required this.icon,
    required this.title,
    required this.steps,
  });

  final IconData icon;
  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: AppColors.accentMuted,
              child: Icon(icon, color: AppColors.accent),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: AppTypography.h3)),
          ]),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    child: Text('${i + 1}.', style: AppTypography.labelLg),
                  ),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
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
