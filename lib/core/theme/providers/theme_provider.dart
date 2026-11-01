import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_theme_mode.dart';

/// نگه‌دارنده وضعیت تم برنامه میان سه حالت: روشن (Light)، تاریک (Dark) و آرامش (Zen)
final themeProvider = StateProvider<AppThemeMode>((ref) {
  return AppThemeMode.signature;
});
