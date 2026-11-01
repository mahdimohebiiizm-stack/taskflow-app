import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';

/// Child entity representing a single 1-level checklist item under a [TaskEntity].
class SubTaskEntity extends Equatable {
  final String id;
  final String title;
  final bool isCompleted;

  const SubTaskEntity._({
    required this.id,
    required this.title,
    required this.isCompleted,
  });

  /// Factory constructor enforcing domain validation rules on creation.
  static Result<SubTaskEntity, DomainFailure> create({
    required String id,
    required String title,
    bool isCompleted = false,
  }) {
    final trimmedId = id.trim();
    final trimmedTitle = title.trim();

    if (trimmedId.isEmpty) {
      return const Err(
        ValidationFailure(message: 'SubTask ID cannot be empty.'),
      );
    }

    if (trimmedTitle.isEmpty) {
      return const Err(
        ValidationFailure(message: 'SubTask title cannot be empty.'),
      );
    }

    return Success(
      SubTaskEntity._(
        id: trimmedId,
        title: trimmedTitle,
        isCompleted: isCompleted,
      ),
    );
  }

  /// Reconstructs a validated [SubTaskEntity] (e.g., from trusted storage mappers).
  factory SubTaskEntity.reconstitute({
    required String id,
    required String title,
    required bool isCompleted,
  }) {
    return SubTaskEntity._(
      id: id,
      title: title,
      isCompleted: isCompleted,
    );
  }

  /// Returns a new [SubTaskEntity] with [isCompleted] inverted.
  SubTaskEntity toggle() {
    return SubTaskEntity._(
      id: id,
      title: title,
      isCompleted: !isCompleted,
    );
  }

  SubTaskEntity copyWith({
    String? title,
    bool? isCompleted,
  }) {
    return SubTaskEntity._(
      id: id,
      title: title != null ? title.trim() : this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  List<Object?> get props => [id, title, isCompleted];
}
