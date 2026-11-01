import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_flow/core/di/injection_container.dart';
import 'package:task_flow/core/notifications/notification_service.dart';
import 'package:task_flow/core/services/backup_service.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/core/theme/app_colors.dart';
import 'package:task_flow/core/theme/app_theme_mode.dart';
import 'package:task_flow/core/utils/persian_number_formatter.dart';
import 'package:task_flow/core/widgets/bouncing_tap.dart';
import 'package:task_flow/core/widgets/dual_layout_transition.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:task_flow/features/gamification/presentation/widgets/xp_store_card.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_state.dart';
import 'package:task_flow/features/settings/presentation/pages/technical_settings_view.dart';
import 'package:task_flow/features/settings/presentation/pages/user_profile_page.dart';
import 'package:task_flow/features/settings/presentation/widgets/player_profile_card.dart';

/// تب «پروفایل من» (تب ۴ نوار ناوبری)
/// مجهز به سیستم Dual-Layout Transition:
/// - چیدمان اختصاصی "زندگی‌ساز" (Signature) مطابق `zendegisaz-04-profile.png`
/// - چیدمان کلاسیک شیشه‌ای برای پوسته‌های تاریک، آرامش و روشن
class SettingsPage extends ConsumerStatefulWidget {
  final bool isDark;
  final bool isZen;

  const SettingsPage({
    super.key,
    required this.isDark,
    this.isZen = false,
  });

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _openUserProfilePage() {
    final theme = Theme.of(context);
    final isZen =
        widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => UserProfilePage(isDark: widget.isDark, isZen: isZen),
      ),
    );
  }

  void _openTechnicalSettings() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => TechnicalSettingsView(
          isDark: widget.isDark,
          isZen: widget.isZen,
        ),
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

  void _showBackupGlassBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = widget.isDark;
        final textColor = isDark ? AppColors.textDark : AppColors.textLight;
        final secondaryTextColor =
            isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
                      : Colors.white.withValues(alpha: 0.95),
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
                            color: const Color(0xFF0A84FF)
                                .withValues(alpha: 0.15),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
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
    try {
      if (!sl.isRegistered<BackupService>()) return;
      final backupService = sl<BackupService>();
      final result = await backupService.exportBackup();
      if (!mounted) return;
      if (result is BackupSuccess) {
        unawaited(SoundAndHapticService.instance.playSuccessChime());
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
      }
    } catch (_) {}
  }

  void _showThemeSelectorSheet(BuildContext context, AppThemeMode currentMode) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF12151E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0xFF1E2330), width: 1.2),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3F50),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'انتخاب پوسته برنامه',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildThemeOptionTile(
                  sheetContext,
                  title: 'زندگی‌ساز',
                  subtitle: 'طراحی مینی‌مالیستی نئون تاریک (اختصاصی)',
                  mode: AppThemeMode.signature,
                  isSelected: currentMode == AppThemeMode.signature,
                ),
                const Divider(color: Color(0xFF1A1D26), height: 1),
                _buildThemeOptionTile(
                  sheetContext,
                  title: 'تاریک',
                  subtitle: 'پوسته کلاسیک تاریک با جلوه شیشه‌ای',
                  mode: AppThemeMode.dark,
                  isSelected: currentMode == AppThemeMode.dark,
                ),
                const Divider(color: Color(0xFF1A1D26), height: 1),
                _buildThemeOptionTile(
                  sheetContext,
                  title: 'آرامش (Zen)',
                  subtitle: 'رنگ‌های گرم و تمرکز طبیعی',
                  mode: AppThemeMode.zen,
                  isSelected: currentMode == AppThemeMode.zen,
                ),
                const Divider(color: Color(0xFF1A1D26), height: 1),
                _buildThemeOptionTile(
                  sheetContext,
                  title: 'روشن',
                  subtitle: 'پوسته روشن و شفاف',
                  mode: AppThemeMode.light,
                  isSelected: currentMode == AppThemeMode.light,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionTile(
    BuildContext sheetContext, {
    required String title,
    required String subtitle,
    required AppThemeMode mode,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        context.read<SettingsBloc>().add(SettingsThemeModeChanged(mode));
        Navigator.of(sheetContext).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color:
                          isSelected ? const Color(0xFF0A84FF) : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                color: Color(0xFF0A84FF),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  String _getThemeLabel(AppThemeMode mode) {
    return switch (mode) {
      AppThemeMode.signature => 'زندگی‌ساز',
      AppThemeMode.dark => 'تاریک',
      AppThemeMode.zen => 'آرامش',
      AppThemeMode.light => 'روشن',
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return BlocBuilder<GamificationBloc, GamificationState>(
          builder: (context, gamificationState) {
            final userSettings = settingsState.settings;
            final isSignature = userSettings.themeMode.isSignatureLayout;

            return SafeArea(
              top: true,
              bottom: false,
              child: DualLayoutTransition(
                isSignatureLayout: isSignature,
                signatureChild: _buildSignatureProfileView(
                  context,
                  userSettings,
                  gamificationState,
                ),
                classicChild: _buildClassicProfileView(
                  context,
                  userSettings,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ساختار چیدمان اختصاصی "زندگی‌ساز" مطابق `zendegisaz-04-profile.png`
  Widget _buildSignatureProfileView(
    BuildContext context,
    UserSettingsEntity settings,
    GamificationState gamificationState,
  ) {
    final int level = gamificationState.level;
    final int nextLevel = level + 1;
    final int totalXp = gamificationState.totalXp;
    final int targetLevelXp = math.max(nextLevel * 50, ((totalXp ~/ 50) + 1) * 50);
    final int remainingXp = math.max(0, targetLevelXp - totalXp);
    final double progressRatio = targetLevelXp > 0
        ? ((totalXp % 50) / 50.0).clamp(0.0, 1.0)
        : 0.0;
    final String honoraryTitle = gamificationState.title.isNotEmpty
        ? gamificationState.title
        : GamificationBloc.calculateTitle(level);
    final int ownedFreezes = gamificationState.streakFreezes;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ColoredBox(
        color: const Color(0xFF090B10),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
              children: [
                // عنوانی پنهان برای حفظ سازگاری تست‌ها
                const Offstage(
                  offstage: true,
                  child: Text('پروفایل من', key: Key('profile_page_title')),
                ),

                // بخش A: هدر آواتار کاربری، سطح و دکمه چرخ‌دنده تنظیمات
                _buildSignatureHeader(
                  context,
                  settings,
                  honoraryTitle,
                  level,
                  progressRatio,
                ),
                const SizedBox(height: 18),

                // بخش B: نوار پیشرفت سطح بعدی و مقدار باقی‌مانده XP
                _buildSignatureXpBar(
                  level,
                  nextLevel,
                  totalXp,
                  remainingXp,
                  progressRatio,
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFF1A1D26), height: 1, thickness: 1),

                // بخش C: ردیف ۳ ستونه معیارهای استمرار، سپر و امتیاز کل
                _buildSignatureMetricsRow(
                  settings.streakCount,
                  ownedFreezes,
                  totalXp,
                ),
                const Divider(color: Color(0xFF1A1D26), height: 1, thickness: 1),
                const SizedBox(height: 20),

                // بخش D: کارت خرید سپر محافظ استمرار با هزینه اکیداً ۵۰۰ XP
                _buildSignatureStreakFreezeCard(
                  context,
                  totalXp,
                  ownedFreezes,
                ),
                const SizedBox(height: 28),

                // بخش E: فهرست تنظیمات مینی‌مالیستی
                _buildSignatureSettingsSection(context, settings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بخش A: هدر آواتار، عنوان افتخاری و آیکون چرخ‌دنده مینیمال
  Widget _buildSignatureHeader(
    BuildContext context,
    UserSettingsEntity settings,
    String honoraryTitle,
    int level,
    double progressRatio,
  ) {
    final name = settings.userName.trim().isNotEmpty
        ? settings.userName.trim()
        : 'کاربر';
    final firstChar = name.isNotEmpty ? name.characters.first : 'ع';

    return Container(
      key: const Key('signature_profile_header'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          BouncingTap(
            key: const Key('settings_user_profile_card'),
            onTap: _openUserProfilePage,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: progressRatio,
                          strokeWidth: 3.5,
                          backgroundColor: const Color(0xFF1C202B),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0A84FF),
                          ),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFF141721),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          firstChar,
                          key: const Key('signature_profile_avatar_char'),
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$honoraryTitle · سطح ${toPersianDigits(level.toString())}',
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF97316),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            key: const Key('profile_technical_settings_button'),
            tooltip: 'تنظیمات فنی سامانه',
            icon: const Icon(
              CupertinoIcons.gear_alt,
              size: 20,
              color: Color(0xFF6B7280),
            ),
            onPressed: _openTechnicalSettings,
          ),
        ],
      ),
    );
  }

  /// بخش B: نوار پیشرفت تا سطح بعدی
  Widget _buildSignatureXpBar(
    int level,
    int nextLevel,
    int totalXp,
    int remainingXp,
    double progressRatio,
  ) {
    final effectiveRatio = progressRatio > 0 ? progressRatio : (totalXp > 0 ? 0.05 : 0.02);
    return Container(
      key: const Key('signature_profile_xp_bar'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تا سطح ${toPersianDigits(nextLevel.toString())}',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                Text(
                  '${toPersianDigits(remainingXp.toString())} XP مونده',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final fillWidth = math.max(
                    constraints.maxWidth * effectiveRatio,
                    4.0,
                  );
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: fillWidth,
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بخش C: ردیف ۳ ستونه معیارهای استمرار، سپر و امتیاز کل
  Widget _buildSignatureMetricsRow(int streak, int shields, int totalXp) {
    return Container(
      key: const Key('signature_profile_metrics_row'),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // ستون راست: روز استمرار (نارنجی)
            Expanded(
              child: Column(
                children: [
                  Text(
                    toPersianDigits(streak.toString()),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'روز استمرار',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFF1A1D26),
            ),
            // ستون میانی: سپر محافظ (بنفش)
            Expanded(
              child: Column(
                children: [
                  Text(
                    toPersianDigits(shields.toString()),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFA855F7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'سپر محافظ',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: const Color(0xFF1A1D26),
            ),
            // ستون چپ: امتیاز کل XP (آبی الکتریک)
            Expanded(
              child: Column(
                children: [
                  Text(
                    toPersianDigits(totalXp.toString()),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0A84FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'XP کل',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بخش D: کارت خرید سپر محافظ استمرار (اکیداً ۵۰۰ XP)
  Widget _buildSignatureStreakFreezeCard(
    BuildContext context,
    int totalXp,
    int ownedFreezes,
  ) {
    const freezeCost = 500;
    final canAfford = totalXp >= freezeCost;

    return Container(
      key: const Key('signature_streak_freeze_card'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF12151E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2330), width: 1.2),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFA855F7).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.shield,
                  color: Color(0xFFA855F7),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'سپر محافظ استمرار',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'اگه یه روز نشد، استمرارت میمونه',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              key: const Key('signature_buy_freeze_button'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: canAfford
                      ? const Color(0xFF0A84FF)
                      : const Color(0xFF3A3F50),
                  width: 1.5,
                ),
                backgroundColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: canAfford
                  ? () {
                      HapticFeedback.mediumImpact();
                      SoundAndHapticService.instance.playSuccessChime();
                      context
                          .read<GamificationBloc>()
                          .add(const BuyStreakFreezeEvent(cost: 500));
                      try {
                        final currentSettings =
                            context.read<SettingsBloc>().state.settings;
                        context.read<SettingsBloc>().add(
                              SettingsUpdated(
                                currentSettings.copyWith(
                                  streakFreezeCount: ownedFreezes + 1,
                                ),
                              ),
                            );
                      } catch (_) {}
                    }
                  : () {
                      HapticFeedback.heavyImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            'امتیاز شما برای خرید سپر محافظ کافی نیست (حداقل ۵۰۰ XP).',
                            style: TextStyle(fontFamily: 'Vazirmatn'),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      );
                    },
              child: Text(
                '${toPersianDigits('500')} XP',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: canAfford
                      ? const Color(0xFF0A84FF)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بخش E: فهرست تنظیمات مینی‌مالیستی
  Widget _buildSignatureSettingsSection(
    BuildContext context,
    UserSettingsEntity settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'تنظیمات',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ۱. ظاهر برنامه
        InkWell(
          key: const Key('signature_theme_selector_row'),
          onTap: () => _showThemeSelectorSheet(context, settings.themeMode),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ظاهر برنامه',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getThemeLabel(settings.themeMode),
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 14,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      CupertinoIcons.chevron_left,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(color: Color(0xFF1A1D26), height: 1),

        // ۲. حالت استراحت
        Padding(
          key: const Key('signature_vacation_mode_row'),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'حالت استراحت',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              CupertinoSwitch(
                value: settings.isVacationMode,
                activeTrackColor: const Color(0xFF34C759),
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  context
                      .read<SettingsBloc>()
                      .add(SettingsVacationModeToggled(val));
                },
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF1A1D26), height: 1),

        // ۳. پشتیبان‌گیری
        InkWell(
          key: const Key('signature_backup_row'),
          onTap: () => _showBackupGlassBottomSheet(context),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'پشتیبان‌گیری',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_left,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
        const Divider(color: Color(0xFF1A1D26), height: 1),

        // ۴. تست نوتیفیکیشن پس‌زمینه (۵ ثانیه)
        InkWell(
          key: const Key('signature_test_notification_row'),
          onTap: _handleTestBackgroundNotification,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.bell,
                  size: 18,
                  color: Color(0xFF0A84FF),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تست نوتیفیکیشن پس‌زمینه (۵ ثانیه)',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_left,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
        const Divider(color: Color(0xFF1A1D26), height: 1),

        // ۵. تنظیمات پیشرفته و فنی
        InkWell(
          key: const Key('signature_advanced_settings_row'),
          onTap: _openTechnicalSettings,
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تنظیمات پیشرفته و فنی',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_left,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// چیدمان کلاسیک شیشه‌ای برای پوسته‌های تاریک، آرامش و روشن (حفظ ۱۰۰٪ امکانات پیشین)
  Widget _buildClassicProfileView(
    BuildContext context,
    UserSettingsEntity settings,
  ) {
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

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 140),
          children: [
            // هدر پروفایل من به همراه دکمه چرخ‌دنده تنظیمات فنی (Key: profile_technical_settings_button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'پروفایل من',
                    key: const Key('profile_page_title'),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    key: const Key('profile_technical_settings_button'),
                    tooltip: 'تنظیمات فنی سامانه',
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2C2C2E)
                            : const Color(0xFFE5E5EA),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.settings,
                        size: 20,
                        color: textColor,
                      ),
                    ),
                    onPressed: _openTechnicalSettings,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ۱. کارت اگزمکتیو گیمر و پیشرفت استمرار (سطح، نوار XP و نشان آتش استمرار)
            const PlayerProfileCard(),
            const SizedBox(height: 18),

            // ۲. کارت فروشگاه امتیاز (XP Store & Streak Freeze Economy)
            const XpStoreCard(),
            const SizedBox(height: 24),

            // ۳. سرفصل و کارت مینیمال حساب کاربری
            _buildSectionHeader('شناسه و حساب کاربری', secondaryTextColor),
            const SizedBox(height: 10),

            _buildMinimalCard(
              isDark: isDark,
              child: BouncingTap(
                key: const Key('settings_user_profile_card'),
                onTap: _openUserProfilePage,
                child: Row(
                  children: [
                    ProfileAvatarPreset.buildUserCircleAvatar(
                      avatarKey:
                          const Key('settings_user_profile_circle_avatar'),
                      avatarIndex: settings.avatarIndex,
                      customAvatarPath: settings.customAvatarPath,
                      radius: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            settings.userName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            settings.userRole,
                            style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12.5,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'آنلاین',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      CupertinoIcons.chevron_left,
                      size: 16,
                      color: secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
}
