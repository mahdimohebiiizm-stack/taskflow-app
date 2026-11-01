import 'package:equatable/equatable.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';

sealed class GamificationEvent extends Equatable {
  const GamificationEvent();

  @override
  List<Object?> get props => [];
}

class GamificationTaskCompleted extends GamificationEvent {
  final String taskId;
  final String title;
  final TaskPriority priority;

  const GamificationTaskCompleted({
    required this.taskId,
    required this.title,
    this.priority = TaskPriority.medium,
  });

  @override
  List<Object?> get props => [taskId, title, priority];
}

class GamificationPomodoroCompleted extends GamificationEvent {
  final int minutes;
  final int earnedXp;
  final String? taskTitle;

  const GamificationPomodoroCompleted({
    required this.minutes,
    required this.earnedXp,
    this.taskTitle,
  });

  @override
  List<Object?> get props => [minutes, earnedXp, taskTitle];
}

class GamificationPomodoroCancelled extends GamificationEvent {
  final String? taskTitle;

  const GamificationPomodoroCancelled({this.taskTitle});

  @override
  List<Object?> get props => [taskTitle];
}

class GamificationTaskOverdue extends GamificationEvent {
  final String taskId;
  final String title;
  final int penaltyXp;

  const GamificationTaskOverdue({
    required this.taskId,
    required this.title,
    this.penaltyXp = 5,
  });

  @override
  List<Object?> get props => [taskId, title, penaltyXp];
}

class GamificationStreakBroken extends GamificationEvent {
  final int? lostStreak;

  const GamificationStreakBroken({this.lostStreak});

  @override
  List<Object?> get props => [lostStreak];
}

class GamificationLevelUpTriggered extends GamificationEvent {
  final int? newLevel;
  final String? newTitle;

  const GamificationLevelUpTriggered({this.newLevel, this.newTitle});

  @override
  List<Object?> get props => [newLevel, newTitle];
}

class BuyStreakFreezeEvent extends GamificationEvent {
  final int cost;
  const BuyStreakFreezeEvent({this.cost = 500});

  @override
  List<Object?> get props => [cost];
}

typedef GamificationBuyStreakFreeze = BuyStreakFreezeEvent;

class GamificationInitialized extends GamificationEvent {
  final int totalXp;
  final int streakFreezes;
  final int? level;
  final String? title;

  const GamificationInitialized({
    required this.totalXp,
    this.streakFreezes = 0,
    this.level,
    this.title,
  });

  @override
  List<Object?> get props => [totalXp, streakFreezes, level, title];
}


