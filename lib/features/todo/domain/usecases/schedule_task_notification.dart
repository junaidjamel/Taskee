import '../entities/todo.dart';
import '../../data/datasource/notification_service.dart';

class ScheduleTaskNotification {
  final NotificationService notificationService;

  ScheduleTaskNotification(this.notificationService);

  Future<void> call(Todo todo) async {
    await notificationService.scheduleNotification(
      id: todo.id,
      title: todo.title,
      dueAt: todo.dueAt,
    );
  }
}
