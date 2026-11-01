import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/dashboard/dashboard_page.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:task_flow/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_event.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_event.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  late Database db;
  late NotificationRepository repository;

  setUp(() async {
    await resetDependencies();
    db = await AppDatabase.open(
      databasePath: inMemoryDatabasePath,
      databaseFactory: databaseFactoryFfiNoIsolate,
    );
    await initDependencies(overrideDatabase: db, preloadAudioInIsolate: false);
    repository = sl<NotificationRepository>();
  });

  tearDown(() async {
    await resetDependencies();
  });

  group('Phase 6.5 — SQLite Persistent Notification Center & CRUD', () {
    test('inserts, retrieves, marks as read, and clears notifications in SQLite', () async {
      final now = DateTime.now().toUtc();
      final n1 = AppNotificationEntity(
        id: 'notif-1',
        title: 'تکمیل تسک',
        message: "تسک 'طراحی معماری' با موفقیت تمام شد! (+20 XP)",
        type: AppNotificationType.reward,
        isRead: false,
        timestamp: now,
      );
      final n2 = AppNotificationEntity(
        id: 'notif-2',
        title: 'موعد گذشته',
        message: "تسک 'ارسال ایمیل' انجام نشد و موعد آن گذشت. (-5 XP)",
        type: AppNotificationType.penalty,
        isRead: false,
        timestamp: now.add(const Duration(minutes: 5)),
      );

      await repository.saveNotification(n1);
      await repository.saveNotification(n2);

      // Verify unread count
      final unreadCountResult = await repository.getUnreadCount();
      expect(unreadCountResult.isSuccess, isTrue);
      expect((unreadCountResult as Success).value, equals(2));

      // Verify chronological ordering (newest first)
      final listResult = await repository.getNotifications();
      expect(listResult.isSuccess, isTrue);
      final list = (listResult as Success).value as List<AppNotificationEntity>;
      expect(list.length, equals(2));
      expect(list[0].id, equals('notif-2'));
      expect(list[1].id, equals('notif-1'));

      // Mark n2 as read
      await repository.markAsRead('notif-2');
      final updatedUnread = await repository.getUnreadCount();
      expect((updatedUnread as Success).value, equals(1));

      // Mark all as read
      await repository.markAllAsRead();
      final zeroUnread = await repository.getUnreadCount();
      expect((zeroUnread as Success).value, equals(0));

      // Delete one notification
      await repository.deleteNotification('notif-1');
      final afterDelete = await repository.getNotifications();
      expect(((afterDelete as Success).value as List<AppNotificationEntity>).length, equals(1));

      // Clear all
      await repository.clearAll();
      final emptyList = await repository.getNotifications();
      expect((emptyList as Success).value, isEmpty);
    });
  });

  group('Phase 6.5 — NotificationBloc & GamificationBloc State Machine', () {
    test('NotificationBloc handles loads, reads, and clears correctly', () async {
      final bloc = NotificationBloc(repository: repository);
      expect(bloc.state.notifications, isEmpty);
      expect(bloc.state.unreadCount, equals(0));

      final n = AppNotificationEntity(
        id: 'bloc-notif-1',
        title: 'جلسه تمرکز پومودورو',
        message: 'تمرکز ۲۵ دقیقه‌ای با موفقیت تمام شد! (+25 XP)',
        type: AppNotificationType.reward,
        timestamp: DateTime.now().toUtc(),
      );

      bloc.add(NotificationAdded(n));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.notifications.length, equals(1));
      expect(bloc.state.unreadCount, equals(1));
      expect(bloc.state.hasUnread, isTrue);

      bloc.add(const NotificationMarkedAsRead('bloc-notif-1'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.unreadCount, equals(0));
      expect(bloc.state.hasUnread, isFalse);

      bloc.add(const NotificationsCleared());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.notifications, isEmpty);

      await bloc.close();
    });

    test('GamificationBloc persists reward and penalty notifications to SQLite', () async {
      final gamificationBloc = sl<GamificationBloc>();

      gamificationBloc.add(
        const GamificationTaskCompleted(
          taskId: 't-100',
          title: 'TAMIZ',
          priority: TaskPriority.high,
        ),
      );
      gamificationBloc.add(
        const GamificationPomodoroCompleted(
          minutes: 25,
          earnedXp: 25,
          taskTitle: 'TAMIZ',
        ),
      );
      gamificationBloc.add(
        const GamificationTaskOverdue(
          taskId: 't-101',
          title: 'TAMIZ',
          penaltyXp: 5,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final notifRes = await repository.getNotifications();
      final notifications = (notifRes as Success).value as List<AppNotificationEntity>;
      expect(notifications.length, equals(3));
      expect(notifications.any((n) => n.type == AppNotificationType.penalty), isTrue);
      expect(notifications.any((n) => n.type == AppNotificationType.reward), isTrue);
    });
  });

  group('Phase 6.5 — Dashboard Bell Icon & Glass Bottom Sheet UI', () {
    testWidgets('Dashboard renders bell icon with unread badge and opens notifications glass sheet',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Pre-seed an unread reward and penalty notification
      final now = DateTime.now().toUtc();
      await repository.saveNotification(
        AppNotificationEntity(
          id: 'ui-notif-1',
          title: 'تکمیل تسک',
          message: "تسک 'TAMIZ' با موفقیت تمام شد! (+20 XP)",
          type: AppNotificationType.reward,
          isRead: false,
          timestamp: now,
        ),
      );
      await repository.saveNotification(
        AppNotificationEntity(
          id: 'ui-notif-2',
          title: 'موعد گذشته',
          message: "تسک 'TAMIZ' انجام نشد و موعد آن گذشت. (-5 XP)",
          type: AppNotificationType.penalty,
          isRead: false,
          timestamp: now.add(const Duration(minutes: 2)),
        ),
      );

      final taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
      final settingsBloc = sl<SettingsBloc>()..add(const SettingsLoadRequested());
      final notifBloc = sl<NotificationBloc>()..add(const NotificationsLoadRequested());

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<TaskBloc>.value(value: taskBloc),
            BlocProvider<SettingsBloc>.value(value: settingsBloc),
            BlocProvider<NotificationBloc>.value(value: notifBloc),
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

      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Bell Button and Unread Dot are present
      final bellButton = find.byKey(const Key('dashboard_notifications_button'));
      expect(bellButton, findsOneWidget);

      final unreadDot = find.byKey(const Key('dashboard_notifications_unread_dot'));
      expect(unreadDot, findsOneWidget);

      // 2. Tap Bell Button to open Glass Bottom Sheet
      await tester.tap(bellButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // 3. Verify Glass Bottom Sheet opens with title
      final bottomSheet = find.byKey(const Key('notifications_bottom_sheet'));
      expect(bottomSheet, findsOneWidget);
      expect(find.byKey(const Key('notifications_sheet_title')), findsOneWidget);
      expect(find.text('پیام‌ها و اعلان‌ها'), findsOneWidget);

      // 4. Verify notification items are rendered
      expect(find.byKey(const Key('notification_tile_ui-notif-1')), findsOneWidget);
      expect(find.byKey(const Key('notification_tile_ui-notif-2')), findsOneWidget);

      // 5. Tap "Mark all as read"
      final markAllReadBtn = find.byKey(const Key('notifications_mark_all_read_button'));
      expect(markAllReadBtn, findsOneWidget);
      await tester.tap(markAllReadBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 6. Close bottom sheet
      final closeBtn = find.byKey(const Key('notifications_close_button'));
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify bottom sheet dismissed
      expect(find.byKey(const Key('notifications_bottom_sheet')), findsNothing);
    });
  });
}
