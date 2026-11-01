import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_tasks_usecase.dart';

/// Snapshot containing both today's/all tasks and user profile settings
/// (titles, streak count, streak freeze shields, XP) fetched in parallel.
class ConcurrentDashboardSnapshot {
  final Result<List<TaskEntity>, Failure> tasksResult;
  final Result<UserSettingsEntity, Failure> settingsResult;

  const ConcurrentDashboardSnapshot({
    required this.tasksResult,
    required this.settingsResult,
  });
}

/// Service that enforces strict concurrent execution (`Future.wait`) when
/// fetching dashboard tasks and user profile/gamification settings in parallel.
class ConcurrentDashboardLoader {
  final GetTasksUseCase _getTasksUseCase;
  final GetSettingsUseCase _getSettingsUseCase;

  const ConcurrentDashboardLoader({
    required GetTasksUseCase getTasksUseCase,
    required GetSettingsUseCase getSettingsUseCase,
  })  : _getTasksUseCase = getTasksUseCase,
        _getSettingsUseCase = getSettingsUseCase;

  /// Fetches tasks and user settings (titles, streak, freeze shields) simultaneously
  /// using `Future.wait` so the UI never waits on sequential I/O.
  Future<ConcurrentDashboardSnapshot> loadConcurrently({
    TaskStatus? statusFilter,
    DateTime? scheduledDate,
  }) async {
    final results = await Future.wait<Object>([
      _getTasksUseCase(
        GetTasksParams(
          status: statusFilter,
          scheduledDate: scheduledDate,
        ),
      ),
      _getSettingsUseCase(const NoParams()),
    ]);

    return ConcurrentDashboardSnapshot(
      tasksResult: results[0] as Result<List<TaskEntity>, Failure>,
      settingsResult: results[1] as Result<UserSettingsEntity, Failure>,
    );
  }
}
