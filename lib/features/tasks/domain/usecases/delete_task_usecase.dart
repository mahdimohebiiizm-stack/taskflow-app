import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

/// Deletes a task by ID and cascades deletion to its child sub-tasks via [TaskRepository].
class DeleteTaskUseCase implements UseCase<void, DeleteTaskParams> {
  final TaskRepository _repository;

  const DeleteTaskUseCase(this._repository);

  @override
  Future<Result<void, Failure>> call(DeleteTaskParams params) {
    return _repository.deleteTask(params.taskId);
  }
}

class DeleteTaskParams extends Equatable {
  final String taskId;

  const DeleteTaskParams({required this.taskId});

  @override
  List<Object?> get props => [taskId];
}
