import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/notifications/notification_service.dart';
import 'package:task_flow/core/performance/smart_render_engine.dart';
import 'package:task_flow/core/services/backup_service.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/core/theme/app_accent_color.dart';
import 'package:task_flow/core/theme/app_colors.dart';
import 'package:task_flow/core/theme/app_theme_mode.dart';
import 'package:task_flow/core/theme/providers/theme_provider.dart';
import 'package:task_flow/core/utils/persian_number_formatter.dart';
import 'package:task_flow/core/widgets/bouncing_tap.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_bloc.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_event.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_event.dart';
import 'package:task_flow/features/onboarding/onboarding_page.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_state.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_event.dart';

/// صفحه تنظیمات فنی و زیرساختی سامانه (Technical Settings View)
/// شامل پوسته‌ها، رنگ شاخص، حالت استراحت، موتور رندر هوشمند و پشتیبان‌گیری
class TechnicalSettingsView extends ConsumerStatefulWidget {
  final bool isDark;
  final bool isZen;

  const TechnicalSettingsView({
    super.key,
    required this.isDark,
    this.isZen = false,
  });

  @override
  ConsumerState<TechnicalSettingsView> createState() =>
      _TechnicalSettingsViewState();
}

class _TechnicalSettingsViewState extends ConsumerState<TechnicalSettingsView> {
  bool _isBackupInProgress = false;
  String _backupLoadingMessage = '';

  void _openOnboardingPage() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => const OnboardingPage(),
      ),
    );
  }

  Future<void> _handleTestBackgroundNotification() async {
    unawaited(HapticFeedback.mediumImpact());
    unawaited(SoundAndHapticService.instance.playSoftTick());

    final notificationService = sl.isRegistered<NotificationService>()
        ? sl<NotificationService>()
        : NotificationService();

    await notificationService.scheduleTestNotification(
      seconds: 5,
      title: 'زندگی‌ساز 🚀',
      body: 'نوتیفیکیشن پس‌زمینه با موفقیت کار می‌کند!',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'نوتیفیکیشن برای ۵ ثانیه دیگر تنظیم شد؛ اکنون برنامه را مینیمایز کنید.',
          style: TextStyle(fontFamily: 'Vazirmatn'),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  /// شیت شیشه‌ای پشتیبان‌گیری از دیتابیس محلی (SQLite)
  void _showBackupGlassBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(context);
        final isZen =
            widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;
        final isDark = widget.isDark;
        final textColor = isDark
            ? AppColors.textDark
            : (isZen ? AppColors.textZen : AppColors.textLight);
        final secondaryTextColor = isDark
            ? const Color(0xFF94A3B8)
            : (isZen ? AppColors.textZenSecondary : const Color(0xFF64748B));

        return Directionality(
          textDirection: TextDirection.rtl,
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                key: const Key('add_device_glass_bottom_sheet'),
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 34),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C1E).withValues(alpha: 0.95)
                      : (isZen
                          ? AppColors.surfaceZen.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.95)),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.22)
                              : Colors.black.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0A84FF).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.archivebox_fill,
                            size: 20,
                            color: Color(0xFF0A84FF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'تهیه نسخه پشتیبان (آزمایشی)',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تمامی تسک‌ها، پروژه‌ها و گزارش‌های شما در فایل دیتابیس محلی (SQLite) ذخیره شده و بدون وابستگی به سرور در دسترس هستند.',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12.5,
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            key: const Key('cancel_add_device_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : const Color(0xFFE5E5EA),
                              foregroundColor: secondaryTextColor,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text(
                              'انصراف',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            key: const Key('confirm_add_device_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A84FF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              _handleCreateBackup();
                            },
                            icon: const Icon(
                              CupertinoIcons.checkmark_shield_fill,
                              size: 18,
                            ),
                            label: const Text(
                              'تایید و ذخیره نسخه پشتیبان',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
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
        );
      },
    );
  }

  Future<void> _handleCreateBackup() async {
    setState(() {
      _isBackupInProgress = true;
      _backupLoadingMessage = 'در حال تهیه و فشرده‌سازی نسخه پشتیبان...';
    });

    try {
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null && box.hasSize
          ? box.localToGlobal(Offset.zero) & box.size
          : null;
      final backupService = sl<BackupService>();
      final result =
          await backupService.exportBackup(sharePositionOrigin: origin);

      if (!mounted) return;
      setState(() {
        _isBackupInProgress = false;
      });

      if (result is BackupSuccess) {
        unawaited(SoundAndHapticService.instance.playSuccessChime());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'نسخه پشتیبان با موفقیت تهیه شد (${toPersianDigits(result.totalRecords.toString())} رکورد ثبت گردید).',
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      } else if (result is BackupFailure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              toPersianDigits('خطا در تهیه نسخه پشتیبان: ${result.message}'),
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBackupInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            toPersianDigits('خطای غیرمنتظره در پشتیبان‌گیری: $e'),
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEF4444),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  Future<void> _handleRestoreBackup() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (dialogCtx) => CupertinoAlertDialog(
        title: const Text(
          'بازیابی اطلاعات',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'با انتخاب فایل پشتیبان، داده‌های فعلی برنامه به طور کامل جایگزین خواهند شد. آیا مایل به ادامه هستید؟',
            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child:
                const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'ادامه و انتخاب فایل',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isBackupInProgress = true;
      _backupLoadingMessage = 'در حال بازخوانی و همگام‌سازی اطلاعات...';
    });

    try {
      final backupService = sl<BackupService>();
      final result = await backupService.restoreBackup();

      if (!mounted) return;
      setState(() {
        _isBackupInProgress = false;
      });

      if (result is RestoreSuccess) {
        unawaited(SoundAndHapticService.instance.playSuccessChime());

        if (!mounted) return;
        // Trigger app-wide state refresh
        context.read<SettingsBloc>().add(const SettingsLoadRequested());
        context.read<TaskBloc>().add(const TasksLoadRequested());
        try {
          context
              .read<FinancialAnalyticsBloc>()
              .add(const FinancialAnalyticsLoadRequested());
        } catch (_) {}
        try {
          context
              .read<NotificationBloc>()
              .add(const NotificationsLoadRequested());
        } catch (_) {}

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'اطلاعات با موفقیت بازیابی شد (${toPersianDigits(result.restoredRecords.toString())} رکورد بازیابی و همگام گردید).',
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      } else if (result is RestoreFailure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              toPersianDigits('خطا در بازیابی اطلاعات: ${result.message}'),
              style: const TextStyle(fontFamily: 'Vazirmatn'),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBackupInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            toPersianDigits('خطای غیرمنتظره در بازیابی: $e'),
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEF4444),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZen =
        widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;
    final isDark = widget.isDark;
    final textColor = isDark
        ? AppColors.textDark
        : (isZen ? AppColors.textZen : AppColors.textLight);
    final secondaryTextColor = isDark
        ? const Color(0xFF94A3B8)
        : (isZen ? AppColors.textZenSecondary : const Color(0xFF64748B));
    final bgColor = isDark
        ? const Color(0xFF000000)
        : (isZen ? AppColors.backgroundZen : const Color(0xFFF2F2F7));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          key: const Key('technical_settings_back_button'),
          icon: Icon(
            CupertinoIcons.back,
            color: textColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'تنظیمات فنی و سامانه',
          key: const Key('technical_settings_title'),
          style: TextStyle(
            color: textColor,
            fontFamily: 'Vazirmatn',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final settings = state.settings;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 60),
                children: [
                  // سرفصل: تنظیمات ظاهری و تجربه کاربری
                  _buildSectionHeader(
                    'تنظیمات ظاهری و تجربه کاربری',
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 10),

                  // ۱. انتخاب حالت تم پایه (روشن / تیره / آرامش Zen)
                  _buildMinimalCard(
                    key: const Key('settings_theme_mode_card'),
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: switch (settings.themeMode) {
                                  AppThemeMode.signature => const Color(0xFF00E5FF)
                                      .withValues(alpha: 0.15),
                                  AppThemeMode.dark => const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.15),
                                  AppThemeMode.light => const Color(0xFF3B82F6)
                                      .withValues(alpha: 0.15),
                                  AppThemeMode.zen => const Color(0xFF2E7D32)
                                      .withValues(alpha: 0.15),
                                },
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                switch (settings.themeMode) {
                                  AppThemeMode.signature =>
                                    CupertinoIcons.sparkles,
                                  AppThemeMode.dark =>
                                    CupertinoIcons.moon_stars_fill,
                                  AppThemeMode.light =>
                                    CupertinoIcons.sun_max_fill,
                                  AppThemeMode.zen => Icons.spa_rounded,
                                },
                                color: switch (settings.themeMode) {
                                  AppThemeMode.signature =>
                                    const Color(0xFF00E5FF),
                                  AppThemeMode.dark =>
                                    const Color(0xFFF59E0B),
                                  AppThemeMode.light =>
                                    const Color(0xFF3B82F6),
                                  AppThemeMode.zen =>
                                    const Color(0xFF2E7D32),
                                },
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'پوسته کلی برنامه',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  switch (settings.themeMode) {
                                    AppThemeMode.signature =>
                                      'طراحی اختصاصی زندگی‌ساز فعال است',
                                    AppThemeMode.dark => 'پوسته شب فعال است',
                                    AppThemeMode.light => 'پوسته روز فعال است',
                                    AppThemeMode.zen =>
                                      'پوسته آرامش (Zen) فعال است',
                                  },
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            for (final mode in AppThemeMode.values) ...[
                              Expanded(
                                child: BouncingTap(
                                  onTap: () {
                                    unawaited(
                                      SoundAndHapticService.instance
                                          .playSoftTick(),
                                    );
                                    HapticFeedback.selectionClick();
                                    context.read<SettingsBloc>().add(
                                          SettingsThemeModeChanged(mode),
                                        );
                                    ref.read(themeProvider.notifier).state =
                                        mode;
                                  },
                                  child: Container(
                                    key:
                                        Key('settings_theme_mode_${mode.name}'),
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 9),
                                    decoration: BoxDecoration(
                                      color: settings.themeMode == mode
                                          ? settings.accentColor.color
                                              .withValues(alpha: 0.16)
                                          : (isDark
                                              ? const Color(0xFF2C2C2E)
                                              : const Color(0xFFE5E5EA)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: settings.themeMode == mode
                                          ? Border.all(
                                              color: settings.accentColor.color,
                                              width: 1.2,
                                            )
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          switch (mode) {
                                            AppThemeMode.signature =>
                                              CupertinoIcons.sparkles,
                                            AppThemeMode.light =>
                                              CupertinoIcons.sun_max_fill,
                                            AppThemeMode.dark =>
                                              CupertinoIcons.moon_stars_fill,
                                            AppThemeMode.zen =>
                                              Icons.spa_rounded,
                                          },
                                          size: 15,
                                          color: settings.themeMode == mode
                                              ? settings.accentColor.color
                                              : secondaryTextColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          mode.label,
                                          style: TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 11.5,
                                            fontWeight:
                                                settings.themeMode == mode
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                            color: settings.themeMode == mode
                                                ? settings.accentColor.color
                                                : secondaryTextColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (mode != AppThemeMode.values.last)
                                const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ۲. انتخاب رنگ شاخص و برند
                  _buildMinimalCard(
                    key: const Key('settings_accent_color_card'),
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: settings.accentColor.color
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                CupertinoIcons.paintbrush_fill,
                                color: settings.accentColor.color,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'رنگ شاخص و برند (Accent Color)',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'شخصی‌سازی هویت بصری، دکمه‌ها و نشانگرها',
                                  style: TextStyle(
                                    color: secondaryTextColor,
                                    fontSize: 12,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: AppAccentColor.values.map((accent) {
                              final isSelected = settings.accentColor == accent;
                              return Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: BouncingTap(
                                  key: Key(
                                      'settings_accent_color_${accent.name}'),
                                  onTap: () {
                                    context.read<SettingsBloc>().add(
                                          SettingsAccentColorChanged(accent),
                                        );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeInOut,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? accent.color.withValues(
                                              alpha: isDark ? 0.22 : 0.12,
                                            )
                                          : (isDark
                                              ? const Color(0xFF2C2C2E)
                                              : const Color(0xFFF2F2F7)),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? accent.color
                                            : Colors.transparent,
                                        width: 1.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: accent.color,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: accent.color
                                                    .withValues(alpha: 0.35),
                                                blurRadius: 4,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check_rounded,
                                                  size: 13,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          accent.label,
                                          style: TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 12.5,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? accent.color
                                                : textColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(growable: false),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ۳. حالت استراحت (Vacation Mode)
                  _buildMinimalCard(
                    isDark: isDark,
                    child: Row(
                      key: const Key('settings_vacation_mode_card'),
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  CupertinoIcons.airplane,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'حالت استراحت (Vacation Mode)',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      settings.isVacationMode
                                          ? 'جریمه‌ها متوقف است • عادت‌ها خودکار به فردا منتقل می‌شوند'
                                          : 'در زمان سفر یا استراحت، بدون جریمه عادت‌ها را به روز بعد منتقل کنید',
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
                        ),
                        CupertinoSwitch(
                          key: const Key('settings_vacation_mode_switch'),
                          value: settings.isVacationMode,
                          activeTrackColor: const Color(0xFF10B981),
                          onChanged: (value) {
                            context.read<SettingsBloc>().add(
                                  SettingsVacationModeToggled(value),
                                );
                            try {
                              context.read<TaskBloc>().add(
                                    TaskVacationModeChanged(value),
                                  );
                            } catch (_) {}
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ۴. موتور رندر هوشمند (Smart Render)
                  _buildMinimalCard(
                    isDark: isDark,
                    child: Row(
                      key: const Key('settings_smart_render_card'),
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  CupertinoIcons.speedometer,
                                  color: Color(0xFF8B5CF6),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'موتور رندر هوشمند (Smart Render)',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      SmartRenderEngine.forceLowEndDeviceMode
                                          ? 'حالت مات و فوق‌سریع ۶۰ فریم فعال است'
                                          : 'بهینه‌سازی هوشمند مصرف باتری و گرافیک',
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
                        ),
                        CupertinoSwitch(
                          key: const Key('settings_smart_render_switch'),
                          value: SmartRenderEngine.forceLowEndDeviceMode,
                          activeTrackColor: const Color(0xFF8B5CF6),
                          onChanged: (value) {
                            setState(() {
                              SmartRenderEngine.forceLowEndDeviceMode = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ۵. تست نوتیفیکیشن پس‌زمینه (Background Notification Test)
                  _buildMinimalCard(
                    key: const Key('settings_test_notification_card'),
                    isDark: isDark,
                    child: BouncingTap(
                      key: const Key('settings_test_notification_button'),
                      onTap: _handleTestBackgroundNotification,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A84FF)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  CupertinoIcons.bell_fill,
                                  color: Color(0xFF0A84FF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'تست نوتیفیکیشن پسزمینه',
                                    key: const Key(
                                        'settings_test_notification_title'),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'ارسال نوتیفیکیشن دقیقاً ۵ ثانیه پس از لمس دکمه',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A84FF)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  CupertinoIcons.timer,
                                  size: 13,
                                  color: Color(0xFF0A84FF),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '۵ ثانیه',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0A84FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ۶. راهنمای تعاملی و امکانات
                  _buildMinimalCard(
                    key: const Key('settings_reopen_onboarding_card'),
                    isDark: isDark,
                    child: BouncingTap(
                      onTap: _openOnboardingPage,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9500)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  CupertinoIcons.sparkles,
                                  color: Color(0xFFFF9500),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'راهنمای تعاملی و امکانات',
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'مرور قابلیت‌های کلیدی، حالت آرامش و سیستم پاداش',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                      fontSize: 12,
                                      fontFamily: 'Vazirmatn',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Icon(
                            CupertinoIcons.chevron_left,
                            size: 16,
                            color: secondaryTextColor.withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // سرفصل: فضای ابری و پشتیبان‌گیری
                  _buildCloudBackupSection(
                    isDark: isDark,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  ),

                  const SizedBox(height: 28),

                  // سرفصل: پایگاه داده محلی و همگام‌سازی
                  _buildSectionHeader(
                    'مدیریت داده‌ها و پایگاه داده محلی (SQLite)',
                    secondaryTextColor,
                  ),
                  const SizedBox(height: 10),

                  _buildConnectedDevicesSection(
                    isDark: isDark,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor,
                  ),

                  const SizedBox(height: 28),

                  // سرفصل: اطلاعات فنی
                  _buildSectionHeader('مشخصات فنی سیستم', secondaryTextColor),
                  const SizedBox(height: 10),

                  _buildMinimalCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildTechRow(
                          icon: CupertinoIcons.layers_alt_fill,
                          label: 'موتور هسته',
                          value: 'موتور پردازش سریع و بهینه',
                          textColor: textColor,
                          secondaryColor: secondaryTextColor,
                        ),
                        Divider(
                          height: 24,
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                        _buildTechRow(
                          icon: CupertinoIcons.circle_grid_hex_fill,
                          label: 'پایگاه داده',
                          value: 'پایگاه داده آفلاین با امنیت بالا',
                          textColor: textColor,
                          secondaryColor: secondaryTextColor,
                        ),
                        Divider(
                          height: 24,
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                        _buildTechRow(
                          icon: CupertinoIcons.money_dollar_circle_fill,
                          label: 'واحد مالی سیستم',
                          value: 'ریال / تومان (قفل‌شده)',
                          textColor: textColor,
                          secondaryColor: secondaryTextColor,
                        ),
                        Divider(
                          height: 24,
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                        _buildTechRow(
                          icon: CupertinoIcons.checkmark_shield_fill,
                          label: 'وضعیت نسخه',
                          value: toPersianDigits('نسخه ۱.۱.۰ تجاری'),
                          textColor: textColor,
                          secondaryColor: secondaryTextColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // لایه محافظ و بارگذاری هنگام پشتیبان‌گیری / بازیابی
              if (_isBackupInProgress)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        color: (isDark ? Colors.black : Colors.white)
                            .withValues(alpha: 0.45),
                        alignment: Alignment.center,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1C1C1E)
                                : (isZen ? AppColors.surfaceZen : Colors.white),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 28,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CupertinoActivityIndicator(radius: 16),
                              const SizedBox(height: 16),
                              Text(
                                _backupLoadingMessage,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCloudBackupSection({
    required bool isDark,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final theme = Theme.of(context);
    final isZen =
        widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'فضای ابری و پشتیبانگیری',
          secondaryTextColor,
        ),
        const SizedBox(height: 10),
        _buildMinimalCard(
          key: const Key('settings_cloud_backup_card'),
          isDark: isDark,
          child: Column(
            children: [
              BouncingTap(
                key: const Key('settings_create_backup_button'),
                onTap: _handleCreateBackup,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF0A84FF).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          CupertinoIcons.cloud_upload,
                          color: Color(0xFF0A84FF),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تهیه نسخه پشتیبان',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'خروجی امن اطلاعات، استریک‌ها و بودجه جهت ذخیره در Drive یا iCloud',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 11.5,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_left,
                        size: 16,
                        color: secondaryTextColor.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  thickness: 0.6,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : (isZen
                          ? const Color(0xFF4A443A).withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.06)),
                ),
              ),
              BouncingTap(
                key: const Key('settings_restore_backup_button'),
                onTap: _handleRestoreBackup,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF34C759).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          CupertinoIcons.cloud_download,
                          color: Color(0xFF34C759),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'بازیابی اطلاعات',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'بازگردانی از فایل پشتیبان و همگام‌سازی لحظه‌ای تمام بخش‌ها',
                              style: TextStyle(
                                color: secondaryTextColor,
                                fontSize: 11.5,
                                fontFamily: 'Vazirmatn',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_left,
                        size: 16,
                        color: secondaryTextColor.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedDevicesSection({
    required bool isDark,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final theme = Theme.of(context);
    final isZen =
        widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;
    return _buildMinimalCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A84FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.circle_grid_hex_fill,
                      color: Color(0xFF0A84FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'پایگاه داده آفلاین محلی (SQLite)',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2C2C2E)
                  : (isZen ? const Color(0xFFE2DDD2) : const Color(0xFFF2F2F7)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'وضعیت: سینک آفلاین فعال',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                const Spacer(),
                Text(
                  'بدون وابستگی ابری',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 11.5,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          BouncingTap(
            onTap: () => _showBackupGlassBottomSheet(context),
            child: ElevatedButton.icon(
              key: const Key('settings_add_device_button'),
              onPressed: () => _showBackupGlassBottomSheet(context),
              icon: const Icon(CupertinoIcons.archivebox_fill, size: 18),
              label: const Text(
                'تهیه نسخه پشتیبان (آزمایشی)',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? const Color(0xFF2C2C2E)
                    : (isZen ? const Color(0xFFE2DDD2) : const Color(0xFFF2F2F7)),
                foregroundColor: const Color(0xFF0A84FF),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalCard({
    Key? key,
    required bool isDark,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isZen =
        widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;
    final bgColor = isDark
        ? const Color(0xFF1C1C1E)
        : (isZen ? AppColors.surfaceZen : Colors.white);

    return AnimatedContainer(
      key: key,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: isZen
                      ? const Color(0x1A4A4036)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildTechRow({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlueGlow, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: secondaryColor,
            fontSize: 13,
            fontFamily: 'Vazirmatn',
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Vazirmatn',
          ),
        ),
      ],
    );
  }
}
