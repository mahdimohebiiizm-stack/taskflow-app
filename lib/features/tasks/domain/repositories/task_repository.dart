import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

/// Domain Port (Abstract Interface) for Task and Financial persistence operations.
/// The Domain layer depends only on this contract, never on SQLite/Data details.
abstract interface class TaskRepository {
  /// Retrieves all tasks ordered by priority (descending) and due date (ascending).
  /// Optionally filters by [status] and/or calendar [scheduledDate].
  Future<Result<List<TaskEntity>, Failure>> getTasks({
    TaskStatus? status,
    DateTime? scheduledDate,
  });

  /// Retrieves a single [TaskEntity] by its [taskId], including its child sub-tasks and expenses.
  Future<Result<TaskEntity, Failure>> getTaskById(String taskId);

  /// Persists a newly created or updated [TaskEntity] (and its child sub-tasks and expenses atomically).
  Future<Result<TaskEntity, Failure>> saveTask(TaskEntity task);

  /// Deletes a task by [taskId] (cascading to its child sub-tasks and expenses).
  Future<Result<void, Failure>> deleteTask(String taskId);

  /// Atomically marks a batch of tasks as penalized inside a single SQLite transaction.
  Future<Result<void, Failure>> batchPenalizeTasks(
    List<String> taskIds,
    DateTime updatedAt,
  );

  /// Atomically reverts penalty status on a batch of tasks (for Undo) inside a single SQLite transaction.
  Future<Result<void, Failure>> batchRevertPenalizedTasks(
    List<String> taskIds,
    DateTime updatedAt,
  );

  /// Queries all tasks that were unfinished and penalized (`isPenalized == true`) on [date].
  Future<Result<List<TaskEntity>, Failure>> getPenalizedTasksForDate(
    DateTime date,
  );

  /// Atomically updates manual `sortOrder` values for Drag & Drop reordering.
  Future<Result<void, Failure>> batchUpdateSortOrders(
    Map<String, int> sortOrders,
    DateTime updatedAt,
  );
}
