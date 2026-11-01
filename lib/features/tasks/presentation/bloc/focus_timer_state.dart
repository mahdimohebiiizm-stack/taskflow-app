import 'package:equatable/equatable.dart';

sealed class FocusTimerState extends Equatable {
  final int duration;
  final int totalDuration;

  const FocusTimerState({
    required this.duration,
    required this.totalDuration,
  });

  double get progressRatio =>
      totalDuration > 0 ? (totalDuration - duration) / totalDuration : 0.0;

  @override
  List<Object?> get props => [duration, totalDuration];
}

final class FocusTimerInitial extends FocusTimerState {
  const FocusTimerInitial({super.duration = 1500})
      : super(totalDuration: duration);
}

final class FocusTimerRunning extends FocusTimerState {
  final String taskId;
  final String? taskTitle;

  const FocusTimerRunning({
    required this.taskId,
    required super.duration,
    required super.totalDuration,
    this.taskTitle,
  });

  @override
  List<Object?> get props => [taskId, duration, totalDuration, taskTitle];
}

final class FocusTimerPausedState extends FocusTimerState {
  final String taskId;
  final String? taskTitle;

  const FocusTimerPausedState({
    required this.taskId,
    required super.duration,
    required super.totalDuration,
    this.taskTitle,
  });

  @override
  List<Object?> get props => [taskId, duration, totalDuration, taskTitle];
}

final class FocusTimerCompletedState extends FocusTimerState {
  final String taskId;
  final String? taskTitle;
  final int earnedXp;

  const FocusTimerCompletedState({
    required this.taskId,
    required super.totalDuration,
    required this.earnedXp,
    this.taskTitle,
  }) : super(duration: 0);

  @override
  List<Object?> get props => [taskId, duration, totalDuration, earnedXp, taskTitle];
}

final class FocusTimerCancelledState extends FocusTimerState {
  final String taskId;
  final String? taskTitle;
  final int elapsedDuration;

  const FocusTimerCancelledState({
    required this.taskId,
    required super.totalDuration,
    required this.elapsedDuration,
    this.taskTitle,
  }) : super(duration: totalDuration - elapsedDuration);

  @override
  List<Object?> get props =>
      [taskId, duration, totalDuration, elapsedDuration, taskTitle];
}
