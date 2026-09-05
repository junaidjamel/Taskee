import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:taskee/app/routing/app_route.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class ResourceHomeScreen extends StatelessWidget {
  const ResourceHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final isTablet = constraints.maxWidth >= 650;
        final horizontalPadding = isDesktop ? 40.0 : (isTablet ? 28.0 : 20.0);

        return Scaffold(
          floatingActionButton: isDesktop
              ? null
              : FloatingActionButton(
                  onPressed: () => context.go('/${Routes.saveResourceScreen}'),
                  child: const Icon(Icons.add),
                ),
          body: AppGradient(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isDesktop ? 36 : 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(isDesktop: isDesktop),
                        SizedBox(height: isDesktop ? 32 : 28),
                        _Navigation(isDesktop: isDesktop),
                        SizedBox(height: isDesktop ? 28 : 24),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.auto_awesome,
                                  title: 'What are you working on?',
                                  body: 'Describe the project. We’ll surface things you already saved that may help.',
                                  action: 'Find useful resources',
                                  onTap: () => context.go('/${Routes.projectMatchScreen}'),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.add_link,
                                  title: 'Save something useful',
                                  body: 'Threads, YouTube, GitHub, websites, screenshots — save it with context.',
                                  action: 'Save a resource',
                                  onTap: () => context.go('/${Routes.saveResourceScreen}'),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _ActionCard(
                                  icon: Icons.mic_none_rounded,
                                  title: 'Say it before you forget it',
                                  body: 'Record an idea or import a voice memo. We’ll transcribe it and make it useful again later.',
                                  action: 'Save a voice memory',
                                  onTap: () => context.go('/${Routes.voiceMemoryScreen}'),
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _ActionCard(
                            icon: Icons.auto_awesome,
                            title: 'What are you working on?',
                            body: 'Describe the project. We’ll surface things you already saved that may help.',
                            action: 'Find useful resources',
                            onTap: () => context.go('/${Routes.projectMatchScreen}'),
                          ),
                          const SizedBox(height: 16),
                          _ActionCard(
                            icon: Icons.add_link,
                            title: 'Save something useful',
                            body: 'Threads, YouTube, GitHub, websites, screenshots — save it with context.',
                            action: 'Save a resource',
                            onTap: () => context.go('/${Routes.saveResourceScreen}'),
                          ),
                          const SizedBox(height: 16),
                          _ActionCard(
                            icon: Icons.mic_none_rounded,
                            title: 'Say it before you forget it',
                            body: 'Record an idea or import a voice memo. We’ll transcribe it and make it useful again later.',
                            action: 'Save a voice memory',
                            onTap: () => context.go('/${Routes.voiceMemoryScreen}'),
                          ),
                        ],
                        SizedBox(height: isDesktop ? 44 : 28),
                        _ReturnSection(isDesktop: isDesktop),
                        const SizedBox(height: 32),
                        Text(
                          'Save it once. Find it when it matters.',
                          style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final bool isDesktop;
  const _Header({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Remember what helps.', style: AppTypography.h2),
              const SizedBox(height: 8),
              Text(
                'Save useful coding resources and bring them back when a project needs them.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (!isDesktop)
          IconButton.filledTonal(
            tooltip: 'Sync devices',
            onPressed: () => context.go('/${Routes.syncScreen}'),
            icon: const Icon(Icons.cloud_sync_outlined),
          ),
        if (isDesktop) ...[
          OutlinedButton.icon(
            onPressed: () => context.go('/${Routes.syncScreen}'),
            icon: const Icon(Icons.cloud_sync_outlined),
            label: const Text('Sync devices'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: () => context.go('/${Routes.saveResourceScreen}'),
            icon: const Icon(Icons.add_link),
            label: const Text('Save resource'),
          ),
        ],
      ],
    );
  }
}

class _Navigation extends StatelessWidget {
  final bool isDesktop;
  const _Navigation({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final nav = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.kBorderColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(child: _NavPill(label: 'NOW', selected: true, onTap: () {})),
          Expanded(child: _NavPill(label: 'LIBRARY', onTap: () => context.go('/${Routes.libraryScreen}'))),
        ],
      ),
    );
    return isDesktop ? SizedBox(width: 420, child: nav) : nav;
  }
}

class _ReturnSection extends StatelessWidget {
  final bool isDesktop;
  const _ReturnSection({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 24 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: .72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorderColor),
      ),
      child: isDesktop
          ? Row(
              children: [
                const Expanded(child: _ReturnCopy()),
                const SizedBox(width: 24),
                OutlinedButton.icon(
                  onPressed: () => context.go('/${Routes.libraryScreen}'),
                  icon: const Icon(Icons.history),
                  label: const Text('Browse saved resources'),
                ),
              ],
            )
          : const _ReturnCopy(),
    );
  }
}

class _ReturnCopy extends StatelessWidget {
  const _ReturnCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Useful again', style: AppTypography.h3),
        const SizedBox(height: 6),
        Text(
          'As your library grows, this space will bring older resources back when they become relevant again.',
          style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _NavPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavPill({required this.label, required this.onTap, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.kTabGreyColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTypography.labelLg.copyWith(
            fontSize: 13.5,
            color: selected ? Colors.white : Colors.white38,
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;
  const _ActionCard({required this.icon, required this.title, required this.body, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.accentMuted,
            child: Icon(icon, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.h3),
          const SizedBox(height: 8),
          Text(body, style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward),
            label: Text(action),
          ),
        ],
      ),
    );
  }
}
