import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/settings/domain/repositories/settings_repository.dart';

class GetSettingsUseCase implements UseCase<UserSettingsEntity, NoParams> {
  final SettingsRepository repository;

  const GetSettingsUseCase(this.repository);

  @override
  Future<Result<UserSettingsEntity, Failure>> call(NoParams params) {
    return repository.getSettings();
  }
}
