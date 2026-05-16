import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskee/app/extension/size_extension.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/note/domain/entities/note.dart';
import 'package:taskee/features/note/presentation/pages/addNote/widget/create_orUpdate_note_widget.dart';
import 'package:taskee/features/shared/cubit/tab_cubit.dart';
import 'package:taskee/features/todo/domain/entities/todo.dart';
import 'package:taskee/features/widget/app_gradient.dart';

import 'widgets/create_orUpdate_task_widget.dart';

class CreateTaskOrNoteScreen extends StatefulWidget {
  final bool isUpdateTaskscreen;
  final Todo? todo;
  final Note? note;
  const CreateTaskOrNoteScreen({
    super.key,
    this.isUpdateTaskscreen = false,
    this.todo,
    this.note,
  });

  @override
  State<CreateTaskOrNoteScreen> createState() => _CreateTaskOrNoteScreenState();
}

class _CreateTaskOrNoteScreenState extends State<CreateTaskOrNoteScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final currentTab = context.read<TabCubit>().state;

    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: currentTab,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<TabCubit>().changeTab(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradient(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BackButton().paddingOnly(left: 20),
                Text(
                  widget.isUpdateTaskscreen ? 'Update' : 'Create',
                  style: AppTypography.h2,
                ),
                const SizedBox(width: 48 + 20),
              ],
            ),

            25.kH,

            if (!widget.isUpdateTaskscreen) ...[
              _buildTabBar(_tabController).paddingOnly(left: 20),
              15.kH,
            ],

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  CreateOrUpdateTaskWidget(todo: widget.todo),
                  CreateOrUpdateNoteWidget(note: widget.note),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(TabController controller) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.kBorderColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: IntrinsicWidth(
        child: TabBar(
          controller: controller,
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
