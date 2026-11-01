import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

/// Toggles a child [SubTaskEntity] and automatically reverts parent status
/// from `Done` to `In Progress` if the sub-task becomes incomplete.
class ToggleSubTaskUseCase implements UseCase<TaskEntity, ToggleSubTaskParams> {
  final TaskRepository _repository;

  const ToggleSubTaskUseCase(this._repository);

  @override
  Future<Result<TaskEntity, Failure>> call(ToggleSubTaskParams params) async {
    final taskResult = await _repository.getTaskById(params.taskId);

    return switch (taskResult) {
      Err<TaskEntity, Failure>(failure: final f) => Err(f),
      Success<TaskEntity, Failure>(value: final existingTask) =>
        await _applyToggle(existingTask, params),
    };
  }

  Future<Result<TaskEntity, Failure>> _applyToggle(
    TaskEntity existingTask,
    ToggleSubTaskParams params,
  ) async {
    final toggleResult = existingTask.toggleSubTask(
      params.subTaskId,
      updatedAt: params.timestamp ?? DateTime.now().toUtc(),
    );

    return switch (toggleResult) {
      Err<TaskEntity, DomainFailure>(failure: final domainFailure) =>
        Err(domainFailure),
      Success<TaskEntity, DomainFailure>(value: final updatedTask) =>
        await _repository.saveTask(updatedTask),
    };
  }
}

class ToggleSubTaskParams extends Equatable {
  final String taskId;
  final String subTaskId;
  final DateTime? timestamp;

  const ToggleSubTaskParams({
    required this.taskId,
    required this.subTaskId,
    this.timestamp,
  });

  @override
  List<Object?> get props => [taskId, subTaskId, timestamp];
}
