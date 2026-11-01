import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/notifications/notification_service.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_bloc.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/settings/presentation/pages/technical_settings_view.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  setUp(() async {
    final db = await AppDatabase.open(
      databasePath: inMemoryDatabasePath,
      databaseFactory: databaseFactoryFfiNoIsolate,
    );
    await resetDependencies();
    await initDependencies(overrideDatabase: db, preloadAudioInIsolate: false);
  });

  tearDown(() async {
    await resetDependencies();
  });

  Widget buildTechnicalSettingsHarness({
    NotificationService? notificationService,
  }) {
    final settingsBloc = sl<SettingsBloc>()..add(const SettingsLoadRequested());
    final taskBloc = sl<TaskBloc>();
    final notifBloc = sl<NotificationBloc>();
    final gamificationBloc = sl<GamificationBloc>();
    final finBloc = sl<FinancialAnalyticsBloc>();

    if (notificationService != null && sl.isRegistered<NotificationService>()) {
      sl.unregister<NotificationService>();
      sl.registerSingleton<NotificationService>(notificationService);
    }

    return ProviderScope(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<TaskBloc>.value(value: taskBloc),
          BlocProvider<NotificationBloc>.value(value: notifBloc),
          BlocProvider<GamificationBloc>.value(value: gamificationBloc),
          BlocProvider<FinancialAnalyticsBloc>.value(value: finBloc),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: TechnicalSettingsView(isDark: true),
          ),
        ),
      ),
    );
  }

  group('Phase 8 — Background Notification Test in Technical Settings', () {
    testWidgets('renders Test Background Notification card and triggers 5s schedule', (tester) async {
      final mockNotificationService = MockNotificationService();
      when(
        () => mockNotificationService.scheduleTestNotification(
          seconds: any(named: 'seconds'),
          title: any(named: 'title'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildTechnicalSettingsHarness(notificationService: mockNotificationService),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final testCardFinder = find.byKey(const Key('settings_test_notification_card'));
      expect(testCardFinder, findsOneWidget);
      expect(find.byKey(const Key('settings_test_notification_title')), findsOneWidget);
      expect(find.text('تست نوتیفیکیشن پسزمینه'), findsOneWidget);
      expect(find.text('۵ ثانیه'), findsOneWidget);

      // Tap the background notification test button
      await tester.ensureVisible(find.byKey(const Key('settings_test_notification_button')));
      await tester.tap(find.byKey(const Key('settings_test_notification_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify NotificationService called with 5 seconds delay and specified message
      verify(
        () => mockNotificationService.scheduleTestNotification(
          seconds: 5,
          title: 'زندگی‌ساز 🚀',
          body: 'نوتیفیکیشن پس‌زمینه با موفقیت کار می‌کند!',
        ),
      ).called(1);

      // Verify feedback SnackBar appears
      expect(find.textContaining('نوتیفیکیشن برای ۵ ثانیه دیگر تنظیم شد'), findsOneWidget);
    });

    test('NotificationService.scheduleTestNotification executes without throwing', () async {
      final realService = NotificationService();
      expect(
        () => realService.scheduleTestNotification(
          seconds: 5,
          title: 'زندگی‌ساز 🚀',
          body: 'نوتیفیکیشن پس‌زمینه با موفقیت کار می‌کند!',
        ),
        returnsNormally,
      );
    });
  });
}
