import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/services/widget_sync_service.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

class MockHomeWidgetDriver extends Mock implements HomeWidgetDriver {}

void main() {
  late MockHomeWidgetDriver mockDriver;
  late WidgetSyncService syncService;

  setUp(() {
    mockDriver = MockHomeWidgetDriver();
    syncService = WidgetSyncService(driver: mockDriver);

    when(
      () => mockDriver.saveWidgetData<dynamic>(
        any<String>(),
        any<dynamic>(),
        appGroupId: any<String?>(named: 'appGroupId'),
      ),
    ).thenAnswer((_) async => true);

    when(
      () => mockDriver.saveWidgetData<int>(
        any<String>(),
        any<int>(),
        appGroupId: any<String?>(named: 'appGroupId'),
      ),
    ).thenAnswer((_) async => true);

    when(
      () => mockDriver.saveWidgetData<String>(
        any<String>(),
        any<String>(),
        appGroupId: any<String?>(named: 'appGroupId'),
      ),
    ).thenAnswer((_) async => true);

    when(
      () => mockDriver.updateWidget(
        name: any(named: 'name'),
        androidName: any(named: 'androidName'),
        iOSName: any(named: 'iOSName'),
        qualifiedAndroidName: any(named: 'qualifiedAndroidName'),
      ),
    ).thenAnswer((_) async => true);
  });

  TaskEntity createSampleTask({
    required String id,
    required String title,
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.todo,
    DateTime? dueDate,
  }) {
    final res = TaskEntity.create(
      id: id,
      title: title,
      priority: priority,
      dueDate: dueDate,
      createdAt: DateTime(2026, 1, 1),
    );
    final task = (res as Success<TaskEntity, dynamic>).value;
    if (status != TaskStatus.todo) {
      final transitionRes = task.transitionStatus(
        status,
        updatedAt: DateTime(2026, 1, 1),
      );
      return (transitionRes as Success<TaskEntity, dynamic>).value;
    }
    return task;
  }

  group('WidgetSyncService', () {
    test('initial state has default zero values and empty task list', () {
      expect(syncService.streakCount, 0);
      expect(syncService.dailyBudgetRials, 0);
      expect(syncService.cachedTasks, isEmpty);
    });

    test('syncSnapshot serializes streak, budget and top 3 pending tasks to native container', () async {
      final tasks = [
        createSampleTask(id: 't1', title: 'Task Low', priority: TaskPriority.low),
        createSampleTask(id: 't2', title: 'Task Critical', priority: TaskPriority.critical),
        createSampleTask(id: 't3', title: 'Task High', priority: TaskPriority.high),
        createSampleTask(id: 't4', title: 'Task Medium', priority: TaskPriority.medium),
        createSampleTask(id: 't5', title: 'Task Done', priority: TaskPriority.critical, status: TaskStatus.done),
      ];

      final result = await syncService.syncSnapshot(
        streakCount: 7,
        dailyBudgetRials: 150000,
        tasks: tasks,
      );

      expect(result, isTrue);
      expect(syncService.streakCount, 7);
      expect(syncService.dailyBudgetRials, 150000);
      expect(syncService.cachedTasks.length, 5);

      // Verify streak and budget saved
      verify(() => mockDriver.saveWidgetData<int>(
        WidgetPayloadKeys.streakCount,
        7,
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);

      verify(() => mockDriver.saveWidgetData<int>(
        WidgetPayloadKeys.dailyBudgetRials,
        150000,
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);

      verify(() => mockDriver.saveWidgetData<String>(
        WidgetPayloadKeys.dailyBudgetFormatted,
        '150000 ریال',
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);

      // Verify pending count (4 active pending tasks, excluding the done one)
      verify(() => mockDriver.saveWidgetData<int>(
        WidgetPayloadKeys.pendingTasksCount,
        4,
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);

      // Verify top 3 prioritizes: Critical (Task Critical), High (Task High), Medium (Task Medium)
      verify(() => mockDriver.saveWidgetData<String>(
        WidgetPayloadKeys.task1Title,
        'Task Critical',
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);
      verify(() => mockDriver.saveWidgetData<String>(
        WidgetPayloadKeys.task1Priority,
        TaskPriority.critical.name,
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);

      verify(() => mockDriver.saveWidgetData<String>(
        WidgetPayloadKeys.task2Title,
        'Task High',
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);
      verify(() => mockDriver.saveWidgetData<String>(
        WidgetPayloadKeys.task2Priority,
        TaskPriority.high.name,
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);

      verify(() => mockDriver.saveWidgetData<String>(
        WidgetPayloadKeys.task3Title,
        'Task Medium',
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);
      verify(() => mockDriver.saveWidgetData<String>(
        WidgetPayloadKeys.task3Priority,
        TaskPriority.medium.name,
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);

      // Verify JSON representation
      final capturedJson = verify(() => mockDriver.saveWidgetData<String>(
        WidgetPayloadKeys.pendingTasksJson,
        captureAny(),
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).captured.single as String;

      final decoded = jsonDecode(capturedJson) as List<dynamic>;
      expect(decoded.length, 3);
      expect(decoded[0]['title'], 'Task Critical');
      expect(decoded[1]['title'], 'Task High');
      expect(decoded[2]['title'], 'Task Medium');

      // Verify updateWidget was called with correct identifiers
      verify(() => mockDriver.updateWidget(
        name: WidgetPayloadKeys.iOSWidgetKind,
        androidName: WidgetPayloadKeys.androidWidgetProvider,
        iOSName: WidgetPayloadKeys.iOSWidgetKind,
      )).called(1);
    });

    test('updateStreak updates only streak and pushes updated snapshot', () async {
      await syncService.syncSnapshot(
        streakCount: 3,
        dailyBudgetRials: 50000,
        tasks: [],
      );

      final result = await syncService.updateStreak(10);
      expect(result, isTrue);
      expect(syncService.streakCount, 10);
      expect(syncService.dailyBudgetRials, 50000);

      verify(() => mockDriver.saveWidgetData<int>(
        WidgetPayloadKeys.streakCount,
        10,
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);
    });

    test('updateBudget updates only budget and pushes updated snapshot', () async {
      await syncService.syncSnapshot(
        streakCount: 5,
        dailyBudgetRials: 100000,
        tasks: [],
      );

      final result = await syncService.updateBudget(200000);
      expect(result, isTrue);
      expect(syncService.streakCount, 5);
      expect(syncService.dailyBudgetRials, 200000);

      verify(() => mockDriver.saveWidgetData<int>(
        WidgetPayloadKeys.dailyBudgetRials,
        200000,
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);
    });

    test('fewer than 3 tasks fills remaining task fields with empty strings', () async {
      final tasks = [
        createSampleTask(id: 't1', title: 'Single Task', priority: TaskPriority.high),
      ];

      await syncService.syncSnapshot(
        streakCount: 1,
        dailyBudgetRials: 50000,
        tasks: tasks,
      );

      verify(() => mockDriver.saveWidgetData<String>(
        WidgetPayloadKeys.task1Title,
        'Single Task',
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);
      verify(() => mockDriver.saveWidgetData<String>(
        WidgetPayloadKeys.task2Title,
        '',
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);
      verify(() => mockDriver.saveWidgetData<String>(
        WidgetPayloadKeys.task3Title,
        '',
        appGroupId: WidgetPayloadKeys.appGroupId,
      )).called(1);
    });

    test('gracefully degrades and does not throw when driver throws an exception', () async {
      when(
        () => mockDriver.saveWidgetData<int>(
          any<String>(),
          any<int>(),
          appGroupId: any<String?>(named: 'appGroupId'),
        ),
      ).thenThrow(Exception('Native bridge disconnected'));

      final result = await syncService.syncSnapshot(
        streakCount: 5,
        dailyBudgetRials: 50000,
        tasks: [],
      );

      expect(result, isFalse);
    });
  });
}
