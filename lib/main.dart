import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/di/injection_container.dart';
import 'core/observability/app_bloc_observer.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_mode.dart';
import 'core/theme/providers/theme_provider.dart';
import 'features/navigation/main_screen.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/splash/splash_page.dart';
import 'features/analytics/presentation/bloc/analytics_bloc.dart';
import 'features/analytics/presentation/bloc/analytics_event.dart';
import 'features/analytics/presentation/bloc/financial_analytics_bloc.dart';
import 'features/analytics/presentation/bloc/financial_analytics_event.dart';
import 'features/gamification/presentation/bloc/gamification_bloc.dart';
import 'features/notifications/presentation/bloc/notification_bloc.dart';
import 'features/notifications/presentation/bloc/notification_event.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';
import 'features/settings/presentation/bloc/settings_state.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/tasks/presentation/bloc/task_event.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = const AppBlocObserver();
  await initDependencies(preloadAudioInIsolate: true);

  runApp(
    const ProviderScope(
      child: TaskFlowApp(),
    ),
  );
}

/// ویجت ریشه برنامه با تایپوگرافی سراسری `Vazirmatn` و مدیریت وضعیت چندلایه (BLoC + Riverpod)
class TaskFlowApp extends ConsumerWidget {
  final Widget? home;
  final bool? showSplash;

  const TaskFlowApp({
    super.key,
    this.home,
    this.showSplash,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeProvider);
    final effectiveShowSplash = showSplash ??
        (!Platform.environment.containsKey('FLUTTER_TEST'));

    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskBloc>(
          lazy: false,
          create: (_) => sl<TaskBloc>()..add(const TasksLoadRequested()),
        ),
        BlocProvider<SettingsBloc>(
          lazy: false,
          create: (_) => sl<SettingsBloc>()..add(const SettingsLoadRequested()),
        ),
        BlocProvider<AnalyticsBloc>(
          lazy: false,
          create: (_) => sl<AnalyticsBloc>()..add(const AnalyticsLoadRequested()),
        ),
        BlocProvider<FinancialAnalyticsBloc>(
          lazy: false,
          create: (_) => sl<FinancialAnalyticsBloc>()
            ..add(const FinancialAnalyticsLoadRequested()),
        ),
        BlocProvider<NotificationBloc>(
          lazy: false,
          create: (_) =>
              sl<NotificationBloc>()..add(const NotificationsLoadRequested()),
        ),
        BlocProvider<GamificationBloc>(
          lazy: false,
          create: (_) => sl<GamificationBloc>(),
        ),
      ],
      child: BlocConsumer<SettingsBloc, SettingsState>(
        listenWhen: (prev, curr) =>
            prev.settings.themeMode != curr.settings.themeMode,
        listener: (context, state) {
          if (ref.read(themeProvider) != state.settings.themeMode) {
            ref.read(themeProvider.notifier).state = state.settings.themeMode;
          }
        },
        builder: (context, settingsState) {
          final accentColor = settingsState.settings.accentColor.color;
          final hasSeenOnboarding = settingsState.settings.hasSeenOnboarding;
          final nonSplashTarget = hasSeenOnboarding
              ? const MainScreen()
              : const OnboardingPage();
          final effectiveHome = home ??
              (effectiveShowSplash ? const SplashPage() : nonSplashTarget);
          final (themeData, darkThemeData, flutterThemeMode) =
              switch (appThemeMode) {
            AppThemeMode.signature => (
                AppTheme.lightTheme(primaryColor: accentColor),
                AppTheme.darkTheme(primaryColor: accentColor),
                ThemeMode.dark,
              ),
            AppThemeMode.dark => (
                AppTheme.lightTheme(primaryColor: accentColor),
                AppTheme.darkTheme(primaryColor: accentColor),
                ThemeMode.dark,
              ),
            AppThemeMode.light => (
                AppTheme.lightTheme(primaryColor: accentColor),
                AppTheme.darkTheme(primaryColor: accentColor),
                ThemeMode.light,
              ),
            AppThemeMode.zen => (
                AppTheme.zenTheme(primaryColor: accentColor),
                AppTheme.zenTheme(primaryColor: accentColor),
                ThemeMode.light,
              ),
          };

          return MaterialApp(
            title: 'TaskFlow - زندگی‌ساز',
            debugShowCheckedModeBanner: false,
            theme: themeData,
            darkTheme: darkThemeData,
            themeMode: flutterThemeMode,
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
            ),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fa', 'IR'),
            ],
            locale: const Locale('fa', 'IR'),
            builder: (context, child) {
              return DefaultTextStyle.merge(
                style: const TextStyle(
                  fontFamily: AppTheme.defaultFontFamily,
                  fontFamilyFallback: AppTheme.fontFallbacks,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: effectiveHome,
          );
        },
      ),
    );
  }
}
