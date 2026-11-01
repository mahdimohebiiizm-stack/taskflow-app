import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/features/tasks/data/models/expense_item_model.dart';
import 'package:task_flow/features/tasks/data/models/sub_task_model.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

/// Contract for local SQLite persistence operations on [TaskModel].
abstract interface class TaskLocalDataSource {
  /// Retrieves all tasks ordered by priority (descending) and due date (ascending).
  /// Optionally filters by [status] and/or calendar [scheduledDate].
  Future<List<TaskModel>> getTasks({
    TaskStatus? status,
    DateTime? scheduledDate,
  });

  /// Retrieves a single [TaskModel] by [taskId] along with its ordered [SubTaskModel]s
  /// and [ExpenseItemModel]s.
  /// Throws [RecordNotFoundException] if no matching task exists.
  Future<TaskModel> getTaskById(String taskId);

  /// Atomically upserts a [TaskModel] and synchronizes its child [SubTaskModel]s
  /// and [ExpenseItemModel]s inside a single ACID transaction.
  Future<TaskModel> saveTask(TaskModel task);

  /// Deletes a task by [taskId] (cascading to child sub-tasks and expenses via Foreign Key).
  /// Throws [RecordNotFoundException] if no matching task existed.
  Future<void> deleteTask(String taskId);

  /// Atomically updates a list of tasks to is_penalized = 1 in a single SQLite batch transaction.
  Future<void> batchPenalizeTasks(List<String> taskIds, DateTime updatedAt);

  /// Atomically reverts penalty on a list of tasks to is_penalized = 0 (for Undo) in a single SQLite batch transaction.
  Future<void> batchRevertPenalizedTasks(
    List<String> taskIds,
    DateTime updatedAt,
  );

  /// Queries all tasks that were unfinished and penalized (`is_penalized = 1`) on the specified calendar [date].
  Future<List<TaskModel>> getPenalizedTasksForDate(DateTime date);

  /// Atomically updates manual `sort_order` values after Drag & Drop reordering.
  Future<void> batchUpdateSortOrders(
    Map<String, int> sortOrders,
    DateTime updatedAt,
  );
}

/// SQLite implementation of [TaskLocalDataSource].
/// Receives its [Database] dependency exclusively through constructor injection.
class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final Database _database;

  const TaskLocalDataSourceImpl({required Database database})
      : _database = database;

  @override
  Future<List<TaskModel>> getTasks({
    TaskStatus? status,
    DateTime? scheduledDate,
  }) async {
    try {
      final whereClauses = <String>[];
      final whereArgs = <Object?>[];

      if (status != null) {
        whereClauses.add('${TaskModel.colStatus} = ?');
        whereArgs.add(status.storageKey);
      }

      if (scheduledDate != null) {
        final localStart = DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          0,
          0,
          0,
        );
        final localEnd = DateTime(
          scheduledDate.year,
          scheduledDate.month,
          scheduledDate.day,
          23,
          59,
          59,
          999,
        );

        final utcStart = localStart.toUtc().toIso8601String();
        final utcEnd = localEnd.toUtc().toIso8601String();
        final localStartIso = localStart.toIso8601String();
        final localEndIso = localEnd.toIso8601String();

        whereClauses.add('('
            '(${TaskModel.colDueDate} >= ? AND ${TaskModel.colDueDate} <= ?) OR '
            '(${TaskModel.colDueDate} >= ? AND ${TaskModel.colDueDate} <= ?) OR '
            '(${TaskModel.colDueDate} IS NULL AND ${TaskModel.colCreatedAt} >= ? AND ${TaskModel.colCreatedAt} <= ?)'
            ')');
        whereArgs.addAll([
          utcStart,
          utcEnd,
          localStartIso,
          localEndIso,
          utcStart,
          utcEnd,
        ]);
      }

      final taskRows = await _database.query(
        TaskModel.tableName,
        where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: '${TaskModel.colPriorityWeight} DESC, '
            'CASE WHEN ${TaskModel.colDueDate} IS NULL THEN 1 ELSE 0 END ASC, '
            '${TaskModel.colDueDate} ASC, '
            '${TaskModel.colCreatedAt} DESC',
      );

      return _hydrateTaskModels(taskRows);
    } on AppException {
      rethrow;
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to query tasks from local SQLite database.',
        cause: error,
      );
    }
  }

  @override
  Future<List<TaskModel>> getPenalizedTasksForDate(DateTime date) async {
    try {
      final penalizedRows = await _database.query(
        TaskModel.tableName,
        where: '${TaskModel.colIsPenalized} = 1',
        orderBy: '${TaskModel.colPriorityWeight} DESC, '
            '${TaskModel.colCreatedAt} DESC',
      );
      final models = await _hydrateTaskModels(penalizedRows);
      return models
          .where((m) => m.toEntity().isScheduledForDate(date))
          .toList(growable: false);
    } on AppException {
      rethrow;
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to query penalized tasks for date from SQLite.',
        cause: error,
      );
    }
  }

  Future<List<TaskModel>> _hydrateTaskModels(
    List<Map<String, Object?>> taskRows,
  ) async {
    if (taskRows.isEmpty) {
      return const <TaskModel>[];
    }

    final taskIds = taskRows
        .map((row) => row[TaskModel.colId] as String)
        .toList(growable: false);

    final placeholders = List<String>.filled(taskIds.length, '?').join(', ');

    final childResults = await Future.wait<List<Map<String, Object?>>>([
      _database.query(
        SubTaskModel.tableName,
        where: '${SubTaskModel.colTaskId} IN ($placeholders)',
        whereArgs: taskIds,
        orderBy: '${SubTaskModel.colPosition} ASC',
      ),
      _database.query(
        ExpenseItemModel.tableName,
        where: '${ExpenseItemModel.colTaskId} IN ($placeholders)',
        whereArgs: taskIds,
        orderBy: '${ExpenseItemModel.colPosition} ASC',
      ),
    ]);

    final subTaskRows = childResults[0];
    final expenseRows = childResults[1];

    final subTasksByTaskId = <String, List<SubTaskModel>>{};
    for (final row in subTaskRows) {
      final subTask = SubTaskModel.fromMap(row);
      (subTasksByTaskId[subTask.taskId] ??= <SubTaskModel>[]).add(subTask);
    }

    final expensesByTaskId = <String, List<ExpenseItemModel>>{};
    for (final row in expenseRows) {
      final expense = ExpenseItemModel.fromMap(row);
      (expensesByTaskId[expense.taskId] ??= <ExpenseItemModel>[]).add(expense);
    }

    return taskRows.map((row) {
      final taskId = row[TaskModel.colId] as String;
      return TaskModel.fromMap(
        row,
        subTasks: subTasksByTaskId[taskId] ?? const <SubTaskModel>[],
        expenses: expensesByTaskId[taskId] ?? const <ExpenseItemModel>[],
      );
    }).toList(growable: false);
  }

  @override
  Future<TaskModel> getTaskById(String taskId) async {
    try {
      final results = await Future.wait<List<Map<String, Object?>>>([
        _database.query(
          TaskModel.tableName,
          where: '${TaskModel.colId} = ?',
          whereArgs: <Object?>[taskId],
          limit: 1,
        ),
        _database.query(
          SubTaskModel.tableName,
          where: '${SubTaskModel.colTaskId} = ?',
          whereArgs: <Object?>[taskId],
          orderBy: '${SubTaskModel.colPosition} ASC',
        ),
        _database.query(
          ExpenseItemModel.tableName,
          where: '${ExpenseItemModel.colTaskId} = ?',
          whereArgs: <Object?>[taskId],
          orderBy: '${ExpenseItemModel.colPosition} ASC',
        ),
      ]);

      final taskRows = results[0];
      if (taskRows.isEmpty) {
        throw RecordNotFoundException(
          recordId: taskId,
          message: 'Task with ID "$taskId" was not found in local storage.',
        );
      }

      final subTaskRows = results[1];
      final expenseRows = results[2];

      final subTasks =
          subTaskRows.map(SubTaskModel.fromMap).toList(growable: false);
      final expenses =
          expenseRows.map(ExpenseItemModel.fromMap).toList(growable: false);

      return TaskModel.fromMap(
        taskRows.first,
        subTasks: subTasks,
        expenses: expenses,
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw LocalDatabaseException(
        message:
            'Failed to retrieve task "$taskId" from local SQLite database.',
        cause: error,
      );
    }
  }

  @override
  Future<TaskModel> saveTask(TaskModel task) async {
    try {
      final existingRows = await _database.query(
        TaskModel.tableName,
        columns: const <String>[TaskModel.colId],
        where: '${TaskModel.colId} = ?',
        whereArgs: <Object?>[task.id],
        limit: 1,
      );

      final batch = _database.batch();

      if (existingRows.isEmpty) {
        batch.insert(
          TaskModel.tableName,
          task.toTaskTableMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      } else {
        batch.update(
          TaskModel.tableName,
          task.toTaskTableMap(),
          where: '${TaskModel.colId} = ?',
          whereArgs: <Object?>[task.id],
        );
      }

      // 1. Synchronize child sub-tasks atomically inside the same batch transaction.
      batch.delete(
        SubTaskModel.tableName,
        where: '${SubTaskModel.colTaskId} = ?',
        whereArgs: <Object?>[task.id],
      );

      for (var i = 0; i < task.subTasks.length; i++) {
        final subTask = task.subTasks[i];
        final normalizedSubTask = SubTaskModel(
          id: subTask.id,
          taskId: task.id,
          title: subTask.title,
          isCompleted: subTask.isCompleted,
          position: i,
        );
        batch.insert(
          SubTaskModel.tableName,
          normalizedSubTask.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      // 2. Synchronize child expenses atomically inside the same batch transaction.
      batch.delete(
        ExpenseItemModel.tableName,
        where: '${ExpenseItemModel.colTaskId} = ?',
        whereArgs: <Object?>[task.id],
      );

      for (var i = 0; i < task.expenses.length; i++) {
        final expense = task.expenses[i];
        final normalizedExpense = ExpenseItemModel(
          id: expense.id,
          taskId: task.id,
          title: expense.title,
          amountMinorUnits: expense.amountMinorUnits,
          currency: expense.currency,
          incurredAt: expense.incurredAt,
          position: i,
        );
        batch.insert(
          ExpenseItemModel.tableName,
          normalizedExpense.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }

      await batch.commit(noResult: true);

      return task;
    } on AppException {
      rethrow;
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to atomically persist task "${task.id}".',
        cause: error,
      );
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      final deletedRows = await _database.delete(
        TaskModel.tableName,
        where: '${TaskModel.colId} = ?',
        whereArgs: <Object?>[taskId],
      );

      if (deletedRows == 0) {
        throw RecordNotFoundException(
          recordId: taskId,
          message: 'Cannot delete: Task with ID "$taskId" does not exist.',
        );
      }
    } on AppException {
      rethrow;
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to delete task "$taskId" from local SQLite database.',
        cause: error,
      );
    }
  }

  @override
  Future<void> batchPenalizeTasks(
    List<String> taskIds,
    DateTime updatedAt,
  ) async {
    if (taskIds.isEmpty) return;
    try {
      await _database.transaction((txn) async {
        final batch = txn.batch();
        final isoDate = updatedAt.toIso8601String();
        for (final id in taskIds) {
          batch.update(
            TaskModel.tableName,
            {
              TaskModel.colIsPenalized: 1,
              TaskModel.colUpdatedAt: isoDate,
            },
            where: '${TaskModel.colId} = ?',
            whereArgs: [id],
          );
        }
        await batch.commit(noResult: true);
      });
    } on AppException {
      rethrow;
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to atomically batch penalize tasks in SQLite.',
        cause: error,
      );
    }
  }

  @override
  Future<void> batchRevertPenalizedTasks(
    List<String> taskIds,
    DateTime updatedAt,
  ) async {
    if (taskIds.isEmpty) return;
    try {
      await _database.transaction((txn) async {
        final batch = txn.batch();
        final isoDate = updatedAt.toIso8601String();
        for (final id in taskIds) {
          batch.update(
            TaskModel.tableName,
            {
              TaskModel.colIsPenalized: 0,
              TaskModel.colUpdatedAt: isoDate,
            },
            where: '${TaskModel.colId} = ?',
            whereArgs: [id],
          );
        }
        await batch.commit(noResult: true);
      });
    } on AppException {
      rethrow;
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to atomically batch revert penalized tasks in SQLite.',
        cause: error,
      );
    }
  }

  @override
  Future<void> batchUpdateSortOrders(
    Map<String, int> sortOrders,
    DateTime updatedAt,
  ) async {
    if (sortOrders.isEmpty) return;
    try {
      await _database.transaction((txn) async {
        final batch = txn.batch();
        final isoDate = updatedAt.toIso8601String();
        for (final entry in sortOrders.entries) {
          batch.update(
            TaskModel.tableName,
            {
              TaskModel.colSortOrder: entry.value,
              TaskModel.colUpdatedAt: isoDate,
            },
            where: '${TaskModel.colId} = ?',
            whereArgs: [entry.key],
          );
        }
        await batch.commit(noResult: true);
      });
    } on AppException {
      rethrow;
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to batch update sort_order in SQLite.',
        cause: error,
      );
    }
  }
}
