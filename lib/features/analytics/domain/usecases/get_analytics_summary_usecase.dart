import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:task_flow/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

class GetAnalyticsSummaryParams extends Equatable {
  final Currency targetCurrency;
  final DateTime? referenceDate;

  const GetAnalyticsSummaryParams({
    required this.targetCurrency,
    this.referenceDate,
  });

  @override
  List<Object?> get props => [targetCurrency, referenceDate];
}

class GetAnalyticsSummaryUseCase
    implements UseCase<AnalyticsSummaryEntity, GetAnalyticsSummaryParams> {
  final AnalyticsRepository repository;

  const GetAnalyticsSummaryUseCase(this.repository);

  @override
  Future<Result<AnalyticsSummaryEntity, Failure>> call(
    GetAnalyticsSummaryParams params,
  ) {
    return repository.getAnalyticsSummary(
      targetCurrency: params.targetCurrency,
      referenceDate: params.referenceDate,
    );
  }
}
