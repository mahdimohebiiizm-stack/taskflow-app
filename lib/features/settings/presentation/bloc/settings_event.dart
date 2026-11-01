import 'package:equatable/equatable.dart';
import 'package:task_flow/core/theme/app_accent_color.dart';
import 'package:task_flow/core/theme/app_theme_mode.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

final class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

final class SettingsDefaultCurrencyChanged extends SettingsEvent {
  final Currency newCurrency;

  const SettingsDefaultCurrencyChanged(this.newCurrency);

  @override
  List<Object?> get props => [newCurrency];
}

final class SettingsThemeModeToggled extends SettingsEvent {
  final bool isDarkMode;

  const SettingsThemeModeToggled(this.isDarkMode);

  @override
  List<Object?> get props => [isDarkMode];
}

final class SettingsThemeModeChanged extends SettingsEvent {
  final AppThemeMode themeMode;

  const SettingsThemeModeChanged(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

final class SettingsUserNameUpdated extends SettingsEvent {
  final String newName;

  const SettingsUserNameUpdated(this.newName);

  @override
  List<Object?> get props => [newName];
}

final class SettingsVacationModeToggled extends SettingsEvent {
  final bool isVacationMode;

  const SettingsVacationModeToggled(this.isVacationMode);

  @override
  List<Object?> get props => [isVacationMode];
}

final class SettingsProfileUpdated extends SettingsEvent {
  final String userName;
  final String userRole;
  final String userEmail;
  final String userBio;
  final int avatarIndex;
  final String? customAvatarPath;
  final bool? isGoldenAuraEnabled;

  const SettingsProfileUpdated({
    required this.userName,
    required this.userRole,
    required this.userEmail,
    required this.userBio,
    required this.avatarIndex,
    this.customAvatarPath,
    this.isGoldenAuraEnabled,
  });

  @override
  List<Object?> get props => [
        userName,
        userRole,
        userEmail,
        userBio,
        avatarIndex,
        customAvatarPath,
        isGoldenAuraEnabled,
      ];
}

/// Dispatched when the user completes 100% of their daily tasks without penalties.
/// Increments `streakCount`, grants XP, and awards a Streak Freeze shield every 7 consecutive days.
final class SettingsDailyStreakSucceeded extends SettingsEvent {
  final String? dateIso;

  const SettingsDailyStreakSucceeded({this.dateIso});

  @override
  List<Object?> get props => [dateIso];
}

/// Dispatched when a day ends with unfinished/penalized tasks.
/// Consumes 1 Streak Freeze shield if available (preserving `streakCount`), or resets `streakCount` to 0.
final class SettingsDailyStreakFailed extends SettingsEvent {
  final String? dateIso;

  const SettingsDailyStreakFailed({this.dateIso});

  @override
  List<Object?> get props => [dateIso];
}

/// Dispatched when XP is awarded for individual task completion or gamification milestones.
final class SettingsXpAwarded extends SettingsEvent {
  final int deltaXp;

  const SettingsXpAwarded(this.deltaXp);

  @override
  List<Object?> get props => [deltaXp];
}

/// Toggles the Golden Glowing Aura around the avatar (unlocked at 30+ streak days).
final class SettingsGoldenAuraToggled extends SettingsEvent {
  final bool isEnabled;

  const SettingsGoldenAuraToggled(this.isEnabled);

  @override
  List<Object?> get props => [isEnabled];
}

/// Dispatched when the user selects a new brand accent color.
final class SettingsAccentColorChanged extends SettingsEvent {
  final AppAccentColor accentColor;

  const SettingsAccentColorChanged(this.accentColor);

  @override
  List<Object?> get props => [accentColor];
}

/// Dispatched when first-time onboarding is concluded ("شروع" button).
final class SettingsOnboardingCompleted extends SettingsEvent {
  const SettingsOnboardingCompleted();
}

/// Dispatched when streak freeze count is updated.
final class SettingsStreakFreezesUpdated extends SettingsEvent {
  final int count;

  const SettingsStreakFreezesUpdated(this.count);

  @override
  List<Object?> get props => [count];
}

/// Dispatched when full user settings are updated.
final class SettingsUpdated extends SettingsEvent {
  final UserSettingsEntity settings;

  const SettingsUpdated(this.settings);

  @override
  List<Object?> get props => [settings];
}


