import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/analytics/data/datasources/analytics_local_datasource.dart';
import 'package:task_flow/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:task_flow/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsLocalDataSource localDataSource;

  const AnalyticsRepositoryImpl({required this.localDataSource});

  @override
  Future<Result<AnalyticsSummaryEntity, Failure>> getAnalyticsSummary({
    required Currency targetCurrency,
    DateTime? referenceDate,
  }) async {
    try {
      final summary = await localDataSource.getAnalyticsSummary(
        targetCurrency: targetCurrency,
        referenceDate: referenceDate,
      );
      return Success(summary);
    } on LocalDatabaseException catch (e) {
      return Err(DatabaseFailure(message: e.message));
    } catch (e) {
      return Err(DatabaseFailure(message: 'Unexpected error loading analytics: $e'));
    }
  }
}
