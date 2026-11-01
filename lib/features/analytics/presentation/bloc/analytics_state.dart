import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

enum AnalyticsStatus { initial, loading, success, failure }

class AnalyticsState extends Equatable {
  final AnalyticsStatus status;
  final AnalyticsSummaryEntity? summary;
  final Currency targetCurrency;
  final Failure? failure;

  const AnalyticsState({
    this.status = AnalyticsStatus.initial,
    this.summary,
    this.targetCurrency = Currency.irt,
    this.failure,
  });

  AnalyticsState copyWith({
    AnalyticsStatus? status,
    AnalyticsSummaryEntity? Function()? summary,
    Currency? targetCurrency,
    Failure? Function()? failure,
  }) {
    return AnalyticsState(
      status: status ?? this.status,
      summary: summary != null ? summary() : this.summary,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [status, summary, targetCurrency, failure];
}
