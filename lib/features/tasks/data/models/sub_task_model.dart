import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/features/tasks/domain/entities/sub_task_entity.dart';

/// Data Transfer Object (DTO) for [SubTaskEntity] persistence in SQLite.
class SubTaskModel extends Equatable {
  static const String tableName = 'sub_tasks';
  static const String colId = 'id';
  static const String colTaskId = 'task_id';
  static const String colTitle = 'title';
  static const String colIsCompleted = 'is_completed';
  static const String colPosition = 'position';

  final String id;
  final String taskId;
  final String title;
  final bool isCompleted;
  final int position;

  const SubTaskModel({
    required this.id,
    required this.taskId,
    required this.title,
    required this.isCompleted,
    required this.position,
  });

  /// Deterministically maps a domain [SubTaskEntity] into a [SubTaskModel].
  factory SubTaskModel.fromEntity(
    SubTaskEntity entity, {
    required String taskId,
    required int position,
  }) {
    return SubTaskModel(
      id: entity.id,
      taskId: taskId,
      title: entity.title,
      isCompleted: entity.isCompleted,
      position: position,
    );
  }

  /// Deterministically parses a SQLite row [Map] into a [SubTaskModel].
  /// Throws [LocalDatabaseException] if any column is missing or corrupted.
  factory SubTaskModel.fromMap(Map<String, Object?> map) {
    try {
      final id = map[colId] as String?;
      final taskId = map[colTaskId] as String?;
      final title = map[colTitle] as String?;
      final rawCompleted = map[colIsCompleted];
      final rawPosition = map[colPosition];

      if (id == null || id.trim().isEmpty) {
        throw const LocalDatabaseException(
          message: 'Corrupted sub_tasks row: missing or empty "id".',
        );
      }
      if (taskId == null || taskId.trim().isEmpty) {
        throw const LocalDatabaseException(
          message: 'Corrupted sub_tasks row: missing or empty "task_id".',
        );
      }
      if (title == null || title.trim().isEmpty) {
        throw const LocalDatabaseException(
          message: 'Corrupted sub_tasks row: missing or empty "title".',
        );
      }

      final bool isCompleted;
      if (rawCompleted is int) {
        isCompleted = rawCompleted == 1;
      } else if (rawCompleted is bool) {
        isCompleted = rawCompleted;
      } else {
        throw LocalDatabaseException(
          message:
              'Corrupted sub_tasks row: invalid "is_completed" value ($rawCompleted).',
        );
      }

      final position = rawPosition is int ? rawPosition : 0;

      return SubTaskModel(
        id: id,
        taskId: taskId,
        title: title,
        isCompleted: isCompleted,
        position: position,
      );
    } catch (error) {
      if (error is LocalDatabaseException) {
        rethrow;
      }
      throw LocalDatabaseException(
        message: 'Failed to deserialize SubTaskModel from SQLite map.',
        cause: error,
      );
    }
  }

  /// Serializes this model into a SQLite-compatible [Map].
  Map<String, Object?> toMap() {
    return <String, Object?>{
      colId: id,
      colTaskId: taskId,
      colTitle: title,
      colIsCompleted: isCompleted ? 1 : 0,
      colPosition: position,
    };
  }

  /// Deterministically converts this [SubTaskModel] into a domain [SubTaskEntity].
  SubTaskEntity toEntity() {
    return SubTaskEntity.reconstitute(
      id: id,
      title: title,
      isCompleted: isCompleted,
    );
  }

  @override
  List<Object?> get props => [id, taskId, title, isCompleted, position];
}
