import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

abstract interface class AnalyticsRepository {
  Future<Result<AnalyticsSummaryEntity, Failure>> getAnalyticsSummary({
    required Currency targetCurrency,
    DateTime? referenceDate,
  });
}
