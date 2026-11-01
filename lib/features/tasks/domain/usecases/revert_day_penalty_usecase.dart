import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

/// Atomically reverts penalty status on a list of tasks (e.g. for Undo action within 5s).
class RevertDayPenaltyUseCase
    implements UseCase<void, RevertDayPenaltyParams> {
  final TaskRepository _repository;

  const RevertDayPenaltyUseCase(this._repository);

  @override
  Future<Result<void, Failure>> call(RevertDayPenaltyParams params) async {
    if (params.taskIds.isEmpty) {
      return const Success(null);
    }
    final now = params.now ?? DateTime.now();
    return _repository.batchRevertPenalizedTasks(params.taskIds, now);
  }
}

class RevertDayPenaltyParams extends Equatable {
  final List<String> taskIds;
  final DateTime? now;

  const RevertDayPenaltyParams({
    required this.taskIds,
    this.now,
  });

  @override
  List<Object?> get props => [taskIds, now];
}
