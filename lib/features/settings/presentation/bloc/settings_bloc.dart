import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/services/widget_sync_service.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:task_flow/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:task_flow/features/settings/domain/usecases/update_settings_usecase.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_state.dart';
import 'package:uuid/uuid.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final GetSettingsUseCase getSettingsUseCase;
  final UpdateSettingsUseCase updateSettingsUseCase;
  final NotificationRepository? notificationRepository;
  final Uuid _uuid;

  SettingsBloc({
    required this.getSettingsUseCase,
    required this.updateSettingsUseCase,
    this.notificationRepository,
    Uuid uuid = const Uuid(),
  })  : _uuid = uuid,
        super(const SettingsState()) {
    on<SettingsLoadRequested>(_onSettingsLoadRequested);
    on<SettingsDefaultCurrencyChanged>(_onSettingsDefaultCurrencyChanged);
    on<SettingsThemeModeToggled>(_onSettingsThemeModeToggled);
    on<SettingsThemeModeChanged>(_onSettingsThemeModeChanged);
    on<SettingsUserNameUpdated>(_onSettingsUserNameUpdated);
    on<SettingsVacationModeToggled>(_onSettingsVacationModeToggled);
    on<SettingsProfileUpdated>(_onSettingsProfileUpdated);
    on<SettingsDailyStreakSucceeded>(_onSettingsDailyStreakSucceeded);
    on<SettingsDailyStreakFailed>(_onSettingsDailyStreakFailed);
    on<SettingsXpAwarded>(_onSettingsXpAwarded);
    on<SettingsGoldenAuraToggled>(_onSettingsGoldenAuraToggled);
    on<SettingsAccentColorChanged>(_onSettingsAccentColorChanged);
    on<SettingsOnboardingCompleted>(_onSettingsOnboardingCompleted);
    on<SettingsStreakFreezesUpdated>(_onSettingsStreakFreezesUpdated);
    on<SettingsUpdated>(_onSettingsUpdated);
  }

  Future<void> _onSettingsLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await getSettingsUseCase(const NoParams());
    switch (result) {
      case Success(value: final settings):
        emit(
          state.copyWith(
            status: SettingsStatus.success,
            settings: settings,
            failure: () => null,
          ),
        );
        unawaited(WidgetSyncService.instance.updateStreak(settings.streakCount));
      case Err(failure: final f):
        emit(
          state.copyWith(
            status: SettingsStatus.failure,
            failure: () => f,
          ),
        );
    }
  }

  Future<void> _onSettingsDefaultCurrencyChanged(
    SettingsDefaultCurrencyChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(defaultCurrency: event.newCurrency);
    emit(state.copyWith(settings: updated));
    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsThemeModeToggled(
    SettingsThemeModeToggled event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(isDarkMode: event.isDarkMode);
    emit(state.copyWith(settings: updated));
    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsThemeModeChanged(
    SettingsThemeModeChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(themeMode: event.themeMode);
    emit(state.copyWith(settings: updated));
    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsUserNameUpdated(
    SettingsUserNameUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(userName: event.newName);
    emit(state.copyWith(settings: updated));
    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsVacationModeToggled(
    SettingsVacationModeToggled event,
    Emitter<SettingsState> emit,
  ) async {
    final updated =
        state.settings.copyWith(isVacationMode: event.isVacationMode);
    emit(state.copyWith(settings: updated));
    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsProfileUpdated(
    SettingsProfileUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(
      userName: event.userName.trim().isEmpty
          ? state.settings.userName
          : event.userName.trim(),
      userRole: event.userRole.trim(),
      userEmail: event.userEmail.trim(),
      userBio: event.userBio.trim(),
      avatarIndex: event.avatarIndex,
      customAvatarPath: () => event.customAvatarPath,
      isGoldenAuraEnabled:
          event.isGoldenAuraEnabled ?? state.settings.isGoldenAuraEnabled,
    );
    emit(state.copyWith(settings: updated, failure: () => null));
    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsDailyStreakSucceeded(
    SettingsDailyStreakSucceeded event,
    Emitter<SettingsState> emit,
  ) async {
    final updated =
        state.settings.recordSuccessfulStreakDay(dateIso: event.dateIso);
    emit(state.copyWith(settings: updated, failure: () => null));
    unawaited(WidgetSyncService.instance.updateStreak(updated.streakCount));
    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsDailyStreakFailed(
    SettingsDailyStreakFailed event,
    Emitter<SettingsState> emit,
  ) async {
    final updated =
        state.settings.recordFailedStreakDay(dateIso: event.dateIso);
    emit(state.copyWith(settings: updated, failure: () => null));
    unawaited(WidgetSyncService.instance.updateStreak(updated.streakCount));

    if (notificationRepository != null) {
      final notification = AppNotificationEntity(
        id: _uuid.v4(),
        title: 'شکست استریک',
        message: 'استریک شما شکسته شد.',
        type: AppNotificationType.penalty,
        timestamp: DateTime.now().toUtc(),
      );
      await notificationRepository!.saveNotification(notification);
    }

    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsXpAwarded(
    SettingsXpAwarded event,
    Emitter<SettingsState> emit,
  ) async {
    if (event.deltaXp <= 0) return;
    final nextXp = state.settings.effectiveXp + event.deltaXp;
    final updated = state.settings.copyWith(xpPoints: nextXp);
    emit(state.copyWith(settings: updated, failure: () => null));
    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsGoldenAuraToggled(
    SettingsGoldenAuraToggled event,
    Emitter<SettingsState> emit,
  ) async {
    final updated =
        state.settings.copyWith(isGoldenAuraEnabled: event.isEnabled);
    emit(state.copyWith(settings: updated, failure: () => null));
    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsAccentColorChanged(
    SettingsAccentColorChanged event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(accentColor: event.accentColor);
    emit(state.copyWith(settings: updated, failure: () => null));
    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsOnboardingCompleted(
    SettingsOnboardingCompleted event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(hasSeenOnboarding: true);
    emit(state.copyWith(settings: updated, failure: () => null));
    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsStreakFreezesUpdated(
    SettingsStreakFreezesUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    final updated = state.settings.copyWith(streakFreezeCount: event.count);
    emit(state.copyWith(settings: updated, failure: () => null));
    final result = await updateSettingsUseCase(UpdateSettingsParams(updated));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }

  Future<void> _onSettingsUpdated(
    SettingsUpdated event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(settings: event.settings, failure: () => null));
    final result = await updateSettingsUseCase(UpdateSettingsParams(event.settings));
    if (result case Err(failure: final f)) {
      emit(state.copyWith(failure: () => f));
    }
  }
}
