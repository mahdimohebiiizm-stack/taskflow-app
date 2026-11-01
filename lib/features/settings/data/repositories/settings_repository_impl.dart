import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:task_flow/features/settings/data/models/user_settings_model.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  const SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<Result<UserSettingsEntity, Failure>> getSettings() async {
    try {
      final model = await localDataSource.getSettings();
      return Success(model);
    } on LocalDatabaseException catch (e) {
      return Err(DatabaseFailure(message: e.message));
    } catch (e) {
      return Err(DatabaseFailure(message: 'Unexpected error loading settings: $e'));
    }
  }

  @override
  Future<Result<UserSettingsEntity, Failure>> updateSettings(
    UserSettingsEntity settings,
  ) async {
    try {
      final model = UserSettingsModel.fromEntity(settings);
      final saved = await localDataSource.saveSettings(model);
      return Success(saved);
    } on LocalDatabaseException catch (e) {
      return Err(DatabaseFailure(message: e.message));
    } catch (e) {
      return Err(DatabaseFailure(message: 'Unexpected error saving settings: $e'));
    }
  }
}
