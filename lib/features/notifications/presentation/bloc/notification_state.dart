import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/notifications/domain/entities/app_notification_entity.dart';

class NotificationState extends Equatable {
  final List<AppNotificationEntity> notifications;
  final int unreadCount;
  final bool isLoading;
  final Failure? failure;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.failure,
  });

  bool get hasUnread => unreadCount > 0;

  NotificationState copyWith({
    List<AppNotificationEntity>? notifications,
    int? unreadCount,
    bool? isLoading,
    Failure? Function()? failure,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        unreadCount,
        isLoading,
        failure,
      ];
}
