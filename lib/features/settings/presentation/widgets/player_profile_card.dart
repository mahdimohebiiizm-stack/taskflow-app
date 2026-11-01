import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/utils/persian_number_formatter.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/tasks/presentation/widgets/gamification_dashboard_widget.dart';

/// Executive Apple HIG Player Profile Card displayed at the top of the Settings / Profile screen.
///
/// Refactored in Phase 5.2: Migrated from Home Dashboard to the Settings screen to keep
/// the home screen 100% focused on task execution.
class PlayerProfileCard extends StatelessWidget {
  final int? streakCount;
  final int? totalXp;
  final int? level;
  final String? title;
  final DashboardTriState? forcedTriState;
  final EdgeInsetsGeometry padding;

  const PlayerProfileCard({
    super.key,
    this.streakCount,
    this.totalXp,
    this.level,
    this.title,
    this.forcedTriState,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Resolve reactive values from BLoC if not explicitly passed
    final resolvedStreak = streakCount ?? _readStreakFromContext(context);
    final resolvedXp = totalXp ?? _readXpFromContext(context);
    final resolvedLevel = level ?? _readLevelFromContext(context, resolvedXp);
    final resolvedTitle = title ?? _readTitleFromContext(context, resolvedLevel);

    // 2. Determine Tri-State
    final triState = forcedTriState ?? _computeTriState(resolvedStreak);

    // 3. Theme tokens based on Tri-State
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _PlayerTriStatePalette.resolve(triState, isDark: isDark);

    return Padding(
      padding: padding,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: AnimatedContainer(
            key: const Key('settings_player_profile_card'),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: palette.backgroundGradient,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: palette.borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: palette.glowColor,
                  blurRadius: 18.0,
                  spreadRadius: 2.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row: Level Title + Streak Flame Badge
                Row(
                  children: [
                    Expanded(
                      child: _LevelAndTitleHeader(
                        level: resolvedLevel,
                        title: resolvedTitle,
                        accentColor: palette.accentColor,
                        textColor: palette.textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StreakFlameBadge(
                      streakCount: resolvedStreak,
                      triState: triState,
                      palette: palette,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Middle: XP Progress Bar
                _XpProgressBar(
                  totalXp: resolvedXp,
                  level: resolvedLevel,
                  palette: palette,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static DashboardTriState _computeTriState(int streak) {
    if (streak > 3) return DashboardTriState.hot;
    if (streak == 0) return DashboardTriState.cold;
    return DashboardTriState.neutral;
  }

  static int _readStreakFromContext(BuildContext context) {
    try {
      return context.watch<SettingsBloc>().state.settings.streakCount;
    } catch (_) {
      return 0;
    }
  }

  static int _readXpFromContext(BuildContext context) {
    try {
      return context.watch<GamificationBloc>().state.totalXp;
    } catch (_) {
      return 0;
    }
  }

  static int _readLevelFromContext(BuildContext context, int xp) {
    try {
      return context.watch<GamificationBloc>().state.level;
    } catch (_) {
      return GamificationBloc.calculateLevel(xp);
    }
  }

  static String _readTitleFromContext(BuildContext context, int level) {
    try {
      return context.watch<GamificationBloc>().state.title;
    } catch (_) {
      return GamificationBloc.calculateTitle(level);
    }
  }
}

/// Header displaying player level and honorary title.
class _LevelAndTitleHeader extends StatelessWidget {
  final int level;
  final String title;
  final Color accentColor;
  final Color textColor;

  const _LevelAndTitleHeader({
    required this.level,
    required this.title,
    required this.accentColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('gamification_level_title'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'سطح ${toPersianDigits('$level')}',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dynamic Streak Flame Badge reacting to Cold, Neutral, and Hot momentum states.
class _StreakFlameBadge extends StatelessWidget {
  final int streakCount;
  final DashboardTriState triState;
  final _PlayerTriStatePalette palette;

  const _StreakFlameBadge({
    required this.streakCount,
    required this.triState,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final (Key badgeKey, String iconText, String labelText) = switch (triState) {
      DashboardTriState.hot => (
          const Key('gamification_streak_hot'),
          '🔥',
          '${toPersianDigits('$streakCount')} روز استمرار آتشین',
        ),
      DashboardTriState.cold => (
          const Key('gamification_streak_cold'),
          '❄️',
          'استمرار غیرفعال',
        ),
      DashboardTriState.neutral => (
          const Key('gamification_streak_neutral'),
          '⚡',
          '${toPersianDigits('$streakCount')} روز استمرار',
        ),
    };

    return Container(
      key: badgeKey,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.badgeBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.badgeBorderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            iconText,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            labelText,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: palette.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Linear XP Progress Bar with fluid animated count-up.
class _XpProgressBar extends StatelessWidget {
  final int totalXp;
  final int level;
  final _PlayerTriStatePalette palette;

  const _XpProgressBar({
    required this.totalXp,
    required this.level,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    const xpPerLevel = 50;
    final currentLevelBaseXp = (level - 1) * xpPerLevel;
    final currentLevelXp = (totalXp - currentLevelBaseXp).clamp(0, xpPerLevel);
    final targetRatio = (currentLevelXp / xpPerLevel).clamp(0.0, 1.0);

    return Column(
      key: const Key('gamification_xp_bar'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'پیشرفت تا سطح بعدی',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: palette.mutedColor,
              ),
            ),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: currentLevelXp.toDouble()),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, val, _) {
                return Text(
                  '${toPersianDigits(val.toInt().toString())} / ${toPersianDigits('$xpPerLevel')} XP',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: palette.accentColor,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: targetRatio),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, ratio, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 7,
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: palette.barBgColor,
                  valueColor: AlwaysStoppedAnimation<Color>(palette.accentColor),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Palette tokens resolved dynamically based on Tri-State and light/dark theme.
class _PlayerTriStatePalette {
  final Gradient backgroundGradient;
  final Color borderColor;
  final Color glowColor;
  final Color accentColor;
  final Color textColor;
  final Color mutedColor;
  final Color barBgColor;
  final Color badgeBgColor;
  final Color badgeBorderColor;

  const _PlayerTriStatePalette({
    required this.backgroundGradient,
    required this.borderColor,
    required this.glowColor,
    required this.accentColor,
    required this.textColor,
    required this.mutedColor,
    required this.barBgColor,
    required this.badgeBgColor,
    required this.badgeBorderColor,
  });

  factory _PlayerTriStatePalette.resolve(DashboardTriState state, {required bool isDark}) {
    switch (state) {
      case DashboardTriState.cold:
        return _PlayerTriStatePalette(
          backgroundGradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0F1E2C), Color(0xFF162A3D)]
                : const [Color(0xFFE8F1F8), Color(0xFFD4E6F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: const Color(0xFF3898EC).withValues(alpha: 0.35),
          glowColor: const Color(0xFF3898EC).withValues(alpha: 0.14),
          accentColor: const Color(0xFF3898EC),
          textColor: isDark ? const Color(0xFFE6F3FF) : const Color(0xFF102A43),
          mutedColor: isDark ? const Color(0xFF8BB5DC) : const Color(0xFF486581),
          barBgColor: const Color(0xFF3898EC).withValues(alpha: 0.15),
          badgeBgColor: const Color(0xFF3898EC).withValues(alpha: 0.12),
          badgeBorderColor: const Color(0xFF3898EC).withValues(alpha: 0.28),
        );

      case DashboardTriState.hot:
        return _PlayerTriStatePalette(
          backgroundGradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF2C1014), Color(0xFF381416)]
                : const [Color(0xFFFFF1EB), Color(0xFFFDE4D8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: const Color(0xFFFF5238).withValues(alpha: 0.45),
          glowColor: const Color(0xFFFF5238).withValues(alpha: 0.22),
          accentColor: const Color(0xFFFF5238),
          textColor: isDark ? const Color(0xFFFFF0ED) : const Color(0xFF4D140C),
          mutedColor: isDark ? const Color(0xFFEAA298) : const Color(0xFF87382B),
          barBgColor: const Color(0xFFFF5238).withValues(alpha: 0.18),
          badgeBgColor: const Color(0xFFFF5238).withValues(alpha: 0.14),
          badgeBorderColor: const Color(0xFFFF5238).withValues(alpha: 0.35),
        );

      case DashboardTriState.neutral:
        return _PlayerTriStatePalette(
          backgroundGradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF1C1C1E), Color(0xFF242426)]
                : const [Color(0xFFFFFFFF), Color(0xFFF7F7F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
          glowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
          accentColor: isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
          textColor: isDark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E),
          mutedColor: isDark ? const Color(0xFFA1A1A6) : const Color(0xFF636366),
          barBgColor: isDark ? const Color(0x22FFFFFF) : const Color(0x11000000),
          badgeBgColor: (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF)).withValues(alpha: 0.12),
          badgeBorderColor: (isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF)).withValues(alpha: 0.25),
        );
    }
  }
}
