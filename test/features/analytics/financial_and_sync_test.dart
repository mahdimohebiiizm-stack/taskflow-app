import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/performance/smart_render_engine.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/sync/background_sync_service.dart';
import 'package:task_flow/core/sync/pending_sync_event.dart';
import 'package:task_flow/features/analytics/domain/entities/rial_financial_summary_entity.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_bloc.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_event.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_state.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/expense_item_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_state.dart';

void main() {
  final baseTime = DateTime.utc(2026, 10, 12, 9, 0);

  group('CQRS & Rial Financial Analytics Layer', () {
    test('converts Toman expenses exclusively to Rials (1 Toman = 10 Rials) and formats with ریال', () async {
      final exp1 = (ExpenseItemEntity.create(
        id: 'exp-1',
        title: 'قبض برق',
        money: (Money.create(
          amountMinorUnits: 250000,
          currency: Currency.irt,
        ) as Success<Money, DomainFailure>)
            .value,
        incurredAt: baseTime,
      ) as Success<ExpenseItemEntity, DomainFailure>)
          .value;

      final exp2 = (ExpenseItemEntity.create(
        id: 'exp-2',
        title: 'صندوق درآمد ثابت',
        money: (Money.create(
          amountMinorUnits: 500000,
          currency: Currency.irt,
        ) as Success<Money, DomainFailure>)
            .value,
        incurredAt: baseTime,
      ) as Success<ExpenseItemEntity, DomainFailure>)
          .value;

      final task1 = (TaskEntity.create(
        id: 'fin-1',
        title: 'پرداخت قبض برق و اینترنت',
        status: TaskStatus.done,
        expenses: <ExpenseItemEntity>[exp1],
        createdAt: baseTime,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      final task2 = (TaskEntity.create(
        id: 'fin-2',
        title: 'پس‌انداز ماهانه',
        status: TaskStatus.todo,
        expenses: <ExpenseItemEntity>[exp2],
        createdAt: baseTime,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      final bloc = FinancialAnalyticsBloc();
      bloc.add(
        FinancialAnalyticsTasksProjected(
          tasks: <TaskEntity>[task1, task2],
          customBudgetRials: 10000000,
        ),
      );

      await expectLater(
        bloc.stream,
        emits(
          isA<FinancialAnalyticsState>()
              .having((s) => s.status, 'status', FinancialAnalyticsStatus.success)
              .having((s) => s.summary.totalSpentRials, 'totalSpentRials', 7500000)
              .having((s) => s.summary.completedTasksSpentRials, 'completedTasksSpentRials', 2500000)
              .having((s) => s.summary.pendingTasksSpentRials, 'pendingTasksSpentRials', 5000000)
              .having((s) => s.summary.remainingBudgetRials, 'remainingBudgetRials', 2500000)
              .having((s) => s.summary.financialTasksCount, 'financialTasksCount', 2),
        ),
      );

      expect(
        RialFinancialSummaryEntity.formatRials(7500000),
        equals('۷,۵۰۰,۰۰۰ ریال'),
      );
      await bloc.close();
    });
  });

  group('Offline-First Event Sourcing & BackgroundSyncService', () {
    test('queues PendingSyncEvent while offline and flushes silently when online', () async {
      final syncService = BackgroundSyncService(
        initialOnlineState: false,
      );

      syncService.enqueue(
        entityId: 'task-101',
        eventType: SyncEventTypes.taskCreated,
        payload: const <String, dynamic>{'title': 'تسک آفلاین ۱'},
        autoFlush: false,
      );
      syncService.enqueue(
        entityId: 'task-101',
        eventType: SyncEventTypes.taskStatusTransitioned,
        payload: const <String, dynamic>{'nextStatus': 'done'},
        autoFlush: false,
      );

      expect(syncService.pendingEvents.length, 2);
      expect(syncService.syncedEvents.length, 0);

      syncService.setOnlineStatus(true, autoFlush: false);
      final flushedCount = await syncService.flushPendingEvents();
      expect(flushedCount, 2);
      expect(syncService.pendingEvents, isEmpty);
      expect(syncService.syncedEvents.length, 2);
      expect(syncService.syncedEvents.first.isSynced, isTrue);

      await syncService.dispose();
    });
  });

  group('SmartRenderEngine 60 FPS Adaptive Guard', () {
    tearDown(() {
      SmartRenderEngine.forceLowEndDeviceMode = false;
    });

    test('degrades heavy visual effects on long lists or when low-end device mode is active', () {
      SmartRenderEngine.forceLowEndDeviceMode = false;

      expect(SmartRenderEngine.shouldDegrade(itemCount: 5), isFalse);
      expect(SmartRenderEngine.shouldDegrade(itemCount: 15), isTrue);
      expect(SmartRenderEngine.shouldDegrade(itemCount: 25), isTrue);

      SmartRenderEngine.forceLowEndDeviceMode = true;
      expect(SmartRenderEngine.shouldDegrade(itemCount: 2), isTrue);
      expect(
        SmartRenderEngine.scaleDuration(const Duration(milliseconds: 400), itemCount: 2),
        equals(Duration.zero),
      );
    });
  });

  group('Core Task Engine: Nested Tree, Workspaces, Tags & Drag-Drop SortOrder', () {
    test('supports infinite nested parentTaskId tree, workspaceId/tag filters, and manual sortOrder', () {
      final now = DateTime.now();
      final rootWork = (TaskEntity.create(
        id: 'root-work',
        title: 'طراحی معماری کلاینت',
        workspaceId: TaskWorkspaces.work,
        tags: const <String>['فوری', 'معماری'],
        sortOrder: 2,
        dueDate: now,
        createdAt: baseTime,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      final rootPersonal = (TaskEntity.create(
        id: 'root-personal',
        title: 'مطالعه کتاب عادت‌های اتمی',
        workspaceId: TaskWorkspaces.personal,
        tags: const <String>['مطالعه'],
        sortOrder: 1,
        dueDate: now,
        createdAt: baseTime,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      final nestedChild = (TaskEntity.create(
        id: 'child-1',
        title: 'بازبینی لایه دیتابیس',
        parentTaskId: 'root-work',
        workspaceId: TaskWorkspaces.work,
        tags: const <String>['فوری'],
        sortOrder: 1,
        dueDate: now,
        createdAt: baseTime,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      final stateAll = TaskState(
        status: TaskViewStatus.success,
        tasks: <TaskEntity>[rootWork, rootPersonal, nestedChild],
      );

      // Root todayTasks excludes nestedChild and orders by manual sortOrder (1 before 2)
      expect(stateAll.todayTasks.map((t) => t.id).toList(), equals(['root-personal', 'root-work']));
      expect(stateAll.childTasksOf('root-work').map((t) => t.id).toList(), equals(['child-1']));
      expect(stateAll.availableTags, containsAll(<String>['فوری', 'معماری', 'مطالعه']));

      // Filter by workspace
      final stateWorkOnly = stateAll.copyWith(selectedWorkspaceId: () => TaskWorkspaces.work);
      expect(stateWorkOnly.todayTasks.map((t) => t.id).toList(), equals(['root-work']));

      // Filter by tag
      final stateTagStudy = stateAll.copyWith(selectedTag: () => 'مطالعه');
      expect(stateTagStudy.todayTasks.map((t) => t.id).toList(), equals(['root-personal']));
    });
  });
}
