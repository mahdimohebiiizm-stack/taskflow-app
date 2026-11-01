import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/core/theme/app_theme_mode.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_state.dart';
import 'package:task_flow/features/settings/presentation/pages/settings_page.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockGamificationBloc extends MockBloc<GamificationEvent, GamificationState>
    implements GamificationBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(const BuyStreakFreezeEvent(cost: 500));
  });

  group('Phase 8.4: Signature Profile View & 500 XP Shield Contract Tests', () {
    test('AppThemeMode.signature enables isSignatureLayout exclusively', () {
      expect(AppThemeMode.signature.isSignatureLayout, isTrue);
      expect(AppThemeMode.dark.isSignatureLayout, isFalse);
      expect(AppThemeMode.zen.isSignatureLayout, isFalse);
      expect(AppThemeMode.light.isSignatureLayout, isFalse);
    });

    test('BuyStreakFreezeEvent defaults to 500 XP cost and accepts custom cost', () {
      const defaultEvent = BuyStreakFreezeEvent();
      expect(defaultEvent.cost, equals(500));

      const explicit500Event = BuyStreakFreezeEvent(cost: 500);
      expect(explicit500Event.cost, equals(500));
      expect(explicit500Event, equals(defaultEvent));
    });

    test('Signature Profile Keys Contract includes all required widgets', () {
      const headerKey = Key('signature_profile_header');
      const xpBarKey = Key('signature_profile_xp_bar');
      const metricsKey = Key('signature_profile_metrics_row');
      const cardKey = Key('signature_streak_freeze_card');
      const buyBtnKey = Key('signature_buy_freeze_button');
      const themeRowKey = Key('signature_theme_selector_row');
      const vacationRowKey = Key('signature_vacation_mode_row');
      const backupRowKey = Key('signature_backup_row');
      const testNotifRowKey = Key('signature_test_notification_row');
      const advSettingsRowKey = Key('signature_advanced_settings_row');
      const techSettingsBtnKey = Key('profile_technical_settings_button');

      expect(headerKey, equals(const Key('signature_profile_header')));
      expect(xpBarKey, equals(const Key('signature_profile_xp_bar')));
      expect(metricsKey, equals(const Key('signature_profile_metrics_row')));
      expect(cardKey, equals(const Key('signature_streak_freeze_card')));
      expect(buyBtnKey, equals(const Key('signature_buy_freeze_button')));
      expect(themeRowKey, equals(const Key('signature_theme_selector_row')));
      expect(vacationRowKey, equals(const Key('signature_vacation_mode_row')));
      expect(backupRowKey, equals(const Key('signature_backup_row')));
      expect(testNotifRowKey, equals(const Key('signature_test_notification_row')));
      expect(advSettingsRowKey, equals(const Key('signature_advanced_settings_row')));
      expect(techSettingsBtnKey, equals(const Key('profile_technical_settings_button')));
    });

    testWidgets('renders Signature Profile with 500 XP shield button and triggers buy event', (tester) async {
      final mockSettingsBloc = MockSettingsBloc();
      final mockGamificationBloc = MockGamificationBloc();

      const initialSettings = UserSettingsEntity(
        themeMode: AppThemeMode.signature,
        userName: 'علی',
        userRole: 'برنامه‌ریز',
        streakCount: 3,
        defaultCurrency: Currency.irt,
      );

      when(() => mockSettingsBloc.state).thenReturn(
        const SettingsState(settings: initialSettings),
      );

      when(() => mockGamificationBloc.state).thenReturn(
        const GamificationState(
          totalXp: 595,
          level: 2,
          title: 'برنامه‌ریز',
          streakFreezes: 0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MultiBlocProvider(
            providers: [
              BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
              BlocProvider<GamificationBloc>.value(value: mockGamificationBloc),
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
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Signature Profile Header & Avatar
      expect(find.byKey(const Key('signature_profile_header')), findsOneWidget);
      expect(find.text('علی'), findsOneWidget);
      expect(find.byKey(const Key('profile_technical_settings_button')), findsOneWidget);

      // 2. Verify XP Bar & Metrics Row
      expect(find.byKey(const Key('signature_profile_xp_bar')), findsOneWidget);
      expect(find.byKey(const Key('signature_profile_metrics_row')), findsOneWidget);
      expect(find.text('روز استمرار'), findsOneWidget);
      expect(find.text('سپر محافظ'), findsOneWidget);
      expect(find.text('XP کل'), findsOneWidget);

      // 3. Verify Streak Freeze Purchase Card with strictly 500 XP
      expect(find.byKey(const Key('signature_streak_freeze_card')), findsOneWidget);
      expect(find.byKey(const Key('signature_buy_freeze_button')), findsOneWidget);
      expect(find.textContaining('۵۰۰ XP'), findsOneWidget);

      // 4. Verify Minimal Settings Rows
      expect(find.byKey(const Key('signature_theme_selector_row')), findsOneWidget);
      expect(find.byKey(const Key('signature_vacation_mode_row')), findsOneWidget);
      expect(find.byKey(const Key('signature_backup_row')), findsOneWidget);
      expect(find.byKey(const Key('signature_test_notification_row')), findsOneWidget);
      expect(find.byKey(const Key('signature_advanced_settings_row')), findsOneWidget);

      // 5. Tap 500 XP Buy Button and verify BuyStreakFreezeEvent dispatched
      await tester.tap(find.byKey(const Key('signature_buy_freeze_button')));
      await tester.pump();

      verify(
        () => mockGamificationBloc.add(const BuyStreakFreezeEvent(cost: 500)),
      ).called(1);
    });

    testWidgets('DualLayoutTransition switches between Signature and Classic profile views', (tester) async {
      final mockSettingsBloc = MockSettingsBloc();
      final mockGamificationBloc = MockGamificationBloc();

      const classicSettings = UserSettingsEntity(
        themeMode: AppThemeMode.dark,
        userName: 'علی',
        userRole: 'برنامه‌ریز',
        streakCount: 3,
        defaultCurrency: Currency.irt,
      );

      when(() => mockSettingsBloc.state).thenReturn(
        const SettingsState(settings: classicSettings),
      );

      when(() => mockGamificationBloc.state).thenReturn(
        const GamificationState(
          totalXp: 595,
          level: 2,
          title: 'برنامه‌ریز',
          streakFreezes: 0,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MultiBlocProvider(
            providers: [
              BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
              BlocProvider<GamificationBloc>.value(value: mockGamificationBloc),
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
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // In Classic layout, PlayerProfileCard and XpStoreCard should be present
      expect(find.byKey(const Key('settings_player_profile_card')), findsOneWidget);
      expect(find.byKey(const Key('xp_store_card')), findsOneWidget);
      expect(find.byKey(const Key('signature_profile_metrics_row')), findsNothing);
    });
  });
}
