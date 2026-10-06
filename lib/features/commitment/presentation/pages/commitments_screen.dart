import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:resource_memory/app/routing/app_route.dart';
import 'package:resource_memory/app/theme/app_colors.dart';
import 'package:resource_memory/app/theme/app_typography.dart';
import 'package:resource_memory/features/commitment/data/commitment_store.dart';
import 'package:resource_memory/features/commitment/data/phone_bridge.dart';
import 'package:resource_memory/features/commitment/domain/commitment.dart';

class CommitmentsScreen extends StatefulWidget {
  const CommitmentsScreen({super.key});

  @override
  State<CommitmentsScreen> createState() => _CommitmentsScreenState();
}

class _CommitmentsScreenState extends State<CommitmentsScreen> {
  List<Commitment> get items => CommitmentStore.getAll();

  Future<void> _setStatus(Commitment item, CommitmentStatus status) async {
    final updated = item.copyWith(status: status);
    await CommitmentStore.save(updated);

    if (status == CommitmentStatus.upcoming) {
      await PhoneBridge.requestNotificationPermission();
      await PhoneBridge.scheduleCommitmentReminders(updated);
    } else if (status == CommitmentStatus.done || status == CommitmentStatus.dismissed) {
      await PhoneBridge.cancelCommitmentReminders(item.id);
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final possible = items.where((e) => e.status == CommitmentStatus.needsConfirmation).toList();
    final upcoming = items.where((e) =>
      e.status != CommitmentStatus.needsConfirmation &&
      e.status != CommitmentStatus.done &&
      e.status != CommitmentStatus.dismissed).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Remember'),
        actions: [
          IconButton(
            tooltip: 'Spoken reminders',
            onPressed: () => context.go('/${Routes.spokenReminderSettingsScreen}'),
            icon: const Icon(Icons.volume_up_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
          children: [
            Text('What am I forgetting?', style: AppTypography.h2),
            const SizedBox(height: 6),
            Text(
              'Things that need your attention stay here until you handle them.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 30),
            if (possible.isNotEmpty) ...[
              _SectionLabel('Needs your review'),
              const SizedBox(height: 8),
              _CommitmentList(
                items: possible,
                trailingBuilder: (item) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => _setStatus(item, CommitmentStatus.dismissed),
                      child: const Text('Ignore'),
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: () => _setStatus(item, CommitmentStatus.upcoming),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
            ],
            _SectionLabel('Upcoming'),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              const _EmptyState()
            else
              _CommitmentList(
                items: upcoming,
                trailingBuilder: (item) => PopupMenuButton<CommitmentStatus>(
                  tooltip: 'More actions',
                  icon: const Icon(Icons.more_horiz),
                  onSelected: (value) => _setStatus(item, value),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: CommitmentStatus.ready, child: Text("I'm ready")),
                    PopupMenuItem(value: CommitmentStatus.onMyWay, child: Text("I'm on my way")),
                    PopupMenuItem(value: CommitmentStatus.done, child: Text('Done')),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.labelLg.copyWith(color: AppColors.textSecondary),
  );
}

class _CommitmentList extends StatelessWidget {
  final List<Commitment> items;
  final Widget Function(Commitment item) trailingBuilder;
  const _CommitmentList({required this.items, required this.trailingBuilder});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _CommitmentRow(item: items[i], trailing: trailingBuilder(items[i])),
            if (i < items.length - 1)
              Divider(height: 1, indent: 16, color: AppColors.kBorderColor),
          ],
        ],
      ),
    );
  }
}

class _CommitmentRow extends StatelessWidget {
  final Commitment item;
  final Widget trailing;
  const _CommitmentRow({required this.item, required this.trailing});

  @override
  Widget build(BuildContext context) {
    final local = item.dueAt.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = TimeOfDay.fromDateTime(local).format(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              time,
              style: AppTypography.labelLg.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTypography.bodyMd.copyWith(color: AppColors.textPrimary)),
                const SizedBox(height: 3),
                Text(
                  item.detail == null ? date : '$date · ${item.detail}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      'Nothing needs your attention right now.',
      style: AppTypography.bodyMd.copyWith(color: AppColors.textSecondary),
    ),
  );
}
