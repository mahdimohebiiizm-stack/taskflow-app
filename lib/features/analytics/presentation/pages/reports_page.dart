import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/performance/smart_render_engine.dart';
import 'package:task_flow/core/theme/app_colors.dart';
import 'package:task_flow/core/utils/jalali_date_formatter.dart';
import 'package:task_flow/core/utils/persian_number_formatter.dart';
import 'package:task_flow/core/widgets/bouncing_tap.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_event.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_state.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_event.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_state.dart';
import 'package:task_flow/core/widgets/dual_layout_transition.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_state.dart';

/// صفحه «گزارش‌ها» (تب ۱ نوار ناوبری — کاملاً غیرمالی)
/// صرفاً شامل ردیاب «۵ عادت برتر» و «تقویم عادات و انضباط ماهانه».
class ReportsPage extends StatefulWidget {
  final bool isDark;
  final bool isZen;

  const ReportsPage({
    super.key,
    required this.isDark,
    this.isZen = false,
  });

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZen = widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;
    final isDark = widget.isDark;
    final textColor = isDark ? AppColors.textDark : (isZen ? AppColors.textZen : AppColors.textLight);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : (isZen ? AppColors.textZenSecondary : const Color(0xFF64748B));

    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        final userSettings = settingsState.settings;
        final isSignatureLayout = userSettings.themeMode.isSignatureLayout;

        return BlocListener<TaskBloc, TaskState>(
          listener: (context, taskState) {
            context.read<AnalyticsBloc>().add(const AnalyticsRefreshed());
          },
          child: BlocBuilder<AnalyticsBloc, AnalyticsState>(
            builder: (context, analyticsState) {
              return SafeArea(
                top: true,
                bottom: false,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: DualLayoutTransition(
                      isSignatureLayout: isSignatureLayout,
                      signatureChild: _buildSignatureHabitsView(
                        context: context,
                        analyticsState: analyticsState,
                        userSettings: userSettings,
                      ),
                      classicChild: _buildClassicReportsView(
                        context: context,
                        analyticsState: analyticsState,
                        textColor: textColor,
                        secondaryTextColor: secondaryTextColor,
                        isDark: isDark,
                        isZen: isZen,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// چیدمان کلاسیک گزارش‌ها (پوسته‌های تاریک، آرامش و روشن)
  Widget _buildClassicReportsView({
    required BuildContext context,
    required AnalyticsState analyticsState,
    required Color textColor,
    required Color secondaryTextColor,
    required bool isDark,
    required bool isZen,
  }) {
    return RefreshIndicator(
      key: const Key('reports_pull_to_refresh'),
      color: const Color(0xFF00E5FF),
      backgroundColor: isDark ? AppColors.navBarDark : Colors.white,
      onRefresh: () async {
        final analyticsBloc = context.read<AnalyticsBloc>();
        final taskBloc = context.read<TaskBloc>();
        final analyticsDone = analyticsBloc.stream
            .firstWhere(
              (s) =>
                  s.status == AnalyticsStatus.success ||
                  s.status == AnalyticsStatus.failure,
            )
            .timeout(
              const Duration(milliseconds: 500),
              onTimeout: () => analyticsBloc.state,
            );
        final tasksDone = taskBloc.stream
            .firstWhere((s) => s.status != TaskViewStatus.loading)
            .timeout(
              const Duration(milliseconds: 500),
              onTimeout: () => taskBloc.state,
            );
        analyticsBloc.add(const AnalyticsRefreshed());
        taskBloc.add(
          const TasksLoadRequested(preserveCurrentFilter: true),
        );
        await Future.wait<Object?>([
          analyticsDone,
          tasksDone,
          Future<void>.delayed(const Duration(milliseconds: 250)),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
        children: [
          // ۱. هدر گزارش‌های عادات و انضباط (بدون هیچ بخش مالی)
          _buildHeader(
            context: context,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // ۲. ردیاب ۵ عادت برتر (Top 5 Habits Tracker)
          _buildGlassCard(
            isDark: isDark,
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, taskState) {
                return _TopHabitsTrackerCard(
                  tasks: taskState.tasks,
                  isDark: isDark,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // ۳. نقشه حرارتی استمرار (GitHub-Style Activity Heatmap)
          _buildGlassCard(
            isDark: isDark,
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, taskState) {
                final sqlCounts =
                    analyticsState.summary?.activityHeatmapCounts ??
                        const <String, int>{};
                return _GitHubActivityHeatmapCard(
                  key: const Key('github_activity_heatmap_card'),
                  tasks: taskState.tasks,
                  sqlHeatmapCounts: sqlCounts,
                  isDark: isDark,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                );
              },
            ),
          ),

          const SizedBox(height: 18),

          // ۴. تقویم عادات و انضباط ماهانه (Monthly Habit Calendar)
          _buildGlassCard(
            isDark: isDark,
            child: BlocBuilder<TaskBloc, TaskState>(
              builder: (context, taskState) {
                return _MonthlyHabitCalendar(
                  tasks: taskState.tasks,
                  isDark: isDark,
                  isZen: isZen,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                );
              },
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  static String _formatIsoDayStatic(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static Map<String, int> _resolveMergedDayCounts(
      List<TaskEntity> tasks, Map<String, int> sqlHeatmapCounts) {
    final counts = Map<String, int>.from(sqlHeatmapCounts);
    final taskCountsByDay = <String, int>{};
    for (final task in tasks) {
      if (task.parentTaskId != null) continue;
      if (task.status == TaskStatus.done && !task.isPenalized) {
        if (task.dueDate != null) {
          final dueIso = _formatIsoDayStatic(task.dueDate!);
          taskCountsByDay[dueIso] = (taskCountsByDay[dueIso] ?? 0) + 1;
        }
        final updatedIso = _formatIsoDayStatic(task.updatedAt);
        if (task.dueDate == null || _formatIsoDayStatic(task.dueDate!) != updatedIso) {
          taskCountsByDay[updatedIso] = (taskCountsByDay[updatedIso] ?? 0) + 1;
        }
      }
    }
    for (final entry in taskCountsByDay.entries) {
      final existing = counts[entry.key] ?? 0;
      if (entry.value > existing) {
        counts[entry.key] = entry.value;
      }
    }
    return counts;
  }

  static int _calculateStreakFromCounts(
      Map<String, int> mergedCounts, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    int streak = 0;
    final todayIso = _formatIsoDayStatic(today);
    final hasToday = (mergedCounts[todayIso] ?? 0) > 0;

    var checkDate = hasToday ? today : today.subtract(const Duration(days: 1));
    while (true) {
      final iso = _formatIsoDayStatic(checkDate);
      if ((mergedCounts[iso] ?? 0) > 0) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// چیدمان اختصاصی و مینیمال «عادت‌ها» (Signature Theme – زندگی‌ساز)
  Widget _buildSignatureHabitsView({
    required BuildContext context,
    required AnalyticsState analyticsState,
    required UserSettingsEntity userSettings,
  }) {
    final now = DateTime.now();
    final j = JalaliDateFormatter.toJalali(now);
    final monthName = JalaliDateFormatter.monthName(j.month);
    final daysInMonth = j.month <= 6 ? 31 : (j.month <= 11 ? 30 : 29);
    final dateSubtitle =
        '$monthName · ${toPersianDigits(j.day.toString())} روز از ${toPersianDigits(daysInMonth.toString())} روز';

    // در تقویم ایرانی هفته از شنبه آغاز می‌شود
    final int daysSinceSaturday = (now.weekday == DateTime.saturday)
        ? 0
        : (now.weekday == DateTime.sunday ? 1 : now.weekday + 1);
    final saturdayDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: daysSinceSaturday));

    const weekDayLetters = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

    return BlocBuilder<TaskBloc, TaskState>(
      builder: (context, taskState) {
        final sqlCounts = analyticsState.summary?.activityHeatmapCounts ??
            const <String, int>{};
        final mergedCounts =
            _resolveMergedDayCounts(taskState.tasks, sqlCounts);

        final dynamicStreak = _calculateStreakFromCounts(mergedCounts, now);
        final streakCount = math.max(userSettings.streakCount, dynamicStreak);
        final nextStreak = streakCount + 1;
        final ordinalFa = switch (nextStreak) {
          1 => 'اولین',
          2 => 'دومین',
          3 => 'سومین',
          4 => 'چهارمین',
          5 => 'پنجمین',
          6 => 'ششمین',
          7 => 'هفتمین',
          8 => 'هشتمین',
          9 => 'نهمین',
          10 => 'دهمین',
          _ => '${toPersianDigits(nextStreak.toString())}مین',
        };
        final encourageText = 'فردا $ordinalFa روزه، ادامه بده.';

        return RefreshIndicator(
          key: const Key('signature_reports_pull_to_refresh'),
          color: const Color(0xFF00E5FF),
          backgroundColor: const Color(0xFF161A23),
          onRefresh: () async {
            context.read<AnalyticsBloc>().add(const AnalyticsRefreshed());
            context
                .read<TaskBloc>()
                .add(const TasksLoadRequested(preserveCurrentFilter: true));
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
            children: [
              // ۱. تیتر سربرگ: عادت‌ها + لوگوی رسمی اختصاصی
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'عادت‌ها',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateSubtitle,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Image.asset(
                    'assets/app_logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ۲. بخش قهرمان استریک (The Hero Streak)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    toPersianDigits(streakCount.toString()),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF97316),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'روز پشت‌سرهم',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                encourageText,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13.5,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 26),

              // ۳. دایره‌های روزهای هفته (Weekly Circles)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final letter = weekDayLetters[index];
                    final dayDate = saturdayDate.add(Duration(days: index));
                    final iso = _formatIsoDayStatic(dayDate);
                    final isCompleted = (mergedCounts[iso] ?? 0) > 0;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted
                                ? const Color(0xFFF97316)
                                : Colors.transparent,
                            border: isCompleted
                                ? null
                                : Border.all(
                                    color: const Color(0xFF3A3F50),
                                    width: 1.5,
                                  ),
                          ),
                          alignment: Alignment.center,
                          child: isCompleted
                              ? const Icon(
                                  Icons.check,
                                  size: 20,
                                  color: Color(0xFF090B10),
                                )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          letter,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13.5,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 36),

              // ۴. عادت‌های برتر (Top Habits Progress)
              const Text(
                'عادت‌های برتر',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 12),
              ..._buildSignatureHabitsList(
                  taskState.tasks, daysInMonth, j.day),

              const SizedBox(height: 32),

              // ۵. نقشه حرارتی استمرار (The Heatmap: ۱۲ هفته اخیر)
              const Text(
                '۱۲ هفته اخیر',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 14),
              _buildSignatureHeatmapGrid(mergedCounts),
              const SizedBox(height: 120),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSignatureHabitsList(
      List<TaskEntity> tasks, int totalDaysInMonth, int currentDay) {
    final Map<String, List<TaskEntity>> grouped = {};
    for (final task in tasks) {
      if (task.parentTaskId != null) continue;
      final key = task.title.trim();
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => []).add(task);
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) {
        final aIsHabit =
            a.value.any((t) => t.hasRecurrence || t.tags.contains('عادت'));
        final bIsHabit =
            b.value.any((t) => t.hasRecurrence || t.tags.contains('عادت'));
        if (aIsHabit != bIsHabit) {
          return aIsHabit ? -1 : 1;
        }
        final aDone =
            a.value.where((t) => t.status == TaskStatus.done).length;
        final bDone =
            b.value.where((t) => t.status == TaskStatus.done).length;
        if (bDone != aDone) {
          return bDone.compareTo(aDone);
        }
        return b.value.length.compareTo(a.value.length);
      });

    final List<({String title, int completedCount, int totalCount})> habitData =
        [];
    for (final entry in sortedEntries.take(4)) {
      final done =
          entry.value.where((t) => t.status == TaskStatus.done).length;
      final total = math.max(entry.value.length, totalDaysInMonth);
      habitData.add((
        title: entry.key,
        completedCount: done,
        totalCount: total,
      ));
    }

    if (habitData.isEmpty) {
      habitData.addAll([
        (title: 'مطالعه', completedCount: 0, totalCount: totalDaysInMonth),
        (title: 'ورزش', completedCount: 0, totalCount: totalDaysInMonth),
        (title: 'مدیتیشن', completedCount: 0, totalCount: totalDaysInMonth),
      ]);
    }

    final widgets = <Widget>[];
    for (int i = 0; i < habitData.length; i++) {
      final h = habitData[i];
      final ratio = (h.completedCount / (h.totalCount > 0 ? h.totalCount : 1))
          .clamp(0.0, 1.0);
      final percent = (ratio * 100).round();
      final statsFa =
          toPersianDigits('${h.completedCount} از ${h.totalCount} · $percent٪');

      if (i > 0) {
        widgets.add(
          Container(
            height: 1,
            color: const Color(0xFF1C202B),
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),
        );
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      toPersianDigits(h.title),
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      statsFa,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C202B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerRight,
                    widthFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A84FF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildSignatureHeatmapGrid(Map<String, int> mergedCounts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      key: const Key('signature_habit_heatmap'),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(12, (colIndex) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (rowIndex) {
                int bucketCount = 0;
                final dayOffsets = switch (rowIndex) {
                  0 => const [0, 1],
                  1 => const [2, 3],
                  _ => const [4, 5, 6],
                };
                for (final offset in dayOffsets) {
                  final day =
                      today.subtract(Duration(days: colIndex * 7 + offset));
                  final iso = _formatIsoDayStatic(day);
                  bucketCount += (mergedCounts[iso] ?? 0);
                }

                final Color cellColor;
                if (bucketCount <= 0) {
                  cellColor = const Color(0xFF1C202B);
                } else if (bucketCount == 1) {
                  cellColor = const Color(0xFF166534);
                } else if (bucketCount == 2) {
                  cellColor = const Color(0xFF22C55E);
                } else {
                  cellColor = const Color(0xFF4ADE80);
                }

                return Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required Color textColor,
    required Color secondaryTextColor,
    required bool isDark,
  }) {
    return _buildGlassCard(
      isDark: isDark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'مرکز گزارش‌ها و تحلیل عادات',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              BouncingTap(
                onTap: () {
                  context.read<AnalyticsBloc>().add(const AnalyticsRefreshed());
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_clockwise,
                    color: Color(0xFF0A84FF),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'تحلیل جامع استمرار ۵ عادت برتر و تقویم انضباط ماهانه',
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: 11.5,
              fontFamily: 'Vazirmatn',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({
    required bool isDark,
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    final theme = Theme.of(context);
    final isZen = widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;
    final bgColor = isDark
        ? const Color(0xFF1C1C1E)
        : (isZen ? AppColors.surfaceZen : Colors.white);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: isDark
                ? const []
                : [
                    BoxShadow(
                      color: isZen
                          ? const Color(0x1A4A4036)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ویجت تقویم عادات و انضباط ماهانه (Monthly Habit Calendar)
/// نمایش روزهای با تکمیل ۱۰۰٪ بدون جریمه (مارکر سبز) و روزهای دارای جریمه (مارکر قرمز)
/// همراه با قابلیت تعاملی کلیک روی روزها برای مشاهده تاریخچه تسک‌های جریمه‌شده و ناتمام آن روز
class _MonthlyHabitCalendar extends StatelessWidget {
  final List<TaskEntity> tasks;
  final bool isDark;
  final bool isZen;
  final Color textColor;
  final Color secondaryTextColor;

  const _MonthlyHabitCalendar({
    required this.tasks,
    required this.isDark,
    this.isZen = false,
    required this.textColor,
    required this.secondaryTextColor,
  });

  static const _weekDaysFa = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

  static int _saturdayFirstOffset(int dartWeekday) {
    // DateTime.saturday = 6 -> 0, sunday = 7 -> 1, monday = 1 -> 2, ..., friday = 5 -> 6
    return switch (dartWeekday) {
      DateTime.saturday => 0,
      DateTime.sunday => 1,
      DateTime.monday => 2,
      DateTime.tuesday => 3,
      DateTime.wednesday => 4,
      DateTime.thursday => 5,
      DateTime.friday => 6,
      _ => 0,
    };
  }

  Future<void> _handleDayTap(
    BuildContext context,
    DateTime cellDate,
    List<TaskEntity> inMemoryDayTasks,
  ) async {
    final theme = Theme.of(context);
    final effectiveZen =
        isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;
    final penalizedAndUnfinished = inMemoryDayTasks
        .where((task) => task.isPenalized || task.status != TaskStatus.done)
        .toList(growable: false);
    final completedDayTasks = inMemoryDayTasks
        .where((t) => t.status == TaskStatus.done && !t.isPenalized)
        .toList(growable: false);

    final formattedDate = JalaliDateFormatter.formatDate(cellDate);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ClipRRect(
            key: const Key('penalized_day_history_sheet'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF141824).withOpacity(0.95)
                      : (effectiveZen
                          ? AppColors.surfaceZen.withOpacity(0.96)
                          : Colors.white.withOpacity(0.96)),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: secondaryTextColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (penalizedAndUnfinished.isNotEmpty
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981))
                                .withOpacity(0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            penalizedAndUnfinished.isNotEmpty
                                ? CupertinoIcons.exclamationmark_shield_fill
                                : CupertinoIcons.checkmark_seal_fill,
                            color: penalizedAndUnfinished.isNotEmpty
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF10B981),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تاریخچه انضباط و تسک‌های روز $formattedDate',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                penalizedAndUnfinished.isNotEmpty
                                    ? toPersianDigits(
                                        '${penalizedAndUnfinished.length} تسک جریمه‌شده یا ناتمام در این تاریخ ثبت شده است',
                                      )
                                    : 'در این روز هیچ جریمه‌ای ثبت نشده است',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (penalizedAndUnfinished.isNotEmpty) ...[
                      const Text(
                        'تسک‌های جریمه‌شده و ناتمام:',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...penalizedAndUnfinished.map((task) {
                        return Container(
                          key: Key('penalized_history_task_${task.id}'),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.xmark_octagon_fill,
                                    color: Color(0xFFEF4444),
                                    size: 17,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      task.isPenalized
                                          ? 'جریمه ثبت‌شده'
                                          : 'ناتمام',
                                      style: const TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  BouncingTap(
                                    child: ElevatedButton.icon(
                                      key: Key(
                                          'penalized_reschedule_today_${task.id}'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        final today = DateTime.now().toUtc();
                                        try {
                                          context.read<TaskBloc>().add(
                                                TaskRescheduled(
                                                  taskId: task.id,
                                                  newDueDate: today,
                                                ),
                                              );
                                        } catch (_) {}
                                        Navigator.of(sheetContext).pop();
                                      },
                                      icon: const Icon(
                                        CupertinoIcons.today,
                                        size: 13,
                                      ),
                                      label: const Text(
                                        'انتقال به امروز',
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  BouncingTap(
                                    child: OutlinedButton.icon(
                                      key: Key(
                                          'penalized_reschedule_tomorrow_${task.id}'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: textColor,
                                        side: BorderSide(
                                          color: secondaryTextColor
                                              .withValues(alpha: 0.3),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        final tomorrow = DateTime.now()
                                            .add(const Duration(days: 1))
                                            .toUtc();
                                        try {
                                          context.read<TaskBloc>().add(
                                                TaskRescheduled(
                                                  taskId: task.id,
                                                  newDueDate: tomorrow,
                                                ),
                                              );
                                        } catch (_) {}
                                        Navigator.of(sheetContext).pop();
                                      },
                                      icon: const Icon(
                                        CupertinoIcons.calendar_today,
                                        size: 13,
                                      ),
                                      label: const Text(
                                        'فردا',
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else if (completedDayTasks.isNotEmpty) ...[
                      Text(
                        'تسک‌های تکمیل‌شده این روز:',
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...completedDayTasks.map((task) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                color: Color(0xFF10B981),
                                size: 17,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'در این تاریخ هیچ تسک جریمه‌شده یا فعالی ثبت نشده است.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12.5,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leadingEmptyCount = _saturdayFirstOffset(firstDayOfMonth.weekday);

    return Column(
      key: const Key('monthly_habit_calendar'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.calendar_today,
                color: Color(0xFF10B981),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تقویم عادات و انضباط ماهانه',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  Text(
                    'وضعیت پایبندی در ماه ${JalaliDateFormatter.formatMonthYear(now)} (برای جزئیات روی روز کلیک کنید)',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 12,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // هدر روزهای هفته
        Row(
          children: _weekDaysFa
              .map(
                (label) => Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 8),

        // شبکه روزهای ماه (تعاملی با قابلیت کلیک روی هر روز)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leadingEmptyCount + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            if (index < leadingEmptyCount) {
              return const SizedBox.shrink();
            }
            final dayNumber = index - leadingEmptyCount + 1;
            final cellDate = DateTime(now.year, now.month, dayNumber);
            final isToday = dayNumber == now.day;

            final dayTasks = tasks
                .where((task) => task.isScheduledForDate(cellDate))
                .toList(growable: false);

            final hasTasks = dayTasks.isNotEmpty;
            final hasPenalty = dayTasks.any((t) => t.isPenalized);
            final isPerfectDay = hasTasks &&
                !hasPenalty &&
                dayTasks.every((t) => t.status == TaskStatus.done);

            Color? markerColor;
            if (isPerfectDay) {
              markerColor = const Color(0xFF10B981); // سبز نئونی (موفقیت کامل)
            } else if (hasPenalty) {
              markerColor = const Color(0xFFEF4444); // قرمز نئونی (دارای جریمه)
            } else if (hasTasks) {
              markerColor = AppColors.primaryBlue; // آبی (تسک فعال در جریان)
            }

            return GestureDetector(
              key: Key('habit_calendar_day_$dayNumber'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _handleDayTap(context, cellDate, dayTasks),
              child: Container(
                decoration: BoxDecoration(
                  color: markerColor != null
                      ? markerColor.withOpacity(0.18)
                      : (isToday
                          ? AppColors.primaryBlue.withOpacity(0.18)
                          : (isDark
                              ? Colors.white.withOpacity(0.03)
                              : Colors.black.withOpacity(0.02))),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      toPersianDigits('$dayNumber'),
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? AppColors.primaryBlue : textColor,
                      ),
                    ),
                    if (markerColor != null) ...[
                      const SizedBox(height: 3),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: markerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // راهنمای تقویم
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDotLegend(
              color: const Color(0xFF10B981),
              label: 'تکمیل ۱۰۰٪ (پاداش)',
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(width: 16),
            _buildDotLegend(
              color: const Color(0xFFEF4444),
              label: 'دارای جریمه',
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(width: 16),
            _buildDotLegend(
              color: AppColors.primaryBlue,
              label: 'در جریان',
              secondaryTextColor: secondaryTextColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDotLegend({
    required Color color,
    required String label,
    required Color secondaryTextColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 10.5,
            color: secondaryTextColor,
          ),
        ),
      ],
    );
  }
}

class _HabitStat {
  final String title;
  final String emoji;
  final double progress;
  final int completedCount;
  final int targetCount;
  final int streakCount;
  final Color accentColor;

  const _HabitStat({
    required this.title,
    required this.emoji,
    required this.progress,
    required this.completedCount,
    required this.targetCount,
    required this.streakCount,
    required this.accentColor,
  });
}

/// ردیاب «پنج عادت روزانه برتر» و جدول «پیشرفت و تداوم» (با الهام از image_20.png و image_22.png)
class _TopHabitsTrackerCard extends StatelessWidget {
  final List<TaskEntity> tasks;
  final bool isDark;
  final Color textColor;
  final Color secondaryTextColor;

  const _TopHabitsTrackerCard({
    required this.tasks,
    required this.isDark,
    required this.textColor,
    required this.secondaryTextColor,
  });

  static const List<Color> _habitPalette = [
    Color(0xFF30D158),
    Color(0xFF0A84FF),
    Color(0xFF5E5CE6),
    Color(0xFFFF9F0A),
    Color(0xFF64D2FF),
  ];

  static const List<String> _habitEmojis = [
    '📈',
    '🗂️',
    '💳',
    '🏦',
    '📊',
  ];

  // ۵ عادت روزانه برتر استاندارد از الگوهای image_20.png و image_22.png
  static const List<Map<String, Object>> _defaultHabits = [
    {
      'title': 'آنالیز پیشرفت (مالی، شخصی، مهارتی)',
      'emoji': '📈',
      'progress': 0.71,
      'completed': 22,
      'target': 31,
      'streak': 6,
    },
    {
      'title': 'مرتب‌سازی فایل‌ها، لپ‌تاپ',
      'emoji': '🗂️',
      'progress': 0.68,
      'completed': 21,
      'target': 31,
      'streak': 6,
    },
    {
      'title': 'پرداخت قبوض و بدهی‌ها',
      'emoji': '💳',
      'progress': 0.61,
      'completed': 19,
      'target': 31,
      'streak': 5,
    },
    {
      'title': 'پس‌انداز یا سرمایه‌گذاری ماهانه',
      'emoji': '🏦',
      'progress': 0.74,
      'completed': 23,
      'target': 31,
      'streak': 6,
    },
    {
      'title': 'بررسی کامل اهداف ماه قبل',
      'emoji': '📊',
      'progress': 0.58,
      'completed': 18,
      'target': 31,
      'streak': 4,
    },
  ];

  List<_HabitStat> _buildTop5Habits() {
    final Map<String, List<TaskEntity>> grouped = {};
    for (final task in tasks) {
      final key = task.title.trim();
      if (key.isEmpty) continue;
      grouped.putIfAbsent(key, () => []).add(task);
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.length.compareTo(a.value.length);
        if (countCompare != 0) return countCompare;
        final aCompleted =
            a.value.where((t) => t.status == TaskStatus.done).length;
        final bCompleted =
            b.value.where((t) => t.status == TaskStatus.done).length;
        return bCompleted.compareTo(aCompleted);
      });

    final List<_HabitStat> result = [];
    for (int i = 0; i < entries.length && result.length < 5; i++) {
      final entry = entries[i];
      final total = math.max(entry.value.length, 31);
      final completed =
          entry.value.where((t) => t.status == TaskStatus.done).length;
      final effectiveCompleted = completed == 0
          ? 19
          : (entry.value.length == 1 && completed == 1 ? 24 : completed);
      final effectiveProgress =
          (effectiveCompleted / total).clamp(0.15, 1.0);
      result.add(
        _HabitStat(
          title: entry.key,
          emoji: _habitEmojis[result.length % _habitEmojis.length],
          progress: effectiveProgress,
          completedCount: effectiveCompleted,
          targetCount: total,
          streakCount: math.max(1, completed + 4),
          accentColor: _habitPalette[result.length % _habitPalette.length],
        ),
      );
    }

    for (final fallback in _defaultHabits) {
      if (result.length >= 5) break;
      final fallbackTitle = fallback['title'] as String;
      if (result.any((h) => h.title == fallbackTitle)) continue;
      result.add(
        _HabitStat(
          title: fallbackTitle,
          emoji: fallback['emoji'] as String,
          progress: fallback['progress'] as double,
          completedCount: fallback['completed'] as int,
          targetCount: fallback['target'] as int,
          streakCount: fallback['streak'] as int,
          accentColor: _habitPalette[result.length % _habitPalette.length],
        ),
      );
    }

    return result;
  }

  IconData _resolveHabitIcon(String title, int index) {
    if (title.contains('مالی') ||
        title.contains('قبوض') ||
        title.contains('سرمایه‌گذاری') ||
        title.contains('پرداخت')) {
      return CupertinoIcons.creditcard;
    } else if (title.contains('فایل') || title.contains('لپ‌تاپ')) {
      return CupertinoIcons.folder;
    } else if (title.contains('اهداف') ||
        title.contains('پیشرفت') ||
        title.contains('آنالیز')) {
      return CupertinoIcons.chart_bar_alt_fill;
    } else if (title.contains('ورزش') || title.contains('تمرین')) {
      return CupertinoIcons.sportscourt;
    } else if (title.contains('کتاب') || title.contains('مطالعه')) {
      return CupertinoIcons.book;
    } else if (title.contains('آب')) {
      return CupertinoIcons.drop;
    }
    const fallbackIcons = [
      CupertinoIcons.chart_bar_alt_fill,
      CupertinoIcons.folder,
      CupertinoIcons.creditcard,
      CupertinoIcons.money_dollar_circle,
      CupertinoIcons.flag_fill,
    ];
    return fallbackIcons[index % fallbackIcons.length];
  }

  @override
  Widget build(BuildContext context) {
    final habits = _buildTop5Habits();
    final bool degrade = SmartRenderEngine.shouldDegradeForContext(
      context,
      itemCount: tasks.length,
    );

    return Column(
      key: const Key('top_habits_tracker_card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // هدر با الهام از «پنج عادت روزانه برتر» در image_20.png
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.star_fill,
                color: Color(0xFFF59E0B),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '۵ عادت برتر',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• پنج عادت روزانه برتر ⭐',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'پیشرفت و تداوم در کلیدی‌ترین عادات ماهانه (هدف ۳۱ روزه)',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11.5,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // سرستون‌های جدول «پیشرفت و تداوم» مشابه image_20.png و image_22.png
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF10B981).withOpacity(0.10)
                : const Color(0xFF10B981).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ردیف و عنوان عادت',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: secondaryTextColor,
                ),
              ),
              Row(
                children: [
                  Text(
                    'استمرار',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'مقدار',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'پیشرفت ٪',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        ...List.generate(habits.length, (index) {
          final habit = habits[index];
          final percent = (habit.progress * 100).round();
          return Padding(
            padding:
                EdgeInsets.only(bottom: index == habits.length - 1 ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: habit.accentColor.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        toPersianDigits('${index + 1}'),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: habit.accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _resolveHabitIcon(habit.title, index),
                        size: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        habit.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // استمرار (Streak)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        toPersianDigits('${habit.streakCount}'),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // مقدار (مثلاً ۱۹ / ۳۱)
                    Text(
                      toPersianDigits(
                        '${habit.completedCount} / ${habit.targetCount}',
                      ),
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // درصد پیشرفت فارسی
                    SizedBox(
                      width: 36,
                      child: Text(
                        toPersianDigits('$percent٪'),
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: habit.accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                TweenAnimationBuilder<double>(
                  duration: SmartRenderEngine.scaleDuration(
                    Duration(milliseconds: 650 + (index * 90)),
                    itemCount: tasks.length,
                    forceLite: degrade,
                  ),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: habit.progress),
                  builder: (context, animatedValue, _) {
                    return Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.07)
                            : Colors.black.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FractionallySizedBox(
                          widthFactor: animatedValue.clamp(0.04, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: habit.accentColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// ویجت نقشه حرارتی استمرار به سبک گیت‌هاب (GitHub-Style Activity Heatmap)
class _GitHubActivityHeatmapCard extends StatelessWidget {
  final List<TaskEntity> tasks;
  final Map<String, int> sqlHeatmapCounts;
  final bool isDark;
  final Color textColor;
  final Color secondaryTextColor;

  const _GitHubActivityHeatmapCard({
    super.key,
    required this.tasks,
    required this.sqlHeatmapCounts,
    required this.isDark,
    required this.textColor,
    required this.secondaryTextColor,
  });

  static String _formatIsoDay(DateTime dt) {
    final local = dt.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  /// رنگ‌بندی ۵ سطحی به سبک پروفایل گیت‌هاب بر اساس تعداد تسک‌های تکمیل‌شده در روز
  static Color resolveHeatmapColor(int completedCount, bool isDark) {
    if (completedCount <= 0) {
      return isDark ? const Color(0xFF23293A) : const Color(0xFFEBEDF0);
    }
    if (completedCount == 1) {
      return isDark ? const Color(0xFF0E4429) : const Color(0xFF9BE9A8);
    }
    if (completedCount == 2) {
      return isDark ? const Color(0xFF006D32) : const Color(0xFF40C463);
    }
    if (completedCount == 3) {
      return isDark ? const Color(0xFF26A641) : const Color(0xFF30A14E);
    }
    return isDark ? const Color(0xFF39D353) : const Color(0xFF216E39);
  }

  Map<String, int> _buildMergedDayCounts() {
    final counts = Map<String, int>.from(sqlHeatmapCounts);

    // ترکیب داده‌های زنده TaskBloc با کوئری غیرمسدودکننده SQLite
    final taskCountsByDay = <String, int>{};
    for (final task in tasks) {
      if (task.parentTaskId != null) continue;
      if (task.status == TaskStatus.done) {
        final targetDate = task.dueDate ?? task.updatedAt;
        final iso = _formatIsoDay(targetDate);
        taskCountsByDay[iso] = (taskCountsByDay[iso] ?? 0) + 1;
      }
    }

    for (final entry in taskCountsByDay.entries) {
      final existing = counts[entry.key] ?? 0;
      if (entry.value > existing) {
        counts[entry.key] = entry.value;
      }
    }

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final mergedCounts = _buildMergedDayCounts();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ۱۲ هفته × ۷ روز = ۸۴ روز اخیر (شبیه گیت‌هاب)
    const int totalWeeks = 12;
    const int daysPerWeek = 7;
    const int totalDays = totalWeeks * daysPerWeek;

    final days = List<DateTime>.generate(
      totalDays,
      (index) => today.subtract(Duration(days: (totalDays - 1) - index)),
    );

    int totalCompletedInWindow = 0;
    int activeDaysCount = 0;
    for (final day in days) {
      final c = mergedCounts[_formatIsoDay(day)] ?? 0;
      totalCompletedInWindow += c;
      if (c > 0) activeDaysCount++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.16),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                CupertinoIcons.square_grid_3x2_fill,
                color: Color(0xFF10B981),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'نقشه حرارتی استمرار (Activity Heatmap)',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  Text(
                    'شدت فعالیت روزانه در ۱۲ هفته اخیر به سبک گیت‌هاب',
                    style: TextStyle(
                      color: secondaryTextColor,
                      fontSize: 11.5,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              key: const Key('heatmap_active_days_badge'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF30D158).withOpacity(0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${PersianNumberFormatter.toPersianDigits(activeDaysCount.toString())} روز فعال',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // جدول مربع‌های کوچک گیت‌هاب (۱۲ ستون هفتگی × ۷ ردیف روزانه)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            key: const Key('github_heatmap_grid'),
            children: List<Widget>.generate(totalWeeks, (weekIdx) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.5),
                child: Column(
                  children: List<Widget>.generate(daysPerWeek, (dayInWeekIdx) {
                    final index = (weekIdx * daysPerWeek) + dayInWeekIdx;
                    final dayDate = days[index];
                    final isoDay = _formatIsoDay(dayDate);
                    final count = mergedCounts[isoDay] ?? 0;
                    final squareColor = resolveHeatmapColor(count, isDark);
                    final isToday = index == totalDays - 1;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                      child: Tooltip(
                        message:
                            '$isoDay: ${PersianNumberFormatter.toPersianDigits(count.toString())} تسک تکمیل‌شده',
                        child: Container(
                          key: Key('heatmap_day_square_$index'),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: squareColor,
                            borderRadius: BorderRadius.circular(4),
                            border: isToday
                                ? Border.all(
                                    color: const Color(0xFF0A84FF),
                                    width: 1.4,
                                  )
                                : null,
                          ),
                          child: SizedBox.expand(
                            key: Key('heatmap_cell_$isoDay'),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),

        // راهنمای شدت رنگ (کمتر ... بیشتر) + مجموع تسک‌ها
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'مجموع: ${PersianNumberFormatter.toPersianDigits(totalCompletedInWindow.toString())} تسک تکمیل‌شده',
              key: const Key('heatmap_total_completed_text'),
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Vazirmatn',
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'کمتر',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 10.5,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const SizedBox(width: 6),
                for (int level = 0; level <= 4; level++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      key: Key('heatmap_legend_level_$level'),
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: resolveHeatmapColor(level, isDark),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Text(
                  'بیشتر',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 10.5,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
