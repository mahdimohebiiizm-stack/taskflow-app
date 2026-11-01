import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_bloc.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_event.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_state.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:task_flow/main.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/toggle_sub_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/transition_task_status_usecase.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_event.dart';

class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}
class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}
class MockTransitionTaskStatusUseCase extends Mock implements TransitionTaskStatusUseCase {}
class MockToggleSubTaskUseCase extends Mock implements ToggleSubTaskUseCase {}
class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
    registerFallbackValue(const TransitionTaskStatusParams(taskId: 't-1', targetStatus: TaskStatus.done));
    registerFallbackValue(const GetTasksParams());
  });

  group('Phase 9 & 10 Part 2 — Financial Bridge (Tasks == Budget)', () {
    test('FinancialAnalyticsBudgetAdjusted adds +50,000 Rials and deducts -10,000 Rials', () async {
      final bloc = FinancialAnalyticsBloc();

      // Default budget is 50,000,000 Rials
      expect(bloc.state.summary.totalBudgetRials, equals(50000000));

      // Task completed: +50,000 Rials
      bloc.add(const FinancialAnalyticsBudgetAdjusted(deltaRials: 50000, reason: 'پاداش انجام تسک'));
      await expectLater(
        bloc.stream,
        emits(
          isA<FinancialAnalyticsState>().having(
            (s) => s.summary.totalBudgetRials,
            'totalBudgetRials',
            50050000,
          ),
        ),
      );

      // Task overdue: -10,000 Rials
      bloc.add(const FinancialAnalyticsBudgetAdjusted(deltaRials: -10000, reason: 'جریمه موعد گذشته'));
      await expectLater(
        bloc.stream,
        emits(
          isA<FinancialAnalyticsState>().having(
            (s) => s.summary.totalBudgetRials,
            'totalBudgetRials',
            50040000,
          ),
        ),
      );

      await bloc.close();
    });

    test('TaskBloc dispatches +50,000 Rials to FinancialAnalyticsBloc on Task completed', () async {
      final mockGetTasks = MockGetTasksUseCase();
      final mockCreateTask = MockCreateTaskUseCase();
      final mockTransition = MockTransitionTaskStatusUseCase();
      final mockToggle = MockToggleSubTaskUseCase();
      final mockDelete = MockDeleteTaskUseCase();

      final now = DateTime.now();
      final baseTaskRes = TaskEntity.create(
        id: 'task-complete-1',
        title: 'تسک پروژه ریالی',
        priority: TaskPriority.high,
        createdAt: now,
      );
      final initialTask = (baseTaskRes as Success<TaskEntity, dynamic>).value;

      when(() => mockGetTasks(any())).thenAnswer(
        (_) async => Success([initialTask]),
      );

      final doneTask = (initialTask.transitionStatus(TaskStatus.done, updatedAt: now) as Success<TaskEntity, dynamic>).value;
      when(() => mockTransition(any())).thenAnswer(
        (_) async => Success(doneTask),
      );

      final financialBloc = FinancialAnalyticsBloc();
      final gamificationBloc = GamificationBloc();

      final taskBloc = TaskBloc(
        getTasksUseCase: mockGetTasks,
        createTaskUseCase: mockCreateTask,
        transitionTaskStatusUseCase: mockTransition,
        toggleSubTaskUseCase: mockToggle,
        deleteTaskUseCase: mockDelete,
        financialAnalyticsBloc: financialBloc,
        gamificationBloc: gamificationBloc,
      );

      taskBloc.add(const TasksLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(financialBloc.state.summary.totalBudgetRials, equals(50000000));
      expect(gamificationBloc.state.totalXp, equals(0));

      // Transition to done
      taskBloc.add(const TaskStatusTransitioned(
        taskId: 'task-complete-1',
        targetStatus: TaskStatus.done,
      ));

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Assert Financial Bridge added +50,000 Rials
      expect(financialBloc.state.summary.totalBudgetRials, equals(50050000));
      // Assert Gamification awarded +20 XP for high priority
      expect(gamificationBloc.state.totalXp, equals(20));

      await taskBloc.close();
      await financialBloc.close();
      await gamificationBloc.close();
    });
  });

  group('Phase 9 & 10 Part 2 — Gamification Level-Up Engine', () {
    setUp(() async {
      SoundAndHapticService.instance.resetStats();
      final db = await AppDatabase.open(
        databasePath: inMemoryDatabasePath,
        databaseFactory: databaseFactoryFfiNoIsolate,
      );
      await db.insert(
        AppDatabase.settingsTableName,
        {
          AppDatabase.settingsColKey: 'has_seen_onboarding',
          AppDatabase.settingsColValue: 'true',
        },
      );
      await resetDependencies();
      await initDependencies(overrideDatabase: db);
    });

    tearDown(() async {
      await resetDependencies();
    });

    test('GamificationBloc calculates levels and handles GamificationLevelUpTriggered', () async {
      final bloc = sl<GamificationBloc>();

      expect(bloc.state.level, equals(1));
      expect(bloc.state.title, equals('تازه‌کار'));

      // Trigger level-up event
      bloc.add(const GamificationLevelUpTriggered(newLevel: 2, newTitle: 'برنامه‌ریز نوظهور'));
      await expectLater(
        bloc.stream,
        emits(
          isA<GamificationState>()
              .having((s) => s.level, 'level', 2)
              .having((s) => s.title, 'title', 'برنامه‌ریز نوظهور'),
        ),
      );
    });

    testWidgets('MainScreen listens to GamificationBloc and opens Frosted Level-Up Celebration Dialog with Confetti',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 3600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: TaskFlowApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      final gamificationBloc = sl<GamificationBloc>();

      // Verify screen-wide confetti widget is present in layout
      expect(find.byKey(const Key('main_screen_confetti_widget')), findsOneWidget);
      expect(find.byKey(const Key('level_up_celebration_dialog')), findsNothing);

      // Trigger level up on GamificationBloc
      gamificationBloc.add(const GamificationLevelUpTriggered(newLevel: 3, newTitle: 'برنامه‌ریز حرفه‌ای'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Celebration dialog MUST appear
      expect(find.byKey(const Key('level_up_celebration_dialog')), findsOneWidget);
      expect(find.byKey(const Key('level_up_dialog_title')), findsOneWidget);
      expect(find.text('ارتقای سطح!'), findsOneWidget);
      expect(find.byKey(const Key('level_up_dialog_level')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('level_up_celebration_dialog')),
          matching: find.text('سطح ۳'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('level_up_dialog_user_title')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('level_up_celebration_dialog')),
          matching: find.text('برنامه‌ریز حرفه‌ای'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('level_up_dialog_dismiss_button')), findsOneWidget);

      // Tap dismiss button "عالیه! 🎉"
      await tester.tap(find.byKey(const Key('level_up_dialog_dismiss_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 4));

      expect(find.byKey(const Key('level_up_celebration_dialog')), findsNothing);
    });
  });
}
