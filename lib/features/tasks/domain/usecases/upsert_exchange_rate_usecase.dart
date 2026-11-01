import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/exchange_rate_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

/// Legacy stub kept for backward compatibility; multi-currency is locked to Toman.
class UpsertExchangeRateUseCase
    implements UseCase<ExchangeRateEntity, UpsertExchangeRateParams> {
  final TaskRepository repository;

  const UpsertExchangeRateUseCase(this.repository);

  @override
  Future<Result<ExchangeRateEntity, Failure>> call(
    UpsertExchangeRateParams params,
  ) async {
    return ExchangeRateEntity.create(
      sourceCurrency: Currency.irt,
      targetCurrency: Currency.irt,
      rateNumerator: 1,
      rateDenominator: 1,
      updatedAt: params.updatedAt ?? DateTime.now().toUtc(),
    );
  }
}

class UpsertExchangeRateParams extends Equatable {
  final Currency sourceCurrency;
  final Currency targetCurrency;
  final int rateNumerator;
  final int rateDenominator;
  final DateTime? updatedAt;

  const UpsertExchangeRateParams({
    required this.sourceCurrency,
    required this.targetCurrency,
    required this.rateNumerator,
    this.rateDenominator = 1,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        sourceCurrency,
        targetCurrency,
        rateNumerator,
        rateDenominator,
        updatedAt,
      ];
}
