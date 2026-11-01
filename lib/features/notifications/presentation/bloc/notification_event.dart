import 'package:equatable/equatable.dart';
import 'package:task_flow/features/notifications/domain/entities/app_notification_entity.dart';

sealed class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsLoadRequested extends NotificationEvent {
  const NotificationsLoadRequested();
}

class NotificationAdded extends NotificationEvent {
  final AppNotificationEntity notification;
  const NotificationAdded(this.notification);

  @override
  List<Object?> get props => [notification];
}

class NotificationMarkedAsRead extends NotificationEvent {
  final String id;
  const NotificationMarkedAsRead(this.id);

  @override
  List<Object?> get props => [id];
}

class NotificationsMarkAllRead extends NotificationEvent {
  const NotificationsMarkAllRead();
}

class NotificationsCleared extends NotificationEvent {
  const NotificationsCleared();
}

class NotificationDeleted extends NotificationEvent {
  final String id;
  const NotificationDeleted(this.id);

  @override
  List<Object?> get props => [id];
}
