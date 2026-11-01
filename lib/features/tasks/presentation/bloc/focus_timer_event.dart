import 'package:equatable/equatable.dart';

sealed class FocusTimerEvent extends Equatable {
  const FocusTimerEvent();

  @override
  List<Object?> get props => [];
}

final class FocusTimerStarted extends FocusTimerEvent {
  final String taskId;
  final int durationSeconds;
  final String? taskTitle;

  const FocusTimerStarted({
    required this.taskId,
    required this.durationSeconds,
    this.taskTitle,
  });

  @override
  List<Object?> get props => [taskId, durationSeconds, taskTitle];
}

final class FocusTimerPaused extends FocusTimerEvent {
  const FocusTimerPaused();
}

final class FocusTimerResumed extends FocusTimerEvent {
  const FocusTimerResumed();
}

final class FocusTimerCancelled extends FocusTimerEvent {
  const FocusTimerCancelled();
}

final class FocusTimerCompleted extends FocusTimerEvent {
  const FocusTimerCompleted();
}

final class FocusTimerTicked extends FocusTimerEvent {
  final int duration;

  const FocusTimerTicked({required this.duration});

  @override
  List<Object?> get props => [duration];
}
