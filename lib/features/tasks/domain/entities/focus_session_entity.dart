import 'package:equatable/equatable.dart';

/// Lifecycle state of a Pomodoro Deep Work focus session.
enum FocusSessionStatus {
  running('running'),
  paused('paused'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const FocusSessionStatus(this.value);

  static FocusSessionStatus fromString(String val) {
    return FocusSessionStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => FocusSessionStatus.completed,
    );
  }
}

/// Domain entity representing an isolated Pomodoro focus session.
class FocusSessionEntity extends Equatable {
  final String id;
  final String? taskId;
  final int targetMinutes;
  final int actualMinutes;
  final DateTime startedAt;
  final DateTime? endedAt;
  final FocusSessionStatus status;
  final int earnedXp;

  const FocusSessionEntity({
    required this.id,
    this.taskId,
    required this.targetMinutes,
    required this.actualMinutes,
    required this.startedAt,
    this.endedAt,
    required this.status,
    required this.earnedXp,
  });

  FocusSessionEntity copyWith({
    String? id,
    String? Function()? taskId,
    int? targetMinutes,
    int? actualMinutes,
    DateTime? startedAt,
    DateTime? Function()? endedAt,
    FocusSessionStatus? status,
    int? earnedXp,
  }) {
    return FocusSessionEntity(
      id: id ?? this.id,
      taskId: taskId != null ? taskId() : this.taskId,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt != null ? endedAt() : this.endedAt,
      status: status ?? this.status,
      earnedXp: earnedXp ?? this.earnedXp,
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        targetMinutes,
        actualMinutes,
        startedAt,
        endedAt,
        status,
        earnedXp,
      ];
}
