import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:task_flow/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationLocalDataSource localDataSource;

  const NotificationRepositoryImpl({required this.localDataSource});

  @override
  Future<Result<AppNotificationEntity, Failure>> saveNotification(
    AppNotificationEntity notification,
  ) async {
    try {
      final saved = await localDataSource.insertNotification(notification);
      return Success(saved);
    } catch (e) {
      return Err(DatabaseFailure(message: 'Failed to save notification: $e'));
    }
  }

  @override
  Future<Result<List<AppNotificationEntity>, Failure>> getNotifications({
    int limit = 50,
  }) async {
    try {
      final list = await localDataSource.getNotifications(limit: limit);
      return Success(list);
    } catch (e) {
      return Err(DatabaseFailure(message: 'Failed to fetch notifications: $e'));
    }
  }

  @override
  Future<Result<int, Failure>> getUnreadCount() async {
    try {
      final count = await localDataSource.getUnreadCount();
      return Success(count);
    } catch (e) {
      return Err(DatabaseFailure(message: 'Failed to count unread notifications: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> markAsRead(String id) async {
    try {
      await localDataSource.markAsRead(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(message: 'Failed to mark notification as read: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> markAllAsRead() async {
    try {
      await localDataSource.markAllAsRead();
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(message: 'Failed to mark all as read: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> clearAll() async {
    try {
      await localDataSource.clearAll();
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(message: 'Failed to clear notifications: $e'));
    }
  }

  @override
  Future<Result<void, Failure>> deleteNotification(String id) async {
    try {
      await localDataSource.deleteNotification(id);
      return const Success(null);
    } catch (e) {
      return Err(DatabaseFailure(message: 'Failed to delete notification: $e'));
    }
  }
}
