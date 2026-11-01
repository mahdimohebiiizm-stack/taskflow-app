import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/core/theme/app_theme_mode.dart';
import 'package:task_flow/features/dashboard/dashboard_page.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_event.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
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

  group('Phase 8.2: Signature Today Dashboard & Dual-Layout Transition', () {
    testWidgets(
      'renders ultra-minimalist Signature Today UI with segmented progress, focus CTA, and mini XP bar when theme is signature',
      (WidgetTester tester) async {
        final taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
        final settingsBloc = sl<SettingsBloc>()
          ..add(const SettingsLoadRequested())
          ..add(const SettingsThemeModeChanged(AppThemeMode.signature));
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

        // 1. Signature Header controls
        expect(find.text('زندگی‌ساز'), findsOneWidget);
        expect(find.byKey(const Key('signature_header_theme_button')), findsOneWidget);
        expect(find.byKey(const Key('signature_header_notifications_button')), findsOneWidget);
        expect(find.byKey(const Key('signature_header_end_day_button')), findsOneWidget);
        expect(find.byKey(const Key('signature_header_avatar_button')), findsOneWidget);

        // 2. Signature Hero section
        expect(find.byKey(const Key('signature_hero_headline')), findsOneWidget);
        expect(find.byKey(const Key('signature_date_trigger')), findsOneWidget);
        expect(find.byKey(const Key('dashboard_streak_badge')), findsOneWidget);
        expect(find.byKey(const Key('signature_segmented_progress_bar')), findsOneWidget);

        // 3. Signature Focus CTA Button
        expect(find.byKey(const Key('signature_focus_cta_button')), findsOneWidget);

        // 4. Signature Mini XP Bar at bottom
        expect(find.byKey(const Key('signature_mini_xp_bar')), findsOneWidget);

        // 5. Shared overlay confetti is mounted
        expect(find.byKey(const Key('dashboard_confetti_widget')), findsOneWidget);

        // 6. Classic layout card must NOT be present
        expect(find.byKey(const Key('daily_overall_status_card')), findsNothing);
      },
    );

    testWidgets(
      'DualLayoutTransition dynamically switches between Signature and Classic layouts when theme is changed',
      (WidgetTester tester) async {
        final taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
        final settingsBloc = sl<SettingsBloc>()
          ..add(const SettingsLoadRequested())
          ..add(const SettingsThemeModeChanged(AppThemeMode.signature));
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

        // Signature layout active
        expect(find.byKey(const Key('signature_segmented_progress_bar')), findsOneWidget);
        expect(find.byKey(const Key('daily_overall_status_card')), findsNothing);

        // Change to Classic Dark theme
        settingsBloc.add(const SettingsThemeModeChanged(AppThemeMode.dark));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 250));

        // Classic layout active
        expect(find.byKey(const Key('daily_overall_status_card')), findsOneWidget);
        expect(find.byKey(const Key('signature_segmented_progress_bar')), findsNothing);

        // Change back to Signature theme
        settingsBloc.add(const SettingsThemeModeChanged(AppThemeMode.signature));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.pump(const Duration(milliseconds: 250));

        // Signature layout active again
        expect(find.byKey(const Key('signature_segmented_progress_bar')), findsOneWidget);
        expect(find.byKey(const Key('daily_overall_status_card')), findsNothing);
      },
    );

    testWidgets(
      'Vacation mode overlay blurs the full screen and absorbs pointer in Signature layout',
      (WidgetTester tester) async {
        final taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
        final settingsBloc = sl<SettingsBloc>()
          ..add(const SettingsLoadRequested())
          ..add(const SettingsThemeModeChanged(AppThemeMode.signature))
          ..add(const SettingsVacationModeToggled(true));
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
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Full-screen vacation blur is present over Signature layout
        expect(find.byKey(const Key('vacation_mode_blur_overlay')), findsOneWidget);
        expect(find.text('شما در حالت استراحت هستید 🌴'), findsOneWidget);

        // Signature layout still rendered underneath blur
        expect(find.byKey(const Key('signature_segmented_progress_bar')), findsOneWidget);
        expect(find.byKey(const Key('signature_focus_cta_button')), findsOneWidget);
      },
    );
  });
}
