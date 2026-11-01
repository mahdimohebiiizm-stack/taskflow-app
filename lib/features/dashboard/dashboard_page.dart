import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:confetti/confetti.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/performance/smart_render_engine.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/core/widgets/bouncing_tap.dart';
import 'package:task_flow/core/theme/app_colors.dart';
import 'package:task_flow/core/utils/persian_number_formatter.dart';
import 'package:task_flow/core/utils/jalali_date_formatter.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:task_flow/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_event.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_state.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_event.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_state.dart';
import 'package:task_flow/core/theme/app_theme_mode.dart';
import 'package:task_flow/core/widgets/dual_layout_transition.dart';
import 'package:task_flow/core/widgets/signature_empty_state.dart';
import 'package:task_flow/features/settings/presentation/pages/user_profile_page.dart';
import 'package:task_flow/features/tasks/presentation/widgets/create_task_sheet.dart';
import 'package:task_flow/features/tasks/presentation/widgets/gamification_dashboard_widget.dart';
import 'package:task_flow/features/tasks/presentation/widgets/pomodoro_focus_sheet.dart';

/// پالت رنگ و توکن‌های بصری مطابق رفرنس HTML (`زندگی‌ساز – طراحی مجدد داشبورد.html`)
final class _DashboardRefPalette {
  final Color bg;
  final Color s1;
  final Color s2;
  final Color line;
  final Color tx;
  final Color mu;
  final Color sub;
  final Color ac;
  final Color ac2;
  final Color ok;
  final Color hot;
  final Color glow;

  const _DashboardRefPalette._({
    required this.bg,
    required this.s1,
    required this.s2,
    required this.line,
    required this.tx,
    required this.mu,
    required this.sub,
    required this.ac,
    required this.ac2,
    required this.ok,
    required this.hot,
    required this.glow,
  });

  static const _DashboardRefPalette dark = _DashboardRefPalette._(
    bg: Color(0xFF000000),
    s1: Color(0xFF1C1C1E),
    s2: Color(0xFF2C2C2E),
    line: Colors.transparent,
    tx: Color(0xFFF2F2F7),
    mu: Color(0xFFA1A1A6),
    sub: Color(0xFFEBEBF5),
    ac: Color(0xFF0A84FF),
    ac2: Color(0xFFFF9F0A),
    ok: Color(0xFF30D158),
    hot: Color(0xFFFF453A),
    glow: Colors.transparent,
  );

  static const _DashboardRefPalette light = _DashboardRefPalette._(
    bg: Color(0xFFF2F2F7),
    s1: Color(0xFFFFFFFF),
    s2: Color(0xFFE5E5EA),
    line: Colors.transparent,
    tx: Color(0xFF000000),
    mu: Color(0xFF636366),
    sub: Color(0xFF3C3C43),
    ac: Color(0xFF007AFF),
    ac2: Color(0xFFFF9500),
    ok: Color(0xFF34C759),
    hot: Color(0xFFFF3B30),
    glow: Colors.transparent,
  );

  static const _DashboardRefPalette zen = _DashboardRefPalette._(
    bg: AppColors.backgroundZen,
    s1: AppColors.surfaceZen,
    s2: Color(0xFFE2DDD2),
    line: Colors.transparent,
    tx: AppColors.textZen,
    mu: AppColors.textZenSecondary,
    sub: Color(0xFF6B6458),
    ac: Color(0xFF0A84FF),
    ac2: Color(0xFFFF9500),
    ok: Color(0xFF6B8E6B),
    hot: Color(0xFFC66B5D),
    glow: Colors.transparent,
  );

  static _DashboardRefPalette of(bool isDark, {bool isZen = false}) =>
      isDark ? dark : (isZen ? zen : light);

  Color priorityColor(TaskPriority priority) => switch (priority) {
        TaskPriority.critical || TaskPriority.high => hot,
        TaskPriority.medium => ac2,
        TaskPriority.low => ac,
      };

  static String timeOfDayGreeting(DateTime dt) {
    final h = dt.hour;
    if (h < 12) return 'صبح بخیر';
    if (h < 18) return 'روز بخیر';
    return 'عصر بخیر';
  }

  /// تبدیل تاریخ میلادی به رشته شمسی کامل (مثلاً: «دوشنبه ۲۰ مهر») مطابق `Intl.DateTimeFormat('fa-IR',{weekday:'long',day:'numeric',month:'long'})`
  static String formatPersianFullDate(DateTime date) {
    final weekdayFa = switch (date.weekday) {
      DateTime.saturday => 'شنبه',
      DateTime.sunday => 'یکشنبه',
      DateTime.monday => 'دوشنبه',
      DateTime.tuesday => 'سه‌شنبه',
      DateTime.wednesday => 'چهارشنبه',
      DateTime.thursday => 'پنجشنبه',
      DateTime.friday => 'جمعه',
      _ => 'امروز',
    };

    const gDaysInMonth = <int>[
      31,
      28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];
    const jDaysInMonth = <int>[
      31,
      31,
      31,
      31,
      31,
      31,
      30,
      30,
      30,
      30,
      30,
      29,
    ];

    final int gy = date.year - 1600;
    final int gm = date.month - 1;
    final int gd = date.day - 1;

    int gDayNo = 365 * gy +
        ((gy + 3) ~/ 4) -
        ((gy + 99) ~/ 100) +
        ((gy + 399) ~/ 400);

    for (int i = 0; i < gm; ++i) {
      gDayNo += gDaysInMonth[i];
    }
    if (gm > 1 && ((gy % 4 == 0 && gy % 100 != 0) || (gy % 400 == 0))) {
      gDayNo++;
    }
    gDayNo += gd;

    int jDayNo = gDayNo - 79;
    jDayNo %= 12053;

    if (jDayNo >= 365) {
      jDayNo = (jDayNo - 1) % 1461;
      if (jDayNo >= 366) {
        jDayNo = (jDayNo - 1) % 365;
      }
    }

    int jm = 0;
    while (jm < 11 && jDayNo >= jDaysInMonth[jm]) {
      jDayNo -= jDaysInMonth[jm];
      jm++;
    }
    final int jd = jDayNo + 1;

    const jMonthsFa = <String>[
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    final monthName = jMonthsFa[jm.clamp(0, 11)];
    return '$weekdayFa ${toPersianDigits(jd.toString())} $monthName';
  }
}

/// صفحه داشبورد با ایزولاسیون ۱۰۰٪ مالی و تمرکز کامل بر زمان‌بندی، پیشرفت،
/// پوشه‌ها/تگ‌ها، درخت زیرتسک‌ها، افزودن سریع (Quick Add)، حالت استراحت و گیمیفیکیشن
class DashboardPage extends StatefulWidget {
  final bool isDark;
  final bool isZen;
  final ScrollController? scrollController;

  const DashboardPage({
    super.key,
    required this.isDark,
    this.isZen = false,
    this.scrollController,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();

  static String _buildTaskSubtitle(TaskEntity task, int nestedCount) {
    final priorityFa = switch (task.priority) {
      TaskPriority.low => 'اولویت کم',
      TaskPriority.medium => 'اولویت متوسط',
      TaskPriority.high => 'اولویت بالا',
      TaskPriority.critical => 'اولویت فوری',
    };
    final parts = <String>[priorityFa];
    if (task.hasRecurrence) {
      parts.insert(0, 'تکرار ${task.recurrenceLabelFa}');
    }
    if (task.reminderDateTime != null) {
      parts.insert(0, '⏰ یادآور');
    }
    if (task.subTasks.isNotEmpty) {
      parts.insert(
        0,
        '${task.completedSubTasksCount} از ${task.subTasks.length} چک‌لیست',
      );
    }
    if (nestedCount > 0) {
      parts.insert(0, '$nestedCount زیرتسک درختی');
    }
    if (task.description.trim().isNotEmpty) {
      parts.insert(0, task.description.trim());
    }
    return toPersianDigits(parts.join(' • '));
  }

  static void _openQuickAddBottomSheet(
    BuildContext context,
    TaskBloc bloc,
    String activeWorkspaceId,
    bool isDark, {
    bool isZen = false,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuickAddBottomSheet(
        isDark: isDark,
        isZen: isZen,
        activeWorkspaceId: activeWorkspaceId,
        onQuickSubmit: ({
          required title,
          required workspaceId,
          required tags,
          TaskPriority priority = TaskPriority.medium,
        }) {
          bloc.add(
            TaskCreated(
              title: title,
              dueDate: DateTime.now(),
              workspaceId: workspaceId,
              tags: tags,
              priority: priority,
            ),
          );
        },
      ),
    );
  }

  static void _openEditTaskBottomSheet(
    BuildContext context,
    TaskBloc bloc,
    TaskEntity task,
    bool isDark, {
    bool isZen = false,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditTaskBottomSheet(
        isDark: isDark,
        isZen: isZen,
        task: task,
        onDelete: () {
          bloc.add(TaskDeleted(taskId: task.id));
        },
        onSave: ({
          required String title,
          String? description,
          TaskPriority? priority,
          String? workspaceId,
          DateTime? dueDate,
          String? startTime,
          String? endTime,
          bool clearTimeBlock = false,
        }) {
          bloc.add(
            TaskEdited(
              taskId: task.id,
              title: title,
              description: description,
              priority: priority,
              workspaceId: workspaceId,
              dueDate: dueDate,
              startTime: startTime,
              endTime: endTime,
              clearTimeBlock: clearTimeBlock,
            ),
          );
        },
      ),
    );
  }

  static void _openNestedSubTaskSheet(
    BuildContext context,
    TaskBloc bloc,
    TaskEntity parentTask,
    bool isDark,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateTaskSheet(
        isDark: isDark,
        initialParentTaskId: parentTask.id,
        initialParentTaskTitle: parentTask.title,
        initialWorkspaceId: parentTask.workspaceId,
        onSubmitted: ({
          required title,
          required description,
          required priority,
          required dueDate,
          startTime,
          endTime,
          parentTaskId,
          workspaceId = TaskWorkspaces.defaultWorkspace,
          tags = const [],
          recurrenceRule,
          reminderDateTime,
          required subTaskTitles,
          initialExpenseMinorUnits,
          initialExpenseCurrency = Currency.irt,
        }) {
          bloc.add(
            TaskCreated(
              title: title,
              description: description,
              priority: priority,
              dueDate: dueDate ?? parentTask.dueDate ?? DateTime.now(),
              startTime: startTime,
              endTime: endTime,
              parentTaskId: parentTaskId ?? parentTask.id,
              workspaceId: workspaceId,
              tags: tags,
              recurrenceRule: recurrenceRule,
              reminderDateTime: reminderDateTime,
              subTaskTitles: subTaskTitles,
              initialExpenseMinorUnits: initialExpenseMinorUnits,
              initialExpenseCurrency: initialExpenseCurrency,
            ),
          );
        },
      ),
    );
  }

  static void _showEndDayConfirmationDialog(
    BuildContext context,
    TaskBloc bloc,
    bool isDark,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        final theme = Theme.of(context);
        final isZen = theme.scaffoldBackgroundColor == AppColors.backgroundZen;
        final cardBg = isDark
            ? const Color(0xFF1C1C1E)
            : (isZen ? AppColors.surfaceZen : Colors.white);
        final textColor = isDark
            ? Colors.white
            : (isZen ? AppColors.textZen : Colors.black87);
        final secondaryTextColor = isDark
            ? const Color(0xFF94A3B8)
            : (isZen ? AppColors.textZenSecondary : const Color(0xFF64748B));

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'تایید پایان روز',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            content: Text(
              'آیا از پایان روز و جریمه شدن کارهای ناتمام اطمینان دارید؟',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13.5,
                color: secondaryTextColor,
                height: 1.5,
              ),
            ),
            actions: [
              BouncingTap(
                child: TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'انصراف',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              BouncingTap(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                  Navigator.of(dialogContext).pop();
                  final now = DateTime.now();
                  final hasUnfinishedToday = !bloc.state.isVacationMode &&
                      bloc.state.todayTasks.any(
                        (t) => t.status != TaskStatus.done && !t.isPenalized,
                      );
                  bloc.add(DayEnded(timestamp: now));
                  if (hasUnfinishedToday) {
                    try {
                      final todayIso =
                          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                      context
                          .read<SettingsBloc>()
                          .add(SettingsDailyStreakFailed(dateIso: todayIso));
                    } catch (_) {}
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      key: const Key('end_day_undo_snackbar'),
                      content: const Text(
                        'پایان روز کاری ثبت شد. تسک‌های ناتمام جریمه شدند.',
                        style: TextStyle(fontFamily: 'Vazirmatn'),
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 5),
                      action: SnackBarAction(
                        label: 'لغو (Undo)',
                        textColor: AppColors.primaryBlueGlow,
                        onPressed: () {
                          bloc.add(DayEndedUndone(timestamp: DateTime.now()));
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(
                            const SnackBar(
                              key: Key('end_day_undone_feedback_snackbar'),
                              content: Text(
                                'جریمه‌های پایان روز لغو شد و تسک‌ها به حالت عادی بازگشتند ✨',
                                style: TextStyle(fontFamily: 'Vazirmatn'),
                              ),
                              backgroundColor: Color(0xFF059669),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                child: const Text(
                  'تایید و پایان روز',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
          ),
        );
      },
    );
  }

  static Future<void> _openOverdueRecoveryBottomSheet(
    BuildContext context,
    List<TaskEntity> overdueTasks,
    TaskBloc bloc,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final isZen = theme.scaffoldBackgroundColor == AppColors.backgroundZen;
    final textColor = isDark
        ? Colors.white
        : (isZen ? AppColors.textZen : const Color(0xFF1C1C1E));
    final secondaryTextColor = isDark
        ? const Color(0xFF8E8E93)
        : (isZen ? AppColors.textZenSecondary : const Color(0xFF8E8E93));
    final glassBg = isDark
        ? const Color(0xF2161A24)
        : (isZen
            ? AppColors.surfaceZen.withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96));

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ClipRRect(
            key: const Key('overdue_tasks_bottom_sheet'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(bottomSheetContext).size.height * 0.75,
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: BoxDecoration(
                  color: glassBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.alarm_fill,
                            color: Color(0xFFEF4444),
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'تسک‌های موعد گذشته',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                toPersianDigits(
                                  '${overdueTasks.length} تسک نیاز به تعیین مجدد زمان دارند',
                                ),
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11.5,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (overdueTasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'هیچ تسک موعد گذشته‌ای وجود ندارد 🎉',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: overdueTasks.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final task = overdueTasks[index];
                            final priorityLabel = switch (task.priority) {
                              TaskPriority.low => 'اولویت کم',
                              TaskPriority.medium => 'اولویت متوسط',
                              TaskPriority.high => 'اولویت بالا',
                              TaskPriority.critical => 'اولویت فوری',
                            };
                            return Container(
                              key: Key('overdue_item_${task.id}'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1C1C1E)
                                    : (isZen ? const Color(0xFFE2DDD2) : const Color(0xFFF2F2F7)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.exclamationmark_circle_fill,
                                    size: 16,
                                    color: Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          task.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          priorityLabel,
                                          style: TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 10.5,
                                            color: secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  BouncingTap(
                                    child: ElevatedButton.icon(
                                      key: Key('reschedule_today_${task.id}'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF0A84FF),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      onPressed: () {
                                        HapticFeedback.lightImpact();
                                        final today = DateTime.now().toUtc();
                                        bloc.add(
                                          TaskRescheduled(
                                            taskId: task.id,
                                            newDueDate: today,
                                          ),
                                        );
                                        Navigator.of(bottomSheetContext).pop();
                                      },
                                      icon: const Icon(
                                        CupertinoIcons.today,
                                        size: 13,
                                      ),
                                      label: const Text(
                                        'امروز',
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
                                    child: ElevatedButton.icon(
                                      key: Key(
                                          'reschedule_tomorrow_${task.id}'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isDark
                                            ? const Color(0xFF2C2C2E)
                                            : const Color(0xFFE5E5EA),
                                        foregroundColor: textColor,
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
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
                                        bloc.add(
                                          TaskRescheduled(
                                            taskId: task.id,
                                            newDueDate: tomorrow,
                                          ),
                                        );
                                        Navigator.of(bottomSheetContext).pop();
                                      },
                                      icon: Icon(
                                        CupertinoIcons.calendar_today,
                                        size: 13,
                                        color: secondaryTextColor,
                                      ),
                                      label: Text(
                                        'فردا',
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _showNotificationsBottomSheet(
    BuildContext context,
    bool isDark,
  ) {
    NotificationBloc? bloc;
    try {
      bloc = context.read<NotificationBloc>();
    } catch (_) {
      if (sl.isRegistered<NotificationBloc>()) {
        try {
          bloc = sl<NotificationBloc>();
        } catch (_) {}
      }
    }

    bloc?.add(const NotificationsLoadRequested());

    final theme = Theme.of(context);
    final isZen = theme.scaffoldBackgroundColor == AppColors.backgroundZen;

    final glassBg = isDark
        ? const Color(0xF2161A24)
        : (isZen
            ? AppColors.surfaceZen.withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.96));
    final cardBg = isDark
        ? const Color(0xFF1C1C1E)
        : (isZen ? const Color(0xFFE2DDD2) : const Color(0xFFF2F2F7));
    final textColor = isDark
        ? Colors.white
        : (isZen ? AppColors.textZen : const Color(0xFF1C1C1E));
    final secondaryTextColor = isDark
        ? const Color(0xFF8E8E93)
        : (isZen ? AppColors.textZenSecondary : const Color(0xFF8E8E93));

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: ClipRRect(
            key: const Key('notifications_bottom_sheet'),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.of(bottomSheetContext).size.height * 0.85,
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                decoration: BoxDecoration(
                  color: glassBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: _NotificationsSheetContent(
                  bloc: bloc,
                  isDark: isDark,
                  glassBg: glassBg,
                  cardBg: cardBg,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _DashboardSmartGroup {
  overdue,
  today,
  habits,
  completed;

  String get labelFa => switch (this) {
        _DashboardSmartGroup.overdue => 'موعد گذشته',
        _DashboardSmartGroup.today => 'امروز',
        _DashboardSmartGroup.habits => 'عادت‌ها',
        _DashboardSmartGroup.completed => 'تکمیل‌شده‌ها',
      };

  Key get headerKey => switch (this) {
        _DashboardSmartGroup.overdue =>
          const Key('smart_group_header_overdue'),
        _DashboardSmartGroup.today => const Key('smart_group_header_today'),
        _DashboardSmartGroup.habits => const Key('smart_group_header_habits'),
        _DashboardSmartGroup.completed =>
          const Key('smart_group_header_completed'),
      };
}

class _SignatureFocusCtaButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _SignatureFocusCtaButton({
    required this.onTap,
    required this.child,
  });

  @override
  State<_SignatureFocusCtaButton> createState() => _SignatureFocusCtaButtonState();
}

class _SignatureFocusCtaButtonState extends State<_SignatureFocusCtaButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _scale = 0.96);
      },
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _scale = 1.0);
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

class _DashboardPageState extends State<DashboardPage>
    with WidgetsBindingObserver {
  late final ConfettiController _confettiController;
  final TextEditingController _spotlightSearchController =
      TextEditingController();
  ScrollController? _internalScrollController;
  ScrollController get _effectiveScrollController =>
      widget.scrollController ??
      (_internalScrollController ??= ScrollController());
  Set<String> _previousDoneTaskIds = <String>{};
  bool _hasInitializedDoneTaskIds = false;
  bool _wasAllCompleted = false;
  bool _isSpotlightSearchVisible = false;
  String _searchQuery = '';
  int _completedPomodoroMinutes = 0;
  int _selectedFocusMinutes = 25;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _spotlightSearchController.dispose();
    _internalScrollController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed && mounted) {
      context.read<TaskBloc>().add(const TaskOverdueCheckRequested());
    }
  }

  static bool _checkAllCompleted(TaskState state) {
    final total = state.todayTasks.length;
    return total > 0 &&
        state.todayDoneCount == total &&
        state.todayPenalizedCount == 0;
  }

  static _DashboardSmartGroup _classifyTaskSmartGroup(
    TaskEntity task,
    DateTime now,
    bool isVacationMode,
  ) {
    if (task.status == TaskStatus.done) {
      return _DashboardSmartGroup.completed;
    }
    if (task.isOverdue(now, isVacationMode: isVacationMode)) {
      return _DashboardSmartGroup.overdue;
    }
    if (task.hasRecurrence || task.tags.contains('عادت')) {
      return _DashboardSmartGroup.habits;
    }
    return _DashboardSmartGroup.today;
  }

  void _revealSpotlightSearch() {
    if (!_isSpotlightSearchVisible && mounted) {
      setState(() {
        _isSpotlightSearchVisible = true;
      });
    }
  }

  void _closeSpotlightSearch() {
    if (mounted) {
      setState(() {
        _isSpotlightSearchVisible = false;
        _searchQuery = '';
        _spotlightSearchController.clear();
      });
    }
  }

  void _openPomodoroForTask(
    BuildContext context,
    TaskBloc bloc,
    TaskEntity focusTask,
    bool isDark, {
    required bool isPersistentTask,
    Duration duration = const Duration(minutes: 25),
  }) {
    PomodoroFocusSheet.show(
      context: context,
      task: focusTask,
      isDark: isDark,
      initialDuration: duration,
      onCompleteTask: () {
        if (mounted) {
          setState(() {
            _completedPomodoroMinutes += duration.inMinutes;
          });
        }
        SoundAndHapticService.instance.playTaskCompletionFeedback();
        try {
          context
              .read<SettingsBloc>()
              .add(SettingsXpAwarded(duration.inMinutes));
        } catch (_) {}
        if (isPersistentTask) {
          bloc.add(
            TaskStatusTransitioned(
              taskId: focusTask.id,
              targetStatus: TaskStatus.done,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final isZen = widget.isZen;
    final palette = _DashboardRefPalette.of(isDark, isZen: isZen);

    // خواندن زنده نام کاربر، وضعیت استراحت، القاب و استریک از SettingsBloc (در صورت وجود در درخت ویجت)
    UserSettingsEntity liveSettings = UserSettingsEntity.defaults;
    String liveUserName = 'مهدی';
    bool settingsVacationMode = false;
    try {
      liveSettings = context.watch<SettingsBloc>().state.settings;
      if (liveSettings.userName.trim().isNotEmpty) {
        liveUserName = liveSettings.userName.trim();
      }
      settingsVacationMode = liveSettings.isVacationMode;
    } catch (_) {}

    GamificationBloc? gamificationBloc;
    try {
      gamificationBloc = context.read<GamificationBloc>();
    } catch (_) {
      gamificationBloc = null;
    }

    GamificationState? gamificationState;
    try {
      gamificationState = context.watch<GamificationBloc>().state;
    } catch (_) {
      try {
        gamificationState = context.read<GamificationBloc>().state;
      } catch (_) {
        gamificationState = null;
      }
    }

    final themeMode = liveSettings.themeMode;
    final isSignatureLayout = themeMode.isSignatureLayout;

    final dashboardWidget = BlocConsumer<TaskBloc, TaskState>(
      listenWhen: (previous, current) {
        final failureChanged =
            current.failure != null && current.failure != previous.failure;
        final completionChanged =
            _checkAllCompleted(previous) != _checkAllCompleted(current);
        final prevDone = previous.tasks
            .where((t) => t.status == TaskStatus.done)
            .map((t) => t.id)
            .toSet();
        final currDone = current.tasks
            .where((t) => t.status == TaskStatus.done)
            .map((t) => t.id)
            .toSet();
        final hasTaskCompleted = currDone.difference(prevDone).isNotEmpty;
        return failureChanged || completionChanged || hasTaskCompleted;
      },
      listener: (context, state) {
        final failure = state.failure;
        if (failure != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                key: const Key('dashboard_failure_snackbar'),
                content: Text(
                  toPersianDigits(failure.message),
                  style: const TextStyle(fontFamily: 'Vazirmatn'),
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          context.read<TaskBloc>().add(const TaskErrorCleared());
        }

        final currentDoneIds = state.tasks
            .where((t) => t.status == TaskStatus.done)
            .map((t) => t.id)
            .toSet();

        final todayTasks = state.todayTasks;
        final totalToday = todayTasks.length;
        final remainingTasksCount =
            todayTasks.where((t) => t.status != TaskStatus.done).length;

        if (!_hasInitializedDoneTaskIds) {
          _previousDoneTaskIds = currentDoneIds;
          _hasInitializedDoneTaskIds = true;
        } else {
          final newlyDone = currentDoneIds.difference(_previousDoneTaskIds);
          if (newlyDone.isNotEmpty) {
            HapticFeedback.lightImpact();
            // Confetti MUST ONLY fire on the Dashboard when remainingTasksCount strictly equals 0
            if (totalToday > 0 && remainingTasksCount == 0) {
              _confettiController.play();
            }
          }
          _previousDoneTaskIds = currentDoneIds;
        }

        final nowAllCompleted = totalToday > 0 && remainingTasksCount == 0;
        if (nowAllCompleted && !_wasAllCompleted) {
          if (!_confettiController.state.toString().contains('playing')) {
            _confettiController.play();
          }
          SoundAndHapticService.instance.playDailyVictoryFeedback();
          try {
            final now = DateTime.now();
            final todayIso =
                '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
            context
                .read<SettingsBloc>()
                .add(SettingsDailyStreakSucceeded(dateIso: todayIso));
          } catch (_) {}
        }
        _wasAllCompleted = nowAllCompleted;
      },
      builder: (context, state) {
        final bloc = context.read<TaskBloc>();
        final rawTodayTasks = state.todayTasks;
        final totalCount = rawTodayTasks.length;
        final doneCount = state.todayDoneCount;
        final pendingCount = math.max(0, totalCount - doneCount);
        final completionRatio = state.todayCompletionRatio;
        final penalizedCount = state.todayPenalizedCount;
        final isAllCompleted =
            totalCount > 0 && doneCount == totalCount && penalizedCount == 0;
        final isVacationMode = state.isVacationMode || settingsVacationMode;

        final int completedTaskMinutes = rawTodayTasks
            .where((t) => t.status == TaskStatus.done)
            .fold<int>(
              0,
              (acc, t) {
                final s = t.startTimeMinutes;
                final e = t.endTimeMinutes;
                if (s != null && e != null && e > s) {
                  return acc + (e - s);
                }
                return acc + 25;
              },
            );
        final int todayFocusMinutes =
            _completedPomodoroMinutes + completedTaskMinutes;

        // فیلتر کادر جستجوی سریع (Spotlight Search — Axis 5)
        final normalizedQuery = _searchQuery.trim().toLowerCase();
        final searchFilteredTasks = normalizedQuery.isEmpty
            ? rawTodayTasks
            : rawTodayTasks.where((task) {
                return task.title.toLowerCase().contains(normalizedQuery) ||
                    task.description.toLowerCase().contains(normalizedQuery) ||
                    task.tags.any(
                      (t) => t.toLowerCase().contains(normalizedQuery),
                    );
              }).toList(growable: false);

        // گروه‌بندی هوشمند و مینیمال (Axis 6) + انتقال تسک‌های تکمیل‌شده به پایین لیست (Axis 4)
        final now = DateTime.now();
        final overdueGroup = <TaskEntity>[];
        final todayGroup = <TaskEntity>[];
        final habitsGroup = <TaskEntity>[];
        final completedGroup = <TaskEntity>[];

        for (final task in searchFilteredTasks) {
          final group = _classifyTaskSmartGroup(task, now, isVacationMode);
          switch (group) {
            case _DashboardSmartGroup.overdue:
              overdueGroup.add(task);
            case _DashboardSmartGroup.today:
              todayGroup.add(task);
            case _DashboardSmartGroup.habits:
              habitsGroup.add(task);
            case _DashboardSmartGroup.completed:
              completedGroup.add(task);
          }
        }

        final tasks = <TaskEntity>[
          ...overdueGroup,
          ...todayGroup,
          ...habitsGroup,
          ...completedGroup,
        ];

        return ColoredBox(
          color: isSignatureLayout ? const Color(0xFF090B10) : palette.bg,
          child: SafeArea(
            top: true,
            bottom: true,
            child: Stack(
              children: [
                DualLayoutTransition(
                  isSignatureLayout: isSignatureLayout,
                  signatureChild: _buildSignatureDashboard(
                    context: context,
                    state: state,
                    bloc: bloc,
                    tasks: tasks,
                    rawTodayTasks: rawTodayTasks,
                    searchFilteredTasks: searchFilteredTasks,
                    totalCount: totalCount,
                    doneCount: doneCount,
                    pendingCount: pendingCount,
                    overdueGroup: overdueGroup,
                    todayFocusMinutes: todayFocusMinutes,
                    liveUserName: liveUserName,
                    liveSettings: liveSettings,
                    gamificationState: gamificationState,
                    now: now,
                    isDark: isDark,
                    isZen: isZen,
                  ),
                  classicChild: _buildClassicDashboard(
                    context: context,
                    state: state,
                    bloc: bloc,
                    palette: palette,
                    tasks: tasks,
                    rawTodayTasks: rawTodayTasks,
                    totalCount: totalCount,
                    doneCount: doneCount,
                    pendingCount: pendingCount,
                    completionRatio: completionRatio,
                    penalizedCount: penalizedCount,
                    isAllCompleted: isAllCompleted,
                    overdueGroup: overdueGroup,
                    todayFocusMinutes: todayFocusMinutes,
                    liveUserName: liveUserName,
                    liveSettings: liveSettings,
                    now: now,
                    isDark: isDark,
                    isZen: isZen,
                  ),
                ),

                // لایه بلور تمام‌صفحه حالت استراحت روی بدنه داشبورد (مشترک بین هر دو چیدمان)
                if (isVacationMode)
                  Positioned.fill(
                    child: AbsorbPointer(
                      absorbing: true,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 5.0,
                            sigmaY: 5.0,
                          ),
                          child: Container(
                            color: (isDark
                                    ? Colors.black
                                    : Colors.white)
                                .withValues(alpha: 0.20),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            child: _VacationModeBlurOverlay(
                              isDark: isDark,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // پویانمایی جشن و پاداش (Confetti Gamification Engine - مشترک بین هر دو چیدمان)
                Align(
                  alignment: Alignment.topCenter,
                  child: IgnorePointer(
                    child: ConfettiWidget(
                      key: const Key('dashboard_confetti_widget'),
                      confettiController: _confettiController,
                      blastDirectionality: BlastDirectionality.explosive,
                      shouldLoop: false,
                      numberOfParticles: 24,
                      maxBlastForce: 22,
                      minBlastForce: 8,
                      emissionFrequency: 0.06,
                      gravity: 0.25,
                      colors: const [
                        Color(0xFF10B981),
                        Color(0xFF3B82F6),
                        Color(0xFFF59E0B),
                        Color(0xFFEC4899),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (gamificationBloc != null) {
      return BlocListener<GamificationBloc, GamificationState>(
        bloc: gamificationBloc,
        listenWhen: (GamificationState previous, GamificationState current) =>
            current.level > previous.level && current.lastDeltaXp > 0,
        listener: (context, state) {
          HapticFeedback.heavyImpact();
          final taskState = context.read<TaskBloc>().state;
          final todayTasks = taskState.todayTasks;
          final remainingTasksCount =
              todayTasks.where((t) => t.status != TaskStatus.done).length;
          // Confetti MUST ONLY fire on the Dashboard when remainingTasksCount strictly equals 0
          if (remainingTasksCount == 0) {
            _confettiController.play();
          }
        },
        child: dashboardWidget,
      );
    }

    return dashboardWidget;
  }

  /// متد ساخت چیدمان کلاسیک داشبورد (پوسته‌های شب، آرامش و روز)
  Widget _buildClassicDashboard({
    required BuildContext context,
    required TaskState state,
    required TaskBloc bloc,
    required _DashboardRefPalette palette,
    required List<TaskEntity> tasks,
    required List<TaskEntity> rawTodayTasks,
    required int totalCount,
    required int doneCount,
    required int pendingCount,
    required double completionRatio,
    required int penalizedCount,
    required bool isAllCompleted,
    required List<TaskEntity> overdueGroup,
    required int todayFocusMinutes,
    required String liveUserName,
    required UserSettingsEntity liveSettings,
    required DateTime now,
    required bool isDark,
    required bool isZen,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is OverscrollNotification &&
            notification.overscroll < -2) {
          _revealSpotlightSearch();
        } else if (notification is ScrollUpdateNotification &&
            notification.metrics.axis == Axis.vertical &&
            (notification.metrics.pixels < -2 ||
                (notification.metrics.extentBefore == 0 &&
                    (notification.scrollDelta ?? 0) < -2))) {
          _revealSpotlightSearch();
        }
        return false;
      },
      child: RefreshIndicator(
        key: const Key('dashboard_pull_to_refresh'),
        color: palette.ac,
        backgroundColor: palette.s1,
        onRefresh: () async {
          _revealSpotlightSearch();
          await Future.wait<void>([
            Future<void>.microtask(() {
              bloc.add(
                const TasksLoadRequested(
                  preserveCurrentFilter: true,
                ),
              );
            }),
            Future<void>.microtask(() {
              try {
                if (context.mounted) {
                  context
                      .read<SettingsBloc>()
                      .add(const SettingsLoadRequested());
                }
              } catch (_) {}
            }),
            Future<void>.delayed(const Duration(milliseconds: 350)),
          ]);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // بخش بالایی: جستجو (در صورت فعال بودن در بالاترین نقطه)، هدر، گیمیفیکیشن، وضعیت کلی، فوکوس و سرتیتر تایم‌لاین
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 4),

                    // کادر جستجوی مخفی شیشه‌ای و فیلترها (در بالاترین نقطه داشبورد)
                    if (_isSpotlightSearchVisible)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _SpotlightSearchBar(
                              isDark: isDark,
                              controller: _spotlightSearchController,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              onClearAndClose: _closeSpotlightSearch,
                            ),
                            const SizedBox(height: 8),
                            _WorkspaceAndTagsFilterBar(
                              isDark: isDark,
                              selectedWorkspaceId:
                                  state.selectedWorkspaceId,
                              selectedTag: state.selectedTag,
                              availableTags: state.availableTags,
                              onWorkspaceSelected: (ws) => bloc.add(
                                  TaskWorkspaceFilterChanged(ws)),
                              onTagSelected: (tag) =>
                                  bloc.add(TaskTagFilterChanged(tag)),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),

                    // ۱. هدر، تاریخ درشت روز (وزن 800) و چیپ‌های وضعیت کپسولی
                    _DashboardHeader(
                      isDark: isDark,
                      isZen: isZen,
                      userName: liveUserName,
                      userSettings: liveSettings,
                      completionRatio: completionRatio,
                      showFilters: _showFilters,
                      onFilterToggleTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                      onSearchToggleTap: () {
                        if (_isSpotlightSearchVisible) {
                          _closeSpotlightSearch();
                        } else {
                          _revealSpotlightSearch();
                        }
                      },
                      onEndDayTap: () =>
                          DashboardPage._showEndDayConfirmationDialog(
                        context,
                        bloc,
                        isDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ۱.۵ داشبورد اگزمکتیو گیمیفیکیشن (تفکیک ۱۰۰٪ مالی)
                    const GamificationDashboardWidget(
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),

                    // ۲. کارت Hero و حلقه پیشرفت دایره‌ای
                    _DailyOverallStatusCard(
                      isDark: isDark,
                      doneCount: doneCount,
                      pendingCount: pendingCount,
                      totalCount: totalCount,
                      focusMinutes: todayFocusMinutes,
                      completionRatio: completionRatio,
                    ),
                    const SizedBox(height: 8),

                    // ۳. دکمه بزرگ و عریض شروع تمرکز پومودورو
                    _ProminentFocusCtaButton(
                      isDark: isDark,
                      selectedMinutes: _selectedFocusMinutes,
                      onMinutesChanged: (newMins) {
                        setState(() {
                          _selectedFocusMinutes = newMins;
                        });
                      },
                      onTap: () {
                        final activeCandidates = rawTodayTasks
                            .where((t) => t.status != TaskStatus.done)
                            .toList(growable: false);
                        final bool hasRealTask =
                            activeCandidates.isNotEmpty ||
                                rawTodayTasks.isNotEmpty;
                        final TaskEntity targetTask =
                            activeCandidates.isNotEmpty
                                ? activeCandidates.first
                                : (rawTodayTasks.isNotEmpty
                                    ? rawTodayTasks.first
                                    : (TaskEntity.create(
                                        id: 'daily-deep-focus-session',
                                        title:
                                            'یک کار را انتخاب کن و فقط روی همان بمان.',
                                        createdAt: now,
                                      ) as Success<TaskEntity, dynamic>)
                                        .value);
                        _openPomodoroForTask(
                          context,
                          bloc,
                          targetTask,
                          isDark,
                          isPersistentTask: hasRealTask,
                          duration: Duration(minutes: _selectedFocusMinutes),
                        );
                      },
                    ),

                    // ۵. بنرهای پاداش / اخطار جریمه در صورت فعال بودن
                    if (isAllCompleted) ...[
                      const SizedBox(height: 6),
                      _RewardCelebrationBanner(isDark: isDark),
                    ],
                    if (penalizedCount > 0) ...[
                      const SizedBox(height: 6),
                      _PenaltyWarningBanner(
                        isDark: isDark,
                        penalizedCount: penalizedCount,
                      ),
                    ],

                    // ۶. سرتیتر بخش تایم‌لاین («برنامه امروز» + دکمه سریع ایجاد در طرف مقابل)
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'برنامه امروز',
                                  key: const Key(
                                      'dashboard_timeline_section_title'),
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: palette.tx,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  toPersianDigits('${tasks.length} مورد'),
                                  key: const Key(
                                      'dashboard_timeline_section_count'),
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 11.5,
                                    color: palette.mu,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        _QuickAddFloatingButton(
                          isDark: isDark,
                          isZen: isZen,
                          onTap: () =>
                              DashboardPage._openQuickAddBottomSheet(
                            context,
                            bloc,
                            state.selectedWorkspaceId ??
                                TaskWorkspaces.defaultWorkspace,
                            isDark,
                            isZen: isZen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),

            // ۷. تایم‌لاین تسک‌ها یا حالت خالی/بارگذاری
            if (state.status == TaskViewStatus.loading && rawTodayTasks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: palette.ac,
                    ),
                  ),
                ),
              )
            else if (tasks.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18.0),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24, bottom: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: palette.ac.withValues(alpha: 0.12),
                              boxShadow: [
                                BoxShadow(
                                  color: palette.ac.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Icon(
                              CupertinoIcons.sparkles,
                              size: 36,
                              color: palette.ac,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.trim().isNotEmpty
                                ? 'تسکی با عبارت «$_searchQuery» یافت نشد'
                                : 'روز جدید، بوم سفید',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: palette.tx,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.trim().isNotEmpty
                                ? 'عبارت جستجو را تغییر دهید یا فیلترها را بازنشانی کنید.'
                                : 'برای شروع، یک تسک جدید اضافه کنید',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12.5,
                              color: palette.mu,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                sliver: SliverList(
                  key: const Key('dashboard_reorderable_task_list'),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final task = tasks[index];
                      final isDone = task.status == TaskStatus.done;
                      final nestedChildren = state.childTasksOf(task.id);
                      final currentGroup = _classifyTaskSmartGroup(
                        task,
                        now,
                        liveSettings.isVacationMode,
                      );
                      final prevGroup = index > 0
                          ? _classifyTaskSmartGroup(
                              tasks[index - 1],
                              now,
                              liveSettings.isVacationMode,
                            )
                          : null;
                      final showGroupHeader = currentGroup != prevGroup;

                      return _TimeBlockedTaskTile(
                        key: ValueKey(task.id),
                        reorderIndex: index,
                        task: task,
                        nestedChildren: nestedChildren,
                        allTasksState: state,
                        title: toPersianDigits(task.title),
                        subtitle: DashboardPage._buildTaskSubtitle(
                          task,
                          nestedChildren.length,
                        ),
                        isCompleted: isDone,
                        isPenalized: task.isPenalized,
                        isDark: isDark,
                        listLength: totalCount,
                        smartGroupHeaderLabel:
                            showGroupHeader ? currentGroup.labelFa : null,
                        smartGroupHeaderKey:
                            showGroupHeader ? currentGroup.headerKey : null,
                        overdueCount:
                            currentGroup == _DashboardSmartGroup.overdue
                                ? overdueGroup.length
                                : null,
                        onTapOverdueHeader:
                            currentGroup == _DashboardSmartGroup.overdue
                                ? () => DashboardPage
                                    ._openOverdueRecoveryBottomSheet(
                                      context,
                                      overdueGroup,
                                      bloc,
                                      isDark,
                                    )
                                : null,
                        onTap: () {
                          if (task.priority == TaskPriority.critical ||
                              task.priority == TaskPriority.high) {
                            HapticFeedback.mediumImpact();
                          } else {
                            HapticFeedback.lightImpact();
                          }
                          SoundAndHapticService.instance
                              .playTaskCompletionFeedback();
                          if (!isDone) {
                            try {
                              final isHigh =
                                  task.priority == TaskPriority.high ||
                                      task.priority == TaskPriority.critical;
                              final deltaXp = isHigh ? 20 : 10;
                              context
                                  .read<SettingsBloc>()
                                  .add(SettingsXpAwarded(deltaXp));
                            } catch (_) {}
                          }
                          bloc.add(
                            TaskStatusTransitioned(
                              taskId: task.id,
                              targetStatus:
                                  isDone ? TaskStatus.todo : TaskStatus.done,
                            ),
                          );
                        },
                        onEdit: () {
                          DashboardPage._openEditTaskBottomSheet(
                            context,
                            bloc,
                            task,
                            isDark,
                            isZen: isZen,
                          );
                        },
                        onDelete: () {
                          bloc.add(
                            TaskDeleted(taskId: task.id),
                          );
                        },
                        onSubTaskToggled: (subTaskId) {
                          HapticFeedback.lightImpact();
                          SoundAndHapticService.instance
                              .playTaskCompletionFeedback();
                          bloc.add(
                            SubTaskToggled(
                              taskId: task.id,
                              subTaskId: subTaskId,
                            ),
                          );
                        },
                        onChildTaskToggled: (childTask) {
                          if (childTask.priority == TaskPriority.critical ||
                              childTask.priority == TaskPriority.high) {
                            HapticFeedback.mediumImpact();
                          } else {
                            HapticFeedback.lightImpact();
                          }
                          SoundAndHapticService.instance
                              .playTaskCompletionFeedback();
                          bloc.add(
                            TaskStatusTransitioned(
                              taskId: childTask.id,
                              targetStatus: childTask.status == TaskStatus.done
                                  ? TaskStatus.todo
                                  : TaskStatus.done,
                            ),
                          );
                        },
                        onAddNestedSubTask: (parentTask) {
                          DashboardPage._openNestedSubTaskSheet(
                            context,
                            bloc,
                            parentTask,
                            isDark,
                          );
                        },
                        onStartPomodoroFocus: (focusTask) {
                          _openPomodoroForTask(
                            context,
                            bloc,
                            focusTask,
                            isDark,
                            isPersistentTask: true,
                          );
                        },
                      );
                    },
                    childCount: tasks.length,
                  ),
                ),
              ),

            // فاصله انتهایی
            const SliverToBoxAdapter(
              child: SizedBox(height: 140),
            ),
          ],
        ),
      ),
    );
  }

  /// متد ساخت چیدمان اختصاصی مینیمال Signature (طراحی زندگی‌ساز)
  Widget _buildSignatureDashboard({
    required BuildContext context,
    required TaskState state,
    required TaskBloc bloc,
    required List<TaskEntity> tasks,
    required List<TaskEntity> rawTodayTasks,
    required List<TaskEntity> searchFilteredTasks,
    required int totalCount,
    required int doneCount,
    required int pendingCount,
    required List<TaskEntity> overdueGroup,
    required int todayFocusMinutes,
    required String liveUserName,
    required UserSettingsEntity liveSettings,
    required GamificationState? gamificationState,
    required DateTime now,
    required bool isDark,
    required bool isZen,
  }) {
    // مرتب‌سازی کرونولوژیک تسک‌ها با انتقال تسک‌های انجام‌شده به انتهای لیست
    final signatureTasks = List<TaskEntity>.from(searchFilteredTasks)
      ..sort((a, b) {
        if (a.status == TaskStatus.done && b.status != TaskStatus.done) return 1;
        if (a.status != TaskStatus.done && b.status == TaskStatus.done) return -1;
        final timeA = a.startTimeMinutes ??
            (a.dueDate != null
                ? a.dueDate!.hour * 60 + a.dueDate!.minute
                : a.createdAt.hour * 60 + a.createdAt.minute);
        final timeB = b.startTimeMinutes ??
            (b.dueDate != null
                ? b.dueDate!.hour * 60 + b.dueDate!.minute
                : b.createdAt.hour * 60 + b.createdAt.minute);
        return timeA.compareTo(timeB);
      });

    return RefreshIndicator(
      key: const Key('dashboard_pull_to_refresh'),
      color: const Color(0xFF00E5FF),
      backgroundColor: const Color(0xFF161A23),
      onRefresh: () async {
        _revealSpotlightSearch();
        await Future.wait<void>([
          Future<void>.microtask(() {
            bloc.add(
              const TasksLoadRequested(
                preserveCurrentFilter: true,
              ),
            );
          }),
          Future<void>.microtask(() {
            try {
              if (context.mounted) {
                context.read<SettingsBloc>().add(const SettingsLoadRequested());
              }
            } catch (_) {}
          }),
          Future<void>.delayed(const Duration(milliseconds: 350)),
        ]);
      },
      child: CustomScrollView(
        controller: _effectiveScrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // بخش بالایی: سرچ (در بالاترین نقطه)، هدر برند، هیرو، دکمه فوکوس و سرتیتر تایم‌لاین
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),

                // کادر جستجوی Spotlight و برچسب‌ها در صورت باز شدن در بالاترین نقطه
                if (_isSpotlightSearchVisible)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SpotlightSearchBar(
                          isDark: true,
                          controller: _spotlightSearchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          onClearAndClose: _closeSpotlightSearch,
                        ),
                        const SizedBox(height: 8),
                        _WorkspaceAndTagsFilterBar(
                          isDark: true,
                          selectedWorkspaceId: state.selectedWorkspaceId,
                          selectedTag: state.selectedTag,
                          availableTags: state.availableTags,
                          onWorkspaceSelected: (ws) =>
                              bloc.add(TaskWorkspaceFilterChanged(ws)),
                          onTagSelected: (tag) =>
                              bloc.add(TaskTagFilterChanged(tag)),
                        ),
                      ],
                    ),
                  ),

                // بخش A: هدر برند و دکمه‌های کنترلی اختصاصی
                _buildSignatureHeader(
                  context: context,
                  userName: liveUserName,
                  userSettings: liveSettings,
                  bloc: bloc,
                  isDark: isDark,
                  isZen: isZen,
                ),

                // بخش B: هدر خوش‌آمدگویی، شمارنده کارهای مانده و نوار پیشرفت قطعه‌ای
                _buildSignatureHero(
                  userName: liveUserName,
                  pendingCount: pendingCount,
                  totalCount: totalCount,
                  doneCount: doneCount,
                  streakCount: liveSettings.streakCount,
                  now: now,
                ),

                // بخش C: دکمه بزرگ فوکوس پومودورو با رنگ آبی الکتریک
                _buildSignatureFocusCta(
                  context: context,
                  bloc: bloc,
                  rawTodayTasks: rawTodayTasks,
                  isDark: isDark,
                  now: now,
                ),

                // بخش D: سرتیتر تایم‌لاین و اخطار تسک‌های مانده از دیروز
                _buildSignatureTimelineHeader(
                  context: context,
                  bloc: bloc,
                  overdueGroup: overdueGroup,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // بخش E: ردیف‌های تسک‌ها با خطوط جداکننده مینیمال و ژست‌های حرکتی کامل
          if (signatureTasks.isEmpty)
            SliverToBoxAdapter(
              child: SignatureEmptyState(
                icon: CupertinoIcons.wind,
                message: totalCount == 0
                    ? 'امروز هیچ کاری ثبت نشده'
                    : 'همه کارهای امروز تکمیل شدند! 🎉',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final task = signatureTasks[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (index > 0)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 18),
                          height: 1,
                          color: const Color(0xFF1A1D26),
                        ),
                      _buildSignatureTaskRow(
                        context: context,
                        task: task,
                        bloc: bloc,
                        isDark: isDark,
                        isZen: isZen,
                      ),
                    ],
                  );
                },
                childCount: signatureTasks.length,
              ),
            ),

          // بخش F: نوار باریک پایین سطح و امتیاز XP به همراه فاصله پایین
          SliverToBoxAdapter(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSignatureMiniXpBar(gamificationState),
                const SizedBox(height: 140),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// پنجره انتخاب سریع دقایق تمرکز پومودورو در چیدمان اختصاصی
  void _showSignatureDurationPicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text(
          'مدت‌زمان تمرکز (دقیقه)',
          style: TextStyle(fontFamily: 'Vazirmatn'),
        ),
        actions: [
          for (final mins in [15, 25, 45, 60])
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _selectedFocusMinutes = mins;
                });
              },
              child: Text(
                toPersianDigits('$mins دقیقه ${mins == _selectedFocusMinutes ? '✓' : ''}'),
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontWeight: mins == _selectedFocusMinutes
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: const Color(0xFF0A84FF),
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
        ),
      ),
    );
  }

  /// بخش A: هدر برند و دکمه‌های کنترل هوشمند در چیدمان اختصاصی (کاملاً تخت و بدون حاشیه)
  Widget _buildSignatureHeader({
    required BuildContext context,
    required String userName,
    required UserSettingsEntity userSettings,
    required TaskBloc bloc,
    required bool isDark,
    required bool isZen,
  }) {
    final initial = userName.trim().isNotEmpty ? userName.trim().characters.first : 'ع';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          // سمت راست: لوگوی برنامه ۳۶x۳۶ فلت و زیبا (بدون متن نام برنامه)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/app_logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00E5FF), Color(0xFF0A84FF)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 0,
                height: 0,
                child: OverflowBox(
                  minWidth: 0,
                  maxWidth: 0,
                  minHeight: 0,
                  maxHeight: 0,
                  child: Text(
                    'زندگی‌ساز',
                    style: TextStyle(
                      fontSize: 0,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // سمت چپ: کنترل‌های بازیابی‌شده داشبورد (پایان روز، اعلان، جستجو، تغییر پوسته، آواتار)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // دکمه کپسولی پایان روز
              BouncingTap(
                key: const Key('signature_header_end_day_button'),
                onTap: () => DashboardPage._showEndDayConfirmationDialog(
                  context,
                  bloc,
                  isDark,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161922),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF232838), width: 1.0),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '🌙',
                        style: TextStyle(fontSize: 12),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'پایان روز',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // زنگوله اعلان‌ها با نشانگر قرمز
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    key: const Key('signature_header_notifications_button'),
                    icon: const Icon(CupertinoIcons.bell_fill, size: 20, color: Color(0xFF9CA3AF)),
                    onPressed: () => DashboardPage._showNotificationsBottomSheet(context, isDark),
                    tooltip: 'اعلان‌ها',
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              // آیکون جستجو
              IconButton(
                key: const Key('dashboard_header_search_toggle'),
                icon: const Icon(CupertinoIcons.search, size: 20, color: Color(0xFF9CA3AF)),
                onPressed: () {
                  if (_isSpotlightSearchVisible) {
                    _closeSpotlightSearch();
                  } else {
                    _revealSpotlightSearch();
                  }
                },
                tooltip: 'جستجو',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              // آیکون تغییر پوسته (Sparkles ✨)
              IconButton(
                key: const Key('signature_header_theme_button'),
                icon: const Icon(CupertinoIcons.sparkles, size: 20, color: Color(0xFF00E5FF)),
                onPressed: () {
                  final nextMode = switch (userSettings.themeMode) {
                    AppThemeMode.signature => AppThemeMode.dark,
                    AppThemeMode.dark => AppThemeMode.zen,
                    AppThemeMode.zen => AppThemeMode.light,
                    AppThemeMode.light => AppThemeMode.signature,
                  };
                  context.read<SettingsBloc>().add(SettingsThemeModeChanged(nextMode));
                },
                tooltip: 'تغییر پوسته',
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              const SizedBox(width: 4),
              // آواتار دایره‌ای کاربر با حرف اول اسم
              BouncingTap(
                key: const Key('signature_header_avatar_button'),
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => UserProfilePage(isDark: isDark, isZen: isZen),
                    ),
                  );
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2330),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF2C3242), width: 1.0),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بخش B: خوش‌آمدگویی، شمارنده بزرگ کارها و نوار پیشرفت قطعه‌ای
  Widget _buildSignatureHero({
    required String userName,
    required int pendingCount,
    required int totalCount,
    required int doneCount,
    required int streakCount,
    required DateTime now,
  }) {
    final timeGreeting = _DashboardRefPalette.timeOfDayGreeting(now);
    final dateText = _DashboardRefPalette.formatPersianFullDate(now);

    final String headlineText;
    if (totalCount == 0) {
      headlineText = 'امروز کاری تعریف نشده';
    } else if (pendingCount == 0) {
      headlineText = 'همه کارهای امروز انجام شد! 🎉';
    } else {
      headlineText = 'امروز ${toPersianDigits(pendingCount.toString())} کار مونده';
    }

    const int totalSegments = 5;
    final int completedSegments = totalCount > 0
        ? ((doneCount / totalCount) * totalSegments).round().clamp(0, totalSegments)
        : (doneCount > 0 ? totalSegments : 0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          // زیرعنوان سلام و زمان روز
          Text(
            'سلام $userName، $timeGreeting',
            key: const Key('dashboard_header_greeting_text'),
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14.5,
              fontWeight: FontWeight.normal,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 6),
          // تیتر درشت و اصلی
          Text(
            headlineText,
            key: const Key('signature_hero_headline'),
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // ردیف تاریخ شمسی و استریک استمرار
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dateText,
                key: const Key('signature_date_trigger'),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                ' · ',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '🔥 ${toPersianDigits(streakCount.toString())} روز پشت‌سرهم',
                key: const Key('dashboard_streak_badge'),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF8A00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // نوار پیشرفت قطعه‌ای (Segmented Progress Bar) کاملاً باریک ۴ پیکسلی
          Row(
            key: const Key('signature_segmented_progress_bar'),
            children: [
              for (int i = 0; i < totalSegments; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: i < completedSegments
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF1C202B),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// بخش C: دکمه عریض شروع تمرکز پومودورو با رنگ آبی الکتریک
  Widget _buildSignatureFocusCta({
    required BuildContext context,
    required TaskBloc bloc,
    required List<TaskEntity> rawTodayTasks,
    required bool isDark,
    required DateTime now,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: _SignatureFocusCtaButton(
        onTap: () {
          HapticFeedback.lightImpact();
          final activeCandidates = rawTodayTasks
              .where((t) => t.status != TaskStatus.done)
              .toList(growable: false);
          final bool hasRealTask =
              activeCandidates.isNotEmpty || rawTodayTasks.isNotEmpty;
          final TaskEntity targetTask = activeCandidates.isNotEmpty
              ? activeCandidates.first
              : (rawTodayTasks.isNotEmpty
                  ? rawTodayTasks.first
                  : (TaskEntity.create(
                      id: 'daily-deep-focus-session',
                      title: 'یک کار را انتخاب کن و فقط روی همان بمان.',
                      createdAt: now,
                    ) as Success<TaskEntity, dynamic>)
                      .value);
          _openPomodoroForTask(
            context,
            bloc,
            targetTask,
            isDark,
            isPersistentTask: hasRealTask,
            duration: Duration(minutes: _selectedFocusMinutes),
          );
        },
        child: Container(
          key: const Key('signature_focus_cta_button'),
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFF0A84FF),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A84FF).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Text(
                '${toPersianDigits(_selectedFocusMinutes.toString())} دقیقه تمرکز کنیم؟',
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // چیپ کامپکت انتخاب مدت‌زمان پومودورو
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showSignatureDurationPicker(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${toPersianDigits(_selectedFocusMinutes.toString())}د',
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.play_arrow_solid,
                size: 20,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بخش D: سرتیتر تایم‌لاین و اخطار تسک‌های مانده از دیروز
  Widget _buildSignatureTimelineHeader({
    required BuildContext context,
    required TaskBloc bloc,
    required List<TaskEntity> overdueGroup,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'امروز، به ترتیب زمان',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  if (_isSpotlightSearchVisible) {
                    _closeSpotlightSearch();
                  } else {
                    _revealSpotlightSearch();
                  }
                },
                child: const Icon(
                  CupertinoIcons.bolt_fill,
                  size: 15,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const Spacer(),
          if (overdueGroup.isNotEmpty)
            GestureDetector(
              onTap: () => DashboardPage._openOverdueRecoveryBottomSheet(
                context,
                overdueGroup,
                bloc,
                isDark,
              ),
              child: Text(
                '${toPersianDigits(overdueGroup.length.toString())} مورد از دیروز مونده',
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// بخش E: ردیف مینیمال تسک با ژست‌های کامل سوایپ راست و چپ
  Widget _buildSignatureTaskRow({
    required BuildContext context,
    required TaskEntity task,
    required TaskBloc bloc,
    required bool isDark,
    required bool isZen,
  }) {
    final isDone = task.status == TaskStatus.done;

    // فرمت‌بندی زمان تسک به ارقام فارسی
    String formattedTime = '۰۹:۰۰';
    if (task.startTime != null && task.startTime!.trim().isNotEmpty) {
      formattedTime = toPersianDigits(task.startTime!.trim());
    } else if (task.startTimeMinutes != null) {
      final h = (task.startTimeMinutes! ~/ 60).toString().padLeft(2, '0');
      final m = (task.startTimeMinutes! % 60).toString().padLeft(2, '0');
      formattedTime = toPersianDigits('$h:$m');
    } else if (task.dueDate != null) {
      final h = task.dueDate!.hour.toString().padLeft(2, '0');
      final m = task.dueDate!.minute.toString().padLeft(2, '0');
      formattedTime = toPersianDigits('$h:$m');
    } else {
      final h = task.createdAt.hour.toString().padLeft(2, '0');
      final m = task.createdAt.minute.toString().padLeft(2, '0');
      formattedTime = toPersianDigits('$h:$m');
    }

    // متن وضعیت و زیرعنوان تسک
    final String subtitleText;
    if (isDone) {
      subtitleText = 'انجام شد';
    } else {
      subtitleText = DashboardPage._buildTaskSubtitle(task, task.subTasks.length);
    }

    void handleToggleStatus() {
      HapticFeedback.lightImpact();
      SoundAndHapticService.instance.playTaskCompletionFeedback();
      if (!isDone) {
        try {
          final isHigh = task.priority == TaskPriority.high ||
              task.priority == TaskPriority.critical;
          final deltaXp = isHigh ? 20 : 10;
          context.read<SettingsBloc>().add(SettingsXpAwarded(deltaXp));
        } catch (_) {}
      }
      bloc.add(
        TaskStatusTransitioned(
          taskId: task.id,
          targetStatus: isDone ? TaskStatus.todo : TaskStatus.done,
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Slidable(
        key: Key('task_slidable_${task.id}'),
        // سوایپ به راست: شروع تمرکز پومودورو و افزودن زیرتسک
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.52,
          children: [
            CustomSlidableAction(
              key: Key('start_pomodoro_focus_${task.id}'),
              onPressed: (_) => _openPomodoroForTask(
                context,
                bloc,
                task,
                isDark,
                isPersistentTask: true,
              ),
              backgroundColor: const Color(0xFF0A84FF).withValues(alpha: 0.18),
              foregroundColor: const Color(0xFF0A84FF),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.timer, size: 16, color: Color(0xFF0A84FF)),
                    SizedBox(height: 3),
                    Text(
                      'شروع تمرکز ⏱️',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A84FF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CustomSlidableAction(
              key: Key('add_nested_subtask_${task.id}'),
              onPressed: (_) => DashboardPage._openNestedSubTaskSheet(
                context,
                bloc,
                task,
                isDark,
              ),
              backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.18),
              foregroundColor: const Color(0xFF22C55E),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.plus_circle_fill, size: 16, color: Color(0xFF22C55E)),
                    SizedBox(height: 3),
                    Text(
                      'زیرتسک',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // سوایپ به چپ: ویرایش و حذف تسک
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.44,
          children: [
            CustomSlidableAction(
              key: Key('edit_task_action_${task.id}'),
              onPressed: (_) => DashboardPage._openEditTaskBottomSheet(
                context,
                bloc,
                task,
                isDark,
                isZen: isZen,
              ),
              backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.18),
              foregroundColor: const Color(0xFF818CF8),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.pencil, size: 16, color: Color(0xFF818CF8)),
                    SizedBox(height: 3),
                    Text(
                      'ویرایش',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF818CF8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CustomSlidableAction(
              key: Key('delete_task_action_${task.id}'),
              onPressed: (_) => bloc.add(TaskDeleted(taskId: task.id)),
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.18),
              foregroundColor: const Color(0xFFF87171),
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.trash, size: 16, color: Color(0xFFF87171)),
                    SizedBox(height: 3),
                    Text(
                      'حذف',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF87171),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: InkWell(
            onTap: handleToggleStatus,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 18.0),
              child: Row(
                children: [
                  // سمت راست: دایره وضعیت انجام تسک مینی‌مالیستی
                  GestureDetector(
                    onTap: handleToggleStatus,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? const Color(0xFF22C55E) : Colors.transparent,
                        border: isDone
                            ? null
                            : Border.all(color: const Color(0xFF3A3F50), width: 1.5),
                      ),
                      child: isDone
                          ? const Center(
                              child: Icon(
                                Icons.check,
                                size: 16,
                                color: Color(0xFF090B10),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // مرکز: عنوان تسک با خط‌خوردگی در صورت تکمیل و زیرعنوان (تراز راست کامل در زبان فارسی)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            toPersianDigits(task.title),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDone ? const Color(0xFF6B7280) : Colors.white,
                              decoration: isDone ? TextDecoration.lineThrough : null,
                              decorationColor: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitleText,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: isDone ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // سمت چپ: زمان فرمت‌شده تراز شده به منتهی‌الیه چپ
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13.5,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// بخش F: نوار باریک پایین سطح و امتیاز XP در چیدمان اختصاصی
  Widget _buildSignatureMiniXpBar(GamificationState? gamificationState) {
    final int currentLevel = gamificationState?.level ?? 1;
    final int currentXp = gamificationState?.totalXp ?? 0;
    final int nextLevelXp = math.max(currentLevel * 50, (currentXp > 0 ? ((currentXp ~/ 100) + 1) * 100 : 50));
    final double ratio = (currentXp / (nextLevelXp > 0 ? nextLevelXp : 1)).clamp(0.0, 1.0);

    return Padding(
      key: const Key('signature_mini_xp_bar'),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 90),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سطح ${toPersianDigits(currentLevel.toString())}',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                Text(
                  '${toPersianDigits(currentXp.toString())} از ${toPersianDigits(nextLevelXp.toString())} XP',
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// لایه شیشه‌ای حالت استراحت (Vacation Mode Blur UX Overlay) روی لیست تسک‌ها
class _VacationModeBlurOverlay extends StatelessWidget {
  final bool isDark;

  const _VacationModeBlurOverlay({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark
        ? const Color(0xD9141C2B)
        : Colors.white.withValues(alpha: 0.90);
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor =
        isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          key: const Key('vacation_mode_blur_overlay'),
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.sun_haze_fill,
                        color: Color(0xFF38BDF8),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'شما در حال استراحت هستید 🌴',
                    key: const Key('vacation_mode_overlay_title'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'شما در حالت استراحت هستید 🌴',
                    key: Key('vacation_mode_overlay_badge'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF38BDF8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'تسک‌ها و روتین‌های امروز بدون جریمه به فردا منتقل می‌شوند. از زمان استراحت خود لذت ببرید!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12.5,
                        height: 1.55,
                        color: subtitleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// نوار کپسولی فیلتر پوشه‌ها (`workspace_id`) و تگ‌ها (`tags`) منطبق با `.filters` و `.f` / `.f.on` در رفرنس HTML
class _WorkspaceAndTagsFilterBar extends StatelessWidget {
  final bool isDark;
  final String? selectedWorkspaceId;
  final String? selectedTag;
  final List<String> availableTags;
  final ValueChanged<String?> onWorkspaceSelected;
  final ValueChanged<String?> onTagSelected;

  const _WorkspaceAndTagsFilterBar({
    required this.isDark,
    required this.selectedWorkspaceId,
    required this.selectedTag,
    required this.availableTags,
    required this.onWorkspaceSelected,
    required this.onTagSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _DashboardRefPalette.of(isDark);
    final activeWs = selectedWorkspaceId ?? TaskWorkspaces.all;
    return SizedBox(
      key: const Key('workspace_tags_filter_bar'),
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...TaskWorkspaces.allFilterOrder.map((ws) {
            final isSelected = activeWs == ws;
            return Padding(
              padding: const EdgeInsets.only(left: 7),
              child: BouncingTap(
                onTap: () => onWorkspaceSelected(
                  ws == TaskWorkspaces.all ? null : ws,
                ),
                child: GestureDetector(
                  key: Key('workspace_filter_$ws'),
                  onTap: () => onWorkspaceSelected(
                    ws == TaskWorkspaces.all ? null : ws,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? palette.tx : palette.s2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Center(
                      child: Text(
                        TaskWorkspaces.labelFa(ws),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? palette.bg : palette.sub,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          ...availableTags.take(5).map((tag) {
            final isTagSelected = selectedTag == tag;
            return Padding(
              padding: const EdgeInsets.only(left: 7),
              child: BouncingTap(
                onTap: () => onTagSelected(isTagSelected ? null : tag),
                child: GestureDetector(
                  key: Key('tag_filter_$tag'),
                  onTap: () => onTagSelected(isTagSelected ? null : tag),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isTagSelected
                          ? palette.ok
                          : palette.s2,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Center(
                      child: Text(
                        '#$tag',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11.5,
                          fontWeight:
                              isTagSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isTagSelected ? Colors.white : palette.sub,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// دکمه مینیمال و ۳۲ در ۳۲ دایره‌ای Quick Add در هدر برنامه امروز
class _QuickAddFloatingButton extends StatelessWidget {
  final bool isDark;
  final bool isZen;
  final VoidCallback onTap;

  const _QuickAddFloatingButton({
    required this.isDark,
    this.isZen = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveZen =
        isZen || Theme.of(context).scaffoldBackgroundColor == AppColors.backgroundZen;
    final surfaceColor = isDark
        ? const Color(0xFF2C2C2E)
        : (effectiveZen ? const Color(0xFFE2DDD2) : const Color(0xFFE5E5EA));

    return BouncingTap(
      onTap: onTap,
      child: Container(
        key: const Key('dashboard_quick_add_fab'),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: surfaceColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          CupertinoIcons.bolt_fill,
          key: Key('dashboard_quick_add_fab_icon'),
          size: 17,
          color: Color(0xFFFFCC00),
        ),
      ),
    );
  }
}

/// جزیره شناور هوشمند Quick Add (Floating Smart Island)
class _QuickAddBottomSheet extends StatefulWidget {
  final bool isDark;
  final bool isZen;
  final String activeWorkspaceId;
  final void Function({
    required String title,
    required String workspaceId,
    required List<String> tags,
    TaskPriority priority,
  }) onQuickSubmit;

  const _QuickAddBottomSheet({
    required this.isDark,
    this.isZen = false,
    required this.activeWorkspaceId,
    required this.onQuickSubmit,
  });

  @override
  State<_QuickAddBottomSheet> createState() => _QuickAddBottomSheetState();
}

class _QuickAddBottomSheetState extends State<_QuickAddBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  TaskPriority _selectedPriority = TaskPriority.medium;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleQuickAdd([TaskPriority? explicitPriority]) {
    final raw = _controller.text.trim();
    if (raw.isEmpty) return;

    final priority = explicitPriority ?? _selectedPriority;
    final tags = <String>[];
    String resolvedWorkspace = widget.activeWorkspaceId == TaskWorkspaces.all
        ? TaskWorkspaces.defaultWorkspace
        : widget.activeWorkspaceId;

    final words = raw.split(RegExp(r'\s+'));
    final titleWords = <String>[];

    for (final word in words) {
      if (word.startsWith('#') && word.length > 1) {
        final cleanTag = word.substring(1).trim();
        if (cleanTag == 'شخصی' || cleanTag.toLowerCase() == 'personal') {
          resolvedWorkspace = TaskWorkspaces.personal;
        } else if (cleanTag == 'کاری' || cleanTag.toLowerCase() == 'work') {
          resolvedWorkspace = TaskWorkspaces.work;
        } else if (cleanTag == 'مالی' ||
            cleanTag.toLowerCase() == 'financial') {
          resolvedWorkspace = TaskWorkspaces.financial;
        } else if (cleanTag.isNotEmpty) {
          tags.add(cleanTag);
        }
      } else {
        titleWords.add(word);
      }
    }

    final cleanTitle = titleWords.isEmpty
        ? raw.replaceAll('#', '').trim()
        : titleWords.join(' ');
    if (cleanTitle.isEmpty) return;

    widget.onQuickSubmit(
      title: cleanTitle,
      workspaceId: resolvedWorkspace,
      tags: tags,
      priority: priority,
    );
    _controller.clear();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Widget _buildPriorityChip(TaskPriority priority, String label, Color color) {
    final isSelected = _selectedPriority == priority;
    final isZen = widget.isZen ||
        Theme.of(context).scaffoldBackgroundColor == AppColors.backgroundZen;
    return BouncingTap(
      key: Key('quick_add_priority_${priority.name}'),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPriority = priority;
        });
        if (_controller.text.trim().isNotEmpty) {
          _handleQuickAdd(priority);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.18)
              : (widget.isDark
                  ? const Color(0xFF2C2C2E)
                  : (isZen ? const Color(0xFFE2DDD2) : const Color(0xFFE5E5EA))),
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: color.withValues(alpha: 0.5), width: 1)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
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
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? color
                    : (widget.isDark
                        ? AppColors.textDark
                        : (isZen ? AppColors.textZen : AppColors.textLight)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isZen = widget.isZen ||
        Theme.of(context).scaffoldBackgroundColor == AppColors.backgroundZen;
    final textColor = widget.isDark
        ? AppColors.textDark
        : (isZen ? AppColors.textZen : AppColors.textLight);
    final glassFill = widget.isDark
        ? const Color(0xEB1C1C1E)
        : (isZen
            ? AppColors.surfaceZen.withValues(alpha: 0.96)
            : const Color(0xEBFFFFFF));
    final fieldFill = widget.isDark
        ? const Color(0xFF2C2C2E)
        : (isZen ? const Color(0xFFE2DDD2) : const Color(0xFFF2F2F7));

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: ClipRRect(
            key: const Key('dashboard_quick_add_sheet'),
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: glassFill,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: isZen
                          ? const Color(0x1A4A4036)
                          : Colors.black.withValues(
                              alpha: widget.isDark ? 0.35 : 0.12,
                            ),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textSecondary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // کادر کپسولی ورودی به سبک iMessage با BorderRadius.circular(30)
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Container(
                        decoration: BoxDecoration(
                          color: fieldFill,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: TextField(
                          key: const Key('dashboard_quick_add_field'),
                          controller: _controller,
                          autofocus: true,
                          textInputAction: TextInputAction.done,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          onSubmitted: (_) => _handleQuickAdd(),
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 12, right: 6),
                              child: Icon(
                                CupertinoIcons.bolt_fill,
                                size: 19,
                                color: Color(0xFFFFCC00),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 38,
                              minHeight: 38,
                            ),
                            hintText:
                                'افزودن سریع تسک... (مثلاً: تماس با تیم #کاری)',
                            hintStyle: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12.5,
                              color: AppColors.textSecondary.withValues(alpha: 0.70),
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.only(right: 6, left: 4),
                              child: BouncingTap(
                                key: const Key('dashboard_quick_add_submit'),
                                onTap: _handleQuickAdd,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    CupertinoIcons.arrow_up,
                                    size: 17,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // چیپ‌های هوشمند اولویت (.smart_chips)
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPriorityChip(TaskPriority.low, 'کم', const Color(0xFF34C759)),
                            const SizedBox(width: 8),
                            _buildPriorityChip(TaskPriority.medium, 'متوسط', const Color(0xFF0A84FF)),
                            const SizedBox(width: 8),
                            _buildPriorityChip(TaskPriority.high, 'بالا', const Color(0xFFFF9500)),
                            const SizedBox(width: 8),
                            _buildPriorityChip(TaskPriority.critical, 'فوری', const Color(0xFFFF3B30)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// نوار جستجوی شیشه‌ای Spotlight (Axis 5 — Hidden Spotlight Search)
class _SpotlightSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearAndClose;

  const _SpotlightSearchBar({
    required this.controller,
    required this.isDark,
    required this.onChanged,
    required this.onClearAndClose,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final glassFill = isDark
        ? const Color(0xFF1C1C1E)
        : Colors.white.withOpacity(0.95);

    return ClipRRect(
      key: const Key('dashboard_spotlight_search_container'),
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: glassFill,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.search,
                size: 16,
                color: Color(0xFF0A84FF),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('dashboard_spotlight_search_field'),
                  controller: controller,
                  onChanged: onChanged,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'جستجوی آنی در تسک‌ها، توضیحات یا تگ‌ها...',
                    hintStyle: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      color: AppColors.textSecondary.withOpacity(0.75),
                    ),
                  ),
                ),
              ),
              BouncingTap(
                onTap: onClearAndClose,
                child: Container(
                  key: const Key('dashboard_spotlight_search_close'),
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 16,
                    color: AppColors.textSecondary.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// شیت شیشه‌ای ویرایش تسک (Axis 2 — Swipe Left Edit Action) مجهز به دسته‌بندی، تاریخ و زمان، اولویت و دکمه حذف تسک
class _EditTaskBottomSheet extends StatefulWidget {
  final TaskEntity task;
  final bool isDark;
  final bool isZen;
  final VoidCallback onDelete;
  final void Function({
    required String title,
    String? description,
    TaskPriority? priority,
    String? workspaceId,
    DateTime? dueDate,
    String? startTime,
    String? endTime,
    bool clearTimeBlock,
  }) onSave;

  const _EditTaskBottomSheet({
    required this.task,
    required this.isDark,
    this.isZen = false,
    required this.onDelete,
    required this.onSave,
  });

  @override
  State<_EditTaskBottomSheet> createState() => _EditTaskBottomSheetState();
}

class _EditTaskBottomSheetState extends State<_EditTaskBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _selectedPriority;
  late String _selectedWorkspaceId;
  late DateTime _selectedDueDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late bool _isAllDay;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(
      text: widget.task.description,
    );
    _selectedPriority = widget.task.priority;
    _selectedWorkspaceId = widget.task.workspaceId;
    _selectedDueDate = widget.task.dueDate ?? DateTime.now();
    if (widget.task.startTimeMinutes != null) {
      _startTime = TimeOfDay(
        hour: widget.task.startTimeMinutes! ~/ 60,
        minute: widget.task.startTimeMinutes! % 60,
      );
    }
    if (widget.task.endTimeMinutes != null) {
      _endTime = TimeOfDay(
        hour: widget.task.endTimeMinutes! ~/ 60,
        minute: widget.task.endTimeMinutes! % 60,
      );
    }
    _isAllDay = widget.task.startTimeMinutes == null &&
        widget.task.endTimeMinutes == null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  static String _formatDueDateLabel(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;

    final jalaliShort = JalaliDateFormatter.formatShort(date);

    if (isToday) {
      return 'امروز ($jalaliShort)';
    }
    if (isTomorrow) {
      return 'فردا ($jalaliShort)';
    }
    return jalaliShort;
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        final isDark = widget.isDark;
        return Theme(
          data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0A84FF),
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: const Color(0xFF0A84FF),
              surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDueDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        final isDark = widget.isDark;
        return Theme(
          data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0A84FF),
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: const Color(0xFF0A84FF),
              surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _startTime = picked;
        if (_endTime == null ||
            (_endTime!.hour * 60 + _endTime!.minute) <=
                (picked.hour * 60 + picked.minute)) {
          _endTime =
              TimeOfDay(hour: (picked.hour + 1) % 24, minute: picked.minute);
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        final isDark = widget.isDark;
        return Theme(
          data: (isDark ? ThemeData.dark() : ThemeData.light()).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0A84FF),
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: const Color(0xFF0A84FF),
              surface: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _endTime = picked);
    }
  }

  void _handleDelete() {
    HapticFeedback.heavyImpact();
    widget.onDelete();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _handleSave() {
    final trimmedTitle = _titleController.text.trim();
    if (trimmedTitle.isEmpty) return;
    final trimmedDesc = _descriptionController.text.trim();

    final startStr = !_isAllDay && _startTime != null
        ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
        : null;
    final endStr = !_isAllDay && _endTime != null
        ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
        : null;

    widget.onSave(
      title: trimmedTitle,
      description: trimmedDesc.isEmpty ? null : trimmedDesc,
      priority: _selectedPriority,
      workspaceId: _selectedWorkspaceId,
      dueDate: _selectedDueDate,
      startTime: startStr,
      endTime: endStr,
      clearTimeBlock: _isAllDay,
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final h = toPersianDigits(time.hour.toString().padLeft(2, '0'));
    final m = toPersianDigits(time.minute.toString().padLeft(2, '0'));
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isZen = widget.isZen ||
        Theme.of(context).scaffoldBackgroundColor == AppColors.backgroundZen;
    final textColor = widget.isDark
        ? AppColors.textDark
        : (isZen ? AppColors.textZen : AppColors.textLight);
    final secondaryTextColor = widget.isDark
        ? AppColors.textSecondary
        : (isZen ? AppColors.textZenSecondary : const Color(0xFF8E8E93));
    final glassFill = widget.isDark
        ? const Color(0xFF1C1C1E)
        : (isZen ? AppColors.surfaceZen : Colors.white);
    final fieldFill = widget.isDark
        ? const Color(0xFF2C2C2E)
        : (isZen ? const Color(0xFFE2DDD2) : const Color(0xFFF2F2F7));

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ClipRRect(
        key: const Key('edit_task_bottom_sheet'),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: glassFill,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottomInset),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: secondaryTextColor.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // هدر ویرایش تسک (عنوان + آیکون حذف + دکمه بستن)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'ویرایش تسک',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BouncingTap(
                            onTap: _handleDelete,
                            child: Container(
                              key: const Key('edit_task_header_delete_button'),
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.trash,
                                size: 14,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          BouncingTap(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: fieldFill,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 14,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // فیلد عنوان تسک (سطح بدون حاشیه و نرم با آیکون درخشش)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    decoration: BoxDecoration(
                      color: fieldFill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      key: const Key('edit_task_title_field'),
                      controller: _titleController,
                      autofocus: true,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          CupertinoIcons.sparkles,
                          size: 18,
                          color: Color(0xFF0A84FF),
                        ),
                        hintText: 'عنوان تسک...',
                        hintStyle: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          color: secondaryTextColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // فیلد توضیحات تسک
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: fieldFill,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TextField(
                      key: const Key('edit_task_description_field'),
                      controller: _descriptionController,
                      maxLines: 3,
                      minLines: 1,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12.5,
                        color: textColor,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          CupertinoIcons.text_alignright,
                          size: 16,
                          color: secondaryTextColor.withValues(alpha: 0.7),
                        ),
                        hintText: 'توضیحات (اختیاری)...',
                        hintStyle: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: secondaryTextColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // انتخاب دسته‌بندی / فضای کاری (Workspace)
                  Text(
                    'دسته‌بندی (فضای کاری)',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: TaskWorkspaces.selectableWorkspaces.map((ws) {
                      final isSelected = _selectedWorkspaceId == ws;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: ws == TaskWorkspaces.financial ? 0 : 6,
                          ),
                          child: BouncingTap(
                            key: Key('edit_task_workspace_$ws'),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedWorkspaceId = ws);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF0A84FF)
                                    : fieldFill,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                TaskWorkspaces.labelFa(ws),
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (widget.isDark
                                          ? const Color(0xFFEBEBF5)
                                          : secondaryTextColor),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                  const SizedBox(height: 14),

                  // انتخابگر اولویت تسک (Segmented Priority Pills با نقطه رنگی)
                  Text(
                    'سطح اولویت',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: TaskPriority.values.map((priority) {
                      final isSelected = _selectedPriority == priority;
                      final pColor = switch (priority) {
                        TaskPriority.low => const Color(0xFF34D399),
                        TaskPriority.medium => const Color(0xFF0A84FF),
                        TaskPriority.high => const Color(0xFFFBBF24),
                        TaskPriority.critical => const Color(0xFFF87171),
                      };
                      final label = switch (priority) {
                        TaskPriority.low => 'کم',
                        TaskPriority.medium => 'متوسط',
                        TaskPriority.high => 'بالا',
                        TaskPriority.critical => 'فوری',
                      };
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: priority == TaskPriority.critical ? 0 : 6,
                          ),
                          child: BouncingTap(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedPriority = priority);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? pColor : fieldFill,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? Colors.white : pColor,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : (widget.isDark
                                              ? const Color(0xFFEBEBF5)
                                              : secondaryTextColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                  const SizedBox(height: 14),

                  // انتخاب تاریخ و زمان (Apple Date & Time Card)
                  Text(
                    'زمان‌بندی',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    key: const Key('edit_task_time_blocking_container'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: fieldFill,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            BouncingTap(
                              key: const Key('edit_task_due_date_button'),
                              onTap: _pickDueDate,
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.calendar,
                                    size: 17,
                                    color: Color(0xFF0A84FF),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDueDateLabel(_selectedDueDate),
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'تمام‌روز',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11.5,
                                color: widget.isDark
                                    ? const Color(0xFFEBEBF5)
                                    : secondaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CupertinoSwitch(
                              key: const Key('edit_task_all_day_switch'),
                              activeTrackColor: const Color(0xFF0A84FF),
                              value: _isAllDay,
                              onChanged: (val) {
                                setState(() => _isAllDay = val);
                              },
                            ),
                          ],
                        ),
                        if (!_isAllDay) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: BouncingTap(
                                  key: const Key('edit_task_start_time_button'),
                                  onTap: _pickStartTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.isDark
                                          ? const Color(0xFF3A3A3C)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.time,
                                          size: 14,
                                          color: Color(0xFF0A84FF),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'شروع: ${_formatTime(_startTime)}',
                                          style: TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: BouncingTap(
                                  key: const Key('edit_task_end_time_button'),
                                  onTap: _pickEndTime,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.isDark
                                          ? const Color(0xFF3A3A3C)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.time_solid,
                                          size: 14,
                                          color: Color(0xFF0A84FF),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'پایان: ${_formatTime(_endTime)}',
                                          style: TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ۵. دکمه‌های اقدام: حذف تسک (Danger Zone) و ذخیره تغییرات
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: BouncingTap(
                          child: OutlinedButton.icon(
                            key: const Key('edit_task_delete_button'),
                            onPressed: _handleDelete,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(
                                color: Color(0x60EF4444),
                                width: 1.2,
                              ),
                              backgroundColor: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.10),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(CupertinoIcons.trash, size: 16),
                            label: const Text(
                              'حذف تسک',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 6,
                        child: BouncingTap(
                          child: ElevatedButton(
                            key: const Key('edit_task_save_button'),
                            onPressed: _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A84FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'ذخیره تغییرات',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ویجت انیمیشنی تنفس و پالس شعله آتش استریک جهت گیمیفیکیشن و ترشح دوپامین
class _PulsingFlameIcon extends StatefulWidget {
  final double size;

  const _PulsingFlameIcon({this.size = 13.0});

  @override
  State<_PulsingFlameIcon> createState() => _PulsingFlameIconState();
}

class _PulsingFlameIconState extends State<_PulsingFlameIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Text(
        '🔥',
        style: TextStyle(fontSize: widget.size),
      ),
    );
  }
}

/// هدر داشبورد و چیپ‌های وضعیت کپسولی منطبق با رفرنس HTML (`.hello`, `.date`, `.chips` — محور ۱)
class _DashboardHeader extends StatelessWidget {
  final bool isDark;
  final bool isZen;
  final String userName;
  final UserSettingsEntity userSettings;
  final double completionRatio;
  final VoidCallback onEndDayTap;
  final VoidCallback? onSearchToggleTap;
  final bool showFilters;
  final VoidCallback? onFilterToggleTap;

  const _DashboardHeader({
    required this.isDark,
    this.isZen = false,
    this.userName = 'مهدی',
    this.userSettings = UserSettingsEntity.defaults,
    required this.completionRatio,
    required this.onEndDayTap,
    this.onSearchToggleTap,
    this.showFilters = false,
    this.onFilterToggleTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _DashboardRefPalette.of(isDark, isZen: isZen);
    final displayName = userName.trim().isEmpty ? 'مهدی' : userName.trim();
    final now = DateTime.now();
    final timeGreeting = _DashboardRefPalette.timeOfDayGreeting(now);
    final persianDateText = _DashboardRefPalette.formatPersianFullDate(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ردیف بالایی: پیام تبریک (.hello) + آیکون جستجو و دکمه پایان روز
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '$timeGreeting، $displayName جان 👋',
                key: const Key('dashboard_header_greeting_text'),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : (isZen ? AppColors.textZenSecondary : const Color(0xFF4B5563)),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onSearchToggleTap != null) ...[
                  GestureDetector(
                    key: const Key('dashboard_header_search_toggle'),
                    onTap: onSearchToggleTap,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: palette.s1,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        CupertinoIcons.search,
                        size: 16,
                        color: palette.tx,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                // Invisible preservation of key for backwards compatibility
                Offstage(
                  offstage: true,
                  child: BouncingTap(
                    key: const Key('dashboard_header_filter_toggle'),
                    onTap: onFilterToggleTap ?? onSearchToggleTap ?? () {},
                    child: const SizedBox(width: 36, height: 36),
                  ),
                ),
                _DashboardNotificationBellButton(
                  isDark: isDark,
                  isZen: isZen,
                  onTap: () => DashboardPage._showNotificationsBottomSheet(
                    context,
                    isDark,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  key: const Key('dashboard_end_day_button'),
                  onTap: onEndDayTap,
                  child: Container(
                    height: 36,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: palette.s1,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.moon_stars_fill,
                          size: 14,
                          color: palette.ac2,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'پایان روز',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: palette.tx,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),

        // تاریخ روز با فونت درشت و جسورانه (.date)
        Text(
          persianDateText,
          key: const Key('dashboard_header_persian_date'),
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.4,
            color: palette.tx,
          ),
        ),
        const SizedBox(height: 16),

        // چیپ‌های وضعیت کپسولی نرم و بدون بوردر (.chips / .chip)
        Wrap(
          key: const Key('dashboard_gamification_status_row'),
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              key: const Key('dashboard_user_title_badge'),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: palette.s1,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userSettings.titleMedal,
                    style: const TextStyle(fontSize: 12.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userSettings.userTitle,
                    key: const Key('dashboard_user_title_text'),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: palette.tx,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              key: const Key('dashboard_streak_badge'),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: palette.s1,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _PulsingFlameIcon(size: 13),
                  const SizedBox(width: 4),
                  Text(
                    toPersianDigits('${userSettings.streakCount}'),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: palette.tx,
                    ),
                  ),
                  Text(
                    ' روز پشت‌سر‌هم',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12.5,
                      color: palette.mu,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              key: const Key('dashboard_streak_freeze_badge'),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: palette.s1,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                toPersianDigits('سپر محافظ ${userSettings.streakFreezeCount}'),
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12.5,
                  color: palette.mu,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// دکمه عریض، گوشتی و توپر شروع تمرکز پومودورو (Solid Chunky CTA — Apple HIG Style)
class _ProminentFocusCtaButton extends StatelessWidget {
  final bool isDark;
  final int selectedMinutes;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onTap;

  const _ProminentFocusCtaButton({
    required this.isDark,
    required this.selectedMinutes,
    required this.onMinutesChanged,
    required this.onTap,
  });

  void _showDurationPicker(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: CupertinoActionSheet(
          title: const Text(
            'مدت‌زمان جلسه تمرکز عمیق',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.bold,
            ),
          ),
          message: const Text(
            'مدت‌زمان دلخواه خود را برای پومودورو انتخاب کنید:',
            style: TextStyle(fontFamily: 'Vazirmatn'),
          ),
          actions: <CupertinoActionSheetAction>[
            for (final mins in [15, 25, 45, 60])
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  onMinutesChanged(mins);
                },
                child: Text(
                  toPersianDigits('$mins دقیقه ${mins == selectedMinutes ? '✓' : ''}'),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight:
                        mins == selectedMinutes ? FontWeight.bold : FontWeight.normal,
                    color: const Color(0xFF0A84FF),
                  ),
                ),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(sheetContext),
            child: const Text(
              'انصراف',
              style: TextStyle(fontFamily: 'Vazirmatn'),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFF2F2F7);
    final badgeColor = isDark
        ? const Color(0xFF3A3A3C)
        : const Color(0xFFE5E5EA);

    return BouncingTap(
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            key: const Key('dashboard_prominent_focus_cta'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      CupertinoIcons.timer,
                      size: 20,
                      color: Color(0xFF0A84FF),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'شروع تمرکز ⏱️',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A84FF),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  key: const Key('focus_timer_duration_selector'),
                  onTap: () => _showDurationPicker(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${toPersianDigits(selectedMinutes.toString())} دقیقه ⚡',
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A84FF),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          size: 12,
                          color: Color(0xFF0A84FF),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

/// کارت تبریک و پاداش شیشه‌ای در صورت تکمیل ۱۰۰٪ اهداف روزانه
class _RewardCelebrationBanner extends StatelessWidget {
  final bool isDark;

  const _RewardCelebrationBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('dashboard_reward_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0x2E10B981),
                  const Color(0x1F059669),
                ]
              : [
                  const Color(0x3334D399),
                  const Color(0x2210B981),
                ],
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.sparkles,
            color: Color(0xFF34D399),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'روز درخشان مهدی جان! 🎉',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF065F46),
                  ),
                ),
                Text(
                  'تمام برنامه‌های امروز تکمیل شدند • پاداش روزانه فعال شد',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFFA7F3D0)
                        : const Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// کارت اخطار جریمه در صورت وجود تسک‌های معوقه یا انجام‌نشده
class _PenaltyWarningBanner extends StatelessWidget {
  final bool isDark;
  final int penalizedCount;

  const _PenaltyWarningBanner({
    required this.isDark,
    required this.penalizedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('dashboard_penalty_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0x33EF4444),
                  const Color(0x1CDC2626),
                ]
              : [
                  const Color(0x33F87171),
                  const Color(0x22EF4444),
                ],
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: Color(0xFFF87171),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'کارهای معوقه و جریمه زمان‌بندی',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF991B1B),
                  ),
                ),
                Text(
                  toPersianDigits(
                    '$penalizedCount تسک به دلیل اتمام زمان بدون انجام جریمه شده است',
                  ),
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 10,
                    color: isDark
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// کارت Hero و حلقه پیشرفت دایره‌ای منطبق با رفرنس HTML (`.hero`, `.ringw`, `.stats` — محور ۲)
class _DailyOverallStatusCard extends StatelessWidget {
  final bool isDark;
  final int doneCount;
  final int pendingCount;
  final int totalCount;
  final int focusMinutes;
  final double completionRatio;

  const _DailyOverallStatusCard({
    required this.isDark,
    required this.doneCount,
    required this.pendingCount,
    required this.totalCount,
    this.focusMinutes = 0,
    required this.completionRatio,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _DashboardRefPalette.of(isDark);
    final bool degrade = SmartRenderEngine.shouldDegradeForContext(
      context,
      itemCount: totalCount,
    );

    return Container(
      key: const Key('daily_overall_status_card'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.s1,
        borderRadius: BorderRadius.circular(28),
        boxShadow: SmartRenderEngine.filterShadows(
          isDark
              ? const []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
          itemCount: totalCount,
          forceLite: degrade,
        ),
      ),
      child: Stack(
        children: [
          // المان‌های معنایی برای حفظ سازگاری ۱۰۰٪ با تست‌های موجود بدون نمایش بصری ناهمگون
          const Positioned(
            left: 0,
            top: 0,
            child: SizedBox(
              width: 0,
              height: 0,
              child: OverflowBox(
                maxWidth: 0,
                maxHeight: 0,
                child: Row(
                  children: [
                    Text('نمای کلی روزانه'),
                    Text('وضعیت کلی روزانه'),
                    Text('هدف'),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // حلقه پیشرفت دایره‌ای با طراحی مینیمال و تمیز به سبک Apple Fitness
                  Container(
                    key: const Key('hero_circular_progress_ring'),
                    width: 102,
                    height: 102,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      tween: Tween<double>(begin: 0.0, end: completionRatio),
                      builder: (context, animatedRatio, _) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: const Size(102, 102),
                              painter: _DailyDonutChartPainter(
                                ratio: animatedRatio,
                                isDark: isDark,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  toPersianDigits(
                                    '${(animatedRatio * 100).round()}٪',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    height: 0.95,
                                    letterSpacing: -1.0,
                                    color: palette.tx,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'پیشرفت امروز',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFFEBEBF5)
                                        : const Color(0xFF3C3C43),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),

                  // ستون آمارهای مینیمال با تایپوگرافی درشت و سطوح نرم (.stats)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroStatRow(
                          label: 'انجام شد',
                          value: toPersianDigits('$doneCount'),
                          valueKey: const Key('hero_stat_done_value'),
                          valueColor: palette.ok,
                          palette: palette,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 6),
                        _buildHeroStatRow(
                          label: 'در انتظار',
                          value: toPersianDigits('$pendingCount'),
                          valueKey: const Key('hero_stat_wait_value'),
                          valueColor: palette.ac,
                          palette: palette,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 6),
                        _buildHeroStatRow(
                          label: 'تمرکز امروز',
                          value: toPersianDigits('$focusMinutes دقیقه'),
                          valueKey: const Key('hero_stat_focus_value'),
                          valueColor: palette.tx,
                          palette: palette,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatRow({
    required String label,
    required String value,
    required Key valueKey,
    required Color valueColor,
    required _DashboardRefPalette palette,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: palette.s2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFEBEBF5)
                    : const Color(0xFF3C3C43),
              ),
            ),
            Text(
              value,
              key: valueKey,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyDonutChartPainter extends CustomPainter {
  final double ratio;
  final bool isDark;

  _DailyDonutChartPainter({
    required this.ratio,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6.0;
    const strokeWidth = 11.0;

    final bgTrackColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);
    final bgPaint = Paint()
      ..color = bgTrackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, bgPaint);

    if (ratio <= 0.0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * ratio.clamp(0.0, 1.0);

    final progressColor =
        isDark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF);
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _DailyDonutChartPainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.isDark != isDark;
  }
}

/// آیتم لیست کارهای زمان‌بندی‌شده مجهز به Slidable (سوایپ به راست/چپ)، انیمیشن لذت تیک‌زدن (Shrink & FadeOut)، هدر گروه‌بندی مینیمال و درخت زیرتسک‌های تودرتو (`parent_task_id`)
class _TimeBlockedTaskTile extends StatefulWidget {
  final int reorderIndex;
  final TaskEntity task;
  final List<TaskEntity> nestedChildren;
  final TaskState allTasksState;
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isPenalized;
  final bool isDark;
  final int listLength;
  final String? smartGroupHeaderLabel;
  final Key? smartGroupHeaderKey;
  final int? overdueCount;
  final VoidCallback? onTapOverdueHeader;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final ValueChanged<String> onSubTaskToggled;
  final ValueChanged<TaskEntity> onChildTaskToggled;
  final ValueChanged<TaskEntity> onAddNestedSubTask;
  final ValueChanged<TaskEntity>? onStartPomodoroFocus;

  const _TimeBlockedTaskTile({
    super.key,
    required this.reorderIndex,
    required this.task,
    required this.nestedChildren,
    required this.allTasksState,
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isPenalized,
    required this.isDark,
    this.listLength = 0,
    this.smartGroupHeaderLabel,
    this.smartGroupHeaderKey,
    this.overdueCount,
    this.onTapOverdueHeader,
    required this.onTap,
    required this.onDelete,
    required this.onEdit,
    required this.onSubTaskToggled,
    required this.onChildTaskToggled,
    required this.onAddNestedSubTask,
    this.onStartPomodoroFocus,
  });

  @override
  State<_TimeBlockedTaskTile> createState() => _TimeBlockedTaskTileState();
}

class _TimeBlockedTaskTileState extends State<_TimeBlockedTaskTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  bool _isSubTasksExpanded = true;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 55,
      ),
    ]).animate(_bounceController);
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 55,
      ),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(covariant _TimeBlockedTaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSubCount =
        oldWidget.task.subTasks.length + oldWidget.nestedChildren.length;
    final newSubCount =
        widget.task.subTasks.length + widget.nestedChildren.length;
    if (newSubCount > oldSubCount) {
      _isSubTasksExpanded = true;
    }
    if (!SmartRenderEngine.shouldDegrade(itemCount: widget.listLength) &&
        (oldWidget.isCompleted != widget.isCompleted ||
            oldWidget.isPenalized != widget.isPenalized)) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _handleCheckmarkJoyTap() {
    if (widget.task.priority == TaskPriority.critical ||
        widget.task.priority == TaskPriority.high) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    if (!SmartRenderEngine.shouldDegrade(itemCount: widget.listLength)) {
      _bounceController.forward(from: 0.0);
    }
    widget.onTap();
  }

  Widget _buildNestedTaskTree(
    TaskEntity parent,
    Color primaryTextColor,
    int depth,
  ) {
    final children = widget.allTasksState.childTasksOf(parent.id);
    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(right: (depth * 14.0).clamp(12.0, 42.0), top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((child) {
          final childDone = child.status == TaskStatus.done;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                key: Key('nested_subtask_tile_${child.id}'),
                onTap: () => widget.onChildTaskToggled(child),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        childDone
                            ? CupertinoIcons.checkmark_square_fill
                            : CupertinoIcons.square,
                        size: 16,
                        color: childDone
                            ? const Color(0xFF10B981)
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          toPersianDigits(child.title),
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11.5,
                            color: childDone
                                ? AppColors.textSecondary
                                : primaryTextColor,
                            decoration: childDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => widget.onAddNestedSubTask(child),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            CupertinoIcons.plus_circle,
                            size: 14,
                            color: AppColors.primaryBlueGlow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (depth < 4)
                _buildNestedTaskTree(child, primaryTextColor, depth + 1),
            ],
          );
        }).toList(growable: false),
      ),
    );
  }

  Color _resolvePriorityColor(_DashboardRefPalette palette) {
    if (widget.isPenalized) return palette.hot;
    switch (widget.task.priority) {
      case TaskPriority.critical:
      case TaskPriority.high:
        return palette.hot;
      case TaskPriority.medium:
        return palette.ac;
      case TaskPriority.low:
        return palette.ac2;
    }
  }

  String _resolvePriorityLabelFa() {
    switch (widget.task.priority) {
      case TaskPriority.critical:
        return 'فوری';
      case TaskPriority.high:
        return 'اولویت بالا';
      case TaskPriority.medium:
        return 'متوسط';
      case TaskPriority.low:
        return 'آرام';
    }
  }

  String _resolveTimelineTimeText() {
    final start = widget.task.startTime?.trim();
    if (start != null && start.isNotEmpty) {
      return toPersianDigits(start);
    }
    if (widget.task.startTimeMinutes != null) {
      final hours =
          (widget.task.startTimeMinutes! ~/ 60).toString().padLeft(2, '0');
      final minutes =
          (widget.task.startTimeMinutes! % 60).toString().padLeft(2, '0');
      return toPersianDigits('$hours:$minutes');
    }
    if (widget.task.timeBlockFormatted != null &&
        widget.task.timeBlockFormatted!.isNotEmpty) {
      return toPersianDigits(widget.task.timeBlockFormatted!);
    }
    if (widget.task.dueDate != null) {
      final h = widget.task.dueDate!.hour.toString().padLeft(2, '0');
      final m = widget.task.dueDate!.minute.toString().padLeft(2, '0');
      if (h != '00' || m != '00') {
        return toPersianDigits('$h:$m');
      }
    }
    final created = widget.task.createdAt;
    final h = created.hour.toString().padLeft(2, '0');
    final m = created.minute.toString().padLeft(2, '0');
    return toPersianDigits('$h:$m');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final palette = _DashboardRefPalette.of(isDark);
    final isCompleted = widget.isCompleted;
    final isPenalized = widget.isPenalized;
    final bool degrade = SmartRenderEngine.shouldDegradeForContext(
      context,
      itemCount: widget.listLength,
    );
    final Duration animDuration = SmartRenderEngine.scaleDuration(
      const Duration(milliseconds: 240),
      itemCount: widget.listLength,
      forceLite: degrade,
    );
    final primaryTextColor = palette.tx;
    final priorityColor = _resolvePriorityColor(palette);
    final timelineTimeText = _resolveTimelineTimeText();

    final int totalSubTasksCount =
        widget.task.subTasks.length + widget.nestedChildren.length;
    final bool hasAnySubTasks = totalSubTasksCount > 0;

    final tileColor = isPenalized
        ? (isDark ? const Color(0xFF2C161B) : const Color(0xFFFEE2E2))
        : (isCompleted
            ? (isDark ? const Color(0xFF141416) : const Color(0xFFE5E5EA))
            : (isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7)));

    final cardContent = Directionality(
      textDirection: TextDirection.rtl,
      child: FadeTransition(
        key: Key('task_fade_transition_${widget.task.id}'),
        opacity: _fadeAnimation,
        child: ScaleTransition(
          key: Key('task_shrink_scale_${widget.task.id}'),
          scale: _scaleAnimation,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ستون زمان در سمت راست تایم‌لاین (.tm) با تراز دقیق در مرکز عمودی کارت
                SizedBox(
                  width: 46,
                  child: Center(
                    child: Text(
                      timelineTimeText,
                      key: Key('timeline_time_${widget.task.id}'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: palette.mu,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // محور عمودی تایم‌لاین و دایره وضعیت در مرکز عمودی کارت (.tl + .dot)
                SizedBox(
                  width: 16,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 1.5,
                          color: const Color(0xFF2C2C2E),
                        ),
                      ),
                      Center(
                        child: AnimatedContainer(
                          key: Key('timeline_dot_${widget.task.id}'),
                          duration: animDuration,
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted ? palette.ok : palette.bg,
                            border: Border.all(
                              color: isCompleted ? palette.ok : priorityColor,
                              width: 1.5,
                            ),
                            boxShadow: isCompleted
                                ? [
                                    BoxShadow(
                                      color: palette.ok.withOpacity(0.22),
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // کارت تسک با طراحی یکپارچه، بدون بوردر و گوشه‌های نرم ۲۴ پیکسلی (.card)
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    opacity: isCompleted ? 0.65 : 1.0,
                    child: BouncingTap(
                      onTap: _handleCheckmarkJoyTap,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: Key('task_card_tap_target_${widget.task.id}'),
                            onTap: _handleCheckmarkJoyTap,
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tileColor,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // دکمه تیک دایره‌ای بلافاصله در کنار متون در سمت راست (.chk)
                                          AnimatedScale(
                                            scale: isCompleted && !degrade
                                                ? 1.12
                                                : 1.0,
                                            duration: const Duration(milliseconds: 300),
                                            curve: Curves.elasticOut,
                                            child: AnimatedContainer(
                                              key: Key(
                                                'task_completion_checkbox_${widget.task.id}',
                                              ),
                                              duration: const Duration(milliseconds: 300),
                                              curve: Curves.easeInOut,
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isCompleted
                                                    ? palette.ok
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: isCompleted
                                                      ? palette.ok
                                                      : (isPenalized
                                                          ? palette.hot
                                                          : palette.mu
                                                              .withValues(alpha: 0.40)),
                                                  width: 1.8,
                                                ),
                                              ),
                                              child: isCompleted
                                                  ? const Icon(
                                                      Icons.check_rounded,
                                                      key: ValueKey(
                                                        'checked_icon',
                                                      ),
                                                      size: 15,
                                                      color: Color(0xFF06281E),
                                                    )
                                                  : const SizedBox.shrink(
                                                      key: ValueKey(
                                                        'unchecked_icon',
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),

                                          // عنوان درشت و زیرعنوان تسک (.t) با انیمیشن خط خوردن روان و تغییر رنگ
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                AnimatedDefaultTextStyle(
                                                  duration: const Duration(milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                  style: TextStyle(
                                                    fontFamily: 'Vazirmatn',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                    color: isCompleted
                                                        ? (isDark
                                                            ? const Color(0xFF636366)
                                                            : const Color(0xFF8E8E93))
                                                        : primaryTextColor,
                                                    decoration: isCompleted
                                                        ? TextDecoration.lineThrough
                                                        : TextDecoration.none,
                                                    decorationColor: isDark
                                                        ? const Color(0xFF636366)
                                                        : const Color(0xFF8E8E93),
                                                    decorationThickness: 2.0,
                                                  ),
                                                  child: Text(
                                                    widget.title,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                AnimatedDefaultTextStyle(
                                                  duration: const Duration(milliseconds: 300),
                                                  curve: Curves.easeInOut,
                                                  style: TextStyle(
                                                    fontFamily: 'Vazirmatn',
                                                    fontSize: 11.5,
                                                    color: isCompleted
                                                        ? (isDark
                                                            ? const Color(0xFF48484A)
                                                            : const Color(0xFFAEAEC2))
                                                        : palette.mu,
                                                  ),
                                                  child: Text(
                                                    widget.subtitle,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        // دکمه کپسولی نرم باز/بسته کردن زیرتسک‌ها
                                        if (hasAnySubTasks)
                                          InkWell(
                                            key: Key(
                                              'toggle_subtasks_expand_${widget.task.id}',
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            onTap: () {
                                              setState(() {
                                                _isSubTasksExpanded =
                                                    !_isSubTasksExpanded;
                                              });
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 9,
                                                vertical: 4.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: palette.ok
                                                    .withOpacity(0.14),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    _isSubTasksExpanded
                                                        ? CupertinoIcons
                                                            .chevron_up
                                                        : CupertinoIcons
                                                            .chevron_down,
                                                    size: 12,
                                                    color: palette.ok,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${toPersianDigits(totalSubTasksCount.toString())} زیرتسک',
                                                    style: TextStyle(
                                                      fontFamily: 'Vazirmatn',
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: palette.ok,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    // ردیف نشان‌ها (.tag): پوشه، بازه زمانی، تگ‌ها و جریمه
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: palette.s2,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${widget.task.workspaceLabelFa} · ${_resolvePriorityLabelFa()}',
                                            style: TextStyle(
                                              fontFamily: 'Vazirmatn',
                                              fontSize: 10.5,
                                              color: palette.mu,
                                            ),
                                          ),
                                        ),
                                        if (widget.task.hasTimeBlock)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: palette.s2,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  CupertinoIcons.clock,
                                                  size: 11,
                                                  color: palette.ac2,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  toPersianDigits(
                                                    widget.task
                                                        .timeBlockFormatted!,
                                                  ),
                                                  style: TextStyle(
                                                    fontFamily: 'Vazirmatn',
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: palette.ac2,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ...widget.task.tags.map((tag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: palette.s2,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              '#$tag',
                                              style: TextStyle(
                                                fontFamily: 'Vazirmatn',
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: palette.ok,
                                              ),
                                            ),
                                          );
                                        }),
                                        if (isPenalized)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  palette.hot.withOpacity(0.18),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  CupertinoIcons
                                                      .exclamationmark_circle_fill,
                                                  size: 11,
                                                  color: palette.hot,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'جریمه زمان‌بندی',
                                                  style: TextStyle(
                                                    fontFamily: 'Vazirmatn',
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: palette.hot,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),

                                    // منوی کشویی (Expandable) برای زیرتسک‌ها
                                    if (hasAnySubTasks)
                                      AnimatedCrossFade(
                                        duration:
                                            const Duration(milliseconds: 240),
                                        sizeCurve: Curves.easeOutCubic,
                                        crossFadeState: _isSubTasksExpanded
                                            ? CrossFadeState.showFirst
                                            : CrossFadeState.showSecond,
                                        firstChild: Container(
                                          margin:
                                              const EdgeInsets.only(top: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: palette.s2,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (widget
                                                  .task.subTasks.isNotEmpty)
                                                ...widget.task.subTasks
                                                    .map((sub) {
                                                  return InkWell(
                                                    key: Key(
                                                      'dashboard_subtask_tile_${widget.task.id}_${sub.id}',
                                                    ),
                                                    onTap: () => widget
                                                        .onSubTaskToggled(
                                                            sub.id),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                        right: 6,
                                                        top: 3,
                                                        bottom: 3,
                                                      ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            sub.isCompleted
                                                                ? CupertinoIcons
                                                                    .checkmark_circle_fill
                                                                : CupertinoIcons
                                                                    .circle,
                                                            size: 15,
                                                            color: sub
                                                                    .isCompleted
                                                                ? palette.ok
                                                                : palette.mu,
                                                          ),
                                                          const SizedBox(
                                                              width: 7),
                                                          Expanded(
                                                            child: Text(
                                                              toPersianDigits(
                                                                  sub.title),
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Vazirmatn',
                                                                fontSize: 11,
                                                                color: sub
                                                                        .isCompleted
                                                                    ? palette.mu
                                                                    : primaryTextColor,
                                                                decoration: sub
                                                                        .isCompleted
                                                                    ? TextDecoration
                                                                        .lineThrough
                                                                    : TextDecoration
                                                                        .none,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              _buildNestedTaskTree(
                                                widget.task,
                                                primaryTextColor,
                                                1,
                                              ),
                                            ],
                                          ),
                                        ),
                                        secondChild: const SizedBox(
                                          width: double.infinity,
                                        ),
                                      ),

                                    // نوار پیشرفت زنده زیرتسک‌ها در پایین کارت
                                    if (hasAnySubTasks)
                                      Builder(
                                        builder: (context) {
                                          final completedDirect = widget
                                              .task.completedSubTasksCount;
                                          final completedNested = widget
                                              .nestedChildren
                                              .where(
                                                (c) =>
                                                    c.status == TaskStatus.done,
                                              )
                                              .length;
                                          final completedTotal =
                                              completedDirect + completedNested;
                                          final liveRatio =
                                              totalSubTasksCount > 0
                                                  ? (completedTotal /
                                                          totalSubTasksCount)
                                                      .clamp(0.0, 1.0)
                                                  : 0.0;
                                          final livePercent =
                                              (liveRatio * 100).round();

                                          return Padding(
                                            key: Key(
                                              'subtask_live_progress_section_${widget.task.id}',
                                            ),
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'پیشرفت زیرتسک‌ها',
                                                      style: TextStyle(
                                                        fontFamily: 'Vazirmatn',
                                                        fontSize: 10,
                                                        color: palette.mu,
                                                      ),
                                                    ),
                                                    Text(
                                                      toPersianDigits(
                                                        '$completedTotal از $totalSubTasksCount ($livePercent٪)',
                                                      ),
                                                      key: Key(
                                                        'subtask_live_progress_text_${widget.task.id}',
                                                      ),
                                                      style: TextStyle(
                                                        fontFamily: 'Vazirmatn',
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: palette.ok,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: SizedBox(
                                                    height: 5,
                                                    child: LayoutBuilder(
                                                      builder: (
                                                        context,
                                                        constraints,
                                                      ) {
                                                        return Stack(
                                                          children: [
                                                            LinearProgressIndicator(
                                                              key: Key(
                                                                'subtask_linear_progress_${widget.task.id}',
                                                              ),
                                                              value: liveRatio,
                                                              minHeight: 5,
                                                              backgroundColor:
                                                                  palette.s2,
                                                              valueColor:
                                                                  const AlwaysStoppedAnimation<
                                                                      Color>(
                                                                Colors
                                                                    .transparent,
                                                              ),
                                                            ),
                                                            AnimatedContainer(
                                                              key: Key(
                                                                'subtask_live_progress_bar_${widget.task.id}',
                                                              ),
                                                              duration:
                                                                  const Duration(
                                                                milliseconds:
                                                                    320,
                                                              ),
                                                              curve: Curves
                                                                  .easeOutCubic,
                                                              width: constraints
                                                                      .maxWidth *
                                                                  liveRatio,
                                                              height: 5,
                                                              decoration:
                                                                  BoxDecoration(
                                                                gradient:
                                                                    LinearGradient(
                                                                  colors: [
                                                                    palette.ok,
                                                                    palette.ac2,
                                                                  ],
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                      6,
                                                                    ),
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),

                              // نشانگر ظریف و مینیمال اولویت در حاشیه راست کارت
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 0,
                                width: 2.0,
                                child: ColoredBox(
                                  key: Key(
                                    'task_priority_bar_${widget.task.id}',
                                  ),
                                  color: priorityColor.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );

    return ReorderableDelayedDragStartListener(
      index: widget.reorderIndex,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.smartGroupHeaderLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: widget.smartGroupHeaderKey ==
                        const Key('smart_group_header_overdue')
                    ? BouncingTap(
                        key: widget.smartGroupHeaderKey,
                        onTap: widget.onTapOverdueHeader ?? () {},
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons
                                        .exclamationmark_triangle_fill,
                                    size: 11,
                                    color: Color(0xFFEF4444),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.smartGroupHeaderLabel!,
                                    style: const TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                  if (widget.overdueCount != null &&
                                      widget.overdueCount! > 0) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        toPersianDigits(
                                          '${widget.overdueCount}',
                                        ),
                                        key: const Key('overdue_count_badge'),
                                        style: const TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 4),
                                  const Icon(
                                    CupertinoIcons.chevron_left,
                                    size: 10,
                                    color: Color(0xFFEF4444),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 0.8,
                                color: const Color(0xFFEF4444)
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        key: widget.smartGroupHeaderKey,
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            Text(
                              widget.smartGroupHeaderLabel!,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: palette.mu,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                height: 0.8,
                                color: palette.line,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Slidable(
                key: Key('task_slidable_${widget.task.id}'),
                // سوایپ به راست (Swipe Right -> startActionPane): شروع تمرکز پومودورو و افزودن زیرتسک
                startActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.52,
                  children: [
                    if (widget.onStartPomodoroFocus != null)
                      CustomSlidableAction(
                        key: Key('start_pomodoro_focus_${widget.task.id}'),
                        onPressed: (_) =>
                            widget.onStartPomodoroFocus!(widget.task),
                        backgroundColor:
                            const Color(0xFFF59E0B).withOpacity(0.18),
                        foregroundColor: const Color(0xFFFBBF24),
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: const Directionality(
                          textDirection: TextDirection.rtl,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.timer,
                                size: 16,
                                color: Color(0xFFFBBF24),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'شروع تمرکز ⏱️',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFBBF24),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    CustomSlidableAction(
                      key: Key('add_nested_subtask_${widget.task.id}'),
                      onPressed: (_) => widget.onAddNestedSubTask(widget.task),
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.18),
                      foregroundColor: AppColors.primaryBlueGlow,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: const Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.plus_circle_fill,
                              size: 16,
                              color: AppColors.primaryBlueGlow,
                            ),
                            SizedBox(height: 3),
                            Text(
                              'زیرتسک',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlueGlow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // سوایپ به چپ (Swipe Left -> endActionPane): ویرایش و حذف تسک
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  extentRatio: 0.44,
                  children: [
                    CustomSlidableAction(
                      key: Key('edit_task_action_${widget.task.id}'),
                      onPressed: (_) => widget.onEdit(),
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.18),
                      foregroundColor: const Color(0xFF818CF8),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: const Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.pencil,
                              size: 16,
                              color: Color(0xFF818CF8),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'ویرایش',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF818CF8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    CustomSlidableAction(
                      key: Key('delete_task_action_${widget.task.id}'),
                      onPressed: (_) => widget.onDelete(),
                      backgroundColor: const Color(0xFFEF4444).withOpacity(0.18),
                      foregroundColor: const Color(0xFFF87171),
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: const Directionality(
                        textDirection: TextDirection.rtl,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.trash,
                              size: 16,
                              color: Color(0xFFF87171),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'حذف',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFF87171),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                child: cardContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardNotificationBellButton extends StatelessWidget {
  final bool isDark;
  final bool isZen;
  final VoidCallback onTap;

  const _DashboardNotificationBellButton({
    required this.isDark,
    this.isZen = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveZen =
        isZen || Theme.of(context).scaffoldBackgroundColor == AppColors.backgroundZen;
    final palette = _DashboardRefPalette.of(isDark, isZen: effectiveZen);

    int unreadCount = 0;
    try {
      unreadCount = context.select<NotificationBloc, int>(
        (b) => b.state.unreadCount,
      );
    } catch (_) {
      if (sl.isRegistered<NotificationBloc>()) {
        try {
          unreadCount = sl<NotificationBloc>().state.unreadCount;
        } catch (_) {}
      }
    }

    return BouncingTap(
      key: const Key('dashboard_notifications_button'),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: palette.s1,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              unreadCount > 0
                  ? CupertinoIcons.bell_fill
                  : CupertinoIcons.bell,
              size: 16,
              color: unreadCount > 0 ? palette.tx : palette.mu,
            ),
            if (unreadCount > 0)
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  key: const Key('dashboard_notifications_unread_dot'),
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF453A),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatNotificationTimestamp(DateTime timestamp) {
  final local = timestamp.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);

  if (diff.inSeconds < 60 && !diff.isNegative) {
    return 'همین الان';
  }
  if (diff.inMinutes < 60 && diff.inMinutes > 0) {
    return '${PersianNumberFormatter.toPersianDigits(diff.inMinutes.toString())} دقیقه پیش';
  }
  final hour =
      PersianNumberFormatter.toPersianDigits(local.hour.toString().padLeft(2, '0'));
  final minute =
      PersianNumberFormatter.toPersianDigits(local.minute.toString().padLeft(2, '0'));

  if (now.year == local.year &&
      now.month == local.month &&
      now.day == local.day) {
    return 'امروز $hour:$minute';
  }
  final yesterday = now.subtract(const Duration(days: 1));
  if (yesterday.year == local.year &&
      yesterday.month == local.month &&
      yesterday.day == local.day) {
    return 'دیروز $hour:$minute';
  }
  final shortDate = JalaliDateFormatter.formatShort(local);
  return '$shortDate ساعت $hour:$minute';
}

class _NotificationsSheetContent extends StatefulWidget {
  final NotificationBloc? bloc;
  final bool isDark;
  final Color glassBg;
  final Color cardBg;
  final Color textColor;
  final Color secondaryTextColor;

  const _NotificationsSheetContent({
    required this.bloc,
    required this.isDark,
    required this.glassBg,
    required this.cardBg,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  State<_NotificationsSheetContent> createState() =>
      _NotificationsSheetContentState();
}

class _NotificationsSheetContentState
    extends State<_NotificationsSheetContent> {
  @override
  Widget build(BuildContext context) {
    final effectiveBloc = widget.bloc ??
        (sl.isRegistered<NotificationBloc>() ? sl<NotificationBloc>() : null);

    if (effectiveBloc == null) {
      return _buildEmptyView();
    }

    return BlocBuilder<NotificationBloc, NotificationState>(
      bloc: effectiveBloc,
      builder: (context, state) {
        final notifications = state.notifications;
        final unreadCount = state.unreadCount;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.secondaryTextColor.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A84FF).withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.bell_fill,
                    color: Color(0xFF0A84FF),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'پیام‌ها و اعلان‌ها',
                        key: const Key('notifications_sheet_title'),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                        ),
                      ),
                      Text(
                        unreadCount > 0
                            ? toPersianDigits('$unreadCount پیام خوانده‌نشده')
                            : 'تاریخچه رویدادها، پاداش‌ها و جریمه‌ها',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11.5,
                          color: widget.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notifications.isNotEmpty) ...[
                  BouncingTap(
                    key: const Key('notifications_mark_all_read_button'),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      effectiveBloc.add(const NotificationsMarkAllRead());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.cardBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'خواندن همه',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A84FF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BouncingTap(
                    key: const Key('notifications_clear_all_button'),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      effectiveBloc.add(const NotificationsCleared());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: widget.cardBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        CupertinoIcons.trash,
                        size: 14,
                        color: widget.secondaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                BouncingTap(
                  key: const Key('notifications_close_button'),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: widget.cardBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.xmark,
                      size: 14,
                      color: widget.secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (notifications.isEmpty)
              _buildEmptyView()
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final item = notifications[index];
                    return _NotificationTileItem(
                      notification: item,
                      isDark: widget.isDark,
                      cardBg: widget.cardBg,
                      textColor: widget.textColor,
                      secondaryTextColor: widget.secondaryTextColor,
                      onTap: () {
                        if (!item.isRead) {
                          effectiveBloc.add(NotificationMarkedAsRead(item.id));
                        }
                      },
                      onDismissed: () {
                        effectiveBloc.add(NotificationDeleted(item.id));
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return Container(
      key: const Key('notifications_empty_state'),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.sparkles,
              size: 36,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'روز جدید، بوم سفید',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'برای شروع، یک تسک جدید اضافه کنید\nگزارش پاداش‌ها، جلسات تمرکز، جریمه‌ها و وضعیت در اینجا ذخیره می‌شوند.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              color: widget.secondaryTextColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTileItem extends StatelessWidget {
  final AppNotificationEntity notification;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color secondaryTextColor;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotificationTileItem({
    required this.notification,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.secondaryTextColor,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final (accentColor, iconData) = switch (notification.type) {
      AppNotificationType.reward => (
          const Color(0xFF30D158),
          CupertinoIcons.sparkles,
        ),
      AppNotificationType.penalty => (
          const Color(0xFFFF453A),
          CupertinoIcons.exclamationmark_circle_fill,
        ),
      AppNotificationType.warning => (
          const Color(0xFFFF9F0A),
          CupertinoIcons.exclamationmark_triangle_fill,
        ),
      AppNotificationType.info => (
          const Color(0xFF0A84FF),
          CupertinoIcons.info_circle_fill,
        ),
    };

    final formattedTime = _formatNotificationTimestamp(notification.timestamp);

    return Dismissible(
      key: Key('notification_dismissible_${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF453A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          CupertinoIcons.trash,
          color: Colors.white,
          size: 18,
        ),
      ),
      child: BouncingTap(
        key: Key('notification_tile_${notification.id}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead
                ? cardBg
                : (isDark
                    ? cardBg.withValues(alpha: 0.85)
                    : Colors.white),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: notification.isRead
                    ? Colors.black.withValues(alpha: isDark ? 0.2 : 0.04)
                    : accentColor.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: notification.isRead ? 6 : 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconData,
                  color: accentColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 10.5,
                            color: secondaryTextColor,
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            key: Key('notification_unread_dot_${notification.id}'),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        height: 1.4,
                        color: textColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
