import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';

/// Represents an offline-capable, user-configurable currency exchange rate
/// expressed as an exact integer ratio (`rateNumerator / rateDenominator`)
/// between major units of [sourceCurrency] and [targetCurrency].
///
/// Example:
/// - `1 USD = 60,000 IRT` -> `rateNumerator = 60000, rateDenominator = 1`
/// - `1 EUR = 1.08 USD`   -> `rateNumerator = 108, rateDenominator = 100`
class ExchangeRateEntity extends Equatable {
  final Currency sourceCurrency;
  final Currency targetCurrency;
  final int rateNumerator;
  final int rateDenominator;
  final DateTime updatedAt;

  const ExchangeRateEntity._({
    required this.sourceCurrency,
    required this.targetCurrency,
    required this.rateNumerator,
    required this.rateDenominator,
    required this.updatedAt,
  });

  /// Factory method validating that the rational exchange rate is strictly positive.
  static Result<ExchangeRateEntity, DomainFailure> create({
    required Currency sourceCurrency,
    required Currency targetCurrency,
    required int rateNumerator,
    int rateDenominator = 1,
    required DateTime updatedAt,
  }) {
    if (rateNumerator <= 0 || rateDenominator <= 0) {
      return const Err(
        FinancialValidationFailure(
          message:
              'Exchange rate numerator and denominator must be positive integers.',
        ),
      );
    }

    return Success(
      ExchangeRateEntity._(
        sourceCurrency: sourceCurrency,
        targetCurrency: targetCurrency,
        rateNumerator: rateNumerator,
        rateDenominator: rateDenominator,
        updatedAt: updatedAt,
      ),
    );
  }

  /// Reconstitutes an [ExchangeRateEntity] from trusted storage.
  factory ExchangeRateEntity.reconstitute({
    required Currency sourceCurrency,
    required Currency targetCurrency,
    required int rateNumerator,
    required int rateDenominator,
    required DateTime updatedAt,
  }) {
    return ExchangeRateEntity._(
      sourceCurrency: sourceCurrency,
      targetCurrency: targetCurrency,
      rateNumerator: rateNumerator,
      rateDenominator: rateDenominator,
      updatedAt: updatedAt,
    );
  }

  /// Converts [sourceMoney] from [sourceCurrency] into [targetCurrency]
  /// using exact [BigInt] integer arithmetic and half-up integer rounding.
  Result<Money, DomainFailure> convert(Money sourceMoney) {
    if (sourceMoney.currency != sourceCurrency) {
      return Err(
        CurrencyMismatchFailure(
          leftCurrencyCode: sourceMoney.currency.code,
          rightCurrencyCode: sourceCurrency.code,
          message:
              'Source Money currency (${sourceMoney.currency.code}) does not match ExchangeRate source (${sourceCurrency.code}).',
        ),
      );
    }

    if (sourceCurrency == targetCurrency) {
      return Success(sourceMoney);
    }

    final numerator = BigInt.from(sourceMoney.amountMinorUnits) *
        BigInt.from(rateNumerator) *
        BigInt.from(targetCurrency.minorUnitsPerMajor);

    final denominator = BigInt.from(rateDenominator) *
        BigInt.from(sourceCurrency.minorUnitsPerMajor);

    // Half-up integer rounding: (2 * numerator + denominator) ~/ (2 * denominator)
    final convertedMinorUnits = ((numerator * BigInt.two + denominator) ~/
            (denominator * BigInt.two))
        .toInt();

    return Money.create(
      amountMinorUnits: convertedMinorUnits,
      currency: targetCurrency,
    );
  }

  @override
  List<Object?> get props => [
        sourceCurrency,
        targetCurrency,
        rateNumerator,
        rateDenominator,
        updatedAt,
      ];
}
