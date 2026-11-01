import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/core/utils/persian_number_formatter.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_state.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';

/// Apple HIG glassmorphism XP Store card where players can spend XP to buy Streak Freezes.
class XpStoreCard extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const XpStoreCard({
    super.key,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? const Color(0xCC1C1C1E)
        : Colors.white.withValues(alpha: 0.85);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return BlocBuilder<GamificationBloc, GamificationState>(
      builder: (context, gamificationState) {
        final currentXp = gamificationState.totalXp;
        final ownedFreezes = gamificationState.streakFreezes;
        const freezeCost = 500;
        final canAfford = currentXp >= freezeCost;

        return Padding(
          padding: padding,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                key: const Key('xp_store_card'),
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: borderColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? const Color(0xFF0A84FF).withValues(alpha: 0.08)
                          : const Color(0xFF0A84FF).withValues(alpha: 0.05),
                      blurRadius: 18.0,
                      spreadRadius: 1.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header: Store Title + User Balance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A84FF)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.sparkles,
                                size: 18,
                                color: Color(0xFF0A84FF),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'فروشگاه امتیاز',
                              key: const Key('xp_store_title'),
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2C2E)
                                : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'موجودی: ${toPersianDigits(currentXp.toString())} XP',
                            key: const Key('xp_store_user_xp'),
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0A84FF),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Streak Freeze Store Item Card
                    Container(
                      key: const Key('xp_store_streak_freeze_item'),
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF242426)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Ice Frost Icon Container
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '❄️',
                                style: TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Title, Description & Owned Inventory
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'محافظ استریک ❄️',
                                      key: const Key(
                                          'xp_store_item_name_freeze'),
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'حفظ زنجیره در صورت عدم ثبت تسک',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 11.5,
                                    color: secondaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'موجودی شما: ${toPersianDigits(ownedFreezes.toString())} عدد',
                                    key: const Key(
                                        'xp_store_streak_freeze_inventory'),
                                    style: const TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0284C7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Cost & Buy Action Button
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${toPersianDigits(freezeCost.toString())} XP',
                                key: const Key('xp_store_freeze_cost'),
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: canAfford
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                key: const Key(
                                    'xp_store_buy_streak_freeze_button'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: canAfford
                                      ? const Color(0xFF0A84FF)
                                      : (isDark
                                          ? const Color(0xFF3A3A3C)
                                          : const Color(0xFFE2E8F0)),
                                  foregroundColor: canAfford
                                      ? Colors.white
                                      : (isDark
                                          ? const Color(0xFF636366)
                                          : const Color(0xFF94A3B8)),
                                  elevation: canAfford ? 2 : 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: canAfford
                                    ? () {
                                        HapticFeedback.mediumImpact();
                                        context
                                            .read<GamificationBloc>()
                                            .add(const BuyStreakFreezeEvent());
                                        try {
                                          final currentSettings = context
                                              .read<SettingsBloc>()
                                              .state
                                              .settings;
                                          context.read<SettingsBloc>().add(
                                                SettingsUpdated(
                                                  currentSettings.copyWith(
                                                    streakFreezeCount:
                                                        ownedFreezes + 1,
                                                  ),
                                                ),
                                              );
                                        } catch (_) {}
                                        unawaited(SoundAndHapticService.instance
                                            .playSuccessChime());
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'محافظ استریک با موفقیت خریداری و به دارایی‌های شما افزوده شد! ❄️',
                                              style: TextStyle(
                                                fontFamily: 'Vazirmatn',
                                              ),
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            backgroundColor:
                                                const Color(0xFF10B981),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                child: const Text(
                                  'خرید',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
}
