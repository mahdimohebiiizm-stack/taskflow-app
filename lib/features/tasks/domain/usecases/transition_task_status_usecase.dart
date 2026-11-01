import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

/// Transitions a [TaskEntity] to a new [TaskStatus] while enforcing all domain invariants.
class TransitionTaskStatusUseCase
    implements UseCase<TaskEntity, TransitionTaskStatusParams> {
  final TaskRepository _repository;

  const TransitionTaskStatusUseCase(this._repository);

  @override
  Future<Result<TaskEntity, Failure>> call(
    TransitionTaskStatusParams params,
  ) async {
    final taskResult = await _repository.getTaskById(params.taskId);

    return switch (taskResult) {
      Err<TaskEntity, Failure>(failure: final f) => Err(f),
      Success<TaskEntity, Failure>(value: final existingTask) =>
        await _applyTransition(existingTask, params),
    };
  }

  Future<Result<TaskEntity, Failure>> _applyTransition(
    TaskEntity existingTask,
    TransitionTaskStatusParams params,
  ) async {
    final transitionResult = existingTask.transitionStatus(
      params.targetStatus,
      updatedAt: params.timestamp ?? DateTime.now().toUtc(),
    );

    return switch (transitionResult) {
      Err<TaskEntity, DomainFailure>(failure: final domainFailure) =>
        Err(domainFailure),
      Success<TaskEntity, DomainFailure>(value: final updatedTask) =>
        await _repository.saveTask(updatedTask),
    };
  }
}

class TransitionTaskStatusParams extends Equatable {
  final String taskId;
  final TaskStatus targetStatus;
  final DateTime? timestamp;

  const TransitionTaskStatusParams({
    required this.taskId,
    required this.targetStatus,
    this.timestamp,
  });

  @override
  List<Object?> get props => [taskId, targetStatus, timestamp];
}
