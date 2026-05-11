import 'package:flutter/material.dart';
import 'package:taskee/app/extension/size_extension.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/todos/presentation/pages/add/widgets/create_note_widget.dart';
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton().paddingOnly(left: 20),
                  Text('Create', style: AppTypography.h2),
                  const SizedBox(width: 48 + 20),
                ],
              ),

              25.kH,

              _buildTabBar().paddingOnly(left: 20),

              const Expanded(
                child: TabBarView(
                  children: [CreateTaskWidget(), CreateNoteWidget()],
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
