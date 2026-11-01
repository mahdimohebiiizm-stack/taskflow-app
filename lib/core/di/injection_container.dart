import 'package:get_it/get_it.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:task_flow/core/concurrency/concurrent_dashboard_loader.dart';
import 'package:task_flow/core/notifications/notification_service.dart';
import 'package:task_flow/core/services/backup_service.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/core/services/widget_sync_service.dart';
import 'package:task_flow/core/sync/background_sync_service.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:task_flow/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';
import 'package:task_flow/features/tasks/domain/usecases/add_task_expense_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/penalize_day_tasks_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/revert_day_penalty_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/toggle_sub_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/transition_task_status_usecase.dart';
import 'package:task_flow/features/analytics/data/datasources/analytics_local_datasource.dart';
import 'package:task_flow/features/analytics/data/repositories/analytics_repository_impl.dart';
import 'package:task_flow/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:task_flow/features/analytics/domain/usecases/get_analytics_summary_usecase.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_bloc.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/notifications/data/datasources/notification_local_datasource.dart';
import 'package:task_flow/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:task_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:task_flow/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:task_flow/features/settings/domain/repositories/settings_repository.dart';
import 'package:task_flow/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:task_flow/features/settings/domain/usecases/update_settings_usecase.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/tasks/data/datasources/focus_session_local_datasource.dart';
import 'package:task_flow/features/tasks/data/datasources/xp_ledger_local_datasource.dart';
import 'package:task_flow/features/tasks/data/repositories/focus_session_repository_impl.dart';
import 'package:task_flow/features/tasks/data/repositories/xp_ledger_repository_impl.dart';
import 'package:task_flow/features/tasks/domain/repositories/focus_session_repository.dart';
import 'package:task_flow/features/tasks/domain/repositories/xp_ledger_repository.dart';
import 'package:task_flow/features/tasks/domain/services/ticker.dart';
import 'package:task_flow/features/tasks/presentation/bloc/focus_timer_bloc.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';

/// Global Service Locator instance.
final GetIt sl = GetIt.instance;

/// Initializes Dependency Injection container across Clean Architecture layers.
///
/// Uses strict parallel bootstrapping (`Future.wait`) to concurrently initialize
/// SQLite, local notifications, and pre-cached WAV audio buffers (Ding, Victory, Pomodoro).
Future<void> initDependencies({
  Database? overrideDatabase,
  String? databasePath,
  DatabaseFactory? databaseFactory,
  bool preloadAudioInIsolate = false,
}) async {
  // ===========================================================================
  // 1. Infrastructure / External — Parallel Initialization via Future.wait
  // ===========================================================================
  final Future<Database> dbFuture = sl.isRegistered<Database>()
      ? Future<Database>.value(sl<Database>())
      : (overrideDatabase != null
          ? Future<Database>.value(overrideDatabase)
          : AppDatabase.open(
              databasePath: databasePath,
              databaseFactory: databaseFactory,
            ));

  final Future<NotificationService> notificationFuture =
      sl.isRegistered<NotificationService>()
          ? Future<NotificationService>.value(sl<NotificationService>())
          : () async {
              final notificationService = NotificationService();
              await notificationService.initialize();
              return notificationService;
            }();

  final Future<void> audioPreloadFuture = SoundAndHapticService.instance
      .preloadAudioBuffers(useIsolate: preloadAudioInIsolate);

  final initResults = await Future.wait<Object?>([
    dbFuture,
    notificationFuture,
    audioPreloadFuture,
  ]);

  if (!sl.isRegistered<Database>()) {
    sl.registerSingleton<Database>(initResults[0] as Database);
  }

  if (!sl.isRegistered<NotificationService>()) {
    sl.registerSingleton<NotificationService>(
      initResults[1] as NotificationService,
    );
  }

  if (!sl.isRegistered<BackgroundSyncService>()) {
    sl.registerLazySingleton<BackgroundSyncService>(
      () => BackgroundSyncService(),
    );
  }

  if (!sl.isRegistered<SoundAndHapticService>()) {
    sl.registerSingleton<SoundAndHapticService>(
      SoundAndHapticService.instance,
    );
  }

  if (!sl.isRegistered<BackupService>()) {
    sl.registerLazySingleton<BackupService>(
      () => BackupService(database: sl<Database>()),
    );
  }

  if (!sl.isRegistered<WidgetSyncService>()) {
    sl.registerSingleton<WidgetSyncService>(
      WidgetSyncService.instance,
    );
  }

  // ===========================================================================
  // 2. Data Layer — DataSources & Repositories (Stateless Lazy Singletons)
  // ===========================================================================
  if (!sl.isRegistered<TaskLocalDataSource>()) {
    sl.registerLazySingleton<TaskLocalDataSource>(
      () => TaskLocalDataSourceImpl(database: sl<Database>()),
    );
  }

  if (!sl.isRegistered<TaskRepository>()) {
    sl.registerLazySingleton<TaskRepository>(
      () => TaskRepositoryImpl(localDataSource: sl<TaskLocalDataSource>()),
    );
  }

  if (!sl.isRegistered<SettingsLocalDataSource>()) {
    sl.registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSourceImpl(database: sl<Database>()),
    );
  }

  if (!sl.isRegistered<SettingsRepository>()) {
    sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(localDataSource: sl<SettingsLocalDataSource>()),
    );
  }

  if (!sl.isRegistered<AnalyticsLocalDataSource>()) {
    sl.registerLazySingleton<AnalyticsLocalDataSource>(
      () => AnalyticsLocalDataSourceImpl(
        database: sl<Database>(),
      ),
    );
  }

  if (!sl.isRegistered<AnalyticsRepository>()) {
    sl.registerLazySingleton<AnalyticsRepository>(
      () => AnalyticsRepositoryImpl(localDataSource: sl<AnalyticsLocalDataSource>()),
    );
  }

  if (!sl.isRegistered<FocusSessionLocalDataSource>()) {
    sl.registerLazySingleton<FocusSessionLocalDataSource>(
      () => FocusSessionLocalDataSourceImpl(database: sl<Database>()),
    );
  }

  if (!sl.isRegistered<FocusSessionRepository>()) {
    sl.registerLazySingleton<FocusSessionRepository>(
      () => FocusSessionRepositoryImpl(localDataSource: sl<FocusSessionLocalDataSource>()),
    );
  }

  if (!sl.isRegistered<XpLedgerLocalDataSource>()) {
    sl.registerLazySingleton<XpLedgerLocalDataSource>(
      () => XpLedgerLocalDataSourceImpl(database: sl<Database>()),
    );
  }

  if (!sl.isRegistered<XpLedgerRepository>()) {
    sl.registerLazySingleton<XpLedgerRepository>(
      () => XpLedgerRepositoryImpl(localDataSource: sl<XpLedgerLocalDataSource>()),
    );
  }

  if (!sl.isRegistered<NotificationLocalDataSource>()) {
    sl.registerLazySingleton<NotificationLocalDataSource>(
      () => NotificationLocalDataSourceImpl(database: sl<Database>()),
    );
  }

  if (!sl.isRegistered<NotificationRepository>()) {
    sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(
        localDataSource: sl<NotificationLocalDataSource>(),
      ),
    );
  }

  // ===========================================================================
  // 3. Domain Layer — UseCases (Stateless Lazy Singletons)
  // ===========================================================================
  if (!sl.isRegistered<GetTasksUseCase>()) {
    sl.registerLazySingleton<GetTasksUseCase>(
      () => GetTasksUseCase(sl<TaskRepository>()),
    );
  }

  if (!sl.isRegistered<CreateTaskUseCase>()) {
    sl.registerLazySingleton<CreateTaskUseCase>(
      () => CreateTaskUseCase(sl<TaskRepository>()),
    );
  }

  if (!sl.isRegistered<TransitionTaskStatusUseCase>()) {
    sl.registerLazySingleton<TransitionTaskStatusUseCase>(
      () => TransitionTaskStatusUseCase(sl<TaskRepository>()),
    );
  }

  if (!sl.isRegistered<ToggleSubTaskUseCase>()) {
    sl.registerLazySingleton<ToggleSubTaskUseCase>(
      () => ToggleSubTaskUseCase(sl<TaskRepository>()),
    );
  }

  if (!sl.isRegistered<DeleteTaskUseCase>()) {
    sl.registerLazySingleton<DeleteTaskUseCase>(
      () => DeleteTaskUseCase(sl<TaskRepository>()),
    );
  }

  if (!sl.isRegistered<AddTaskExpenseUseCase>()) {
    sl.registerLazySingleton<AddTaskExpenseUseCase>(
      () => AddTaskExpenseUseCase(sl<TaskRepository>()),
    );
  }

  if (!sl.isRegistered<GetSettingsUseCase>()) {
    sl.registerLazySingleton<GetSettingsUseCase>(
      () => GetSettingsUseCase(sl<SettingsRepository>()),
    );
  }

  if (!sl.isRegistered<UpdateSettingsUseCase>()) {
    sl.registerLazySingleton<UpdateSettingsUseCase>(
      () => UpdateSettingsUseCase(sl<SettingsRepository>()),
    );
  }

  if (!sl.isRegistered<GetAnalyticsSummaryUseCase>()) {
    sl.registerLazySingleton<GetAnalyticsSummaryUseCase>(
      () => GetAnalyticsSummaryUseCase(sl<AnalyticsRepository>()),
    );
  }

  if (!sl.isRegistered<PenalizeDayTasksUseCase>()) {
    sl.registerLazySingleton<PenalizeDayTasksUseCase>(
      () => PenalizeDayTasksUseCase(sl<TaskRepository>()),
    );
  }

  if (!sl.isRegistered<RevertDayPenaltyUseCase>()) {
    sl.registerLazySingleton<RevertDayPenaltyUseCase>(
      () => RevertDayPenaltyUseCase(sl<TaskRepository>()),
    );
  }

  if (!sl.isRegistered<ConcurrentDashboardLoader>()) {
    sl.registerLazySingleton<ConcurrentDashboardLoader>(
      () => ConcurrentDashboardLoader(
        getTasksUseCase: sl<GetTasksUseCase>(),
        getSettingsUseCase: sl<GetSettingsUseCase>(),
      ),
    );
  }

  // ===========================================================================
  // 4. Presentation Layer — BLoC (Factory: new instance per screen lifecycle)
  // ===========================================================================
  if (!sl.isRegistered<FinancialAnalyticsBloc>()) {
    sl.registerLazySingleton<FinancialAnalyticsBloc>(
      () => FinancialAnalyticsBloc(
        getTasksUseCase: sl<GetTasksUseCase>(),
      ),
    );
  }

  if (!sl.isRegistered<GamificationBloc>()) {
    sl.registerLazySingleton<GamificationBloc>(
      () => GamificationBloc(
        notificationRepository: sl.isRegistered<NotificationRepository>()
            ? sl<NotificationRepository>()
            : null,
        notificationBloc: sl.isRegistered<NotificationBloc>()
            ? sl<NotificationBloc>()
            : null,
      ),
    );
  }

  if (!sl.isRegistered<TaskBloc>()) {
    sl.registerFactory<TaskBloc>(
      () => TaskBloc(
        getTasksUseCase: sl<GetTasksUseCase>(),
        createTaskUseCase: sl<CreateTaskUseCase>(),
        transitionTaskStatusUseCase: sl<TransitionTaskStatusUseCase>(),
        toggleSubTaskUseCase: sl<ToggleSubTaskUseCase>(),
        deleteTaskUseCase: sl<DeleteTaskUseCase>(),
        addTaskExpenseUseCase: sl<AddTaskExpenseUseCase>(),
        penalizeDayTasksUseCase: sl<PenalizeDayTasksUseCase>(),
        revertDayPenaltyUseCase: sl<RevertDayPenaltyUseCase>(),
        taskRepository: sl<TaskRepository>(),
        notificationService: sl<NotificationService>(),
        notificationRepository: sl.isRegistered<NotificationRepository>()
            ? sl<NotificationRepository>()
            : null,
        notificationBloc: sl.isRegistered<NotificationBloc>()
            ? sl<NotificationBloc>()
            : null,
        financialAnalyticsBloc: sl.isRegistered<FinancialAnalyticsBloc>()
            ? sl<FinancialAnalyticsBloc>()
            : null,
        gamificationBloc: sl.isRegistered<GamificationBloc>()
            ? sl<GamificationBloc>()
            : null,
        soundService: sl<SoundAndHapticService>(),
        widgetSyncService: sl<WidgetSyncService>(),
        backgroundSyncService: sl<BackgroundSyncService>(),
      ),
    );
  }

  if (!sl.isRegistered<SettingsBloc>()) {
    sl.registerFactory<SettingsBloc>(
      () => SettingsBloc(
        getSettingsUseCase: sl<GetSettingsUseCase>(),
        updateSettingsUseCase: sl<UpdateSettingsUseCase>(),
        notificationRepository: sl.isRegistered<NotificationRepository>()
            ? sl<NotificationRepository>()
            : null,
      ),
    );
  }

  if (!sl.isRegistered<AnalyticsBloc>()) {
    sl.registerFactory<AnalyticsBloc>(
      () => AnalyticsBloc(
        getAnalyticsSummaryUseCase: sl<GetAnalyticsSummaryUseCase>(),
      ),
    );
  }

  if (!sl.isRegistered<FocusTimerBloc>()) {
    sl.registerFactory<FocusTimerBloc>(
      () => FocusTimerBloc(
        ticker: const Ticker(),
        focusSessionRepository: sl<FocusSessionRepository>(),
        xpLedgerRepository: sl<XpLedgerRepository>(),
        notificationRepository: sl.isRegistered<NotificationRepository>()
            ? sl<NotificationRepository>()
            : null,
        settingsBloc:
            sl.isRegistered<SettingsBloc>() ? sl<SettingsBloc>() : null,
      ),
    );
  }

  if (!sl.isRegistered<NotificationBloc>()) {
    sl.registerLazySingleton<NotificationBloc>(
      () => NotificationBloc(
        repository: sl<NotificationRepository>(),
      ),
    );
  }

}

/// Resets the Service Locator and closes any active database connection.
/// Designed for clean teardown between test suites.
Future<void> resetDependencies({bool closeDatabase = true}) async {
  if (sl.isRegistered<NotificationService>()) {
    await sl<NotificationService>().dispose();
  }
  if (sl.isRegistered<SoundAndHapticService>()) {
    await sl<SoundAndHapticService>().dispose();
  }
  if (closeDatabase && sl.isRegistered<Database>()) {
    final db = sl<Database>();
    if (db.isOpen) {
      await db.close();
    }
  }
  await sl.reset();
}
