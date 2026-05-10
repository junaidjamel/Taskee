import 'package:flutter/material.dart';

import 'package:taskee/app/extension/context_extension.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';

import 'package:taskee/features/todos/presentation/pages/add/create_taskOrNote_screen.dart';
import 'package:taskee/features/todos/presentation/pages/home/widget/task_widget.dart';
import 'package:taskee/features/todos/presentation/pages/home/widget/user_info_widget.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.gotTo(const CreateTaskOrNoteScreen()),
          child: const Icon(Icons.add),
        ),
        body: AppGradient(
          child: Column(
            children: [
              const UserInfoWidget(),
              const TabCardWidget(),
              const Expanded(
                child: TabBarView(
                  children: [
                    TaskWidget(),
                    Center(child: Text('Important')), // IMPORTANT tab content
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TabCardWidget extends StatelessWidget {
  const TabCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.kBorderColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              color: AppColors.kTabGreyColor,
              borderRadius: BorderRadius.circular(30),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: AppTypography.labelLg,
            tabs: [
              Tab(text: 'TASKS').paddingSymmetric(horizontal: 10),
              Tab(text: 'NOTES').paddingSymmetric(horizontal: 10),
            ],
          ),
        ),
      ),
    );
  }
}
