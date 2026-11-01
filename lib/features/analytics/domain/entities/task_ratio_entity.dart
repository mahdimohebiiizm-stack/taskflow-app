import 'package:equatable/equatable.dart';

/// Aggregates the completion ratio and breakdown of tasks.
class TaskRatioEntity extends Equatable {
  final int totalCount;
  final int completedCount;
  final int inProgressCount;
  final int todoCount;

  const TaskRatioEntity({
    required this.totalCount,
    required this.completedCount,
    required this.inProgressCount,
    required this.todoCount,
  });

  /// Incomplete tasks count (in progress + to do).
  int get incompleteCount => inProgressCount + todoCount;

  /// Completion percentage ratio from 0.0 to 1.0.
  double get completionRate =>
      totalCount == 0 ? 0.0 : (completedCount / totalCount).clamp(0.0, 1.0);

  /// Completion percentage from 0 to 100.
  int get completionPercent => (completionRate * 100).round();

  @override
  List<Object?> get props => [
        totalCount,
        completedCount,
        inProgressCount,
        todoCount,
      ];
}
