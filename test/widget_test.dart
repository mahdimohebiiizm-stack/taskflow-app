import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/main.dart';

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
    // Mark onboarding as completed so smoke test can test the core navigation shell and dashboard
    await db.insert(
      AppDatabase.settingsTableName,
      {
        AppDatabase.settingsColKey: 'has_seen_onboarding',
        AppDatabase.settingsColValue: 'true',
      },
    );
    await db.insert(
      AppDatabase.settingsTableName,
      {
        AppDatabase.settingsColKey: 'theme_mode',
        AppDatabase.settingsColValue: 'dark',
      },
    );
    await resetDependencies();
    await initDependencies(overrideDatabase: db);
  });

  tearDown(() async {
    await resetDependencies();
  });

  testWidgets('TaskFlowApp smoke test renders navigation shell and Pro UX cards',
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

    expect(find.text('زندگی‌ساز'), findsOneWidget);
    expect(find.byKey(const Key('dashboard_pull_to_refresh')), findsOneWidget);
    expect(find.byKey(const Key('daily_overall_status_card')), findsOneWidget);
    expect(find.text('نمای کلی روزانه'), findsOneWidget);
    expect(find.text('وضعیت کلی روزانه'), findsOneWidget);
    expect(find.text('انجام شد'), findsWidgets);
    expect(find.text('در انتظار'), findsWidgets);
    expect(find.text('هدف'), findsWidgets);

    // Axis 1, 3, 5 & 6: Verify circular text-free Quick Add FAB, live header greeting, Title ('تازهکار'), Streak & Freeze Shield badges, and Confetti widget
    expect(find.byKey(const Key('dashboard_header_greeting_text')), findsOneWidget);
    expect(find.textContaining('مهدی جان 👋'), findsOneWidget);
    expect(find.byKey(const Key('dashboard_user_title_badge')), findsOneWidget);
    expect(find.text('تازهکار'), findsOneWidget);
    expect(find.byKey(const Key('dashboard_streak_badge')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_streak_freeze_badge')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_confetti_widget')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_quick_add_bar')), findsNothing);
    expect(find.byKey(const Key('dashboard_quick_add_fab')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_quick_add_fab_icon')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('dashboard_quick_add_fab')),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
    final quickFabSize =
        tester.getSize(find.byKey(const Key('dashboard_quick_add_fab')));
    expect(quickFabSize.width, equals(quickFabSize.height));
    expect(find.text('هزینه امروز'), findsNothing);
    expect(find.byKey(const Key('dashboard_gestures_guide_widget')), findsNothing);
    expect(find.byKey(const Key('dashboard_header_help_button')), findsNothing);

    // Pull-to-Reveal: Filter chips are hidden by default, and reveal alongside Spotlight Search
    expect(find.byKey(const Key('workspace_tags_filter_bar')), findsNothing);
    await tester.tap(find.byKey(const Key('dashboard_header_search_toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('workspace_tags_filter_bar')), findsOneWidget);

    final filterBarTopY =
        tester.getTopLeft(find.byKey(const Key('workspace_tags_filter_bar'))).dy;
    final quickAddFabTopY =
        tester.getTopLeft(find.byKey(const Key('dashboard_quick_add_fab'))).dy;
    final quickAddFabBottomY = tester
        .getBottomLeft(find.byKey(const Key('dashboard_quick_add_fab')))
        .dy;
    final centralFabTopY = tester
        .getTopLeft(find.byKey(const Key('central_nav_create_task_button')))
        .dy;
    expect(filterBarTopY, lessThan(quickAddFabTopY));
    expect(quickAddFabBottomY, lessThan(centralFabTopY));

    // Tap Quick Add Floating Button -> opens minimal Glassmorphic BottomSheet -> submit auto-closes sheet
    await tester.tap(find.byKey(const Key('dashboard_quick_add_fab')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('dashboard_quick_add_sheet')), findsOneWidget);
    expect(find.byKey(const Key('dashboard_quick_add_field')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('dashboard_quick_add_field')),
      'تسک سریع تستی #کاری',
    );
    await tester.tap(find.byKey(const Key('dashboard_quick_add_submit')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const Key('dashboard_quick_add_sheet')), findsNothing);
    expect(find.text('تسک سریع تستی'), findsOneWidget);

    // Axis 4: Complete the task -> triggers Haptic + Pop/Ding sound + 100% completion Confetti & Victory sound + Streak increment!
    await tester.tap(find.text('تسک سریع تستی'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(
      SoundAndHapticService.instance.taskCompletionPlayCount,
      greaterThanOrEqualTo(1),
    );
    expect(
      SoundAndHapticService.instance.dailyVictoryPlayCount,
      greaterThanOrEqualTo(1),
    );

    // Verify mathematical symmetry of the 4 navigation tabs around central FAB
    expect(find.byKey(const Key('nav_tab_0')), findsOneWidget);
    expect(find.byKey(const Key('nav_tab_1')), findsOneWidget);
    expect(find.byKey(const Key('nav_tab_2')), findsOneWidget);
    expect(find.byKey(const Key('nav_tab_3')), findsOneWidget);
    final rightWingTab0 = tester.getSize(find.byKey(const Key('nav_tab_0')));
    final rightWingTab1 = tester.getSize(find.byKey(const Key('nav_tab_1')));
    final leftWingTab3 = tester.getSize(find.byKey(const Key('nav_tab_3')));
    final leftWingTab2 = tester.getSize(find.byKey(const Key('nav_tab_2')));
    expect(rightWingTab0.width, closeTo(leftWingTab2.width, 0.1));
    expect(rightWingTab1.width, closeTo(leftWingTab3.width, 0.1));
    expect(rightWingTab0.height, closeTo(leftWingTab2.height, 0.1));

    // Navigate to Reports tab (index 1) — ONLY non-financial habits & calendar + CircleAvatar in Nav Bar
    await tester.tap(find.byKey(const Key('nav_tab_1')));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const Key('nav_bar_user_circle_avatar')), findsOneWidget);
    expect(find.byKey(const Key('reports_pull_to_refresh')), findsOneWidget);
    expect(find.byKey(const Key('top_habits_tracker_card')), findsOneWidget);
    expect(find.text('۵ عادت برتر'), findsOneWidget);
    expect(find.byKey(const Key('monthly_habit_calendar')), findsOneWidget);
    expect(find.byKey(const Key('rial_financial_analytics_card')), findsNothing);
    expect(find.byKey(const Key('reports_today_expense_rial_box')), findsNothing);

    // Tap a day on the interactive monthly habit calendar and verify history sheet opens
    await tester.tap(find.byKey(const Key('habit_calendar_day_1')));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('penalized_day_history_sheet')), findsOneWidget);
    // Dismiss the bottom sheet
    Navigator.of(tester.element(find.byKey(const Key('penalized_day_history_sheet')))).pop();
    await tester.pump(const Duration(milliseconds: 400));

    // Navigate to Financial Balance tab (index 3) — ONLY financial flows & expense charts
    await tester.tap(find.byKey(const Key('nav_tab_3')));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const Key('financial_analytics_pull_to_refresh')), findsOneWidget);
    expect(find.byKey(const Key('rial_financial_analytics_card')), findsOneWidget);
    expect(find.text('جریان‌های مالی و بودجه (ریال)'), findsOneWidget);
    expect(find.byKey(const Key('reports_today_expense_rial_box')), findsOneWidget);
    expect(find.text('هزینه امروز (ریال)'), findsOneWidget);
    expect(find.byKey(const Key('top_habits_tracker_card')), findsNothing);

    // Navigate to Profile tab (index 2) and verify Player Profile Card, XP Store Card & Technical Settings gear button
    await tester.tap(find.byKey(const Key('nav_tab_2')));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byKey(const Key('settings_player_profile_card')), findsOneWidget);
    expect(find.byKey(const Key('xp_store_card')), findsOneWidget);
    expect(find.byKey(const Key('profile_technical_settings_button')), findsOneWidget);

    // Open Technical Settings View via the gear button
    await tester.tap(find.byKey(const Key('profile_technical_settings_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('settings_vacation_mode_switch')), findsOneWidget);
    expect(find.byKey(const Key('settings_smart_render_switch')), findsOneWidget);

    // Enable Vacation Mode in Settings
    await tester.tap(find.byKey(const Key('settings_vacation_mode_switch')));
    await tester.pump(const Duration(seconds: 2));

    // Tap '+ اتصال و افزودن دستگاه جدید' and verify dark Glassmorphic BottomSheet opens
    await tester.ensureVisible(find.byKey(const Key('settings_add_device_button')));
    await tester.tap(find.byKey(const Key('settings_add_device_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('add_device_glass_bottom_sheet')), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const Key('add_device_glass_bottom_sheet')))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Close Technical Settings View to return to Profile screen
    await tester.tap(find.byKey(const Key('technical_settings_back_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap central avatar button on non-dashboard tab to open UserProfilePage
    await tester.tap(find.byKey(const Key('central_nav_create_task_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('user_profile_page')), findsOneWidget);
    expect(find.byKey(const Key('user_profile_avatar_picker')), findsOneWidget);
    expect(find.byKey(const Key('user_profile_gallery_direct_button')), findsOneWidget);
    expect(find.byKey(const Key('user_profile_gamification_card')), findsOneWidget);
    expect(find.byKey(const Key('user_profile_title_badge')), findsOneWidget);
    expect(find.byKey(const Key('user_profile_streak_text')), findsOneWidget);
    expect(find.byKey(const Key('user_profile_freeze_shield_text')), findsOneWidget);
    expect(find.byKey(const Key('user_profile_name_field')), findsOneWidget);

    // Verify old path TextField is gone in the avatar picker sheet and replaced by gallery button
    await tester.tap(find.byKey(const Key('user_profile_avatar_picker')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('user_profile_photo_picker_sheet')), findsOneWidget);
    expect(find.byKey(const Key('pick_avatar_from_gallery_button')), findsOneWidget);
    expect(find.byKey(const Key('custom_avatar_path_input')), findsNothing);
    Navigator.of(tester.element(find.byKey(const Key('user_profile_photo_picker_sheet')))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Update user name in UserProfilePage and save -> verify real-time Dashboard header update
    await tester.enterText(
      find.byKey(const Key('user_profile_name_field')),
      'آرمان',
    );
    await tester.ensureVisible(find.byKey(const Key('user_profile_save_button')));
    await tester.tap(find.byKey(const Key('user_profile_save_button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('user_profile_back_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Return to Dashboard (tab 0) -> verify live header and Vacation Mode Blur UX overlay
    await tester.tap(find.byKey(const Key('nav_tab_0')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('آرمان جان 👋'), findsOneWidget);
    expect(find.byKey(const Key('vacation_mode_blur_overlay')), findsOneWidget);
    expect(find.text('شما در حال استراحت هستید 🌴'), findsOneWidget);
    expect(find.text('شما در حالت استراحت هستید 🌴'), findsOneWidget);
  });
}
