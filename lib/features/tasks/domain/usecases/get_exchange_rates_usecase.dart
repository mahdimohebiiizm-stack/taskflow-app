import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/exchange_rate_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

/// Legacy stub kept for backward compatibility; multi-currency is locked to Toman.
class GetExchangeRatesUseCase
    implements UseCase<List<ExchangeRateEntity>, NoParams> {
  final TaskRepository repository;

  const GetExchangeRatesUseCase(this.repository);

  @override
  Future<Result<List<ExchangeRateEntity>, Failure>> call(
    NoParams params,
  ) async {
    return const Success([]);
  }
}
