import 'package:sqflite/sqflite.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/features/notifications/data/models/app_notification_model.dart';
import 'package:task_flow/features/notifications/domain/entities/app_notification_entity.dart';

abstract interface class NotificationLocalDataSource {
  Future<AppNotificationEntity> insertNotification(AppNotificationEntity notification);
  Future<List<AppNotificationEntity>> getNotifications({int limit = 50});
  Future<int> getUnreadCount();
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> clearAll();
  Future<void> deleteNotification(String id);
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final Database database;

  const NotificationLocalDataSourceImpl({required this.database});

  @override
  Future<AppNotificationEntity> insertNotification(
    AppNotificationEntity notification,
  ) async {
    try {
      final model = AppNotificationModel.fromEntity(notification);
      await database.insert(
        AppNotificationModel.tableName,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return notification;
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to insert notification into database.',
        cause: e,
      );
    }
  }

  @override
  Future<List<AppNotificationEntity>> getNotifications({int limit = 50}) async {
    try {
      final rows = await database.query(
        AppNotificationModel.tableName,
        orderBy: '${AppNotificationModel.colTimestamp} DESC',
        limit: limit,
      );
      return rows.map((r) => AppNotificationModel.fromMap(r)).toList();
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to fetch notifications from database.',
        cause: e,
      );
    }
  }

  @override
  Future<int> getUnreadCount() async {
    try {
      final result = await database.rawQuery(
        'SELECT COUNT(*) as unread_count FROM ${AppNotificationModel.tableName} WHERE ${AppNotificationModel.colIsRead} = 0',
      );
      if (result.isNotEmpty) {
        return (result.first['unread_count'] as num?)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to count unread notifications.',
        cause: e,
      );
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await database.update(
        AppNotificationModel.tableName,
        {AppNotificationModel.colIsRead: 1},
        where: '${AppNotificationModel.colId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to mark notification as read.',
        cause: e,
      );
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await database.update(
        AppNotificationModel.tableName,
        {AppNotificationModel.colIsRead: 1},
        where: '${AppNotificationModel.colIsRead} = 0',
      );
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to mark all notifications as read.',
        cause: e,
      );
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await database.delete(AppNotificationModel.tableName);
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to clear notifications table.',
        cause: e,
      );
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await database.delete(
        AppNotificationModel.tableName,
        where: '${AppNotificationModel.colId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to delete notification.',
        cause: e,
      );
    }
  }
}
