import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// سیستم تایپوگرافی و پوسته سراسری اپلیکیشن با فونت پیش‌فرض و یکپارچه `Vazirmatn`
class AppTheme {
  static const String defaultFontFamily = 'Vazirmatn';
  static const List<String> fontFallbacks = <String>[
    'Vazirmatn',
    'Vazirmatn-Bold',
    'Tahoma',
  ];

  static TextStyle _vazirStyle({
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
    double height = 1.45,
  }) {
    return TextStyle(
      fontFamily: defaultFontFamily,
      fontFamilyFallback: fontFallbacks,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// ساخت کامل تمامی اسلات‌های `TextTheme` با فونت استاندارد `Vazirmatn`
  static TextTheme _buildTextTheme(
    Color textColor, {
    Color secondaryColor = AppColors.textSecondary,
  }) {
    return TextTheme(
      displayLarge: _vazirStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displayMedium: _vazirStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      displaySmall: _vazirStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineLarge: _vazirStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineMedium: _vazirStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineSmall: _vazirStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      titleLarge: _vazirStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      titleMedium: _vazirStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: _vazirStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: _vazirStyle(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodyMedium: _vazirStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodySmall: _vazirStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
      ),
      labelLarge: _vazirStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      labelMedium: _vazirStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      labelSmall: _vazirStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
    );
  }

  static const PageTransitionsTheme _pageTransitionsTheme =
      PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
    },
  );

  static const Color defaultPrimaryColor = Color(0xFF0A84FF);

  /// تم تاریک (Dark Neon Glass Theme) با تایپوگرافی یکپارچه Vazirmatn و رنگ شاخص پویا
  static ThemeData darkTheme({Color primaryColor = defaultPrimaryColor}) {
    final textTheme = _buildTextTheme(AppColors.textDark);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: const Color(0xFF10B981),
        surface: const Color(0xFF1C1C1E),
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      primaryColor: primaryColor,
      fontFamily: defaultFontFamily,
      fontFamilyFallback: fontFallbacks,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      pageTransitionsTheme: _pageTransitionsTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.25),
        selectionHandleColor: primaryColor,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white70;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return const Color(0xFF3A3A3C);
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: _vazirStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2C2C2E),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentTextStyle: _vazirStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBarDark,
      ),
    );
  }

  /// تم روشن (Light Clean Glass Theme) با تایپوگرافی یکپارچه Vazirmatn و رنگ شاخص پویا
  static ThemeData lightTheme({Color primaryColor = defaultPrimaryColor}) {
    final textTheme = _buildTextTheme(AppColors.textLight);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: const Color(0xFF10B981),
        surface: const Color(0xFFFFFFFF),
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      primaryColor: primaryColor,
      fontFamily: defaultFontFamily,
      fontFamilyFallback: fontFallbacks,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      pageTransitionsTheme: _pageTransitionsTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.25),
        selectionHandleColor: primaryColor,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white70;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return const Color(0xFFE5E5EA);
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: _vazirStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textLight,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentTextStyle: _vazirStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBarLight,
      ),
    );
  }

  /// تم آرامش (Zen Mode Theme) با پالت آرام‌بخش و کم‌تنش، رنگ گرم خاکی/کاغذی و تایپوگرافی اسپرسو
  static ThemeData zenTheme({Color primaryColor = defaultPrimaryColor}) {
    final textTheme = _buildTextTheme(
      AppColors.textZen,
      secondaryColor: AppColors.textZenSecondary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: const Color(0xFF6B8E6B),
        surface: AppColors.surfaceZen,
        onSurface: AppColors.textZen,
      ),
      scaffoldBackgroundColor: AppColors.backgroundZen,
      canvasColor: AppColors.backgroundZen,
      cardColor: AppColors.surfaceZen,
      dialogBackgroundColor: AppColors.surfaceZen,
      shadowColor: const Color(0x1A4A4036),
      cardTheme: CardThemeData(
        color: AppColors.surfaceZen,
        elevation: 1.5,
        shadowColor: const Color(0x1A4A4036),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceZen,
        modalBackgroundColor: AppColors.surfaceZen,
        surfaceTintColor: Colors.transparent,
        shadowColor: Color(0x1A4A4036),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceZen,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x1A4A4036),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      primaryColor: primaryColor,
      fontFamily: defaultFontFamily,
      fontFamilyFallback: fontFallbacks,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      pageTransitionsTheme: _pageTransitionsTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.25),
        selectionHandleColor: primaryColor,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return AppColors.textZenSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return const Color(0xFFDDD7CF);
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: _vazirStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textZen,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textZen,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        contentTextStyle: _vazirStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.surfaceZen,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBarZen,
      ),
    );
  }
}
