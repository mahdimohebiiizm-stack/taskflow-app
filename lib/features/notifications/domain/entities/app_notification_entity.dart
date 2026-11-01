import 'package:equatable/equatable.dart';

/// Type of application notification.
enum AppNotificationType {
  reward('reward'),
  warning('warning'),
  penalty('penalty'),
  info('info');

  final String value;
  const AppNotificationType(this.value);

  static AppNotificationType fromString(String val) {
    return AppNotificationType.values.firstWhere(
      (e) => e.value.toLowerCase() == val.trim().toLowerCase(),
      orElse: () => AppNotificationType.info,
    );
  }
}

/// Domain entity representing a persistent notification record in the In-Box / Notification Center.
class AppNotificationEntity extends Equatable {
  final String id;
  final String title;
  final String message;
  final AppNotificationType type;
  final bool isRead;
  final DateTime timestamp;

  const AppNotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    this.type = AppNotificationType.info,
    this.isRead = false,
    required this.timestamp,
  });

  AppNotificationEntity copyWith({
    String? id,
    String? title,
    String? message,
    AppNotificationType? type,
    bool? isRead,
    DateTime? timestamp,
  }) {
    return AppNotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        type,
        isRead,
        timestamp,
      ];
}
