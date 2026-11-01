/// Enumeration representing the primary theme modes in TaskFlow.
///
/// Order of themes:
/// 1. [signature] ("زندگیساز" - Default on fresh install!)
/// 2. [dark] ("تاریک" - Uses classic layout)
/// 3. [zen] ("آرامش" - Uses classic layout with green palette)
/// 4. [light] ("روشن" - Uses classic layout with day palette)
enum AppThemeMode {
  signature,
  dark,
  zen,
  light;

  String get label {
    switch (this) {
      case AppThemeMode.signature:
        return 'زندگیساز';
      case AppThemeMode.dark:
        return 'تاریک';
      case AppThemeMode.zen:
        return 'آرامش';
      case AppThemeMode.light:
        return 'روشن';
    }
  }

  /// Whether this theme triggers the ultra-minimalist Signature UI layout.
  bool get isSignatureLayout => this == AppThemeMode.signature;

  /// Parses string representations from persistent SQLite storage.
  /// Gracefully migrates legacy boolean strings ('true' -> dark, 'false' -> light).
  static AppThemeMode fromString(String? raw) {
    if (raw == null) return AppThemeMode.signature;
    final lower = raw.trim().toLowerCase();
    if (lower == 'signature' || lower == '0') return AppThemeMode.signature;
    if (lower == 'dark' || lower == 'true' || lower == '1') {
      return AppThemeMode.dark;
    }
    if (lower == 'zen' || lower == '2') return AppThemeMode.zen;
    if (lower == 'light' || lower == 'false' || lower == '3') {
      return AppThemeMode.light;
    }
    return AppThemeMode.signature;
  }
}
