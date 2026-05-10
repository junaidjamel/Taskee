import 'package:flutter/material.dart';
import 'package:taskee/app/extension/size_extension.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/widget/app_gradient.dart';

import 'widgets/create_task_widget.dart';

class CreateTaskOrNoteScreen extends StatelessWidget {
  const CreateTaskOrNoteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: AppGradient(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackButton().paddingOnly(left: 20),
              20.kH,

              // ── Tab bar ──────────────────────────────────────────────
              _buildTabBar().paddingOnly(left: 20),

              const Expanded(
                child: TabBarView(
                  children: [CreateTaskWidget(), _NoteWidget()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.kBorderColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: IntrinsicWidth(
        child: TabBar(
          indicator: BoxDecoration(
            color: AppColors.kTabGreyColor,
            borderRadius: BorderRadius.circular(30),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          labelStyle: AppTypography.labelLg,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: [
            Tab(text: 'TASK').paddingSymmetric(horizontal: 10),
            Tab(text: 'NOTE'),
          ],
        ),
      ),
    );
  }
}

// ── Invisible title tab (mirrors selected tab) ───────────────────────────────
class _TitleTab extends StatelessWidget {
  const _TitleTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tab(child: Text(label, style: AppTypography.h2));
  }
}

// ── Simple Note placeholder ───────────────────────────────────────────────────
class _NoteWidget extends StatelessWidget {
  const _NoteWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.note_alt_outlined, size: 64, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: AppTypography.h2.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap here to start writing your note',
            style: TextStyle(fontSize: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}
