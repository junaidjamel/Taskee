import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:resource_memory/features/commitment/domain/commitment.dart';

class PhoneBridge {
  static const _channel = MethodChannel('com.naylahknee.nanynany/phone');

  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  static Future<bool> requestNotificationPermission() async {
    if (!isIOS) return false;
    return await _channel.invokeMethod<bool>('requestNotificationPermission') ?? false;
  }

  static Future<void> speak(String text) async {
    if (!isIOS || text.trim().isEmpty) return;
    await _channel.invokeMethod<void>('speak', {'text': text.trim()});
  }

  static Future<void> scheduleCommitmentReminders(Commitment commitment) async {
    if (!isIOS) return;

    final now = DateTime.now();
    final due = commitment.dueAt.toLocal();
    final reminders = <({String suffix, Duration before, String body})>[
      (
        suffix: '30m',
        before: const Duration(minutes: 30),
        body: 'You have ${commitment.title} in 30 minutes. Stop what you are doing and start getting ready.',
      ),
      (
        suffix: '10m',
        before: const Duration(minutes: 10),
        body: '${commitment.title} starts in 10 minutes. Are you ready?',
      ),
    ];

    for (final reminder in reminders) {
      final when = due.subtract(reminder.before);
      if (!when.isAfter(now)) continue;
      await _channel.invokeMethod<bool>('scheduleReminder', {
        'id': '${commitment.id}-${reminder.suffix}',
        'title': commitment.title,
        'body': reminder.body,
        'epochMs': when.millisecondsSinceEpoch,
      });
    }
  }

  static Future<void> cancelCommitmentReminders(String commitmentId) async {
    if (!isIOS) return;
    for (final suffix in ['30m', '10m']) {
      await _channel.invokeMethod<void>('cancelReminder', {
        'id': '$commitmentId-$suffix',
      });
    }
  }

  static Future<String?> getPendingShortcut() async {
    if (!isIOS) return null;
    return _channel.invokeMethod<String>('getPendingShortcut');
  }
}
