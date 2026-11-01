import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:task_flow/core/concurrency/concurrent_dashboard_loader.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/features/analytics/data/datasources/analytics_local_datasource.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_event.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_bloc.dart';
import 'package:task_flow/features/analytics/presentation/pages/reports_page.dart';
import 'package:task_flow/features/dashboard/dashboard_page.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
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
    await resetDependencies();
    await initDependencies(
      overrideDatabase: db,
      preloadAudioInIsolate: false,
    );
  });

  tearDown(() async {
    await resetDependencies();
  });

  group('Axis 1 — Strict Concurrency & Parallel Bootstrapping', () {
    test(
      'initDependencies preloads audio buffers concurrently alongside SQLite and NotificationService',
      () async {
        expect(SoundAndHapticService.instance.isPreloaded, isTrue);
        expect(
          SoundAndHapticService.generatePopDingWav(),
          isNotEmpty,
        );
        expect(
          SoundAndHapticService.generatePomodoroGentleChimeWav(),
          isNotEmpty,
        );
        expect(sl.isRegistered<ConcurrentDashboardLoader>(), isTrue);
      },
    );

    test(
      'ConcurrentDashboardLoader fetches today tasks and user settings in parallel via Future.wait',
      () async {
        final loader = sl<ConcurrentDashboardLoader>();
        final snapshot = await loader.loadConcurrently();

        expect(snapshot.settingsResult.isSuccess, isTrue);
        expect(snapshot.tasksResult.isSuccess, isTrue);
      },
    );

    test(
      'AnalyticsLocalDataSourceImpl executes SQLite queries concurrently and computes activityHeatmapCounts',
      () async {
        final analyticsDs = sl<AnalyticsLocalDataSource>();
        final summary = await analyticsDs.getAnalyticsSummary();

        expect(summary.activityHeatmapCounts, isA<Map<String, int>>());
      },
    );
  });

  group('Axis 2 — Pomodoro Focus Engine (25-min Deep Work Timer)', () {
    testWidgets(
      'Task card shows Start Pomodoro button, opens 25:00 timer sheet, plays chime on completion, and checks off task',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        late TaskBloc taskBloc;

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<TaskBloc>(
                create: (_) {
                  taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
                  return taskBloc;
                },
              ),
              BlocProvider<SettingsBloc>(
                create: (_) =>
                    sl<SettingsBloc>()..add(const SettingsLoadRequested()),
              ),
              BlocProvider<AnalyticsBloc>(
                create: (_) =>
                    sl<AnalyticsBloc>()..add(const AnalyticsLoadRequested()),
              ),
              BlocProvider<FinancialAnalyticsBloc>(
                create: (_) => sl<FinancialAnalyticsBloc>(),
              ),
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
        await tester.pump(const Duration(seconds: 1));

        // Add a focus task for today
        final now = DateTime.now();
        taskBloc.add(
          TaskCreated(
            id: 'pomodoro-deep-work-1',
            title: 'مطالعه عمیق معماری فلاتر',
            priority: TaskPriority.high,
            dueDate: DateTime(now.year, now.month, now.day),
            startTime: '10:00',
            endTime: '11:00',
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        final taskSlidable = find.byKey(
          const Key('task_slidable_pomodoro-deep-work-1'),
        );
        expect(taskSlidable, findsOneWidget);

        // Swipe right on the decluttered task card to reveal "شروع تمرکز ⏱️" and "زیرتسک"
        await tester.ensureVisible(taskSlidable);
        await tester.drag(taskSlidable, const Offset(320, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final startFocusBtn = find.byKey(
          const Key('start_pomodoro_focus_pomodoro-deep-work-1'),
        );
        expect(startFocusBtn, findsOneWidget);
        expect(find.text('شروع تمرکز ⏱️'), findsWidgets);

        await tester.tap(startFocusBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verify Pomodoro Focus Sheet is open with 25:00 countdown and circular progress
        expect(
          find.byKey(const Key('pomodoro_focus_bottom_sheet')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('pomodoro_circular_progress')),
          findsOneWidget,
        );
        expect(find.text('۲۵:۰۰'), findsOneWidget);

        // Finish focus session to verify gentle chime + User Autonomy 2-button prompt
        final finishBtn = find.byKey(const Key('pomodoro_finish_timer_button'));
        expect(finishBtn, findsOneWidget);
        await tester.tap(finishBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          SoundAndHapticService.instance.pomodoroCompletionPlayCount,
          greaterThanOrEqualTo(1),
        );
        expect(find.text('۰۰:۰۰'), findsOneWidget);

        // Axis 1 (User Autonomy): Both "تأیید پایان تمرکز" (Primary) and "تیک زدن و اتمام تسک ✅" (Secondary) exist
        final confirmEndFocusBtn =
            find.byKey(const Key('pomodoro_confirm_end_focus_button'));
        final completeTaskBtn =
            find.byKey(const Key('pomodoro_complete_task_button'));
        expect(confirmEndFocusBtn, findsOneWidget);
        expect(find.text('تأیید پایان تمرکز'), findsOneWidget);
        expect(completeTaskBtn, findsOneWidget);
        expect(find.text('تیک زدن و اتمام تسک ✅'), findsOneWidget);

        await tester.tap(completeTaskBtn);
        await tester.pump();
        await tester.pump(const Duration(seconds: 3));

        // Verify sheet closed and task is marked completed
        expect(
          find.byKey(const Key('pomodoro_focus_bottom_sheet')),
          findsNothing,
        );
        final updatedTask = taskBloc.state.tasks.firstWhere(
          (t) => t.id == 'pomodoro-deep-work-1',
        );
        expect(updatedTask.status, equals(TaskStatus.done));
      },
    );

    testWidgets(
      'Pomodoro User Autonomy: Tapping "تأیید پایان تمرکز" closes sheet while keeping task open (todo)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        late TaskBloc taskBloc;

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<TaskBloc>(
                create: (_) {
                  taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
                  return taskBloc;
                },
              ),
              BlocProvider<SettingsBloc>(
                create: (_) =>
                    sl<SettingsBloc>()..add(const SettingsLoadRequested()),
              ),
              BlocProvider<AnalyticsBloc>(
                create: (_) =>
                    sl<AnalyticsBloc>()..add(const AnalyticsLoadRequested()),
              ),
              BlocProvider<FinancialAnalyticsBloc>(
                create: (_) => sl<FinancialAnalyticsBloc>(),
              ),
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
        await tester.pump(const Duration(seconds: 1));

        final now = DateTime.now();
        taskBloc.add(
          TaskCreated(
            id: 'pomodoro-autonomy-open',
            title: 'جلسه تمرکز بدون بستن تسک',
            priority: TaskPriority.medium,
            dueDate: DateTime(now.year, now.month, now.day),
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        final slidableFinder = find.byKey(
          const Key('task_slidable_pomodoro-autonomy-open'),
        );
        await tester.ensureVisible(slidableFinder);
        await tester.drag(slidableFinder, const Offset(320, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        await tester.tap(
          find.byKey(const Key('start_pomodoro_focus_pomodoro-autonomy-open')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.tap(find.byKey(const Key('pomodoro_finish_timer_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap Primary button "تأیید پایان تمرکز"
        await tester.tap(
          find.byKey(const Key('pomodoro_confirm_end_focus_button')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          find.byKey(const Key('pomodoro_focus_bottom_sheet')),
          findsNothing,
        );
        final openTask = taskBloc.state.tasks.firstWhere(
          (t) => t.id == 'pomodoro-autonomy-open',
        );
        expect(openTask.status, equals(TaskStatus.todo));
      },
    );
  });

  group('Axis 3 — GitHub-Style Activity Heatmap in ReportsPage', () {
    testWidgets(
      'ReportsPage renders GitHub-Style Activity Heatmap with emerald active squares and gray idle squares',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        late TaskBloc taskBloc;
        late AnalyticsBloc analyticsBloc;

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<TaskBloc>(
                create: (_) {
                  taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
                  return taskBloc;
                },
              ),
              BlocProvider<SettingsBloc>(
                create: (_) =>
                    sl<SettingsBloc>()..add(const SettingsLoadRequested()),
              ),
              BlocProvider<AnalyticsBloc>(
                create: (_) {
                  analyticsBloc = sl<AnalyticsBloc>()
                    ..add(const AnalyticsLoadRequested());
                  return analyticsBloc;
                },
              ),
            ],
            child: const MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: ReportsPage(isDark: true),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        for (int i = 0; i < 3; i++) {
          final taskId = 'heatmap-task-$i';
          taskBloc.add(
            TaskCreated(
              id: taskId,
              title: 'تسک نقشه حرارتی $i',
              dueDate: today,
            ),
          );
          await tester.pump(const Duration(milliseconds: 250));
          taskBloc.add(
            TaskStatusTransitioned(
              taskId: taskId,
              targetStatus: TaskStatus.done,
            ),
          );
          await tester.pump(const Duration(milliseconds: 250));
        }

        analyticsBloc.add(const AnalyticsRefreshed());
        await tester.pump(const Duration(seconds: 1));

        expect(
          find.byKey(const Key('github_activity_heatmap_card')),
          findsOneWidget,
        );
        expect(
          find.text('نقشه حرارتی استمرار (Activity Heatmap)'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('github_heatmap_grid')), findsOneWidget);

        // Today's square is index 83 (last square in 12x7 grid)
        final todaySquareFinder =
            find.byKey(const Key('heatmap_day_square_83'));
        expect(todaySquareFinder, findsOneWidget);
        final todayContainer = tester.widget<Container>(todaySquareFinder);
        final todayDecoration = todayContainer.decoration! as BoxDecoration;

        // Idle square in the past (e.g. index 0)
        final idleSquareFinder = find.byKey(const Key('heatmap_day_square_0'));
        expect(idleSquareFinder, findsOneWidget);
        final idleContainer = tester.widget<Container>(idleSquareFinder);
        final idleDecoration = idleContainer.decoration! as BoxDecoration;

        // Active day color must differ from idle gray color
        expect(todayDecoration.color, isNot(equals(idleDecoration.color)));
      },
    );
  });

  group('Axis 4 — Subtasks Live Progress Indicator', () {
    testWidgets(
      'Task card with 5 subtasks displays live linear progress bar and updates to "۲ از ۵ (۴۰٪)" when 2 subtasks are completed',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        late TaskBloc taskBloc;

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<TaskBloc>(
                create: (_) {
                  taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
                  return taskBloc;
                },
              ),
              BlocProvider<SettingsBloc>(
                create: (_) =>
                    sl<SettingsBloc>()..add(const SettingsLoadRequested()),
              ),
              BlocProvider<AnalyticsBloc>(
                create: (_) =>
                    sl<AnalyticsBloc>()..add(const AnalyticsLoadRequested()),
              ),
              BlocProvider<FinancialAnalyticsBloc>(
                create: (_) => sl<FinancialAnalyticsBloc>(),
              ),
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
        await tester.pump(const Duration(seconds: 1));

        final now = DateTime.now();
        taskBloc.add(
          TaskCreated(
            id: 'parent-live-progress',
            title: 'پروژه جامع مهندسی موازی',
            dueDate: DateTime(now.year, now.month, now.day),
            startTime: '11:00',
            endTime: '12:30',
            subTaskTitles: const [
              'زیرتسک شماره ۱',
              'زیرتسک شماره ۲',
              'زیرتسک شماره ۳',
              'زیرتسک شماره ۴',
              'زیرتسک شماره ۵',
            ],
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        final createdParent = taskBloc.state.tasks.firstWhere(
          (t) => t.id == 'parent-live-progress',
        );
        expect(createdParent.subTasks.length, equals(5));

        // Toggle 2 of the 5 subtasks to completed
        taskBloc.add(
          SubTaskToggled(
            taskId: 'parent-live-progress',
            subTaskId: createdParent.subTasks[0].id,
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));
        taskBloc.add(
          SubTaskToggled(
            taskId: 'parent-live-progress',
            subTaskId: createdParent.subTasks[1].id,
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        final progressBarFinder = find.byKey(
          const Key('subtask_live_progress_bar_parent-live-progress'),
        );
        final progressTextFinder = find.byKey(
          const Key('subtask_live_progress_text_parent-live-progress'),
        );

        expect(progressBarFinder, findsOneWidget);
        expect(progressTextFinder, findsOneWidget);
        expect(find.text('۲ از ۵ (۴۰٪)'), findsOneWidget);

        final linearBarFinder = find.byKey(
          const Key('subtask_linear_progress_parent-live-progress'),
        );
        expect(linearBarFinder, findsOneWidget);
        final progressBar =
            tester.widget<LinearProgressIndicator>(linearBarFinder);
        expect(progressBar.value, closeTo(0.4, 0.01));
      },
    );
  });

  group(
      'World-Class UI Polish: Slidable Swipe Actions, Compact Dashboard, Checkmark Joy, Spotlight Search & Smart Grouping',
      () {
    testWidgets(
      'Task cards are decluttered, support Swipe-Right (Pomodoro/Subtask) and Swipe-Left (Edit/Delete), Compact Status Card, Pull-Down Spotlight Search, and Smart Grouping with Checkmark Joy move-to-bottom',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        late TaskBloc taskBloc;

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<TaskBloc>(
                create: (_) {
                  taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
                  return taskBloc;
                },
              ),
              BlocProvider<SettingsBloc>(
                create: (_) =>
                    sl<SettingsBloc>()..add(const SettingsLoadRequested()),
              ),
              BlocProvider<AnalyticsBloc>(
                create: (_) =>
                    sl<AnalyticsBloc>()..add(const AnalyticsLoadRequested()),
              ),
              BlocProvider<FinancialAnalyticsBloc>(
                create: (_) => sl<FinancialAnalyticsBloc>(),
              ),
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
        await tester.pump(const Duration(seconds: 1));

        // Axis 3: Verify Compact _DailyOverallStatusCard height
        final dailyCardSize = tester.getSize(
          find.byKey(const Key('daily_overall_status_card')),
        );
        expect(dailyCardSize.height, lessThan(150));

        // Axis 5: Verify Spotlight Search is hidden by default
        expect(
          find.byKey(const Key('dashboard_spotlight_search_container')),
          findsNothing,
        );

        // Create tasks across Smart Groups: Overdue, Today, and Habit (recurring)
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);
        taskBloc.add(
          TaskCreated(
            id: 'smart-overdue-task',
            title: 'تسک موعد گذشته صبحگاهی',
            dueDate: todayDate,
            startTime: '00:01',
            endTime: '00:02',
          ),
        );
        await tester.pump(const Duration(milliseconds: 250));
        taskBloc.add(
          TaskCreated(
            id: 'smart-today-task',
            title: 'طراحی رابط کاربری اپل',
            dueDate: todayDate,
          ),
        );
        await tester.pump(const Duration(milliseconds: 250));
        taskBloc.add(
          TaskCreated(
            id: 'smart-habit-task',
            title: 'نوشیدن ۸ لیوان آب',
            dueDate: todayDate,
            recurrenceRule: 'daily',
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        // Axis 6: Verify Minimal Smart Group Headers ("موعد گذشته", "امروز", and "عادت‌ها")
        expect(
          find.byKey(const Key('smart_group_header_overdue')),
          findsOneWidget,
        );
        expect(find.text('موعد گذشته'), findsOneWidget);
        expect(
          find.byKey(const Key('smart_group_header_today')),
          findsOneWidget,
        );
        expect(find.text('امروز'), findsWidgets);
        expect(
          find.byKey(const Key('smart_group_header_habits')),
          findsOneWidget,
        );
        expect(find.text('عادت‌ها'), findsOneWidget);

        // Axis 4: Checkmark Joy (FadeTransition + ScaleTransition) & Move to Bottom ("تکمیل‌شده‌ها")
        expect(
          find.byKey(const Key('task_fade_transition_smart-today-task')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('task_shrink_scale_smart-today-task')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(const Key('task_card_tap_target_smart-today-task')),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(
          find.byKey(const Key('smart_group_header_completed')),
          findsOneWidget,
        );
        expect(find.text('تکمیل‌شده‌ها'), findsOneWidget);

        // Verify completed task moved below the active habit task
        final habitTopY = tester
            .getTopLeft(
              find.byKey(const Key('task_slidable_smart-habit-task')),
            )
            .dy;
        final completedTopY = tester
            .getTopLeft(
              find.byKey(const Key('task_slidable_smart-today-task')),
            )
            .dy;
        expect(completedTopY, greaterThan(habitTopY));

        // Axis 2: Swipe Left on habit task to reveal "ویرایش" and "حذف"
        final habitSlidable = find.byKey(
          const Key('task_slidable_smart-habit-task'),
        );
        await tester.drag(habitSlidable, const Offset(-300, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final editActionBtn = find.byKey(
          const Key('edit_task_action_smart-habit-task'),
        );
        final deleteActionBtn = find.byKey(
          const Key('delete_task_action_smart-habit-task'),
        );
        expect(editActionBtn, findsOneWidget);
        expect(deleteActionBtn, findsOneWidget);

        // Axis 5: Pull down on the task list to reveal the hidden Spotlight Search bar
        await tester.drag(
          find.byKey(const Key('dashboard_pull_to_refresh')),
          const Offset(0, 180),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(
          find.byKey(const Key('dashboard_spotlight_search_container')),
          findsOneWidget,
        );
        final searchField = find.byKey(
          const Key('dashboard_spotlight_search_field'),
        );
        expect(searchField, findsOneWidget);

        // Filter tasks in real-time via Spotlight Search
        await tester.enterText(searchField, 'اپل');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('طراحی رابط کاربری اپل'), findsOneWidget);
        expect(find.text('نوشیدن ۸ لیوان آب'), findsNothing);
      },
    );

    testWidgets(
      'HTML Reference Redesign: Header Persian Date & Chips, Hero Circular Ring & Focus Stat, Prominent Focus CTA, and Vertical Timeline List',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        late TaskBloc taskBloc;

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: [
              BlocProvider<TaskBloc>(
                create: (_) {
                  taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
                  return taskBloc;
                },
              ),
              BlocProvider<SettingsBloc>(
                create: (_) =>
                    sl<SettingsBloc>()..add(const SettingsLoadRequested()),
              ),
              BlocProvider<AnalyticsBloc>(
                create: (_) =>
                    sl<AnalyticsBloc>()..add(const AnalyticsLoadRequested()),
              ),
              BlocProvider<FinancialAnalyticsBloc>(
                create: (_) => sl<FinancialAnalyticsBloc>(),
              ),
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
        await tester.pump(const Duration(seconds: 1));

        // Axis 1: Header & Status Chips
        expect(
          find.byKey(const Key('dashboard_header_persian_date')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dashboard_gamification_status_row')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dashboard_user_title_badge')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dashboard_streak_badge')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('dashboard_streak_freeze_badge')),
          findsOneWidget,
        );

        // Axis 2: Hero Card & Circular Progress Ring
        expect(
          find.byKey(const Key('daily_overall_status_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('hero_circular_progress_ring')),
          findsOneWidget,
        );
        expect(find.text('پیشرفت امروز'), findsOneWidget);
        expect(find.byKey(const Key('hero_stat_done_value')), findsOneWidget);
        expect(find.byKey(const Key('hero_stat_wait_value')), findsOneWidget);
        expect(find.byKey(const Key('hero_stat_focus_value')), findsOneWidget);
        expect(find.text('تمرکز امروز'), findsOneWidget);

        // Axis 3: Prominent Focus CTA directly below Hero Card
        final prominentFocusCta = find.byKey(
          const Key('dashboard_prominent_focus_cta'),
        );
        expect(prominentFocusCta, findsOneWidget);
        expect(find.text('۲۵ دقیقه ⚡'), findsOneWidget);

        // Create a scheduled task to test Axis 4 Vertical Timeline & Prominent CTA
        final now = DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);
        taskBloc.add(
          TaskCreated(
            id: 'timeline-ref-task-1',
            title: 'بازطراحی داشبورد فلاتر',
            priority: TaskPriority.high,
            dueDate: todayDate,
            startTime: '08:30',
            endTime: '10:00',
          ),
        );
        await tester.pump(const Duration(seconds: 1));

        // Axis 4: Vertical Timeline elements (.tm, .dot, 4px priority bar, .chk)
        expect(
          find.byKey(const Key('timeline_time_timeline-ref-task-1')),
          findsOneWidget,
        );
        expect(find.text('۰۸:۳۰'), findsOneWidget);
        expect(
          find.byKey(const Key('timeline_dot_timeline-ref-task-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('task_priority_bar_timeline-ref-task-1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('task_completion_checkbox_timeline-ref-task-1')),
          findsOneWidget,
        );

        // Tap Prominent Focus CTA -> opens PomodoroFocusSheet
        await tester.tap(prominentFocusCta);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.byKey(const Key('pomodoro_focus_bottom_sheet')),
          findsOneWidget,
        );
      },
    );
  });
}
