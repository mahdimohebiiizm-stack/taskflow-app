import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/theme/app_colors.dart';
import 'package:task_flow/core/widgets/bouncing_tap.dart';
import 'package:task_flow/features/navigation/main_screen.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';

/// مدل داده برای اسلایدهای آنبوردینگ
class _OnboardingSlideData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeText;
  final Color accentColor;
  final bool isGesturesSlide;

  const _OnboardingSlideData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.accentColor,
    this.isGesturesSlide = false,
  });
}

/// صفحه آنبوردینگ تعاملی مجهز به اسلاید اختصاصی آموزش ژست‌های حرکتی و ابزارها
class OnboardingPage extends StatefulWidget {
  final VoidCallback? onFinish;
  final WidgetBuilder? nextScreenBuilder;

  const OnboardingPage({
    super.key,
    this.onFinish,
    this.nextScreenBuilder,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingSlideData> _slides = [
    _OnboardingSlideData(
      icon: CupertinoIcons.square_list_fill,
      badgeText: 'مدیریت کارها • بوم سفید',
      title: 'بوم سفید شما',
      subtitle:
          'کارهایتان را با زمان‌بندی روزانه، اولویت‌بندی دقیق و تقویم بومی جلالی سازماندهی کنید تا هیچ هدفی از قلم نیفتد.',
      accentColor: Color(0xFF0A84FF),
    ),
    _OnboardingSlideData(
      icon: CupertinoIcons.timer,
      badgeText: 'تمرکز عمیق • تم آرامش',
      title: 'تمرکز عمیق',
      subtitle:
          'با تایمر پومودورو و تم اختصاصی آرامش (Zen Mode)، از خستگی چشم جلوگیری کرده و بیشترین بهره‌وری را تجربه کنید.',
      accentColor: Color(0xFF34C759),
    ),
    _OnboardingSlideData(
      icon: Icons.touch_app_rounded,
      badgeText: 'راهنمای کنترل • ژست‌های حرکتی',
      title: 'راهنمای ژست‌های حرکتی و ابزارها',
      subtitle:
          'برای مدیریت سریع‌تر کارها از این ژست‌ها و ابزارهای میان‌بر استفاده کنید:',
      accentColor: Color(0xFF6366F1),
      isGesturesSlide: true,
    ),
    _OnboardingSlideData(
      icon: CupertinoIcons.sparkles,
      badgeText: 'گیمیفیکیشن • پاداش مالی',
      title: 'رشد و پاداش',
      subtitle:
          'استریک روزانه خود را حفظ کنید، مدال‌های جدید به دست آورید و با تکمیل هر تسک پاداش ریالی به بودجه خود بیفزایید.',
      accentColor: Color(0xFFFF9500),
    ),
  ];

  void _finishOnboarding() {
    context.read<SettingsBloc>().add(const SettingsOnboardingCompleted());
    if (widget.onFinish != null) {
      widget.onFinish!();
      return;
    }
    final nextWidget = widget.nextScreenBuilder != null
        ? widget.nextScreenBuilder!(context)
        : const MainScreen();
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(
        builder: (_) => nextWidget,
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isZen = theme.scaffoldBackgroundColor == AppColors.backgroundZen;

    final Color bgColor = isZen
        ? AppColors.backgroundZen
        : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    final Color cardBg = isZen
        ? AppColors.surfaceZen
        : (isDark ? const Color(0xFF1C1C1E) : Colors.white);

    final Color textColor = isZen
        ? AppColors.textZen
        : (isDark ? Colors.white : const Color(0xFF12151C));

    final Color secondaryTextColor = isZen
        ? AppColors.textZenSecondary
        : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF636366));

    final isLastPage = _currentPage == _slides.length - 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // نوار بالایی: رد کردن (Skip)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // لوگوی کوچک برند
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.bolt_fill,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'زندگی‌ساز',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    if (!isLastPage)
                      BouncingTap(
                        onTap: _finishOnboarding,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'رد کردن',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // بخش اسلایدها (PageView)
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // نشانگر نمادین با لایه‌بندی و عمق اپل
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: slide.isGesturesSlide ? 100 : 130,
                                  height: slide.isGesturesSlide ? 100 : 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: slide.accentColor.withValues(alpha: 0.12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: slide.accentColor.withValues(alpha: 0.15),
                                        blurRadius: 36,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: slide.isGesturesSlide ? 72 : 90,
                                  height: slide.isGesturesSlide ? 72 : 90,
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.black.withValues(alpha: 0.4)
                                            : const Color(0x1A000000),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    slide.icon,
                                    size: slide.isGesturesSlide ? 36 : 44,
                                    color: slide.accentColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // نشانگر مرحله (Category Pill)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: slide.accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                slide.badgeText,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: slide.accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // عنوان اسلاید
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // توضیحات اسلاید
                            Text(
                              slide.subtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 13,
                                color: secondaryTextColor,
                                height: 1.5,
                              ),
                            ),

                            // کارت‌های تعاملی ژست‌ها و ابزارها (فقط برای اسلاید ژست‌ها)
                            if (slide.isGesturesSlide) ...[
                              const SizedBox(height: 18),
                              _OnboardingGestureCard(
                                key: const Key('onboarding_gesture_swipe_right'),
                                icon: Icons.swipe_right_rounded,
                                accentColor: const Color(0xFFF59E0B),
                                title: 'سوایپ به راست روی تسک',
                                subtitle: 'شروع تمرکز پومودورو ⏱️ و افزودن زیرتسک ➕',
                                cardBg: cardBg,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                              const SizedBox(height: 10),
                              _OnboardingGestureCard(
                                key: const Key('onboarding_gesture_swipe_left'),
                                icon: Icons.swipe_left_rounded,
                                accentColor: const Color(0xFF818CF8),
                                title: 'سوایپ به چپ روی تسک',
                                subtitle: 'ویرایش سریع تسک ✏️ و حذف تسک 🗑️',
                                cardBg: cardBg,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                              const SizedBox(height: 10),
                              _OnboardingGestureCard(
                                key: const Key('onboarding_gesture_search_filter'),
                                icon: CupertinoIcons.search,
                                accentColor: const Color(0xFF3898EC),
                                title: 'ابزارهای نوار بالا: جستجو و فیلتر',
                                subtitle: 'جستجوی هوشمند 🔍 و فیلتر دسته‌بندی تسک‌ها ⚡',
                                cardBg: cardBg,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // بخش ناوبری پایینی: نشانگر صفحات و دکمه ادامه / شروع
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                child: Column(
                  children: [
                    // نشانگر صفحات (Dots / Capsule Indicator)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) {
                          final isSelected = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isSelected ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.primaryColor
                                  : (isDark
                                      ? Colors.white24
                                      : const Color(0xFFD1D1D6)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),

                    // دکمه اقدام اصلی: ادامه یا شروع
                    BouncingTap(
                      onTap: _nextPage,
                      child: Container(
                        key: isLastPage
                            ? const Key('onboarding_get_started_button')
                            : const Key('onboarding_next_button'),
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLastPage ? 'شروع' : 'ادامه',
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                isLastPage
                                    ? CupertinoIcons.check_mark_circled_solid
                                    : CupertinoIcons.arrow_left,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
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

/// کارت نمایش یک ژست یا ابزار در اسلاید اختصاصی آنبوردینگ
class _OnboardingGestureCard extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final Color cardBg;
  final Color textColor;
  final Color secondaryTextColor;

  const _OnboardingGestureCard({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.cardBg,
    required this.textColor,
    required this.secondaryTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    color: secondaryTextColor,
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
