import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/theme/app_colors.dart';
import 'package:task_flow/core/theme/app_theme.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/onboarding/onboarding_page.dart';
import 'package:task_flow/features/settings/data/models/user_settings_model.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:task_flow/features/settings/domain/usecases/update_settings_usecase.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/splash/splash_page.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

class MockGetSettingsUseCase extends Mock implements GetSettingsUseCase {}
class MockUpdateSettingsUseCase extends Mock implements UpdateSettingsUseCase {}

void main() {
  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const UpdateSettingsParams(UserSettingsEntity.defaults));
  });

  group('Onboarding Initial Default State & Domain Logic Tests', () {
    test('UserSettingsEntity.defaults strictly has hasSeenOnboarding == false', () {
      expect(UserSettingsEntity.defaults.hasSeenOnboarding, isFalse);
    });

    test('UserSettingsModel strictly defaults hasSeenOnboarding to false on fresh install', () {
      final model = UserSettingsModel.fromKeyValueMap(const {});
      expect(model.hasSeenOnboarding, isFalse);
    });

    test('UserSettingsModel constructor strictly defaults hasSeenOnboarding to false', () {
      const model = UserSettingsModel(
        defaultCurrency: Currency.irt,
        userName: 'مهدی',
      );
      expect(model.hasSeenOnboarding, isFalse);
    });
  });

  group('Zen Mode Palette Tests', () {
    test('Zen theme has warm sand background and cream surface', () {
      expect(AppColors.backgroundZen, equals(const Color(0xFFE8E2D5)));
      expect(AppColors.surfaceZen, equals(const Color(0xFFF2EFE8)));
      expect(AppColors.textZen, equals(const Color(0xFF4A443A)));
      expect(AppColors.textZenSecondary, equals(const Color(0xFF8E867A)));
      expect(AppColors.navBarZen, equals(const Color(0xFFF2EFE8)));

      final zenTheme = AppTheme.zenTheme();
      expect(zenTheme.scaffoldBackgroundColor, equals(const Color(0xFFE8E2D5)));
      expect(zenTheme.colorScheme.surface, equals(const Color(0xFFF2EFE8)));
      expect(zenTheme.cardTheme.color, equals(const Color(0xFFF2EFE8)));
    });
  });

  group('SplashPage Tests & Startup Routing', () {
    testWidgets('renders cinematic logo asset and brand text "زندگی‌ساز"',
        (WidgetTester tester) async {
      final mockGetSettings = MockGetSettingsUseCase();
      final mockUpdateSettings = MockUpdateSettingsUseCase();
      when(() => mockGetSettings(any())).thenAnswer(
        (_) async => const Success(UserSettingsEntity.defaults),
      );

      final settingsBloc = SettingsBloc(
        getSettingsUseCase: mockGetSettings,
        updateSettingsUseCase: mockUpdateSettings,
      )..add(const SettingsLoadRequested());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<SettingsBloc>.value(
            value: settingsBloc,
            child: const SplashPage(
              animationDuration: Duration(milliseconds: 300),
              autoNavigate: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('زندگی‌ساز'), findsOneWidget);
      expect(find.byKey(const Key('splash_app_logo_image')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('routes to OnboardingPage on a fresh install when has_seen_onboarding == false',
        (WidgetTester tester) async {
      final mockGetSettings = MockGetSettingsUseCase();
      final mockUpdateSettings = MockUpdateSettingsUseCase();
      when(() => mockGetSettings(any())).thenAnswer(
        (_) async => const Success(
          UserSettingsEntity(
            defaultCurrency: Currency.irt,
            userName: 'مهدی',
            hasSeenOnboarding: false,
          ),
        ),
      );

      final settingsBloc = SettingsBloc(
        getSettingsUseCase: mockGetSettings,
        updateSettingsUseCase: mockUpdateSettings,
      )..add(const SettingsLoadRequested());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BlocProvider<SettingsBloc>.value(
              value: settingsBloc,
              child: const SplashPage(
                animationDuration: Duration(milliseconds: 100),
                holdDuration: Duration(milliseconds: 50),
                autoNavigate: true,
              ),
            ),
          ),
        ),
      );

      // Wait for splash animations and transition to complete
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify that the app navigated to OnboardingPage
      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text('بوم سفید شما'), findsOneWidget);
    });
  });

  group('OnboardingPage Tests', () {
    testWidgets('renders 4 swipeable slides including gestures & tools and completes onboarding on "شروع"',
        (WidgetTester tester) async {
      final mockGetSettings = MockGetSettingsUseCase();
      final mockUpdateSettings = MockUpdateSettingsUseCase();
      when(() => mockGetSettings(any())).thenAnswer(
        (_) async => const Success(UserSettingsEntity.defaults),
      );
      when(() => mockUpdateSettings(any())).thenAnswer(
        (inv) async => Success(
          (inv.positionalArguments[0] as UpdateSettingsParams).settings,
        ),
      );

      final settingsBloc = SettingsBloc(
        getSettingsUseCase: mockGetSettings,
        updateSettingsUseCase: mockUpdateSettings,
      )..add(const SettingsLoadRequested());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: BlocProvider<SettingsBloc>.value(
              value: settingsBloc,
              child: OnboardingPage(
                nextScreenBuilder: (_) => const Scaffold(
                  body: Text('داشبورد اصلی'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Slide 1: بوم سفید شما
      expect(find.text('بوم سفید شما'), findsOneWidget);
      expect(find.text('ادامه'), findsOneWidget);
      expect(find.text('رد کردن'), findsOneWidget);

      // Tap "ادامه" to go to slide 2
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Slide 2: تمرکز عمیق
      expect(find.text('تمرکز عمیق'), findsOneWidget);

      // Tap "ادامه" to go to slide 3: راهنمای ژست‌های حرکتی و ابزارها
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Slide 3: Gestures & Tools
      expect(find.text('راهنمای ژست‌های حرکتی و ابزارها'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_gesture_swipe_right')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_gesture_swipe_left')), findsOneWidget);
      expect(find.byKey(const Key('onboarding_gesture_search_filter')), findsOneWidget);
      expect(find.text('سوایپ به راست روی تسک'), findsOneWidget);
      expect(find.text('سوایپ به چپ روی تسک'), findsOneWidget);
      expect(find.text('ابزارهای نوار بالا: جستجو و فیلتر'), findsOneWidget);

      // Tap "ادامه" to go to slide 4: رشد و پاداش
      await tester.tap(find.byKey(const Key('onboarding_next_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Slide 4: رشد و پاداش
      expect(find.text('رشد و پاداش'), findsOneWidget);
      expect(find.byKey(const Key('onboarding_get_started_button')), findsOneWidget);
      expect(find.text('شروع'), findsOneWidget);

      // Tap "شروع"
      await tester.tap(find.byKey(const Key('onboarding_get_started_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('داشبورد اصلی'), findsOneWidget);
      verify(() => mockUpdateSettings(any())).called(1);
    });
  });
}
