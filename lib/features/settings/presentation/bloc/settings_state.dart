import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';

enum SettingsStatus { initial, loading, success, failure }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final UserSettingsEntity settings;
  final Failure? failure;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings = UserSettingsEntity.defaults,
    this.failure,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    UserSettingsEntity? settings,
    Failure? Function()? failure,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [status, settings, failure];
}
