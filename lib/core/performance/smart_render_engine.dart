import 'dart:ui';
import 'package:flutter/material.dart';

/// موتور رندر هوشمند (Smart Render Engine) برای تضمین نرخ نوسازی ۶۰ فریم بر ثانیه (60 FPS).
///
/// در لیست‌های طولانی (بیش از آستانه مجاز) یا روی دستگاه‌های ضعیف‌تر / حالت کاهش انیمیشن،
/// افکت‌های سنگین گرافیکی (نظیر `BackdropFilter`، سایه‌های نئونی چندلایه و انیمیشن‌های پیچیده)
/// به صورت خودکار به سطوح مات (Matte Opaque Surfaces) و تغییرات سریع و سبک دانگرید می‌شوند.
class SmartRenderEngine {
  /// آستانه تعداد آیتم‌های لیست برای فعال‌سازی خودکار حالت سبک (Matte Mode)
  static const int heavyListThreshold = 15;

  /// فلگ سراسری برای شبیه‌سازی یا اجبار حالت دستگاه‌های ضعیف (Low-End Device Override)
  static bool forceLowEndDeviceMode = false;

  /// بررسی می‌کند که آیا رندر باید به حالت مات و ساده (Matte / Lite Mode) دانگرید شود یا خیر.
  static bool shouldDegrade({
    int itemCount = 0,
    bool? mediaQueryDisableAnimations,
    bool forceLite = false,
  }) {
    if (forceLite || forceLowEndDeviceMode) {
      return true;
    }
    if (mediaQueryDisableAnimations == true) {
      return true;
    }
    if (itemCount >= heavyListThreshold) {
      return true;
    }
    return false;
  }

  /// بررسی وضعیت دانگرید با استفاده از `BuildContext` و تعداد آیتم‌های لیست
  static bool shouldDegradeForContext(
    BuildContext context, {
    int itemCount = 0,
  }) {
    final disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return shouldDegrade(
      itemCount: itemCount,
      mediaQueryDisableAnimations: disableAnimations,
    );
  }

  /// محاسبه زمان انیمیشن بهینه؛ در حالت دانگرید، انیمیشن‌های طولانی به تغییر فوری/مات تبدیل می‌شوند.
  static Duration scaleDuration(
    Duration normalDuration, {
    int itemCount = 0,
    bool forceLite = false,
  }) {
    if (shouldDegrade(itemCount: itemCount, forceLite: forceLite)) {
      return Duration.zero;
    }
    return normalDuration;
  }

  /// حذف سایه‌های نئونی سنگین (Blur Shadows) در حالت دانگرید برای جلوگیری از افت فریم (Jank)
  static List<BoxShadow> filterShadows(
    List<BoxShadow> shadows, {
    int itemCount = 0,
    bool forceLite = false,
  }) {
    if (shouldDegrade(itemCount: itemCount, forceLite: forceLite)) {
      return const <BoxShadow>[];
    }
    return shadows;
  }

  /// رنگ پس‌زمینه کارت: در حالت عادی شیشه‌ای نیمه‌شفاف و در حالت دانگرید، رنگ مات و یکدست (Matte Surface)
  static Color resolveSurfaceColor({
    required bool isDark,
    required Color glassColor,
    Color? matteDarkColor,
    Color? matteLightColor,
    int itemCount = 0,
    bool forceLite = false,
  }) {
    if (shouldDegrade(itemCount: itemCount, forceLite: forceLite)) {
      return isDark
          ? (matteDarkColor ?? const Color(0xFF151C28))
          : (matteLightColor ?? const Color(0xFFFFFFFF));
    }
    return glassColor;
  }

  /// ساخت کانتینر هوشمند که در حالت عادی از `BackdropFilter` شیشه‌ای و در لیست‌های سنگین یا
  /// دستگاه‌های ضعیف از کانتینر مات بدون Blur استفاده می‌کند.
  static Widget buildAdaptiveGlassContainer({
    required BuildContext context,
    required bool isDark,
    required Widget child,
    int itemCount = 0,
    double blurSigma = 12.0,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(20)),
    EdgeInsetsGeometry? padding,
    Color? glassColor,
    Color? borderColor,
    List<BoxShadow>? boxShadows,
  }) {
    final degrade = shouldDegradeForContext(context, itemCount: itemCount);
    final effectiveBg = resolveSurfaceColor(
      isDark: isDark,
      glassColor: glassColor ??
          (isDark
              ? const Color(0xFF161E2E).withOpacity(0.72)
              : Colors.white.withOpacity(0.88)),
      itemCount: itemCount,
      forceLite: degrade,
    );
    final effectiveBorder = borderColor ??
        (isDark
            ? Colors.white.withOpacity(degrade ? 0.12 : 0.08)
            : Colors.black.withOpacity(0.06));
    final effectiveShadows = filterShadows(
      boxShadows ?? const <BoxShadow>[],
      itemCount: itemCount,
      forceLite: degrade,
    );

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: borderRadius,
        border: Border.all(color: effectiveBorder, width: 1.0),
        boxShadow: effectiveShadows,
      ),
      child: child,
    );

    if (degrade || blurSigma <= 0) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: container,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: container,
      ),
    );
  }
}
