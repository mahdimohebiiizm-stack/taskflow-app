import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/services/currency_converter.dart';

void main() {
  const converter = CurrencyConverter();

  Money makeMoney(int minor) {
    return (Money.create(amountMinorUnits: minor, currency: Currency.irt)
            as Success<Money, DomainFailure>)
        .value;
  }

  group('CurrencyConverter — Pure Toman (IRT) Aggregation', () {
    test('retains exact Toman amount on convert', () {
      final source = makeMoney(200000);
      final result = converter.convert(
        sourceMoney: source,
        targetCurrency: Currency.irt,
      );

      expect(result.isSuccess, isTrue);
      final converted = (result as Success<Money, DomainFailure>).value;
      expect(converted.currency, Currency.irt);
      expect(converted.amountMinorUnits, 200000);
    });

    test('aggregates multiple Toman Money entries accurately', () {
      final m1 = makeMoney(600000);
      final m2 = makeMoney(650000);
      final m3 = makeMoney(150000);

      final result = converter.convertTotal(
        monies: [m1, m2, m3],
        targetCurrency: Currency.irt,
      );

      expect(result.isSuccess, isTrue);
      final total = (result as Success<Money, DomainFailure>).value;
      expect(total.currency, Currency.irt);
      expect(total.amountMinorUnits, 1400000);
    });
  });
}
