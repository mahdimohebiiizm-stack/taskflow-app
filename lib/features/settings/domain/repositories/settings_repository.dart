import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';

/// Contract for reading and writing user preferences across the application.
abstract interface class SettingsRepository {
  /// Fetches persistent user settings or returns default settings if unset.
  Future<Result<UserSettingsEntity, Failure>> getSettings();

  /// Updates and persists user settings in SQLite.
  Future<Result<UserSettingsEntity, Failure>> updateSettings(
    UserSettingsEntity settings,
  );
}
