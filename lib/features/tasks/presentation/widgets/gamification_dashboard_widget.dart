import 'package:flutter/material.dart';
import 'package:task_flow/core/utils/jalali_date_formatter.dart';

/// Tri-State productivity momentum representing the user's focus and streak velocity.
enum DashboardTriState {
  /// Procrastination / cold state: zero streak, cool blue frosted palette.
  cold,

  /// Focus / neutral state: balanced productivity, streak 1 to 3, sleek monochrome palette.
  neutral,

  /// Momentum / hot state: high velocity, streak > 3, energetic fire-orange/red glowing palette.
  hot,
}

/// An executive, Apple HIG-styled minimal dashboard header widget.
///
/// Refined in Phase 5.2: The bulky Gamification Profile card (Level, XP progress bar,
/// and Streak Flame) has been migrated to the Settings / Profile tab.
/// This widget now ONLY displays the current Day/Date and a simple greeting with NO large cards.
class GamificationDashboardWidget extends StatelessWidget {
  final int? streakCount;
  final int? totalXp;
  final int? level;
  final String? title;
  final int? budgetRials;
  final DashboardTriState? forcedTriState;
  final EdgeInsetsGeometry padding;

  const GamificationDashboardWidget({
    super.key,
    this.streakCount,
    this.totalXp,
    this.level,
    this.title,
    this.budgetRials,
    this.forcedTriState,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final persianDate = JalaliDateFormatter.formatFull(now);
    final timeGreeting = _getTimeGreeting(now);

    return Padding(
      padding: padding,
      child: Container(
        key: const Key('gamification_dashboard_widget'),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  persianDate,
                  key: const Key('dashboard_date_text'),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            Text(
              timeGreeting,
              key: const Key('dashboard_simple_greeting_text'),
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _getTimeGreeting(DateTime date) {
    final hour = date.hour;
    if (hour >= 5 && hour < 12) return 'صبح بخیر';
    if (hour >= 12 && hour < 17) return 'ظهر بخیر';
    if (hour >= 17 && hour < 20) return 'عصر بخیر';
    return 'شب بخیر';
  }
}

/// SliverPersistentHeaderDelegate for pinning the minimal date/greeting header atop task scroll views.
class GamificationDashboardSliverDelegate extends SliverPersistentHeaderDelegate {
  final int? streakCount;
  final int? totalXp;
  final int? level;
  final String? title;
  final int? budgetRials;
  final DashboardTriState? forcedTriState;

  const GamificationDashboardSliverDelegate({
    this.streakCount,
    this.totalXp,
    this.level,
    this.title,
    this.budgetRials,
    this.forcedTriState,
  });

  @override
  double get minExtent => 38.0;

  @override
  double get maxExtent => 38.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: GamificationDashboardWidget(
        streakCount: streakCount,
        totalXp: totalXp,
        level: level,
        title: title,
        budgetRials: budgetRials,
        forcedTriState: forcedTriState,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant GamificationDashboardSliverDelegate oldDelegate) {
    return oldDelegate.streakCount != streakCount ||
        oldDelegate.totalXp != totalXp ||
        oldDelegate.level != level ||
        oldDelegate.title != title ||
        oldDelegate.budgetRials != budgetRials ||
        oldDelegate.forcedTriState != forcedTriState;
  }
}
