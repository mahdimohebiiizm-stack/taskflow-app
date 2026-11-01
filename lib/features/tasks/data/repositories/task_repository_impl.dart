import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

/// Concrete implementation of [TaskRepository].
///
/// Acts as an anti-corruption boundary between the Data layer and Domain layer:
/// - Receives [TaskLocalDataSource] exclusively via constructor injection.
/// - Deterministically maps between Data DTOs and Domain Entities.
/// - Traps all [AppException] and unexpected runtime errors, translating them
///   into controlled [Failure] instances without leaking exceptions upward.
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _localDataSource;

  const TaskRepositoryImpl({
    required TaskLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Result<List<TaskEntity>, Failure>> getTasks({
    TaskStatus? status,
    DateTime? scheduledDate,
  }) async {
    try {
      final models = await _localDataSource.getTasks(
        status: status,
        scheduledDate: scheduledDate,
      );
      final entities = models
          .map((model) => model.toEntity())
          .where((entity) =>
              scheduledDate == null || entity.isScheduledForDate(scheduledDate))
          .toList(growable: false);
      return Success(entities);
    } on LocalDatabaseException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } on AppException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } catch (error) {
      return Err(
        DatabaseFailure(
          message: 'Unexpected error while loading tasks: $error',
        ),
      );
    }
  }

  @override
  Future<Result<TaskEntity, Failure>> getTaskById(String taskId) async {
    try {
      final model = await _localDataSource.getTaskById(taskId);
      return Success(model.toEntity());
    } on RecordNotFoundException catch (error) {
      return Err(
        NotFoundFailure(
          entityId: error.recordId,
          message: error.message,
        ),
      );
    } on LocalDatabaseException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } on AppException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } catch (error) {
      return Err(
        DatabaseFailure(
          message: 'Unexpected error while loading task "$taskId": $error',
        ),
      );
    }
  }

  @override
  Future<Result<TaskEntity, Failure>> saveTask(TaskEntity task) async {
    try {
      final model = TaskModel.fromEntity(task);
      final savedModel = await _localDataSource.saveTask(model);
      return Success(savedModel.toEntity());
    } on LocalDatabaseException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } on AppException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } catch (error) {
      return Err(
        DatabaseFailure(
          message: 'Unexpected error while saving task "${task.id}": $error',
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> deleteTask(String taskId) async {
    try {
      await _localDataSource.deleteTask(taskId);
      return const Success(null);
    } on RecordNotFoundException catch (error) {
      return Err(
        NotFoundFailure(
          entityId: error.recordId,
          message: error.message,
        ),
      );
    } on LocalDatabaseException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } on AppException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } catch (error) {
      return Err(
        DatabaseFailure(
          message: 'Unexpected error while deleting task "$taskId": $error',
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> batchPenalizeTasks(
    List<String> taskIds,
    DateTime updatedAt,
  ) async {
    try {
      await _localDataSource.batchPenalizeTasks(taskIds, updatedAt);
      return const Success(null);
    } on LocalDatabaseException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } on AppException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } catch (error) {
      return Err(
        DatabaseFailure(
          message: 'Unexpected error while batch penalizing tasks: $error',
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> batchRevertPenalizedTasks(
    List<String> taskIds,
    DateTime updatedAt,
  ) async {
    try {
      await _localDataSource.batchRevertPenalizedTasks(taskIds, updatedAt);
      return const Success(null);
    } on LocalDatabaseException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } on AppException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } catch (error) {
      return Err(
        DatabaseFailure(
          message:
              'Unexpected error while batch reverting penalized tasks: $error',
        ),
      );
    }
  }

  @override
  Future<Result<List<TaskEntity>, Failure>> getPenalizedTasksForDate(
    DateTime date,
  ) async {
    try {
      final models = await _localDataSource.getPenalizedTasksForDate(date);
      final entities =
          models.map((m) => m.toEntity()).toList(growable: false);
      return Success(entities);
    } on LocalDatabaseException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } on AppException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } catch (error) {
      return Err(
        DatabaseFailure(
          message:
              'Unexpected error while loading penalized tasks for date: $error',
        ),
      );
    }
  }

  @override
  Future<Result<void, Failure>> batchUpdateSortOrders(
    Map<String, int> sortOrders,
    DateTime updatedAt,
  ) async {
    try {
      await _localDataSource.batchUpdateSortOrders(sortOrders, updatedAt);
      return const Success(null);
    } on LocalDatabaseException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } on AppException catch (error) {
      return Err(DatabaseFailure(message: error.message));
    } catch (error) {
      return Err(
        DatabaseFailure(
          message: 'Unexpected error while updating task sort orders: $error',
        ),
      );
    }
  }
}
