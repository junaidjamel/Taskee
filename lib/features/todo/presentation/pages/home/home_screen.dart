import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:taskee/app/extension/context_extension.dart';
import 'package:taskee/app/extension/widget_padding_extension.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/shared/cubit/tab_cubit.dart';

import 'package:taskee/features/todo/presentation/pages/add/create_taskOrNote_screen.dart';
import 'package:taskee/features/note/presentation/pages/addNote/widget/note_widget.dart';
import 'package:taskee/features/todo/presentation/pages/home/widget/task_widget.dart';
import 'package:taskee/features/todo/presentation/pages/home/widget/user_info_widget.dart';
import 'package:taskee/features/widget/app_gradient.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
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
    return BlocListener<TabCubit, int>(
      listener: (context, tabIndex) {
        if (_tabController.index != tabIndex) {
          _tabController.animateTo(tabIndex, duration: Duration.zero);
        }
      },
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.gotTo(const CreateTaskOrNoteScreen()),
          child: const Icon(Icons.add),
        ),
        body: AppGradient(
          child: Column(
            children: [
              const UserInfoWidget(),
              TabCardWidget(controller: _tabController), // ← pass controller
              Expanded(
                child: TabBarView(
                  controller: _tabController, // ← pass controller
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [TaskWidget(), NoteWidget()],
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
  final TabController controller;

  const TabCardWidget({super.key, required this.controller});

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
            controller: controller, // ← use passed controller
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
