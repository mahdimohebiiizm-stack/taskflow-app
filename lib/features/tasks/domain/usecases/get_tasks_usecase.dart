import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

/// Retrieves ordered tasks from [TaskRepository], optionally filtered by [TaskStatus].
class GetTasksUseCase implements UseCase<List<TaskEntity>, GetTasksParams> {
  final TaskRepository _repository;

  const GetTasksUseCase(this._repository);

  @override
  Future<Result<List<TaskEntity>, Failure>> call(GetTasksParams params) {
    return _repository.getTasks(
      status: params.status,
      scheduledDate: params.scheduledDate,
    );
  }
}

class GetTasksParams extends Equatable {
  final TaskStatus? status;
  final DateTime? scheduledDate;

  const GetTasksParams({this.status, this.scheduledDate});

  @override
  List<Object?> get props => [status, scheduledDate];
}
