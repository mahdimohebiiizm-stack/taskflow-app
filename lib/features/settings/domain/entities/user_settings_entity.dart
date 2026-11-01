import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:task_flow/core/theme/app_accent_color.dart';
import 'package:task_flow/core/theme/app_theme_mode.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

/// Represents user-configurable application preferences and gamification progression
/// (Streak, Streak Freeze shield, XP, Level, and Titles) persisted in SQLite.
class UserSettingsEntity extends Equatable {
  final Currency defaultCurrency;
  final AppThemeMode themeMode;
  final String userName;
  final AppAccentColor accentColor;
  final bool isVacationMode;
  final String userRole;
  final String userEmail;
  final String userBio;
  final int avatarIndex;
  final String? customAvatarPath;
  final int streakCount;
  final int streakFreezeCount;
  final int xpPoints;
  final String? lastStreakDate;
  final bool isGoldenAuraEnabled;
  final bool hasSeenOnboarding;

  /// Backwards-compatible accessors
  bool get isDarkMode =>
      themeMode == AppThemeMode.dark || themeMode == AppThemeMode.signature;
  bool get isZenMode => themeMode == AppThemeMode.zen;
  bool get isLightMode => themeMode == AppThemeMode.light;
  bool get isSignatureMode => themeMode == AppThemeMode.signature;
  bool get isSignatureLayout => themeMode.isSignatureLayout;
  int get streakFreezes => streakFreezeCount;

  const UserSettingsEntity({
    required this.defaultCurrency,
    AppThemeMode? themeMode,
    bool? isDarkMode,
    required this.userName,
    this.accentColor = AppAccentColor.blue,
    this.isVacationMode = false,
    this.userRole = 'مدیر سیستم • سازماندهی پروژه‌ها',
    this.userEmail = 'mahdi@taskflow.ir',
    this.userBio = 'تمرکز بر بهره‌وری روزانه و نظم شخصی',
    this.avatarIndex = 0,
    this.customAvatarPath,
    this.streakCount = 0,
    int? streakFreezes,
    int? streakFreezeCount,
    this.xpPoints = 0,
    this.lastStreakDate,
    this.isGoldenAuraEnabled = true,
    this.hasSeenOnboarding = false,
  })  : streakFreezeCount = streakFreezes ?? streakFreezeCount ?? 0,
        themeMode = themeMode ??
            (isDarkMode != null
                ? (isDarkMode ? AppThemeMode.dark : AppThemeMode.light)
                : AppThemeMode.signature);

  /// Default baseline preferences for first-time launch.
  static const UserSettingsEntity defaults = UserSettingsEntity(
    defaultCurrency: Currency.irt,
    themeMode: AppThemeMode.signature,
    userName: 'مهدی',
    accentColor: AppAccentColor.blue,
    isVacationMode: false,
    userRole: 'مدیر سیستم • سازماندهی پروژه‌ها',
    userEmail: 'mahdi@taskflow.ir',
    userBio: 'تمرکز بر بهره‌وری روزانه و نظم شخصی',
    avatarIndex: 0,
    streakCount: 0,
    streakFreezeCount: 0,
    xpPoints: 0,
    isGoldenAuraEnabled: true,
    hasSeenOnboarding: false,
  );

  /// Resolves the user's gamification title based on consecutive successful days ([streakDays]):
  /// - `< 3` days: `"تازهکار"`
  /// - `3..13` days: `"برنامهریز"` (Bronze Medal 🥉)
  /// - `14..29` days: `"مبارز زمان"` (Silver Medal 🥈)
  /// - `>= 30` days: `"استاد بهرهوری"` (Gold Medal 🥇 + Golden Aura)
  static String resolveTitleForStreak(int streakDays) {
    if (streakDays >= 30) {
      return 'استاد بهرهوری';
    }
    if (streakDays >= 14) {
      return 'مبارز زمان';
    }
    if (streakDays >= 3) {
      return 'برنامهریز';
    }
    return 'تازهکار';
  }

  /// Resolves the medal/badge icon associated with [streakDays].
  static String resolveMedalForStreak(int streakDays) {
    if (streakDays >= 30) {
      return '🥇';
    }
    if (streakDays >= 14) {
      return '🥈';
    }
    if (streakDays >= 3) {
      return '🥉';
    }
    return '🌱';
  }

  /// Current gamification title based on [streakCount].
  String get userTitle => resolveTitleForStreak(streakCount);

  /// Current medal emoji based on [streakCount].
  String get titleMedal => resolveMedalForStreak(streakCount);

  /// Combined title and medal label (e.g., `"برنامهریز 🥉"`).
  String get userTitleWithMedal => '$userTitle $titleMedal';

  /// Effective XP combining stored [xpPoints] and [streakCount] baseline (`100 XP` per streak day).
  int get effectiveXp {
    final baseline = streakCount * 100;
    return xpPoints > baseline ? xpPoints : baseline;
  }

  /// Non-linear formula: Target cumulative XP to achieve level L:
  /// `Target XP = ((L - 1) * 100) ^ 1.2`
  /// - Level 1: 0 XP
  /// - Level 2: ~250 XP ((1 * 100) ^ 1.2 ≈ 251 XP)
  /// - Level 3: ~574 XP
  /// - Level 4: ~934 XP
  /// - Level 5: ~1325 XP
  /// - Level 6: ~1700 XP ((5 * 100) ^ 1.2 ≈ 1723 XP)
  static int targetXpForLevel(int level) {
    if (level <= 1) return 0;
    return math.pow((level - 1) * 100, 1.2).round();
  }

  /// Computed dynamic player level based on [effectiveXp].
  int get userLevel {
    final xp = effectiveXp;
    if (xp <= 0) return 1;
    int level = 1;
    while (targetXpForLevel(level + 1) <= xp) {
      level++;
    }
    return level;
  }

  /// Cumulative XP required to unlock the next level.
  int get nextLevelTargetXp => targetXpForLevel(userLevel + 1);

  /// Progress ratio towards next level [0.0, 1.0].
  double get levelProgressRatio {
    final curTarget = targetXpForLevel(userLevel);
    final nextTarget = targetXpForLevel(userLevel + 1);
    final span = nextTarget - curTarget;
    if (span <= 0) return 1.0;
    return ((effectiveXp - curTarget) / span).clamp(0.0, 1.0);
  }

  /// Target streak days for the next title tier.
  int get nextTierTargetDays {
    if (streakCount < 3) return 3;
    if (streakCount < 14) return 14;
    if (streakCount < 30) return 30;
    return 30;
  }

  /// Normalized progress `[0.0, 1.0]` toward the next title tier.
  double get tierProgressRatio {
    if (streakCount >= 30) return 1.0;
    if (streakCount >= 14) {
      return ((streakCount - 14) / (30 - 14)).clamp(0.0, 1.0);
    }
    if (streakCount >= 3) {
      return ((streakCount - 3) / (14 - 3)).clamp(0.0, 1.0);
    }
    return (streakCount / 3.0).clamp(0.0, 1.0);
  }

  /// True if the user currently holds at least one Streak Freeze shield (`سپر محافظ`).
  bool get hasStreakFreeze => streakFreezeCount > 0;

  /// True when the user has reached 30+ successful days (`"استاد بهرهوری"`) and unlocked the golden avatar aura.
  bool get isGoldenAuraUnlocked => streakCount >= 30;

  /// True when the golden glowing aura around the avatar should be rendered.
  bool get hasActiveGoldenAura => isGoldenAuraUnlocked && isGoldenAuraEnabled;

  /// Records a 100%-successful day:
  /// - Increments [streakCount] by `1`.
  /// - Awards `+100 XP` (plus `+250 XP` bonus on every 7-day milestone).
  /// - Every 7 consecutive successful days (`nextStreak % 7 == 0`), awards `+1` Streak Freeze shield (`سپر محافظ`).
  UserSettingsEntity recordSuccessfulStreakDay({String? dateIso}) {
    if (dateIso != null &&
        dateIso.trim().isNotEmpty &&
        dateIso.trim() == lastStreakDate) {
      return this;
    }
    final nextStreak = streakCount + 1;
    final earnedShield = (nextStreak > 0 && nextStreak % 7 == 0) ? 1 : 0;
    final nextFreeze = streakFreezeCount + earnedShield;
    final nextXp = effectiveXp + 100 + (earnedShield * 250);

    return copyWith(
      streakCount: nextStreak,
      streakFreezeCount: nextFreeze,
      xpPoints: nextXp,
      lastStreakDate: () => dateIso?.trim() ?? lastStreakDate,
    );
  }

  /// Records an unsuccessful/missed day:
  /// - If [streakFreezeCount] > 0 (`سپر محافظ` available): consumes 1 shield (`streakFreezeCount - 1`)
  ///   and **preserves [streakCount] without resetting it to zero**.
  /// - If [streakFreezeCount] == 0: resets [streakCount] to `0`.
  UserSettingsEntity recordFailedStreakDay({String? dateIso}) {
    if (streakFreezeCount > 0) {
      return copyWith(
        streakFreezeCount: streakFreezeCount - 1,
        lastStreakDate: () => dateIso?.trim() ?? lastStreakDate,
      );
    }
    return copyWith(
      streakCount: 0,
      streakFreezeCount: 0,
      lastStreakDate: () => dateIso?.trim() ?? lastStreakDate,
    );
  }

  UserSettingsEntity copyWith({
    Currency? defaultCurrency,
    AppThemeMode? themeMode,
    bool? isDarkMode,
    String? userName,
    AppAccentColor? accentColor,
    bool? isVacationMode,
    String? userRole,
    String? userEmail,
    String? userBio,
    int? avatarIndex,
    String? Function()? customAvatarPath,
    int? streakCount,
    int? streakFreezeCount,
    int? streakFreezes,
    int? xpPoints,
    String? Function()? lastStreakDate,
    bool? isGoldenAuraEnabled,
    bool? hasSeenOnboarding,
  }) {
    final resolvedThemeMode = themeMode ??
        (isDarkMode != null
            ? (isDarkMode ? AppThemeMode.dark : AppThemeMode.light)
            : this.themeMode);
    return UserSettingsEntity(
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      themeMode: resolvedThemeMode,
      userName: userName ?? this.userName,
      accentColor: accentColor ?? this.accentColor,
      isVacationMode: isVacationMode ?? this.isVacationMode,
      userRole: userRole ?? this.userRole,
      userEmail: userEmail ?? this.userEmail,
      userBio: userBio ?? this.userBio,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      customAvatarPath: customAvatarPath != null
          ? customAvatarPath()
          : this.customAvatarPath,
      streakCount: streakCount ?? this.streakCount,
      streakFreezeCount:
          streakFreezes ?? streakFreezeCount ?? this.streakFreezeCount,
      xpPoints: xpPoints ?? this.xpPoints,
      lastStreakDate:
          lastStreakDate != null ? lastStreakDate() : this.lastStreakDate,
      isGoldenAuraEnabled: isGoldenAuraEnabled ?? this.isGoldenAuraEnabled,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
    );
  }

  @override
  List<Object?> get props => [
        defaultCurrency,
        themeMode,
        userName,
        accentColor,
        isVacationMode,
        userRole,
        userEmail,
        userBio,
        avatarIndex,
        customAvatarPath,
        streakCount,
        streakFreezeCount,
        xpPoints,
        lastStreakDate,
        isGoldenAuraEnabled,
        hasSeenOnboarding,
      ];
}
