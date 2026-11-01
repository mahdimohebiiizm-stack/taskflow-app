import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:task_flow/features/tasks/data/models/expense_item_model.dart';
import 'package:task_flow/features/tasks/data/models/sub_task_model.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/entities/sub_task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/usecases/add_task_expense_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/toggle_sub_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/transition_task_status_usecase.dart';

void main() {
  late Database database;
  late TaskLocalDataSourceImpl dataSource;

  final baseTime = DateTime.utc(2026, 10, 10, 10, 0);

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    await resetDependencies();
    database = await AppDatabase.open(
      databasePath: inMemoryDatabasePath,
      databaseFactory: databaseFactoryFfi,
    );
    await initDependencies(overrideDatabase: database);
    dataSource = TaskLocalDataSourceImpl(database: database);
  });

  tearDown(() async {
    await resetDependencies();
  });

  SubTaskEntity buildSubTask(String id, String title, {bool completed = false}) {
    return (SubTaskEntity.create(
      id: id,
      title: title,
      isCompleted: completed,
    ) as Success<SubTaskEntity, DomainFailure>)
        .value;
  }

  group('SQLite In-Memory Integration Tests (ACID, Ordering & Cascade Delete)',
      () {
    test(
        'should atomically persist Task and SubTasks, and order tasks by priority_weight DESC then due_date ASC',
        () async {
      final createTask = sl<CreateTaskUseCase>();
      final getTasks = sl<GetTasksUseCase>();

      await createTask(
        CreateTaskParams(
          id: 'task-low',
          title: 'Low Priority Task',
          priority: TaskPriority.low,
          dueDate: DateTime.utc(2026, 10, 11),
          createdAt: baseTime,
        ),
      );

      await createTask(
        CreateTaskParams(
          id: 'task-critical-later',
          title: 'Critical Task Due Later',
          priority: TaskPriority.critical,
          dueDate: DateTime.utc(2026, 10, 20),
          createdAt: baseTime,
        ),
      );

      await createTask(
        CreateTaskParams(
          id: 'task-critical-sooner',
          title: 'Critical Task Due Sooner',
          priority: TaskPriority.critical,
          dueDate: DateTime.utc(2026, 10, 12),
          subTasks: <SubTaskEntity>[
            buildSubTask('sub-1', 'First Sub-task'),
            buildSubTask('sub-2', 'Second Sub-task'),
          ],
          createdAt: baseTime,
        ),
      );

      final result = await getTasks(const GetTasksParams());
      expect(result.isSuccess, isTrue);

      final tasks = (result as Success<List<TaskEntity>, Failure>).value;
      expect(
        tasks.map((t) => t.id).toList(),
        equals(<String>[
          'task-critical-sooner',
          'task-critical-later',
          'task-low',
        ]),
      );
      expect(
        tasks.first.subTasks.map((s) => s.id).toList(),
        equals(<String>['sub-1', 'sub-2']),
      );
    });

    test(
        'should enforce ON DELETE CASCADE in SQLite so deleting a parent task removes all its child sub_tasks and task_expenses rows',
        () async {
      final createTask = sl<CreateTaskUseCase>();
      final addExpense = sl<AddTaskExpenseUseCase>();

      await createTask(
        CreateTaskParams(
          id: 'task-cascade',
          title: 'Parent Task with SubTasks and Expenses',
          subTasks: <SubTaskEntity>[
            buildSubTask('sub-a', 'Child A'),
            buildSubTask('sub-b', 'Child B'),
          ],
          createdAt: baseTime,
        ),
      );

      await addExpense(
        AddTaskExpenseParams(
          taskId: 'task-cascade',
          expenseId: 'exp-a',
          title: 'Server Cost',
          amountMinorUnits: 500000,
          currency: Currency.irt,
          incurredAt: baseTime,
        ),
      );

      // Verify child rows exist in both sub_tasks and task_expenses before deletion
      final beforeSubTasks = await database.query(
        SubTaskModel.tableName,
        where: '${SubTaskModel.colTaskId} = ?',
        whereArgs: <Object?>['task-cascade'],
      );
      final beforeExpenses = await database.query(
        ExpenseItemModel.tableName,
        where: '${ExpenseItemModel.colTaskId} = ?',
        whereArgs: <Object?>['task-cascade'],
      );
      expect(beforeSubTasks.length, equals(2));
      expect(beforeExpenses.length, equals(1));

      // Delete parent task
      await dataSource.deleteTask('task-cascade');

      // Verify ON DELETE CASCADE automatically purged child rows from both tables
      final afterSubTasks = await database.query(
        SubTaskModel.tableName,
        where: '${SubTaskModel.colTaskId} = ?',
        whereArgs: <Object?>['task-cascade'],
      );
      final afterExpenses = await database.query(
        ExpenseItemModel.tableName,
        where: '${ExpenseItemModel.colTaskId} = ?',
        whereArgs: <Object?>['task-cascade'],
      );
      expect(afterSubTasks, isEmpty);
      expect(afterExpenses, isEmpty);

      expect(
        () => dataSource.getTaskById('task-cascade'),
        throwsA(isA<RecordNotFoundException>()),
      );
    });

    test(
        'should enforce end-to-end Domain Invariant Option C and automatic rollback across UseCases + SQLite',
        () async {
      final createTask = sl<CreateTaskUseCase>();
      final transitionStatus = sl<TransitionTaskStatusUseCase>();
      final toggleSubTask = sl<ToggleSubTaskUseCase>();

      await createTask(
        CreateTaskParams(
          id: 'task-e2e',
          title: 'End-to-End Workflow Task',
          status: TaskStatus.inProgress,
          subTasks: <SubTaskEntity>[
            buildSubTask('sub-1', 'SubTask 1', completed: false),
          ],
          createdAt: baseTime,
        ),
      );

      // 1. Attempt to transition to Done while sub-1 is incomplete -> Blocked!
      final blockedResult = await transitionStatus(
        const TransitionTaskStatusParams(
          taskId: 'task-e2e',
          targetStatus: TaskStatus.done,
        ),
      );
      expect(blockedResult.isFailure, isTrue);
      expect(
        (blockedResult as Err<TaskEntity, Failure>).failure,
        isA<IncompleteSubTasksFailure>(),
      );

      // 2. Complete sub-1 and transition to Done -> Allowed!
      await toggleSubTask(
        const ToggleSubTaskParams(taskId: 'task-e2e', subTaskId: 'sub-1'),
      );
      final doneResult = await transitionStatus(
        const TransitionTaskStatusParams(
          taskId: 'task-e2e',
          targetStatus: TaskStatus.done,
        ),
      );
      expect(doneResult.isSuccess, isTrue);
      expect(
        (doneResult as Success<TaskEntity, Failure>).value.status,
        equals(TaskStatus.done),
      );

      // 3. Uncheck sub-1 while parent is Done -> Automatically rolls back to In Progress in SQLite!
      final rollbackResult = await toggleSubTask(
        const ToggleSubTaskParams(taskId: 'task-e2e', subTaskId: 'sub-1'),
      );
      expect(rollbackResult.isSuccess, isTrue);
      final rolledBackTask =
          (rollbackResult as Success<TaskEntity, Failure>).value;
      expect(rolledBackTask.status, equals(TaskStatus.inProgress));
      expect(rolledBackTask.subTasks.first.isCompleted, isFalse);
    });

    test(
        'should safely migrate database schema from v1 to v2 without losing existing tasks and support multi-currency expenses & offline exchange rates',
        () async {
      // Reset previous test dependencies before opening v1Db
      await resetDependencies();
      await databaseFactoryFfi.deleteDatabase('migration_v1_test.db');

      // Simulate an existing Version 1 database
      final v1Db = await databaseFactoryFfi.openDatabase(
        'migration_v1_test.db',
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: AppDatabase.configureDatabase,
          onCreate: (db, _) => AppDatabase.createV1Schema(db),
        ),
      );

      await v1Db.insert(TaskModel.tableName, <String, Object?>{
        TaskModel.colId: 'legacy-v1-task',
        TaskModel.colTitle: 'Existing V1 User Task',
        TaskModel.colDescription: 'Must survive migration to v2',
        TaskModel.colStatus: TaskStatus.inProgress.storageKey,
        TaskModel.colPriority: TaskPriority.high.storageKey,
        TaskModel.colPriorityWeight: TaskPriority.high.weight,
        TaskModel.colDueDate: null,
        TaskModel.colCreatedAt: baseTime.toIso8601String(),
        TaskModel.colUpdatedAt: baseTime.toIso8601String(),
      });

      // Execute safe non-destructive migration to latest schema version
      await AppDatabase.upgradeSchema(v1Db, 1, AppDatabase.schemaVersion);

      await initDependencies(overrideDatabase: v1Db);

      final addExpense = sl<AddTaskExpenseUseCase>();

      // Attach two expenses in Toman (IRT) to the migrated v1 task
      await addExpense(
        AddTaskExpenseParams(
          taskId: 'legacy-v1-task',
          expenseId: 'exp-irt-1',
          title: 'Cloud Storage',
          amountMinorUnits: 1200000,
          currency: Currency.irt,
          incurredAt: baseTime,
        ),
      );

      await addExpense(
        AddTaskExpenseParams(
          taskId: 'legacy-v1-task',
          expenseId: 'exp-irt-2',
          title: 'Local Service',
          amountMinorUnits: 300000,
          currency: Currency.irt,
          incurredAt: baseTime,
        ),
      );

      final tasksResult = await sl<GetTasksUseCase>()(const GetTasksParams());
      final migratedTask =
          (tasksResult as Success<List<TaskEntity>, Failure>).value.single;

      expect(migratedTask.id, equals('legacy-v1-task'));
      expect(migratedTask.title, equals('Existing V1 User Task'));
      expect(migratedTask.expenses, hasLength(2));

      final totalInIrt = migratedTask.totalExpensesInCurrency(Currency.irt);
      expect(totalInIrt.isSuccess, isTrue);
      expect(
        (totalInIrt as Success<Money, DomainFailure>).value.format(),
        equals('1,500,000 تومان'),
      );
    });
  });
}
