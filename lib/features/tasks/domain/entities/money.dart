import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

/// Immutable Value Object representing an exact monetary amount in its smallest integer unit.
///
/// Strictly forbids floating-point types (`double`) to guarantee zero IEEE-754 rounding drift.
class Money extends Equatable {
  /// Exact amount in minor units (Tomans for IRT).
  final int amountMinorUnits;

  /// The currency associated with [amountMinorUnits] (locked to Toman).
  final Currency currency;

  const Money._({
    required this.amountMinorUnits,
    required this.currency,
  });

  /// Creates a validated non-negative [Money] instance from minor units.
  static Result<Money, DomainFailure> create({
    required int amountMinorUnits,
    Currency currency = Currency.irt,
  }) {
    if (amountMinorUnits < 0) {
      return const Err(
        FinancialValidationFailure(
          message: 'Monetary amount cannot be negative.',
        ),
      );
    }

    return Success(
      Money._(
        amountMinorUnits: amountMinorUnits,
        currency: currency,
      ),
    );
  }

  /// Creates a zero-valued [Money] instance in Toman.
  factory Money.zero([Currency currency = Currency.irt]) {
    return Money._(
      amountMinorUnits: 0,
      currency: currency,
    );
  }

  /// Reconstitutes a [Money] value object from trusted storage.
  factory Money.reconstitute({
    required int amountMinorUnits,
    Currency currency = Currency.irt,
  }) {
    return Money._(
      amountMinorUnits: amountMinorUnits,
      currency: currency,
    );
  }

  /// Adds two [Money] instances.
  Result<Money, DomainFailure> add(Money other) {
    return Success(
      Money._(
        amountMinorUnits: amountMinorUnits + other.amountMinorUnits,
        currency: Currency.irt,
      ),
    );
  }

  /// Subtracts [other] from this [Money] instance if resulting balance remains non-negative.
  Result<Money, DomainFailure> subtract(Money other) {
    final difference = amountMinorUnits - other.amountMinorUnits;
    if (difference < 0) {
      return const Err(
        FinancialValidationFailure(
          message: 'Subtraction would result in a negative monetary amount.',
        ),
      );
    }

    return Success(
      Money._(
        amountMinorUnits: difference,
        currency: Currency.irt,
      ),
    );
  }

  /// Deterministically formats the monetary value using pure integer arithmetic (e.g., `2,500,000 تومان`).
  String format({bool includeCurrencyCode = true}) {
    final formattedMajor = _formatWithThousandsSeparator(amountMinorUnits);
    return includeCurrencyCode ? '$formattedMajor تومان' : formattedMajor;
  }

  static String _formatWithThousandsSeparator(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    if (value < 0) {
      buffer.write('-');
    }

    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  List<Object?> get props => [amountMinorUnits, currency];
}
