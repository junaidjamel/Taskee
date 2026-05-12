import '../../data/datasource/notification_service.dart';

class CancelTaskNotification {
  final NotificationService notificationService;

  CancelTaskNotification(this.notificationService);

  Future<void> call(int id) async {
    await notificationService.cancelNotification(id);
  }
}
