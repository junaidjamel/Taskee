import 'package:flutter/material.dart';
import '../../../vo/todo_vo.dart';

class TodoListItem extends StatelessWidget {
  final TodoVO todoVO;
  final Function onClickItem;
  final Function onClickDelete;
  final Function onToggleComplete;

  const TodoListItem(
      {required this.todoVO,
      required this.onClickItem,
      required this.onClickDelete,
      required this.onToggleComplete,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key("deleted_todo_${todoVO.id}"),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onClickDelete();
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: ListTile(
        onTap: () => onClickItem(),
        title: Text(
          todoVO.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: todoVO.isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          todoVO.description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: todoVO.isCompleted
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        trailing: const Icon(
          Icons.chevron_right,
        ),
        leading: Checkbox(
          key: Key('todo_item_checkbox_${todoVO.id}'),
          shape: const ContinuousRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          value: todoVO.isCompleted,
          onChanged: (bool? value) {
            onToggleComplete();
          },
        ),
      ),
    );
  }
}
