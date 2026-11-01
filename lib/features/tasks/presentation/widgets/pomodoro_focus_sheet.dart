import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/core/theme/app_colors.dart';
import 'package:task_flow/core/utils/persian_number_formatter.dart';
import 'package:task_flow/core/widgets/bouncing_tap.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/focus_session_repository.dart';
import 'package:task_flow/features/tasks/domain/repositories/xp_ledger_repository.dart';
import 'package:task_flow/features/tasks/domain/services/ticker.dart';
import 'package:task_flow/features/tasks/presentation/bloc/focus_timer_bloc.dart';
import 'package:task_flow/features/tasks/presentation/bloc/focus_timer_event.dart';
import 'package:task_flow/features/tasks/presentation/bloc/focus_timer_state.dart';

/// شیت شیشه‌ای و مینیمال «موتور تمرکز پومودورو» (Pomodoro Deep Work Engine)
/// با تایمر معکوس پیش‌فرض ۲۵ دقیقه، انیمیشن دایره‌ای (Circular Progress)،
/// و اتصال مستقیم به [FocusTimerBloc] برای ذخیره نشست تمرکز و اهدای XP.
class PomodoroFocusSheet extends StatefulWidget {
  final TaskEntity task;
  final bool isDark;
  final Duration initialDuration;
  final VoidCallback onCompleteTask;

  const PomodoroFocusSheet({
    super.key,
    required this.task,
    required this.isDark,
    this.isZen = false,
    this.initialDuration = const Duration(minutes: 25),
    required this.onCompleteTask,
  });

  final bool isZen;

  /// نمایش شیت پومودورو برای یک تسک مشخص
  static Future<void> show({
    required BuildContext context,
    required TaskEntity task,
    required bool isDark,
    Duration initialDuration = const Duration(minutes: 25),
    required VoidCallback onCompleteTask,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PomodoroFocusSheet(
        task: task,
        isDark: isDark,
        initialDuration: initialDuration,
        onCompleteTask: onCompleteTask,
      ),
    );
  }

  @override
  State<PomodoroFocusSheet> createState() => _PomodoroFocusSheetState();
}

class _PomodoroFocusSheetState extends State<PomodoroFocusSheet> {
  late final FocusTimerBloc _timerBloc;
  late final int _totalSeconds;

  @override
  void initState() {
    super.initState();
    _totalSeconds = widget.initialDuration.inSeconds > 0
        ? widget.initialDuration.inSeconds
        : 25 * 60;

    SettingsBloc? settingsBloc;
    try {
      settingsBloc = context.read<SettingsBloc>();
    } catch (_) {
      if (sl.isRegistered<SettingsBloc>()) {
        settingsBloc = sl<SettingsBloc>();
      }
    }

    _timerBloc = FocusTimerBloc(
      ticker: const Ticker(),
      focusSessionRepository: sl.isRegistered<FocusSessionRepository>()
          ? sl<FocusSessionRepository>()
          : null,
      xpLedgerRepository: sl.isRegistered<XpLedgerRepository>()
          ? sl<XpLedgerRepository>()
          : null,
      settingsBloc: settingsBloc,
    );
  }

  @override
  void dispose() {
    _timerBloc.close();
    super.dispose();
  }

  void _toggleTimer(FocusTimerState state) {
    if (state is FocusTimerCompletedState) return;

    if (state is FocusTimerRunning) {
      _timerBloc.add(const FocusTimerPaused());
    } else if (state is FocusTimerPausedState) {
      _timerBloc.add(const FocusTimerResumed());
    } else {
      _timerBloc.add(
        FocusTimerStarted(
          taskId: widget.task.id,
          durationSeconds: _totalSeconds,
          taskTitle: widget.task.title,
        ),
      );
    }
  }

  void _resetTimer(FocusTimerState state) {
    if (state is FocusTimerRunning || state is FocusTimerPausedState) {
      _timerBloc.add(const FocusTimerCancelled());
    }
    _timerBloc.add(
      FocusTimerStarted(
        taskId: widget.task.id,
        durationSeconds: _totalSeconds,
        taskTitle: widget.task.title,
      ),
    );
  }

  void _completeTimerEarly() {
    _timerBloc.add(const FocusTimerCompleted());
  }

  String _formatRemainingTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return toPersianDigits('$minutes:$secs');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZen = widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;
    final isDark = widget.isDark;
    final textColor = isDark ? AppColors.textDark : (isZen ? AppColors.textZen : AppColors.textLight);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : (isZen ? AppColors.textZenSecondary : const Color(0xFF64748B));
    final glassBg = isDark
        ? const Color(0xF2121824)
        : (isZen
            ? AppColors.surfaceZen.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95));

    return BlocProvider.value(
      value: _timerBloc,
      child: BlocConsumer<FocusTimerBloc, FocusTimerState>(
        listener: (context, state) {
          if (state is FocusTimerCompletedState) {
            SoundAndHapticService.instance.playPomodoroCompletedFeedback();
          }
        },
        builder: (context, state) {
          final isRunning = state is FocusTimerRunning;
          final isFinished = state is FocusTimerCompletedState;
          final remainingSeconds = isFinished ? 0 : state.duration;
          final totalSecs = state.totalDuration > 0 ? state.totalDuration : _totalSeconds;
          final double progress = totalSecs > 0
              ? (remainingSeconds / totalSecs).clamp(0.0, 1.0)
              : 0.0;
          final earnedXp = state is FocusTimerCompletedState ? state.earnedXp : 0;

          return ClipRRect(
            key: const Key('pomodoro_focus_bottom_sheet'),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                decoration: BoxDecoration(
                  color: glassBg,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // دستگیره بالای شیت
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // عنوان و نام تسک
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.timer,
                            color: AppColors.primaryBlueGlow,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'جلسه تمرکز عمیق (Deep Work)',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      toPersianDigits(widget.task.title),
                      key: const Key('pomodoro_task_title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlueGlow,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // دایره انیمیشنی تایمر معکوس (Circular Progress)
                    SizedBox(
                      key: const Key('pomodoro_circular_progress'),
                      width: 176,
                      height: 176,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: progress, end: progress),
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        builder: (context, animatedValue, _) {
                          final activeColor = isFinished
                              ? const Color(0xFF10B981)
                              : AppColors.primaryBlueGlow;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 164,
                                height: 164,
                                child: CircularProgressIndicator(
                                  key: const Key('pomodoro_circular_progress_indicator'),
                                  value: animatedValue,
                                  strokeWidth: 8.5,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.07),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(activeColor),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatRemainingTime(remainingSeconds),
                                    key: const Key('pomodoro_timer_text'),
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isFinished
                                        ? 'تمرکز تکمیل شد 🌟'
                                        : (isRunning
                                            ? 'در حال تمرکز عمیق...'
                                            : (state is FocusTimerPausedState
                                                ? 'متوقف شده'
                                                : 'آماده شروع ۲۵ دقیقه')),
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 11.5,
                                      color: isFinished
                                          ? const Color(0xFF10B981)
                                          : secondaryTextColor
                                              .withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),

                    // در صورت اتمام زمان: آزادی عمل کاربر (User Autonomy) با نمایش پاداش XP
                    if (isFinished) ...[
                      Container(
                        key: const Key('pomodoro_completion_banner'),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            if (earnedXp > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  toPersianDigits('+$earnedXp XP پاداش تمرکز دریافت شد ⚡'),
                                  style: const TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ],
                            Text(
                              'جلسه تمرکز عمیق به پایان رسید! تصمیم شما برای این تسک چیست؟',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // دکمه اصلی (Primary Button): بستن شیت و باز نگه داشتن تسک
                            SizedBox(
                              width: double.infinity,
                              child: BouncingTap(
                                child: ElevatedButton.icon(
                                  key: const Key('pomodoro_confirm_end_focus_button'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryBlue,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  icon: const Icon(
                                    CupertinoIcons.checkmark_seal_fill,
                                    size: 17,
                                  ),
                                  label: const Text(
                                    'تأیید پایان تمرکز',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // دکمه ثانویه (Solid Emerald Button): تیک زدن و اتمام تسک + بستن شیت
                            SizedBox(
                              width: double.infinity,
                              child: BouncingTap(
                                child: ElevatedButton.icon(
                                  key: const Key('pomodoro_complete_task_button'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.mediumImpact();
                                    widget.onCompleteTask();
                                    if (mounted) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  icon: const Icon(
                                    CupertinoIcons.check_mark_circled,
                                    size: 17,
                                  ),
                                  label: const Text(
                                    'تیک زدن و اتمام تسک ✅',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // دکمه‌های کنترل تایمر (شروع/توقف، بازنشانی، اتمام تمرکز)
                    if (!isFinished)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BouncingTap(
                          child: ElevatedButton.icon(
                            key: const Key('pomodoro_reset_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFF2F2F7),
                              foregroundColor: secondaryTextColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _resetTimer(state);
                            },
                            icon: const Icon(CupertinoIcons.refresh, size: 15),
                            label: const Text(
                              'بازنشانی',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        BouncingTap(
                          child: ElevatedButton.icon(
                            key: const Key('pomodoro_toggle_play_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: isFinished
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    _toggleTimer(state);
                                  },
                            icon: Icon(
                              isRunning
                                  ? CupertinoIcons.pause_fill
                                  : CupertinoIcons.play_arrow_solid,
                              size: 16,
                            ),
                            label: Text(
                              isRunning
                                  ? 'توقف موقت'
                                  : (state is FocusTimerPausedState
                                      ? 'ادامه تمرکز'
                                      : 'شروع تمرکز'),
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        BouncingTap(
                          child: TextButton(
                            key: const Key('pomodoro_finish_timer_button'),
                            onPressed: isFinished
                                ? null
                                : () {
                                    HapticFeedback.mediumImpact();
                                    _completeTimerEarly();
                                  },
                            child: const Text(
                              'اتمام تمرکز',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF10B981),
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
          );
        },
      ),
    );
  }
}
