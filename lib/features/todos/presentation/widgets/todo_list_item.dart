import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:taskee/app/extension/capital_firstletter_extension.dart';
import 'package:taskee/app/theme/app_typography.dart';

import '../../domain/entities/todo.dart';

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
      key: Key("deleted_todo_${todo.id}"),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => onClickDelete(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(CupertinoIcons.delete, color: Colors.white),
      ),
      child: ListTile(
        onTap: onClickItem,
        title: Text(
          todo.title.capitalizeFirst(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: todo.isCompleted
              ? AppTypography.h4.copyWith(
                  decoration: TextDecoration.lineThrough,
                )
              : AppTypography.h4,
        ),
        subtitle: Text(
          [dueLabel].where((e) => e.trim().isNotEmpty).join('\n'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: todo.isCompleted
              ? AppTypography.bodyLg.copyWith(
                  decoration: TextDecoration.lineThrough,
                )
              : AppTypography.bodyLg,
        ),
        trailing: const Icon(Icons.chevron_right),
        leading: Checkbox(
          key: Key('todo_item_checkbox_${todo.id}'),
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          value: todo.isCompleted,
          onChanged: (_) => onToggleComplete(),
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
