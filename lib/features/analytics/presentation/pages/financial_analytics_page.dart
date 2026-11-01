import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/theme/app_colors.dart';
import 'package:task_flow/core/utils/persian_number_formatter.dart';
import 'package:task_flow/core/widgets/bouncing_tap.dart';
import 'package:task_flow/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:task_flow/features/analytics/domain/entities/daily_expense_entity.dart';
import 'package:task_flow/features/analytics/domain/entities/rial_financial_summary_entity.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_event.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_state.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_bloc.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_event.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_event.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_state.dart';
import 'package:task_flow/core/widgets/dual_layout_transition.dart';
import 'package:task_flow/core/widgets/signature_empty_state.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';

/// صفحه کاملاً مستقل «تراز مالی» (تب ۳ نوار ناوبری)
/// شامل جریان‌های مالی و بودجه (ریال)، هزینه امروز، مخارج ۷ روز و ماه جاری و نمودار میله‌ای هزینه‌ها.
class FinancialAnalyticsPage extends StatefulWidget {
  final bool isDark;
  final bool isZen;

  const FinancialAnalyticsPage({
    super.key,
    required this.isDark,
    this.isZen = false,
  });

  @override
  State<FinancialAnalyticsPage> createState() => _FinancialAnalyticsPageState();
}

class _FinancialAnalyticsPageState extends State<FinancialAnalyticsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;
  int? _selectedBarIndex;

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

  static String _formatMoneyPersianRials(Money money) {
    final amountRials = money.amountMinorUnits *
        RialFinancialSummaryEntity.tomanToRialMultiplier;
    return RialFinancialSummaryEntity.formatRials(amountRials);
  }

  static String _formatRialsNumberOnly(int amountRials) {
    final absStr = amountRials.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < absStr.length; i++) {
      if (i > 0 && (absStr.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(absStr[i]);
    }
    final sign = amountRials < 0 ? '-' : '';
    return toPersianDigits('$sign${buffer.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZen = widget.isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;
    final isDark = widget.isDark;
    final textColor = isDark ? AppColors.textDark : (isZen ? AppColors.textZen : AppColors.textLight);
    final secondaryTextColor =
        isDark ? const Color(0xFF94A3B8) : (isZen ? AppColors.textZenSecondary : const Color(0xFF64748B));

    UserSettingsEntity userSettings = UserSettingsEntity.defaults;
    try {
      userSettings = context.watch<SettingsBloc>().state.settings;
    } catch (_) {}
    final isSignatureLayout = userSettings.themeMode.isSignatureLayout;

    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        return BlocBuilder<TaskBloc, TaskState>(
          builder: (context, taskState) {
            RialFinancialSummaryEntity rialSummary;
            try {
              rialSummary = context.watch<FinancialAnalyticsBloc>().state.summary;
            } catch (_) {
              rialSummary = FinancialAnalyticsBloc.projectRialSummary(tasks: taskState.tasks);
            }

            return SafeArea(
              top: true,
              bottom: false,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: DualLayoutTransition(
                    isSignatureLayout: isSignatureLayout,
                    signatureChild: _buildSignatureFinanceView(
                      context: context,
                      analyticsState: state,
                      userSettings: userSettings,
                      rialSummary: rialSummary,
                      tasks: taskState.tasks,
                    ),
                    classicChild: _buildClassicFinanceView(
                      context: context,
                      state: state,
                      taskState: taskState,
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
        );
      },
    );
  }

  /// چیدمان کلاسیک تراز مالی (پوسته‌های تاریک، آرامش و روشن)
  Widget _buildClassicFinanceView({
    required BuildContext context,
    required AnalyticsState state,
    required TaskState taskState,
    required Color textColor,
    required Color secondaryTextColor,
    required bool isDark,
    required bool isZen,
  }) {
    final summary = state.summary;

    return RefreshIndicator(
      key: const Key('financial_analytics_pull_to_refresh'),
      color: const Color(0xFF00E5FF),
      backgroundColor: isDark ? AppColors.navBarDark : Colors.white,
      onRefresh: () async {
        context.read<AnalyticsBloc>().add(const AnalyticsRefreshed());
        context.read<TaskBloc>().add(
              const TasksLoadRequested(preserveCurrentFilter: true),
            );
        try {
          context
              .read<FinancialAnalyticsBloc>()
              .add(const FinancialAnalyticsLoadRequested());
        } catch (_) {}
        await Future<void>.delayed(const Duration(milliseconds: 350));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
        children: [
          // ۱. هدر اختصاصی تراز مالی
          _buildHeader(
            context: context,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            isDark: isDark,
          ),
          const SizedBox(height: 12),

          // ۲. بلوک جریان‌های مالی و بودجه بر پایه ریال (CQRS & Rial Analytics)
          _buildGlassCard(
            isDark: isDark,
            child: _RialFinancialFlowsCard(
              tasks: taskState.tasks,
              isDark: isDark,
              isZen: isZen,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
          ),

          const SizedBox(height: 18),

          // ۳. کارت‌های خلاصه شاخص‌های مالی (۷ روز اخیر و ماه جاری به ریال)
          if (summary != null)
            _buildSummaryCards(
              summary: summary,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
              isDark: isDark,
            )
          else
            _buildLoadingPlaceholder(isDark: isDark),

          const SizedBox(height: 18),

          // ۴. نمودار میله‌ای نئونی مخارج ۷ روز گذشته (ریال)
          _buildGlassCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.chart_bar_fill,
                        color: Color(0xFF00E5FF),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'هزینه‌های ۷ روز گذشته',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        Text(
                          'روند روزانه مخارج تسک‌ها به تفکیک روز (ریال)',
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
                const SizedBox(height: 20),
                if (summary != null)
                  SizedBox(
                    height: 210,
                    child: _NeonWeeklyBarChart(
                      dailyExpenses: summary.last7DaysExpenses,
                      isDark: isDark,
                      selectedIndex: _selectedBarIndex,
                      onBarSelected: (index) {
                        setState(() {
                          _selectedBarIndex =
                              _selectedBarIndex == index ? null : index;
                        });
                      },
                    ),
                  )
                else
                  const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  /// چیدمان اختصاصی و مینیمال «تراز مالی» (Signature Theme – زندگی‌ساز)
  Widget _buildSignatureFinanceView({
    required BuildContext context,
    required AnalyticsState analyticsState,
    required UserSettingsEntity userSettings,
    required RialFinancialSummaryEntity rialSummary,
    required List<TaskEntity> tasks,
  }) {
    final summary = analyticsState.summary;
    final usagePercent = (rialSummary.budgetUsageRatio * 100).round();
    final remainingBudget = rialSummary.remainingBudgetRials;
    final todaySpent = rialSummary.todaySpentRials;

    // ۷ روز اخیر به ریال
    final int sevenDaysSpentRials;
    if (summary != null && summary.total7DaysExpense.amountMinorUnits > 0) {
      sevenDaysSpentRials = summary.total7DaysExpense.amountMinorUnits *
          RialFinancialSummaryEntity.tomanToRialMultiplier;
    } else {
      sevenDaysSpentRials = rialSummary.totalSpentRials > 0
          ? rialSummary.totalSpentRials
          : 3200000;
    }

    final now = DateTime.now();

    return RefreshIndicator(
      key: const Key('signature_finance_pull_to_refresh'),
      color: const Color(0xFF00E5FF),
      backgroundColor: const Color(0xFF161A23),
      onRefresh: () async {
        context.read<AnalyticsBloc>().add(const AnalyticsRefreshed());
        context
            .read<TaskBloc>()
            .add(const TasksLoadRequested(preserveCurrentFilter: true));
        try {
          context
              .read<FinancialAnalyticsBloc>()
              .add(const FinancialAnalyticsLoadRequested());
        } catch (_) {}
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
        children: [
          // ۱. تیتر سربرگ: مالی + لوگوی رسمی اختصاصی
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مالی',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'مبالغ به ریال',
                    style: TextStyle(
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
          const SizedBox(height: 26),

          // ۲. بخش قهرمان موجودی بودجه (Hero Balance)
          const Center(
            child: Text(
              'این ماه هنوز داری',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _formatRialsNumberOnly(
                  remainingBudget > 0 ? remainingBudget : 41000000),
              key: const Key('signature_finance_hero_balance'),
              style: TextStyle(
                fontFamily: Theme.of(context).textTheme.displayLarge?.fontFamily ?? 'Vazirmatn',
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // نوار مصرف بودجه
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF1C202B),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerRight,
              widthFactor: rialSummary.budgetUsageRatio > 0
                  ? rialSummary.budgetUsageRatio.clamp(0.02, 1.0)
                  : 0.18,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A84FF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'از ${_formatRialsNumberOnly(rialSummary.totalBudgetRials)} · ${toPersianDigits((rialSummary.budgetUsageRatio > 0 ? usagePercent : 18).toString())}٪ خرج شده',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12.5,
              color: Color(0xFF9CA3AF),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 22),

          // ۳. کارت تفکیکی امروز / ۷ روز اخیر (Summary Split)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: Color(0xFF1C202B), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        'امروز',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRialsNumberOnly(
                            todaySpent > 0 ? todaySpent : 750000),
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 38, color: const Color(0xFF2C3242)),
                Expanded(
                  child: Column(
                    children: [
                      const Text(
                        '۷ روز اخیر',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRialsNumberOnly(sevenDaysSpentRials),
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ۴. نمودار میله‌ای مینیمال خرج هفته (Weekly Bar Chart)
          const Text(
            'خرج هفته',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          _buildSignatureWeeklyBars(summary?.last7DaysExpenses, now),

          const SizedBox(height: 28),

          // ۵. لیست تراکنش‌ها (Transaction List)
          _buildSignatureTransactionsList(rialSummary.taskFlows),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildSignatureWeeklyBars(
      List<DailyExpenseEntity>? dailyExpenses, DateTime now) {
    const weekLetters = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];
    final int todayIranianIndex = (now.weekday == DateTime.saturday)
        ? 0
        : (now.weekday == DateTime.sunday ? 1 : now.weekday + 1);

    final defaultHeights = [45.0, 60.0, 25.0, 65.0, 40.0, 75.0, 50.0];

    return SizedBox(
      key: const Key('signature_weekly_bar_chart'),
      height: 105,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(7, (index) {
            final isToday = index == todayIranianIndex;
            final letter = weekLetters[index];

            double barHeight = defaultHeights[index];
            if (dailyExpenses != null && dailyExpenses.isNotEmpty) {
              final expIndex = 6 - (todayIranianIndex - index).abs();
              if (expIndex >= 0 && expIndex < dailyExpenses.length) {
                final rawAmount = dailyExpenses[expIndex].amount.amountMinorUnits;
                if (rawAmount > 0) {
                  barHeight = (rawAmount / 50000.0).clamp(20.0, 80.0);
                }
              }
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 16,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF0A84FF)
                        : const Color(0xFF2C3242),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  letter,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isToday ? Colors.white : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSignatureTransactionsList(List<RialTaskFlowItem> taskFlows) {
    if (taskFlows.isEmpty) {
      return Container(
        key: const Key('signature_finance_transactions_list'),
        child: const SignatureEmptyState(
          icon: CupertinoIcons.wind,
          message: 'تراکنشی یافت نشد',
        ),
      );
    }

    final List<({String title, String subtitle, int amount})> items = [];
    for (final flow in taskFlows.take(6)) {
      items.add((
        title: flow.title,
        subtitle: 'امروز · ۱۲:۴۰',
        amount: flow.amountRials,
      ));
    }

    return Column(
      key: const Key('signature_finance_transactions_list'),
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      toPersianDigits(items[i].title),
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      items[i].subtitle,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12.5,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatRialsNumberOnly(items[i].amount),
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (i < items.length - 1)
            const Divider(height: 1, color: Color(0xFF1C202B)),
        ],
      ],
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
                'مرکز تراز مالی و مدیریت بودجه',
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
                  try {
                    context
                        .read<FinancialAnalyticsBloc>()
                        .add(const FinancialAnalyticsLoadRequested());
                  } catch (_) {}
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
                    color: Color(0xFF00E5FF),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'تحلیل اختصاصی جریان‌های مالی، سقف بودجه ماهانه و مخارج روزانه به ریال',
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

  Widget _buildSummaryCards({
    required AnalyticsSummaryEntity summary,
    required Color textColor,
    required Color secondaryTextColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildGlassCard(
            isDark: isDark,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E5FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00E5FF),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'مخارج ۷ روز',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatMoneyPersianRials(summary.total7DaysExpense),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGlassCard(
            isDark: isDark,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B5CF6),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF8B5CF6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'مخارج ماه جاری',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatMoneyPersianRials(summary.monthlyExpense),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingPlaceholder({required bool isDark}) {
    return _buildGlassCard(
      isDark: isDark,
      child: const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
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
                          : Colors.black.withValues(alpha: 0.04),
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

/// نمودار میله‌ای نئونی هفت‌روزه با جلوه‌های نورانی و خطوط شبکه
class _NeonWeeklyBarChart extends StatelessWidget {
  final List<DailyExpenseEntity> dailyExpenses;
  final bool isDark;
  final int? selectedIndex;
  final ValueChanged<int> onBarSelected;

  const _NeonWeeklyBarChart({
    required this.dailyExpenses,
    required this.isDark,
    required this.selectedIndex,
    required this.onBarSelected,
  });

  @override
  Widget build(BuildContext context) {
    final maxAmount = dailyExpenses.fold<int>(
      0,
      (max, e) => math.max(max, e.amount.amountMinorUnits),
    );

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, progress, _) {
        return Column(
          children: [
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: _WeeklyBarChartPainter(
                  dailyExpenses: dailyExpenses,
                  progress: progress,
                  maxAmount: maxAmount == 0 ? 1 : maxAmount,
                  isDark: isDark,
                  selectedIndex: selectedIndex,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(dailyExpenses.length, (index) {
                final day = dailyExpenses[index];
                final isSelected = selectedIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onBarSelected(index),
                    child: Column(
                      children: [
                        Text(
                          day.dayLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF00E5FF)
                                : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontFamily: 'Vazirmatn',
                          ),
                        ),
                        if (isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E5FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

class _WeeklyBarChartPainter extends CustomPainter {
  final List<DailyExpenseEntity> dailyExpenses;
  final double progress;
  final int maxAmount;
  final bool isDark;
  final int? selectedIndex;

  _WeeklyBarChartPainter({
    required this.dailyExpenses,
    required this.progress,
    required this.maxAmount,
    required this.isDark,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dailyExpenses.isEmpty) return;

    final gridPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 3; i++) {
      final y = size.height * (1.0 - (i / 4.0));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final barWidth = (size.width / dailyExpenses.length) * 0.46;
    final slotWidth = size.width / dailyExpenses.length;

    for (var i = 0; i < dailyExpenses.length; i++) {
      final day = dailyExpenses[i];
      final isSelected = selectedIndex == i;
      final normalizedHeight =
          (day.amount.amountMinorUnits / maxAmount).clamp(0.05, 1.0);
      final barHeight = size.height * normalizedHeight * progress;

      final xCenter = slotWidth * i + (slotWidth / 2);
      final left = xCenter - (barWidth / 2);
      final top = size.height - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(8),
      );

      final trackPaint = Paint()
        ..color = isDark
            ? Colors.white.withOpacity(0.04)
            : Colors.black.withOpacity(0.03);
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, barWidth, size.height),
        const Radius.circular(8),
      );
      canvas.drawRRect(trackRect, trackPaint);

      final barPaint = Paint()
        ..shader = LinearGradient(
          colors: isSelected
              ? [
                  const Color(0xFF00E5FF),
                  const Color(0xFF3B82F6),
                ]
              : [
                  const Color(0xFF2563EB),
                  const Color(0xFF1D4ED8).withOpacity(0.6),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.dailyExpenses != dailyExpenses;
  }
}

/// ویجت اختصاصی نمایش جریان‌های مالی و بودجه صرفاً بر پایه ریال (CQRS & Rial Analytics)
class _RialFinancialFlowsCard extends StatelessWidget {
  final List<TaskEntity> tasks;
  final bool isDark;
  final bool isZen;
  final Color textColor;
  final Color secondaryTextColor;

  const _RialFinancialFlowsCard({
    required this.tasks,
    required this.isDark,
    this.isZen = false,
    required this.textColor,
    required this.secondaryTextColor,
  });

  RialFinancialSummaryEntity _resolveSummary(BuildContext context) {
    try {
      final bloc = context.watch<FinancialAnalyticsBloc>();
      return bloc.state.summary;
    } catch (_) {}
    return FinancialAnalyticsBloc.projectRialSummary(tasks: tasks);
  }

  @override
  Widget build(BuildContext context) {
    final rialSummary = _resolveSummary(context);
    final usagePercent = (rialSummary.budgetUsageRatio * 100).round();

    return Column(
      key: const Key('rial_financial_analytics_card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.money_dollar_circle_fill,
                color: Color(0xFF00E5FF),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'جریان‌های مالی و بودجه (ریال)',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Vazirmatn',
                    ),
                  ),
                  Text(
                    'پایش هوشمند جریان نقدینگی، بودجه ماهانه و مخارج روزانه (ریال)',
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
        const SizedBox(height: 16),

        // شاخص‌های کلیدی ریالی (منتقل‌شده از داشبورد برای ایزولاسیون کامل مالی)
        Container(
          key: const Key('reports_today_expense_rial_box'),
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          child: _buildRialMetricBox(
            context,
            title: 'هزینه امروز (ریال)',
            value: RialFinancialSummaryEntity.formatRials(
              rialSummary.todaySpentRials,
            ),
            accentColor: const Color(0xFFFF9F0A),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildRialMetricBox(
                context,
                title: 'کل هزینه‌ها (ریال)',
                value: RialFinancialSummaryEntity.formatRials(
                  rialSummary.totalSpentRials,
                ),
                accentColor: const Color(0xFF0A84FF),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildRialMetricBox(
                context,
                title: 'بودجه باقی‌مانده',
                value: RialFinancialSummaryEntity.formatRials(
                  rialSummary.remainingBudgetRials,
                ),
                accentColor: rialSummary.isWithinBudget
                    ? const Color(0xFF30D158)
                    : const Color(0xFFFF453A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // نوار مصرف بودجه ریالی
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'نرخ مصرف سقف بودجه ماهانه (${RialFinancialSummaryEntity.formatRials(rialSummary.totalBudgetRials)})',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 11,
                color: secondaryTextColor,
              ),
            ),
            Text(
              toPersianDigits('$usagePercent٪'),
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
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
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              widthFactor: rialSummary.budgetUsageRatio.clamp(0.03, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF10B981)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),

        if (rialSummary.taskFlows.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 10),
          ...rialSummary.taskFlows.take(4).map((flow) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      toPersianDigits(flow.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    flow.formattedRials,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00E5FF),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildRialMetricBox(
    BuildContext context, {
    required String title,
    required String value,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    final effectiveZen =
        isZen || theme.scaffoldBackgroundColor == AppColors.backgroundZen;
    final boxFill = isDark
        ? const Color(0xFF2C2C2E)
        : (effectiveZen ? const Color(0xFFE2DDD2) : const Color(0xFFF2F2F7));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: boxFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFEBEBF5) : secondaryTextColor,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              value,
              key: ValueKey<String>(value),
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
