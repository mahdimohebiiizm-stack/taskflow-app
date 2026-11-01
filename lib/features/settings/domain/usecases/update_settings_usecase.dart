import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/settings/domain/repositories/settings_repository.dart';

class UpdateSettingsParams extends Equatable {
  final UserSettingsEntity settings;

  const UpdateSettingsParams(this.settings);

  @override
  List<Object?> get props => [settings];
}

class UpdateSettingsUseCase
    implements UseCase<UserSettingsEntity, UpdateSettingsParams> {
  final SettingsRepository repository;

  const UpdateSettingsUseCase(this.repository);

  @override
  Future<Result<UserSettingsEntity, Failure>> call(
    UpdateSettingsParams params,
  ) {
    return repository.updateSettings(params.settings);
  }
}
