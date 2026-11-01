import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/features/dashboard/dashboard_page.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_event.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_event.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

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

  Widget buildDashboardHarness({
    required TaskBloc taskBloc,
    required SettingsBloc settingsBloc,
    required NotificationBloc notificationBloc,
    required GamificationBloc gamificationBloc,
  }) {
    return ProviderScope(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<TaskBloc>.value(value: taskBloc),
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<NotificationBloc>.value(value: notificationBloc),
          BlocProvider<GamificationBloc>.value(value: gamificationBloc),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: DashboardPage(isDark: true),
            ),
          ),
        ),
      ),
    );
  }

  group('Phase 6: The Reward Loop (Confetti & Micro-Interactions)', () {
    testWidgets('DashboardPage contains ConfettiWidget overlay wrapped in IgnorePointer',
        (WidgetTester tester) async {
      final taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
      final settingsBloc = sl<SettingsBloc>()..add(const SettingsLoadRequested());
      final notifBloc = sl<NotificationBloc>()..add(const NotificationsLoadRequested());
      final gamificationBloc = sl<GamificationBloc>();

      await tester.pumpWidget(
        buildDashboardHarness(
          taskBloc: taskBloc,
          settingsBloc: settingsBloc,
          notificationBloc: notifBloc,
          gamificationBloc: gamificationBloc,
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      final confettiFinder = find.byKey(const Key('dashboard_confetti_widget'));
      expect(confettiFinder, findsOneWidget);

      // Verify IgnorePointer wraps ConfettiWidget so it never blocks task touches
      final ignorePointerFinder = find.ancestor(
        of: confettiFinder,
        matching: find.byType(IgnorePointer),
      );
      expect(ignorePointerFinder, findsWidgets);
      final directIgnorePointer = tester.widget<IgnorePointer>(ignorePointerFinder.first);
      expect(directIgnorePointer.ignoring, isTrue);
    });

    testWidgets('Triggers confetti celebration burst when a task transitions to done',
        (WidgetTester tester) async {
      final taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
      final settingsBloc = sl<SettingsBloc>()..add(const SettingsLoadRequested());
      final notifBloc = sl<NotificationBloc>()..add(const NotificationsLoadRequested());
      final gamificationBloc = sl<GamificationBloc>();

      // Create a task
      final now = DateTime.now();
      taskBloc.add(
        const TaskCreated(
          id: 'confetti-reward-task-1',
          title: 'تسک جشن و پاداش',
        ),
      );

      await tester.pumpWidget(
        buildDashboardHarness(
          taskBloc: taskBloc,
          settingsBloc: settingsBloc,
          notificationBloc: notifBloc,
          gamificationBloc: gamificationBloc,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Transition task to done
      taskBloc.add(
        TaskStatusTransitioned(
          taskId: 'confetti-reward-task-1',
          targetStatus: TaskStatus.done,
          timestamp: now,
        ),
      );

      // Pump to trigger BlocListener and confetti play
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final confettiWidget = tester.widget<ConfettiWidget>(
        find.byKey(const Key('dashboard_confetti_widget')),
      );
      expect(confettiWidget.confettiController.state, equals(ConfettiControllerState.playing));

      // Allow confetti burst to finish smoothly
      await tester.pump(const Duration(milliseconds: 1500));
    });

    testWidgets('Triggers confetti celebration burst when user levels up in GamificationBloc',
        (WidgetTester tester) async {
      final taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
      final settingsBloc = sl<SettingsBloc>()..add(const SettingsLoadRequested());
      final notifBloc = sl<NotificationBloc>()..add(const NotificationsLoadRequested());
      final gamificationBloc = sl<GamificationBloc>();

      await tester.pumpWidget(
        buildDashboardHarness(
          taskBloc: taskBloc,
          settingsBloc: settingsBloc,
          notificationBloc: notifBloc,
          gamificationBloc: gamificationBloc,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Trigger level up event
      gamificationBloc.add(
        const GamificationLevelUpTriggered(newLevel: 2, newTitle: 'برنامه‌ریز'),
      );

      // Pump to process BlocListener
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final confettiWidget = tester.widget<ConfettiWidget>(
        find.byKey(const Key('dashboard_confetti_widget')),
      );
      expect(confettiWidget.confettiController.state, equals(ConfettiControllerState.playing));

      // Let animation settle
      await tester.pump(const Duration(milliseconds: 1500));
    });
  });
}
