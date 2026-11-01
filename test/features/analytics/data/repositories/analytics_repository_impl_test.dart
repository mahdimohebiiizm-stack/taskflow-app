import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/analytics/data/datasources/analytics_local_datasource.dart';
import 'package:task_flow/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:task_flow/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:task_flow/features/tasks/data/models/expense_item_model.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

void main() {
  late Database database;
  late AnalyticsLocalDataSource dataSource;
  late AnalyticsRepositoryImpl repository;
  late TaskLocalDataSource taskDataSource;

  final now = DateTime.utc(2026, 10, 11, 12, 0);

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await AppDatabase.open(
      databasePath: inMemoryDatabasePath,
      databaseFactory: databaseFactoryFfi,
    );
    dataSource = AnalyticsLocalDataSourceImpl(database: database);
    repository = AnalyticsRepositoryImpl(localDataSource: dataSource);
    taskDataSource = TaskLocalDataSourceImpl(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  group('AnalyticsRepositoryImpl SQLite Aggregation Integration', () {
    test('computes exact task ratios and aggregates 7-day multi-currency expenses', () async {
      // 1. Seed completed task with USD expense ($10 USD = 600,000 IRT at baseline)
      final task1 = TaskModel(
        id: 'task-done-1',
        title: 'Backend API Deployment',
        description: 'Completed service setup',
        status: TaskStatus.done,
        priority: TaskPriority.high,
        createdAt: now,
        updatedAt: now,
        dueDate: now,
        subTasks: const [],
        expenses: [
          ExpenseItemModel(
            id: 'exp-1',
            taskId: 'task-done-1',
            title: 'Server Hosting',
            amountMinorUnits: 600000, // 600,000 IRT
            currency: Currency.irt,
            incurredAt: now,
            position: 0,
          ),
        ],
      );
      await taskDataSource.saveTask(task1);

      // 2. Seed in-progress task with IRT expense (400,000 IRT)
      final task2 = TaskModel(
        id: 'task-prog-2',
        title: 'Design UI Mockups',
        description: 'In progress design',
        status: TaskStatus.inProgress,
        priority: TaskPriority.medium,
        createdAt: now,
        updatedAt: now,
        dueDate: now,
        subTasks: const [],
        expenses: [
          ExpenseItemModel(
            id: 'exp-2',
            taskId: 'task-prog-2',
            title: 'Icon Pack License',
            amountMinorUnits: 400000, // 400,000 IRT
            currency: Currency.irt,
            incurredAt: now,
            position: 0,
          ),
        ],
      );
      await taskDataSource.saveTask(task2);

      // 3. Seed todo task without expenses
      final task3 = TaskModel(
        id: 'task-todo-3',
        title: 'Review Documentation',
        description: '',
        status: TaskStatus.todo,
        priority: TaskPriority.low,
        createdAt: now,
        updatedAt: now,
        dueDate: now,
        subTasks: const [],
        expenses: const [],
      );
      await taskDataSource.saveTask(task3);

      // 4. Query Analytics Summary in IRT
      final result = await repository.getAnalyticsSummary(
        targetCurrency: Currency.irt,
        referenceDate: now,
      );

      expect(result, isA<Success<AnalyticsSummaryEntity, dynamic>>());
      final summary = (result as Success<AnalyticsSummaryEntity, dynamic>).value;

      // Verify Task Ratios
      expect(summary.taskRatio.totalCount, equals(3));
      expect(summary.taskRatio.completedCount, equals(1));
      expect(summary.taskRatio.inProgressCount, equals(1));
      expect(summary.taskRatio.todoCount, equals(1));
      expect(summary.taskRatio.completionPercent, equals(33)); // 1/3 ~ 33%

      // Verify Weekly Expenses
      expect(summary.last7DaysExpenses, hasLength(7));
      // Converted amount: ($10 USD * 60,000) + 400,000 IRT = 1,000,000 IRT
      expect(summary.total7DaysExpense.amountMinorUnits, equals(1000000));
      expect(summary.total7DaysExpense.currency, equals(Currency.irt));
      expect(summary.monthlyExpense.amountMinorUnits, equals(1000000));
    });
  });
}
