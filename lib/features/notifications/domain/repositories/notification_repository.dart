import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/notifications/domain/entities/app_notification_entity.dart';

abstract interface class NotificationRepository {
  Future<Result<AppNotificationEntity, Failure>> saveNotification(
    AppNotificationEntity notification,
  );
  Future<Result<List<AppNotificationEntity>, Failure>> getNotifications({
    int limit = 50,
  });
  Future<Result<int, Failure>> getUnreadCount();
  Future<Result<void, Failure>> markAsRead(String id);
  Future<Result<void, Failure>> markAllAsRead();
  Future<Result<void, Failure>> clearAll();
  Future<Result<void, Failure>> deleteNotification(String id);
}
