import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/features/dashboard/dashboard_page.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_event.dart';
import 'package:task_flow/core/theme/app_theme_mode.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/settings/presentation/pages/settings_page.dart';
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

  Widget buildSettingsHarness({
    required SettingsBloc settingsBloc,
    required TaskBloc taskBloc,
    required NotificationBloc notificationBloc,
    required GamificationBloc gamificationBloc,
  }) {
    return ProviderScope(
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SettingsBloc>.value(value: settingsBloc),
          BlocProvider<TaskBloc>.value(value: taskBloc),
          BlocProvider<NotificationBloc>.value(value: notificationBloc),
          BlocProvider<GamificationBloc>.value(value: gamificationBloc),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SettingsPage(isDark: true),
            ),
          ),
        ),
      ),
    );
  }

  group('UI/UX Refinement: Theme Selection & Full-Screen Vacation Blur', () {
    testWidgets(
      'SettingsPage App Theme card has NO CupertinoSwitch and uses segmented buttons only',
      (WidgetTester tester) async {
        final settingsBloc = sl<SettingsBloc>()..add(const SettingsLoadRequested());
        final taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
        final notifBloc = sl<NotificationBloc>()..add(const NotificationsLoadRequested());
        final gamificationBloc = sl<GamificationBloc>();

        await tester.pumpWidget(
          buildSettingsHarness(
            settingsBloc: settingsBloc,
            taskBloc: taskBloc,
            notificationBloc: notifBloc,
            gamificationBloc: gamificationBloc,
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        // Open TechnicalSettingsView via Profile gear button
        expect(find.byKey(const Key('profile_technical_settings_button')), findsOneWidget);
        await tester.tap(find.byKey(const Key('profile_technical_settings_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final themeCardFinder = find.byKey(const Key('settings_theme_mode_card'));
        expect(themeCardFinder, findsOneWidget);

        // Verify CupertinoSwitch is COMPLETELY REMOVED from the theme card
        final switchInsideThemeCard = find.descendant(
          of: themeCardFinder,
          matching: find.byType(CupertinoSwitch),
        );
        expect(switchInsideThemeCard, findsNothing);

        // Verify segmented buttons exist
        expect(find.byKey(const Key('settings_theme_mode_signature')), findsOneWidget);
        expect(find.byKey(const Key('settings_theme_mode_dark')), findsOneWidget);
        expect(find.byKey(const Key('settings_theme_mode_zen')), findsOneWidget);
        expect(find.byKey(const Key('settings_theme_mode_light')), findsOneWidget);

        // Tap Zen segmented button
        await tester.tap(find.byKey(const Key('settings_theme_mode_zen')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(settingsBloc.state.settings.themeMode, equals(AppThemeMode.zen));
      },
    );

    testWidgets(
      'DashboardPage renders normal dashboard and hides vacation blur when vacationMode == false',
      (WidgetTester tester) async {
        final taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
        final settingsBloc = sl<SettingsBloc>()
          ..add(const SettingsLoadRequested())
          ..add(const SettingsThemeModeChanged(AppThemeMode.dark));
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
        // ignore: avoid_print
        print('SETTINGS THEME MODE: ${settingsBloc.state.settings.themeMode}');
        // ignore: avoid_print
        print('SIGNATURE PROGRESS BAR FOUND: ${find.byKey(const Key('signature_segmented_progress_bar')).evaluate().length}');
        // ignore: avoid_print
        print('DAILY OVERALL CARD FOUND: ${find.byKey(const Key('daily_overall_status_card')).evaluate().length}');

        // Vacation mode overlay must NOT be visible
        expect(find.byKey(const Key('vacation_mode_blur_overlay')), findsNothing);

        // Normal dashboard header, daily overall status card, and timeline title must be visible
        expect(find.byKey(const Key('dashboard_header_greeting_text')), findsOneWidget);
        expect(find.byKey(const Key('daily_overall_status_card')), findsOneWidget);
        expect(find.byKey(const Key('dashboard_timeline_section_title')), findsOneWidget);
      },
    );

    testWidgets(
      'DashboardPage wraps body in BackdropFilter blur and centers Vacation Mode Card when vacationMode == true',
      (WidgetTester tester) async {
        final taskBloc = sl<TaskBloc>()..add(const TasksLoadRequested());
        final settingsBloc = sl<SettingsBloc>()
          ..add(const SettingsLoadRequested())
          ..add(const SettingsThemeModeChanged(AppThemeMode.dark));
        final notifBloc = sl<NotificationBloc>()..add(const NotificationsLoadRequested());
        final gamificationBloc = sl<GamificationBloc>();

        // Enable Vacation Mode
        settingsBloc.add(const SettingsVacationModeToggled(true));

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

        // Top App Bar header remains visible and crisp
        expect(find.byKey(const Key('dashboard_header_greeting_text')), findsOneWidget);

        // Full-Screen Vacation Blur Overlay is present
        expect(find.byKey(const Key('vacation_mode_blur_overlay')), findsOneWidget);
        expect(find.text('شما در حال استراحت هستید 🌴'), findsOneWidget);
        expect(find.text('شما در حالت استراحت هستید 🌴'), findsOneWidget);

        // Verify AbsorbPointer wraps the blur layer to block touches on underlying tasks
        final absorbPointerFinder = find.byWidgetPredicate(
          (widget) => widget is AbsorbPointer && widget.absorbing == true,
        );
        expect(absorbPointerFinder, findsWidgets);

        // Verify BackdropFilter with blur is present
        final backdropFilterFinder = find.byWidgetPredicate(
          (widget) =>
              widget is BackdropFilter &&
              widget.filter == ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        );
        expect(backdropFilterFinder, findsOneWidget);

        // Verify normal dashboard elements are still rendered in the tree behind the blur
        expect(find.byKey(const Key('daily_overall_status_card')), findsOneWidget);
        expect(find.byKey(const Key('dashboard_timeline_section_title')), findsOneWidget);
      },
    );
  });
}
