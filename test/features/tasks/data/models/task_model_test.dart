import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/data/models/exchange_rate_model.dart';
import 'package:task_flow/features/tasks/data/models/expense_item_model.dart';
import 'package:task_flow/features/tasks/data/models/sub_task_model.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/exchange_rate_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/expense_item_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/entities/sub_task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 10, 9, 30);
  final updatedAt = DateTime.utc(2026, 10, 10, 11, 45);
  final dueDate = DateTime.utc(2026, 10, 20);

  SubTaskEntity createValidSubTask({
    required String id,
    required String title,
    required bool isCompleted,
  }) {
    return (SubTaskEntity.create(
      id: id,
      title: title,
      isCompleted: isCompleted,
    ) as Success<SubTaskEntity, DomainFailure>)
        .value;
  }

  ExpenseItemEntity createValidExpense({
    required String id,
    required String title,
    required int amountMinorUnits,
    required Currency currency,
  }) {
    final money = (Money.create(
      amountMinorUnits: amountMinorUnits,
      currency: currency,
    ) as Success<Money, DomainFailure>)
        .value;

    return (ExpenseItemEntity.create(
      id: id,
      title: title,
      money: money,
      incurredAt: createdAt,
    ) as Success<ExpenseItemEntity, DomainFailure>)
        .value;
  }

  group('SubTaskModel Deterministic Mapping & Validation', () {
    test(
        'should deterministically round-trip from SubTaskEntity -> SubTaskModel -> Map -> SubTaskModel -> SubTaskEntity',
        () {
      final entity = createValidSubTask(
        id: 'sub-1',
        title: 'Configure SQLite Foreign Keys',
        isCompleted: true,
      );

      final model = SubTaskModel.fromEntity(
        entity,
        taskId: 'task-100',
        position: 2,
      );
      final map = model.toMap();
      final reconstructedModel = SubTaskModel.fromMap(map);
      final reconstructedEntity = reconstructedModel.toEntity();

      expect(reconstructedModel, equals(model));
      expect(reconstructedModel.position, equals(2));
      expect(reconstructedModel.taskId, equals('task-100'));
      expect(reconstructedEntity, equals(entity));
    });

    test(
        'should throw LocalDatabaseException when SQLite map has corrupted or empty fields',
        () {
      expect(
        () => SubTaskModel.fromMap(const <String, Object?>{
          SubTaskModel.colId: '',
          SubTaskModel.colTaskId: 'task-1',
          SubTaskModel.colTitle: 'Valid title',
          SubTaskModel.colIsCompleted: 0,
        }),
        throwsA(isA<LocalDatabaseException>()),
      );

      expect(
        () => SubTaskModel.fromMap(const <String, Object?>{
          SubTaskModel.colId: 'sub-1',
          SubTaskModel.colTaskId: 'task-1',
          SubTaskModel.colTitle: 'Valid title',
          SubTaskModel.colIsCompleted: 'invalid_bool_type',
        }),
        throwsA(isA<LocalDatabaseException>()),
      );
    });
  });

  group('TaskModel, ExpenseItemModel & ExchangeRateModel Deterministic Mapping',
      () {
    test(
        'should deterministically map TaskEntity <-> TaskModel and preserve exact SubTask and Expense position order',
        () {
      final subTasks = <SubTaskEntity>[
        createValidSubTask(id: 'sub-1', title: 'Step 1', isCompleted: true),
        createValidSubTask(id: 'sub-2', title: 'Step 2', isCompleted: false),
        createValidSubTask(id: 'sub-3', title: 'Step 3', isCompleted: false),
      ];

      final expenses = <ExpenseItemEntity>[
        createValidExpense(
          id: 'exp-1',
          title: 'First Expense',
          amountMinorUnits: 150000,
          currency: Currency.irt,
        ),
        createValidExpense(
          id: 'exp-2',
          title: 'Second Expense',
          amountMinorUnits: 850000,
          currency: Currency.irt,
        ),
      ];

      final entity = (TaskEntity.create(
        id: 'task-42',
        title: 'Complete Data Layer',
        description: 'Ensure 100% deterministic mapping',
        status: TaskStatus.inProgress,
        priority: TaskPriority.critical,
        dueDate: dueDate,
        subTasks: subTasks,
        expenses: expenses,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      final model = TaskModel.fromEntity(entity);
      expect(model.priorityWeight, equals(TaskPriority.critical.weight));

      final tableMap = model.toTaskTableMap();

      // Simulate SQLite returning sub-task and expense rows in scrambled order
      final scrambledSubTasks = <SubTaskModel>[
        model.subTasks[2],
        model.subTasks[0],
        model.subTasks[1],
      ];
      final scrambledExpenses = <ExpenseItemModel>[
        model.expenses[1],
        model.expenses[0],
      ];

      final reconstructedModel = TaskModel.fromMap(
        tableMap,
        subTasks: scrambledSubTasks,
        expenses: scrambledExpenses,
      );
      final reconstructedEntity = reconstructedModel.toEntity();

      expect(reconstructedModel, equals(model));
      expect(reconstructedEntity, equals(entity));
      expect(
        reconstructedEntity.subTasks.map((s) => s.id).toList(),
        equals(<String>['sub-1', 'sub-2', 'sub-3']),
      );
      expect(
        reconstructedEntity.expenses.map((e) => e.id).toList(),
        equals(<String>['exp-1', 'exp-2']),
      );
    });

    test(
        'should deterministically round-trip ExchangeRateEntity <-> ExchangeRateModel <-> Map',
        () {
      final rateEntity = ExchangeRateEntity.reconstitute(
        sourceCurrency: Currency.irt,
        targetCurrency: Currency.irt,
        rateNumerator: 1,
        rateDenominator: 1,
        updatedAt: updatedAt,
      );

      final model = ExchangeRateModel.fromEntity(rateEntity);
      final map = model.toMap();
      final fromMap = ExchangeRateModel.fromMap(map);

      expect(fromMap, equals(model));
      expect(fromMap.toEntity(), equals(rateEntity));
    });

    test(
        'should throw LocalDatabaseException when TaskModel.fromMap receives unknown status or missing timestamps',
        () {
      expect(
        () => TaskModel.fromMap(const <String, Object?>{
          TaskModel.colId: 'task-1',
          TaskModel.colTitle: 'Title',
          TaskModel.colStatus: 'unknown_status_value',
          TaskModel.colPriority: 'high',
          TaskModel.colCreatedAt: '2026-10-10T00:00:00.000Z',
          TaskModel.colUpdatedAt: '2026-10-10T00:00:00.000Z',
        }),
        throwsA(isA<LocalDatabaseException>()),
      );
    });
  });
}
