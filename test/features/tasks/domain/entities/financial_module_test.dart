import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/expense_item_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';

void main() {
  final baseTime = DateTime.utc(2026, 10, 10, 12, 0);

  group('Financial Module — Toman (IRT) Value Objects & Entities', () {
    test('should reject negative Money amounts with FinancialValidationFailure', () {
      final result = Money.create(
        amountMinorUnits: -1,
        currency: Currency.irt,
      );

      expect(result.isFailure, isTrue);
      expect(
        (result as Err<Money, DomainFailure>).failure,
        isA<FinancialValidationFailure>(),
      );
    });

    test('should format Money in Toman (IRT) accurately without floating-point drift', () {
      final irt = (Money.create(
        amountMinorUnits: 2500000,
        currency: Currency.irt,
      ) as Success<Money, DomainFailure>)
          .value;

      expect(irt.format(), equals('2,500,000 تومان'));
      expect(irt.format(includeCurrencyCode: false), equals('2,500,000'));
    });

    test('should resolve any legacy currency code to Currency.irt (Toman)', () {
      expect(Currency.fromCode('IRT'), equals(Currency.irt));
      expect(Currency.fromCode('USD'), equals(Currency.irt));
      expect(Currency.fromCode('EUR'), equals(Currency.irt));
    });

    test('should aggregate task expenses in Toman using pure integer arithmetic', () {
      final exp1 = (ExpenseItemEntity.create(
        id: 'exp-1',
        title: 'API Hosting',
        money: (Money.create(
          amountMinorUnits: 600000,
          currency: Currency.irt,
        ) as Success<Money, DomainFailure>)
            .value,
        incurredAt: baseTime,
      ) as Success<ExpenseItemEntity, DomainFailure>)
          .value;

      final exp2 = (ExpenseItemEntity.create(
        id: 'exp-2',
        title: 'Design License',
        money: (Money.create(
          amountMinorUnits: 650000,
          currency: Currency.irt,
        ) as Success<Money, DomainFailure>)
            .value,
        incurredAt: baseTime,
      ) as Success<ExpenseItemEntity, DomainFailure>)
          .value;

      final exp3 = (ExpenseItemEntity.create(
        id: 'exp-3',
        title: 'Local SMS Gateway',
        money: (Money.create(
          amountMinorUnits: 250000,
          currency: Currency.irt,
        ) as Success<Money, DomainFailure>)
            .value,
        incurredAt: baseTime,
      ) as Success<ExpenseItemEntity, DomainFailure>)
          .value;

      final task = (TaskEntity.create(
        id: 'task-fin-1',
        title: 'Launch SaaS Infrastructure',
        expenses: <ExpenseItemEntity>[exp1, exp2, exp3],
        createdAt: baseTime,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      expect(task.totalExpenses.amountMinorUnits, equals(1500000));
      expect(task.totalExpenses.format(), equals('1,500,000 تومان'));

      final totalResult = task.totalExpensesInCurrency(Currency.irt);
      expect(totalResult.isSuccess, isTrue);
      final totalMoney = (totalResult as Success<Money, DomainFailure>).value;
      expect(totalMoney.amountMinorUnits, equals(1500000));
      expect(totalMoney.format(), equals('1,500,000 تومان'));
    });
  });
}
