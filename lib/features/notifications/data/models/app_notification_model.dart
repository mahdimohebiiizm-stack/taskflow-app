import 'package:task_flow/features/notifications/domain/entities/app_notification_entity.dart';

/// SQLite data model for persistent in-box notifications.
class AppNotificationModel extends AppNotificationEntity {
  static const String tableName = 'app_notifications';

  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colMessage = 'message';
  static const String colType = 'type';
  static const String colIsRead = 'is_read';
  static const String colTimestamp = 'timestamp';

  const AppNotificationModel({
    required super.id,
    required super.title,
    required super.message,
    super.type = AppNotificationType.info,
    super.isRead = false,
    required super.timestamp,
  });

  factory AppNotificationModel.fromEntity(AppNotificationEntity entity) {
    return AppNotificationModel(
      id: entity.id,
      title: entity.title,
      message: entity.message,
      type: entity.type,
      isRead: entity.isRead,
      timestamp: entity.timestamp,
    );
  }

  factory AppNotificationModel.fromMap(Map<String, dynamic> map) {
    final rawDate = map[colTimestamp] as String?;
    final parsedDate = rawDate != null
        ? (DateTime.tryParse(rawDate) ?? DateTime.now())
        : DateTime.now();

    final rawType = map[colType] as String? ?? 'info';
    final isReadRaw = map[colIsRead];
    final isReadBool = isReadRaw == 1 || isReadRaw == true || isReadRaw == '1';

    return AppNotificationModel(
      id: map[colId] as String? ?? '',
      title: map[colTitle] as String? ?? '',
      message: map[colMessage] as String? ?? '',
      type: AppNotificationType.fromString(rawType),
      isRead: isReadBool,
      timestamp: parsedDate,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      colId: id,
      colTitle: title,
      colMessage: message,
      colType: type.value,
      colIsRead: isRead ? 1 : 0,
      colTimestamp: timestamp.toIso8601String(),
    };
  }
}
