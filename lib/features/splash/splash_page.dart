import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/theme/app_colors.dart';
import 'package:task_flow/features/navigation/main_screen.dart';
import 'package:task_flow/features/onboarding/onboarding_page.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_state.dart';

/// صفحه اسپلش سینمایی با لوگوی اختصاصی، پالس نئونی، انیمیشن‌های روان و هدایت هوشمند
class SplashPage extends StatefulWidget {
  final Duration animationDuration;
  final Duration holdDuration;
  final bool autoNavigate;

  const SplashPage({
    super.key,
    this.animationDuration = const Duration(milliseconds: 900),
    this.holdDuration = const Duration(milliseconds: 400),
    this.autoNavigate = true,
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _glowAnimation;
  Timer? _navigationTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.65)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.65, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 20,
      ),
    ]).animate(_controller);

    _controller.forward();

    // زمان‌بندی هدایت خودکار پس از پایان انیمیشن
    if (widget.autoNavigate) {
      _navigationTimer = Timer(
        widget.animationDuration + widget.holdDuration,
        _navigateNext,
      );
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    if (_hasNavigated || !mounted) return;

    final bloc = context.read<SettingsBloc>();
    var settings = bloc.state.settings;
    if (bloc.state.status == SettingsStatus.loading ||
        bloc.state.status == SettingsStatus.initial) {
      try {
        final loadedState = await bloc.stream
            .firstWhere((s) =>
                s.status != SettingsStatus.loading &&
                s.status != SettingsStatus.initial)
            .timeout(const Duration(milliseconds: 600));
        settings = loadedState.settings;
      } catch (_) {
        settings = bloc.state.settings;
      }
    }

    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    final bool hasSeenOnboarding = settings.hasSeenOnboarding;

    final targetPage = hasSeenOnboarding
        ? const MainScreen()
        : const OnboardingPage();

    unawaited(
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, animation, secondaryAnimation) => targetPage,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.06),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1.0)
                      .animate(curvedAnimation),
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 650),
        ),
      ),
    );
  }

  Widget _buildFallbackLogo(Color primaryColor) {
    return Container(
      key: const Key('splash_fallback_logo'),
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF00E5FF),
            Color(0xFF0A84FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Icon(
          CupertinoIcons.checkmark_alt,
          key: Key('splash_fallback_icon'),
          size: 40,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;

    // تشخیص تم آرامش بر اساس رنگ پس‌زمینه اسقفورد
    final isZen = theme.scaffoldBackgroundColor == AppColors.backgroundZen;

    final Color bgColor = isZen
        ? AppColors.backgroundZen
        : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    final Color cardColor = isZen
        ? AppColors.surfaceZen
        : (isDark ? const Color(0xFF1C1C1E) : Colors.white);

    final Color titleColor = isZen
        ? AppColors.textZen
        : (isDark ? Colors.white : const Color(0xFF12151C));

    final Color subtitleColor = isZen
        ? AppColors.textZenSecondary
        : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF636366));

    return GestureDetector(
      onTap: _navigateNext,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: (0.75 + (0.25 * _scaleAnimation.value)).clamp(0.5, 1.15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // لوگوی اختصاصی با هاله نئونی تپنده
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // هاله نورانی دور لوگو با پالس نئونی
                          Container(
                            width: 136,
                            height: 136,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(
                                    alpha: 0.40 * _glowAnimation.value,
                                  ),
                                  blurRadius: 42 * _glowAnimation.value,
                                  spreadRadius: 8 * _glowAnimation.value,
                                ),
                                BoxShadow(
                                  color: primaryColor.withValues(
                                    alpha: 0.30 * _glowAnimation.value,
                                  ),
                                  blurRadius: 26 * _glowAnimation.value,
                                  spreadRadius: 4 * _glowAnimation.value,
                                ),
                              ],
                            ),
                          ),
                          // بدنه کپسولی شیشه‌ای لوگو
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFF00E5FF).withValues(
                                  alpha: 0.25 * _glowAnimation.value,
                                ),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark
                                      ? Colors.black.withValues(alpha: 0.5)
                                      : const Color(0x1F000000),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  'assets/app_logo.png',
                                  key: const Key('splash_app_logo_image'),
                                  width: 76,
                                  height: 76,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackLogo(primaryColor),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // عنوان برند برنامه
                      Text(
                        'زندگی‌ساز',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // زیرعنوان هدفمند
                      Text(
                        'سامانه هوشمند زمان، انضباط و آرامش ذهنی',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 36),
                      // نشانگر ظریف بارگذاری به سبک اپل
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            primaryColor.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
