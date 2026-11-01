/// Standard currency representation for the application (exclusively Toman).
///
/// Uses integer [minorUnitsPerMajor] and [decimalDigits] so all financial
/// calculations are executed in pure integer arithmetic without floating-point types.
enum Currency {
  irt(
    code: 'IRT',
    symbol: 'تومان',
    decimalDigits: 0,
    minorUnitsPerMajor: 1,
  );

  /// Standard 3-letter currency code stored in SQLite.
  final String code;

  /// Display symbol or short label.
  final String symbol;

  /// Number of fractional digits after decimal separator.
  final int decimalDigits;

  /// Integer ratio of minor units per 1 major unit.
  final int minorUnitsPerMajor;

  const Currency({
    required this.code,
    required this.symbol,
    required this.decimalDigits,
    required this.minorUnitsPerMajor,
  });

  /// Resolves a [Currency] from its persistent [code], safely defaulting to Toman.
  static Currency fromCode(String rawCode) {
    return Currency.irt;
  }
}
