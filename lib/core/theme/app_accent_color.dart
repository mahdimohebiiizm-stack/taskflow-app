import 'package:flutter/material.dart';

/// پالت‌های رنگ شاخص پویا (Dynamic Accent Color Architecture)
enum AppAccentColor {
  blue(
    name: 'blue',
    label: 'آبی اپل',
    color: Color(0xFF0A84FF),
  ),
  forestGreen(
    name: 'forestGreen',
    label: 'سبز جنگلی',
    color: Color(0xFF005C4A),
  ),
  sunsetOrange(
    name: 'sunsetOrange',
    label: 'نارنجی غروب',
    color: Color(0xFFFF7043),
  ),
  royalPurple(
    name: 'royalPurple',
    label: 'بنفش رویال',
    color: Color(0xFF5E5CE6),
  );

  final String name;
  final String label;
  final Color color;

  const AppAccentColor({
    required this.name,
    required this.label,
    required this.color,
  });

  static AppAccentColor fromString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return AppAccentColor.blue;
    final normalized = raw.trim().toLowerCase();
    for (final accent in AppAccentColor.values) {
      if (accent.name.toLowerCase() == normalized) {
        return accent;
      }
    }
    return AppAccentColor.blue;
  }
}
