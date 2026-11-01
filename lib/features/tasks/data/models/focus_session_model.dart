import 'package:task_flow/features/tasks/domain/entities/focus_session_entity.dart';

/// Data Transfer Object (DTO) for [FocusSessionEntity] persistence in SQLite.
class FocusSessionModel extends FocusSessionEntity {
  static const String tableName = 'focus_sessions';
  static const String colId = 'id';
  static const String colTaskId = 'task_id';
  static const String colTargetMinutes = 'target_minutes';
  static const String colActualMinutes = 'actual_minutes';
  static const String colStartedAt = 'started_at';
  static const String colEndedAt = 'ended_at';
  static const String colStatus = 'state';
  static const String colEarnedXp = 'earned_xp';

  const FocusSessionModel({
    required super.id,
    super.taskId,
    required super.targetMinutes,
    required super.actualMinutes,
    required super.startedAt,
    super.endedAt,
    required super.status,
    required super.earnedXp,
  });

  factory FocusSessionModel.fromEntity(FocusSessionEntity entity) {
    return FocusSessionModel(
      id: entity.id,
      taskId: entity.taskId,
      targetMinutes: entity.targetMinutes,
      actualMinutes: entity.actualMinutes,
      startedAt: entity.startedAt,
      endedAt: entity.endedAt,
      status: entity.status,
      earnedXp: entity.earnedXp,
    );
  }

  factory FocusSessionModel.fromMap(Map<String, Object?> map) {
    return FocusSessionModel(
      id: map[colId] as String,
      taskId: map[colTaskId] as String?,
      targetMinutes: map[colTargetMinutes] as int? ?? 0,
      actualMinutes: map[colActualMinutes] as int? ?? 0,
      startedAt: DateTime.parse(map[colStartedAt] as String),
      endedAt: map[colEndedAt] != null
          ? DateTime.tryParse(map[colEndedAt] as String)
          : null,
      status: FocusSessionStatus.fromString(map[colStatus] as String? ?? 'completed'),
      earnedXp: map[colEarnedXp] as int? ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      colId: id,
      colTaskId: taskId,
      colTargetMinutes: targetMinutes,
      colActualMinutes: actualMinutes,
      colStartedAt: startedAt.toIso8601String(),
      colEndedAt: endedAt?.toIso8601String(),
      colStatus: status.value,
      colEarnedXp: earnedXp,
    };
  }
}
