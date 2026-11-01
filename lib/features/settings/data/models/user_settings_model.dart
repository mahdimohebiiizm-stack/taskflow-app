import 'package:task_flow/core/theme/app_accent_color.dart';
import 'package:task_flow/core/theme/app_theme_mode.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

class UserSettingsModel extends UserSettingsEntity {
  static const String keyDefaultCurrency = 'default_currency';
  static const String keyAppThemeMode = 'app_theme_mode';
  static const String keyIsDarkMode = 'is_dark_mode';
  static const String keyUserName = 'user_name';
  static const String keyAccentColor = 'accent_color';
  static const String keyIsVacationMode = 'is_vacation_mode';
  static const String keyUserRole = 'user_role';
  static const String keyUserEmail = 'user_email';
  static const String keyUserBio = 'user_bio';
  static const String keyAvatarIndex = 'avatar_index';
  static const String keyCustomAvatarPath = 'custom_avatar_path';
  static const String keyStreakCount = 'streak_count';
  static const String keyStreakFreezeCount = 'streak_freeze_count';
  static const String keyStreakFreezes = 'streak_freezes';
  static const String keyXpPoints = 'xp_points';
  static const String keyLastStreakDate = 'last_streak_date';
  static const String keyIsGoldenAuraEnabled = 'is_golden_aura_enabled';
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';

  const UserSettingsModel({
    required super.defaultCurrency,
    super.themeMode,
    super.isDarkMode,
    required super.userName,
    super.accentColor = AppAccentColor.blue,
    super.isVacationMode = false,
    super.userRole = 'مدیر سیستم • سازماندهی پروژه‌ها',
    super.userEmail = 'mahdi@taskflow.ir',
    super.userBio = 'تمرکز بر بهره‌وری روزانه و نظم شخصی',
    super.avatarIndex = 0,
    super.customAvatarPath,
    super.streakCount = 0,
    super.streakFreezeCount = 0,
    super.streakFreezes = 0,
    super.xpPoints = 0,
    super.lastStreakDate,
    super.isGoldenAuraEnabled = true,
    super.hasSeenOnboarding = false,
  });

  factory UserSettingsModel.fromEntity(UserSettingsEntity entity) {
    return UserSettingsModel(
      defaultCurrency: entity.defaultCurrency,
      themeMode: entity.themeMode,
      userName: entity.userName,
      accentColor: entity.accentColor,
      isVacationMode: entity.isVacationMode,
      userRole: entity.userRole,
      userEmail: entity.userEmail,
      userBio: entity.userBio,
      avatarIndex: entity.avatarIndex,
      customAvatarPath: entity.customAvatarPath,
      streakCount: entity.streakCount,
      streakFreezeCount: entity.streakFreezeCount,
      streakFreezes: entity.streakFreezes,
      xpPoints: entity.xpPoints,
      lastStreakDate: entity.lastStreakDate,
      isGoldenAuraEnabled: entity.isGoldenAuraEnabled,
      hasSeenOnboarding: entity.hasSeenOnboarding,
    );
  }

  factory UserSettingsModel.fromKeyValueMap(Map<String, String> map) {
    final rawCurrency = map[keyDefaultCurrency] ?? Currency.irt.code;
    Currency currency;
    try {
      currency = Currency.fromCode(rawCurrency);
    } catch (_) {
      currency = Currency.irt;
    }

    final rawThemeMode = map[keyAppThemeMode] ?? map['theme_mode'];
    final AppThemeMode themeMode;
    if (rawThemeMode != null && rawThemeMode.isNotEmpty) {
      themeMode = AppThemeMode.fromString(rawThemeMode);
    } else if (map.containsKey(keyIsDarkMode)) {
      final legacyIsDark = (map[keyIsDarkMode] ?? 'true') == 'true';
      themeMode = legacyIsDark ? AppThemeMode.dark : AppThemeMode.light;
    } else {
      themeMode = AppThemeMode.signature;
    }

    final userName = map[keyUserName] ?? 'مهدی';
    final rawAccent = map[keyAccentColor];
    final accentColor = AppAccentColor.fromString(rawAccent);
    final isVacationMode = (map[keyIsVacationMode] ?? 'false') == 'true';
    final userRole = map[keyUserRole] ?? 'مدیر سیستم • سازماندهی پروژه‌ها';
    final userEmail = map[keyUserEmail] ?? 'mahdi@taskflow.ir';
    final userBio = map[keyUserBio] ?? 'تمرکز بر بهره‌وری روزانه و نظم شخصی';
    final avatarIndex = int.tryParse(map[keyAvatarIndex] ?? '0') ?? 0;
    final customAvatarPath = map[keyCustomAvatarPath];
    final streakCount = int.tryParse(map[keyStreakCount] ?? '0') ?? 0;
    final streakFreezeCount = int.tryParse(
          map[keyStreakFreezes] ?? map[keyStreakFreezeCount] ?? '0',
        ) ??
        0;
    final xpPoints = int.tryParse(map[keyXpPoints] ?? '0') ?? 0;
    final lastStreakDate = map[keyLastStreakDate];
    final isGoldenAuraEnabled =
        (map[keyIsGoldenAuraEnabled] ?? 'true') == 'true';
    final hasSeenOnboarding =
        (map[keyHasSeenOnboarding] ?? 'false') == 'true';

    return UserSettingsModel(
      defaultCurrency: currency,
      themeMode: themeMode,
      userName: userName,
      accentColor: accentColor,
      isVacationMode: isVacationMode,
      userRole: userRole,
      userEmail: userEmail,
      userBio: userBio,
      avatarIndex: avatarIndex,
      customAvatarPath:
          (customAvatarPath != null && customAvatarPath.isNotEmpty)
              ? customAvatarPath
              : null,
      streakCount: streakCount,
      streakFreezeCount: streakFreezeCount,
      streakFreezes: streakFreezeCount,
      xpPoints: xpPoints,
      lastStreakDate: (lastStreakDate != null && lastStreakDate.isNotEmpty)
          ? lastStreakDate
          : null,
      isGoldenAuraEnabled: isGoldenAuraEnabled,
      hasSeenOnboarding: hasSeenOnboarding,
    );
  }

  Map<String, String> toKeyValueMap() {
    return {
      keyDefaultCurrency: defaultCurrency.code,
      keyAppThemeMode: themeMode.name,
      keyIsDarkMode: isDarkMode.toString(),
      keyUserName: userName,
      keyAccentColor: accentColor.name,
      keyIsVacationMode: isVacationMode.toString(),
      keyUserRole: userRole,
      keyUserEmail: userEmail,
      keyUserBio: userBio,
      keyAvatarIndex: avatarIndex.toString(),
      if (customAvatarPath != null && customAvatarPath!.isNotEmpty)
        keyCustomAvatarPath: customAvatarPath!,
      keyStreakCount: streakCount.toString(),
      keyStreakFreezeCount: streakFreezeCount.toString(),
      keyStreakFreezes: streakFreezeCount.toString(),
      keyXpPoints: xpPoints.toString(),
      if (lastStreakDate != null && lastStreakDate!.isNotEmpty)
        keyLastStreakDate: lastStreakDate!,
      keyIsGoldenAuraEnabled: isGoldenAuraEnabled.toString(),
      keyHasSeenOnboarding: hasSeenOnboarding.toString(),
    };
  }
}
