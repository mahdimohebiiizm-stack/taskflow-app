import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/tasks/domain/entities/focus_session_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/xp_ledger_entry_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/focus_session_repository.dart';
import 'package:task_flow/features/tasks/domain/repositories/xp_ledger_repository.dart';
import 'package:task_flow/features/tasks/domain/services/ticker.dart';
import 'package:task_flow/features/tasks/presentation/bloc/focus_timer_event.dart';
import 'package:task_flow/features/tasks/presentation/bloc/focus_timer_state.dart';
import 'package:uuid/uuid.dart';

class FocusTimerBloc extends Bloc<FocusTimerEvent, FocusTimerState> {
  final Ticker _ticker;
  final FocusSessionRepository? _focusSessionRepository;
  final XpLedgerRepository? _xpLedgerRepository;
  final NotificationRepository? _notificationRepository;
  final SettingsBloc? _settingsBloc;
  final Uuid _uuid;

  StreamSubscription<int>? _tickerSubscription;
  String? _currentSessionId;
  String? _currentTaskId;
  String? _currentTaskTitle;
  int _currentTotalDuration = 1500;
  DateTime? _sessionStartedAt;

  FocusTimerBloc({
    required Ticker ticker,
    FocusSessionRepository? focusSessionRepository,
    XpLedgerRepository? xpLedgerRepository,
    NotificationRepository? notificationRepository,
    SettingsBloc? settingsBloc,
    Uuid uuid = const Uuid(),
  })  : _ticker = ticker,
        _focusSessionRepository = focusSessionRepository,
        _xpLedgerRepository = xpLedgerRepository,
        _notificationRepository = notificationRepository,
        _settingsBloc = settingsBloc,
        _uuid = uuid,
        super(const FocusTimerInitial()) {
    on<FocusTimerStarted>(_onStarted);
    on<FocusTimerPaused>(_onPaused);
    on<FocusTimerResumed>(_onResumed);
    on<FocusTimerCancelled>(_onCancelled);
    on<FocusTimerCompleted>(_onCompleted);
    on<FocusTimerTicked>(_onTicked);
  }

  void _onStarted(FocusTimerStarted event, Emitter<FocusTimerState> emit) {
    _tickerSubscription?.cancel();
    _currentSessionId = _uuid.v4();
    _currentTaskId = event.taskId;
    _currentTaskTitle = event.taskTitle;
    _currentTotalDuration = event.durationSeconds;
    _sessionStartedAt = DateTime.now().toUtc();

    emit(
      FocusTimerRunning(
        taskId: event.taskId,
        duration: event.durationSeconds,
        totalDuration: event.durationSeconds,
        taskTitle: event.taskTitle,
      ),
    );

    _tickerSubscription = _ticker
        .tick(ticks: event.durationSeconds)
        .listen((duration) => add(FocusTimerTicked(duration: duration)));
  }

  void _onPaused(FocusTimerPaused event, Emitter<FocusTimerState> emit) {
    if (state is FocusTimerRunning) {
      _tickerSubscription?.pause();
      emit(
        FocusTimerPausedState(
          taskId: _currentTaskId ?? '',
          duration: state.duration,
          totalDuration: state.totalDuration,
          taskTitle: _currentTaskTitle,
        ),
      );
    }
  }

  void _onResumed(FocusTimerResumed event, Emitter<FocusTimerState> emit) {
    if (state is FocusTimerPausedState) {
      _tickerSubscription?.resume();
      emit(
        FocusTimerRunning(
          taskId: _currentTaskId ?? '',
          duration: state.duration,
          totalDuration: state.totalDuration,
          taskTitle: _currentTaskTitle,
        ),
      );
    }
  }

  void _onTicked(FocusTimerTicked event, Emitter<FocusTimerState> emit) {
    if (event.duration > 0) {
      emit(
        FocusTimerRunning(
          taskId: _currentTaskId ?? '',
          duration: event.duration,
          totalDuration: _currentTotalDuration,
          taskTitle: _currentTaskTitle,
        ),
      );
    } else {
      add(const FocusTimerCompleted());
    }
  }

  Future<void> _onCompleted(
    FocusTimerCompleted event,
    Emitter<FocusTimerState> emit,
  ) async {
    await _tickerSubscription?.cancel();

    final actualMinutes = (_currentTotalDuration / 60).round();
    // Strict reward rule: 1 XP per minute of successful focus
    final earnedXp = actualMinutes * 1;
    final endedAt = DateTime.now().toUtc();

    if (_focusSessionRepository != null && _currentSessionId != null) {
      final session = FocusSessionEntity(
        id: _currentSessionId!,
        taskId: _currentTaskId,
        targetMinutes: (_currentTotalDuration / 60).round(),
        actualMinutes: actualMinutes,
        startedAt: _sessionStartedAt ?? endedAt,
        endedAt: endedAt,
        status: FocusSessionStatus.completed,
        earnedXp: earnedXp,
      );
      await _focusSessionRepository.saveFocusSession(session);
    }

    if (_xpLedgerRepository != null && earnedXp > 0) {
      final ledgerEntry = XpLedgerEntryEntity(
        id: _uuid.v4(),
        source: XpSource.pomodoroSession,
        referenceId: _currentSessionId,
        xpAmount: earnedXp,
        description: 'تمرکز عمیق پومودورو ($actualMinutes دقیقه)',
        createdAt: endedAt,
      );
      await _xpLedgerRepository.recordXp(ledgerEntry);
    }

    if (_settingsBloc != null && earnedXp > 0) {
      _settingsBloc.add(SettingsXpAwarded(earnedXp));
    }

    if (_notificationRepository != null) {
      final taskPart = _currentTaskTitle != null && _currentTaskTitle!.isNotEmpty
          ? ' برای «$_currentTaskTitle»'
          : '';
      final notification = AppNotificationEntity(
        id: _uuid.v4(),
        title: 'جلسه تمرکز پومودورو',
        message: 'تمرکز $actualMinutes دقیقه‌ای$taskPart با موفقیت تمام شد! (+$earnedXp XP)',
        type: AppNotificationType.reward,
        timestamp: endedAt,
      );
      await _notificationRepository.saveNotification(notification);
    }

    emit(
      FocusTimerCompletedState(
        taskId: _currentTaskId ?? '',
        totalDuration: _currentTotalDuration,
        earnedXp: earnedXp,
        taskTitle: _currentTaskTitle,
      ),
    );
  }

  Future<void> _onCancelled(
    FocusTimerCancelled event,
    Emitter<FocusTimerState> emit,
  ) async {
    await _tickerSubscription?.cancel();
    final elapsed = _currentTotalDuration - state.duration;
    final endedAt = DateTime.now().toUtc();

    // Strict rule: If cancelled, earnedXp = 0. No partial rewards.
    const earnedXp = 0;

    if (_focusSessionRepository != null && _currentSessionId != null) {
      final session = FocusSessionEntity(
        id: _currentSessionId!,
        taskId: _currentTaskId,
        targetMinutes: (_currentTotalDuration / 60).round(),
        actualMinutes: (elapsed / 60).floor(),
        startedAt: _sessionStartedAt ?? endedAt,
        endedAt: endedAt,
        status: FocusSessionStatus.cancelled,
        earnedXp: earnedXp,
      );
      await _focusSessionRepository.saveFocusSession(session);
    }

    if (_notificationRepository != null) {
      final taskPart = _currentTaskTitle != null && _currentTaskTitle!.isNotEmpty
          ? ' روی «$_currentTaskTitle»'
          : '';
      final notification = AppNotificationEntity(
        id: _uuid.v4(),
        title: 'توقف جلسه تمرکز',
        message: 'جلسه تمرکز$taskPart متوقف شد. (۰ XP)',
        type: AppNotificationType.warning,
        timestamp: endedAt,
      );
      await _notificationRepository.saveNotification(notification);
    }

    emit(
      FocusTimerCancelledState(
        taskId: _currentTaskId ?? '',
        totalDuration: _currentTotalDuration,
        elapsedDuration: elapsed,
        taskTitle: _currentTaskTitle,
      ),
    );
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }
}
