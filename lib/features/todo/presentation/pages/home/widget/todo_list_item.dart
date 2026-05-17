import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taskee/app/extension/capital_firstletter_extension.dart';
import 'package:taskee/app/extension/context_extension.dart';
import 'package:taskee/app/extension/size_extension.dart';
import 'package:taskee/app/theme/app_colors.dart';
import 'package:taskee/app/theme/app_typography.dart';
import 'package:taskee/features/todo/domain/entities/todo.dart';

class TodoListItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onClickItem;
  final VoidCallback onClickDelete;
  final VoidCallback onToggleComplete;

  const TodoListItem({
    required this.todo,
    required this.onClickItem,
    required this.onClickDelete,
    required this.onToggleComplete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dueLabel = _dueLabel(context, todo.dueAt);

    return Dismissible(
      key: Key('deleted_todo_${todo.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onClickDelete(),
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(CupertinoIcons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onClickItem,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.kGreyCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.kWhite.withValues(alpha: .2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              8.kW,
              Transform.scale(
                scale: 1.4,
                child: Checkbox(
                  value: todo.isCompleted,
                  onChanged: (_) => onToggleComplete(),
                  activeColor: AppColors.accent,
                  checkColor: AppColors.kBorderColor,
                  side: BorderSide(color: AppColors.kWhite),
                  shape: const CircleBorder(),
                ),
              ),
              8.kW,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      todo.title.capitalizeFirst(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: todo.isCompleted
                          ? AppTypography.h4.copyWith(
                              decoration: TextDecoration.lineThrough,
                            )
                          : AppTypography.h4,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [dueLabel].where((e) => e.trim().isNotEmpty).join('\n'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: todo.isCompleted
                          ? AppTypography.bodyLg.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.kgrey,
                            )
                          : AppTypography.bodyLg.copyWith(
                              color: AppColors.kWhite.withValues(alpha: .5),
                            ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 2),
                height: context.screenHeight * .075,
                width: context.screenWidth * .015,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(100),
                    bottomRight: Radius.circular(100),
                  ),
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dueLabel(BuildContext context, DateTime dueAt) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatShortDate(dueAt);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dueAt),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    return '$date $time';
  }
}
