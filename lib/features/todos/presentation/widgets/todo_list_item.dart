import 'package:flutter/material.dart';

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
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        onTap: onClickItem,
        title: Text(
          todo.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: todo.isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          ['Due: $dueLabel'].where((e) => e.trim().isNotEmpty).join('\n'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: todo.isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
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
