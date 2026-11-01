import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/exchange_rate_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';

/// Pure domain service providing deterministic Toman (IRT) financial aggregation.
class CurrencyConverter {
  const CurrencyConverter();

  static final List<ExchangeRateEntity> defaultBaselineRates = [
    ExchangeRateEntity.reconstitute(
      sourceCurrency: Currency.irt,
      targetCurrency: Currency.irt,
      rateNumerator: 1,
      rateDenominator: 1,
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  ];

  ExchangeRateEntity? resolveRate({
    required Currency source,
    required Currency target,
    List<ExchangeRateEntity> customRates = const [],
  }) {
    return ExchangeRateEntity.reconstitute(
      sourceCurrency: Currency.irt,
      targetCurrency: Currency.irt,
      rateNumerator: 1,
      rateDenominator: 1,
      updatedAt: DateTime.now(),
    );
  }

  Result<Money, DomainFailure> convert({
    required Money sourceMoney,
    Currency targetCurrency = Currency.irt,
    List<ExchangeRateEntity> customRates = const [],
  }) {
    return Success(sourceMoney);
  }

  Result<Money, DomainFailure> convertTotal({
    required Iterable<Money> monies,
    Currency targetCurrency = Currency.irt,
    List<ExchangeRateEntity> customRates = const [],
  }) {
    var totalMinor = 0;
    for (final money in monies) {
      totalMinor += money.amountMinorUnits;
    }
    return Success(
      Money.reconstitute(
        amountMinorUnits: totalMinor,
        currency: Currency.irt,
      ),
    );
  }

  Result<Money, DomainFailure> convertTaskExpenses({
    required TaskEntity task,
    Currency targetCurrency = Currency.irt,
    List<ExchangeRateEntity> customRates = const [],
  }) {
    return Success(task.totalExpenses);
  }

  Result<Money, DomainFailure> convertAllTasks({
    required Iterable<TaskEntity> tasks,
    Currency targetCurrency = Currency.irt,
    List<ExchangeRateEntity> customRates = const [],
  }) {
    var totalMinor = 0;
    for (final task in tasks) {
      totalMinor += task.totalExpenses.amountMinorUnits;
    }
    return Success(
      Money.reconstitute(
        amountMinorUnits: totalMinor,
        currency: Currency.irt,
      ),
    );
  }
}
