import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:task_flow/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_event.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:uuid/uuid.dart';

class GamificationBloc extends Bloc<GamificationEvent, GamificationState> {
  final NotificationRepository? _notificationRepository;
  final NotificationBloc? _notificationBloc;
  final Uuid _uuid;

  GamificationBloc({
    NotificationRepository? notificationRepository,
    NotificationBloc? notificationBloc,
    Uuid uuid = const Uuid(),
  })  : _notificationRepository = notificationRepository,
        _notificationBloc = notificationBloc,
        _uuid = uuid,
        super(const GamificationState()) {
    on<GamificationTaskCompleted>(_onTaskCompleted);
    on<GamificationPomodoroCompleted>(_onPomodoroCompleted);
    on<GamificationPomodoroCancelled>(_onPomodoroCancelled);
    on<GamificationTaskOverdue>(_onTaskOverdue);
    on<GamificationStreakBroken>(_onStreakBroken);
    on<GamificationLevelUpTriggered>(_onLevelUpTriggered);
    on<BuyStreakFreezeEvent>(_onBuyStreakFreeze);
    on<GamificationInitialized>(_onGamificationInitialized);
  }

  /// محاسبه پویای سطح بر اساس امتیاز تجمیعی XP
  static int calculateLevel(int xp) {
    if (xp <= 0) return 1;
    final lvl = 1 + (xp ~/ 50);
    return lvl > 1 ? lvl : 1;
  }

  /// محاسبه عنوان افتخاری بازیکن بر اساس سطح
  static String calculateTitle(int level) {
    if (level >= 10) return 'استاد اعظم';
    if (level >= 7) return 'استاد بهره‌وری';
    if (level >= 5) return 'مبارز زمان';
    if (level >= 3) return 'برنامه‌ریز حرفه‌ای';
    if (level >= 2) return 'برنامه‌ریز نوظهور';
    return 'تازه‌کار';
  }

  Future<void> _logNotification(AppNotificationEntity notification) async {
    if (_notificationRepository != null) {
      await _notificationRepository.saveNotification(notification);
    }
    if (_notificationBloc != null) {
      _notificationBloc.add(NotificationAdded(notification));
    }
  }

  Future<void> _onTaskCompleted(
    GamificationTaskCompleted event,
    Emitter<GamificationState> emit,
  ) async {
    final earnedXp =
        (event.priority == TaskPriority.high || event.priority == TaskPriority.critical)
            ? 20
            : 10;
    final newTotalXp = state.totalXp + earnedXp;
    final newLevel = calculateLevel(newTotalXp);
    final newTitle = calculateTitle(newLevel);
    final isLevelUp = newLevel > state.level;

    emit(state.copyWith(
      totalXp: newTotalXp,
      lastDeltaXp: earnedXp,
      level: newLevel,
      title: newTitle,
    ));

    final notification = AppNotificationEntity(
      id: _uuid.v4(),
      title: 'تکمیل تسک',
      message: "تسک '${event.title}' با موفقیت تمام شد! (+$earnedXp XP)",
      type: AppNotificationType.reward,
      timestamp: DateTime.now().toUtc(),
    );
    await _logNotification(notification);

    if (isLevelUp) {
      final levelUpNotification = AppNotificationEntity(
        id: _uuid.v4(),
        title: 'ارتقای سطح!',
        message: "تبریک! به سطح $newLevel ($newTitle) ارتقا یافتید! 🎉",
        type: AppNotificationType.reward,
        timestamp: DateTime.now().toUtc(),
      );
      await _logNotification(levelUpNotification);
    }
  }

  Future<void> _onPomodoroCompleted(
    GamificationPomodoroCompleted event,
    Emitter<GamificationState> emit,
  ) async {
    final newTotalXp = state.totalXp + event.earnedXp;
    final newLevel = calculateLevel(newTotalXp);
    final newTitle = calculateTitle(newLevel);
    final isLevelUp = newLevel > state.level;

    emit(state.copyWith(
      totalXp: newTotalXp,
      lastDeltaXp: event.earnedXp,
      level: newLevel,
      title: newTitle,
    ));

    final notification = AppNotificationEntity(
      id: _uuid.v4(),
      title: 'جلسه تمرکز عمیق',
      message: "تمرکز ${event.minutes} دقیقه‌ای با موفقیت تمام شد! (+${event.earnedXp} XP)",
      type: AppNotificationType.reward,
      timestamp: DateTime.now().toUtc(),
    );
    await _logNotification(notification);

    if (isLevelUp) {
      final levelUpNotification = AppNotificationEntity(
        id: _uuid.v4(),
        title: 'ارتقای سطح!',
        message: "تبریک! به سطح $newLevel ($newTitle) ارتقا یافتید! 🎉",
        type: AppNotificationType.reward,
        timestamp: DateTime.now().toUtc(),
      );
      await _logNotification(levelUpNotification);
    }
  }

  Future<void> _onPomodoroCancelled(
    GamificationPomodoroCancelled event,
    Emitter<GamificationState> emit,
  ) async {
    final notification = AppNotificationEntity(
      id: _uuid.v4(),
      title: 'توقف جلسه تمرکز',
      message: (event.taskTitle != null && event.taskTitle!.isNotEmpty)
          ? "تمرکز روی '${event.taskTitle}' لغو شد. (۰ XP)"
          : 'جلسه تمرکز پومودورو لغو شد. (۰ XP)',
      type: AppNotificationType.warning,
      timestamp: DateTime.now().toUtc(),
    );
    await _logNotification(notification);
  }

  Future<void> _onTaskOverdue(
    GamificationTaskOverdue event,
    Emitter<GamificationState> emit,
  ) async {
    final newTotalXp = (state.totalXp - event.penaltyXp).clamp(0, 9999999);
    emit(state.copyWith(
      totalXp: newTotalXp,
      lastDeltaXp: -event.penaltyXp,
    ));

    final notification = AppNotificationEntity(
      id: _uuid.v4(),
      title: 'موعد گذشته و جریمه',
      message: "تسک '${event.title}' انجام نشد و موعد آن گذشت. (-${event.penaltyXp} XP)",
      type: AppNotificationType.penalty,
      timestamp: DateTime.now().toUtc(),
    );
    await _logNotification(notification);
  }

  Future<void> _onStreakBroken(
    GamificationStreakBroken event,
    Emitter<GamificationState> emit,
  ) async {
    final notification = AppNotificationEntity(
      id: _uuid.v4(),
      title: 'شکست زنجیره',
      message: 'استریک شما شکسته شد.',
      type: AppNotificationType.penalty,
      timestamp: DateTime.now().toUtc(),
    );
    await _logNotification(notification);
  }

  Future<void> _onLevelUpTriggered(
    GamificationLevelUpTriggered event,
    Emitter<GamificationState> emit,
  ) async {
    final nextLevel = event.newLevel ?? (state.level + 1);
    final nextTitle = event.newTitle ?? calculateTitle(nextLevel);

    emit(state.copyWith(
      level: nextLevel,
      title: nextTitle,
      lastDeltaXp: 50,
    ));

    final notification = AppNotificationEntity(
      id: _uuid.v4(),
      title: 'ارتقای سطح!',
      message: "تبریک! به سطح $nextLevel ($nextTitle) ارتقا یافتید! 🎉",
      type: AppNotificationType.reward,
      timestamp: DateTime.now().toUtc(),
    );
    await _logNotification(notification);
  }

  Future<void> _onBuyStreakFreeze(
    BuyStreakFreezeEvent event,
    Emitter<GamificationState> emit,
  ) async {
    final cost = event.cost;
    if (state.totalXp < cost) {
      return;
    }

    final newTotalXp = state.totalXp - cost;
    final newStreakFreezes = state.streakFreezes + 1;
    final newLevel = calculateLevel(newTotalXp);
    final newTitle = calculateTitle(newLevel);

    emit(state.copyWith(
      totalXp: newTotalXp,
      lastDeltaXp: -cost,
      streakFreezes: newStreakFreezes,
      level: newLevel,
      title: newTitle,
    ));

    final notification = AppNotificationEntity(
      id: _uuid.v4(),
      title: 'خرید محافظ استریک',
      message: 'یک محافظ استریک (Streak Freeze ❄️) با $cost امتیاز خریداری شد.',
      type: AppNotificationType.reward,
      timestamp: DateTime.now().toUtc(),
    );
    await _logNotification(notification);
  }

  void _onGamificationInitialized(
    GamificationInitialized event,
    Emitter<GamificationState> emit,
  ) {
    final lvl = event.level ?? calculateLevel(event.totalXp);
    final ttl = event.title ?? calculateTitle(lvl);
    emit(state.copyWith(
      totalXp: event.totalXp,
      streakFreezes: event.streakFreezes,
      level: lvl,
      title: ttl,
    ));
  }
}

