import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_event.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;

  NotificationBloc({required this.repository}) : super(const NotificationState()) {
    on<NotificationsLoadRequested>(_onLoadRequested);
    on<NotificationAdded>(_onAdded);
    on<NotificationMarkedAsRead>(_onMarkedAsRead);
    on<NotificationsMarkAllRead>(_onMarkAllRead);
    on<NotificationsCleared>(_onCleared);
    on<NotificationDeleted>(_onDeleted);
  }

  Future<void> _onLoadRequested(
    NotificationsLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final result = await repository.getNotifications();
    switch (result) {
      case Success(value: final list):
        final unreadCount = list.where((n) => !n.isRead).length;
        emit(
          state.copyWith(
            notifications: list,
            unreadCount: unreadCount,
            isLoading: false,
            failure: () => null,
          ),
        );
      case Err(failure: final f):
        emit(
          state.copyWith(
            isLoading: false,
            failure: () => f,
          ),
        );
    }
  }

  Future<void> _onAdded(
    NotificationAdded event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await repository.saveNotification(event.notification);
    if (result case Success(value: final saved)) {
      final updatedList = [
        saved,
        ...state.notifications.where((n) => n.id != saved.id),
      ];
      final unreadCount = updatedList.where((n) => !n.isRead).length;
      emit(
        state.copyWith(
          notifications: updatedList,
          unreadCount: unreadCount,
        ),
      );
    }
  }

  Future<void> _onMarkedAsRead(
    NotificationMarkedAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final updatedList = state.notifications.map((n) {
      if (n.id == event.id) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
    final unreadCount = updatedList.where((n) => !n.isRead).length;
    emit(state.copyWith(notifications: updatedList, unreadCount: unreadCount));

    await repository.markAsRead(event.id);
  }

  Future<void> _onMarkAllRead(
    NotificationsMarkAllRead event,
    Emitter<NotificationState> emit,
  ) async {
    final updatedList =
        state.notifications.map((n) => n.copyWith(isRead: true)).toList();
    emit(state.copyWith(notifications: updatedList, unreadCount: 0));

    await repository.markAllAsRead();
  }

  Future<void> _onCleared(
    NotificationsCleared event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(notifications: const [], unreadCount: 0));
    await repository.clearAll();
  }

  Future<void> _onDeleted(
    NotificationDeleted event,
    Emitter<NotificationState> emit,
  ) async {
    final updatedList =
        state.notifications.where((n) => n.id != event.id).toList();
    final unreadCount = updatedList.where((n) => !n.isRead).length;
    emit(state.copyWith(notifications: updatedList, unreadCount: unreadCount));

    await repository.deleteNotification(event.id);
  }
}
