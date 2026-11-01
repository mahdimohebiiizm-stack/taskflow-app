import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/features/analytics/domain/entities/rial_financial_summary_entity.dart';

enum FinancialAnalyticsStatus {
  initial,
  loading,
  success,
  failure,
}

class FinancialAnalyticsState extends Equatable {
  final FinancialAnalyticsStatus status;
  final RialFinancialSummaryEntity summary;
  final Failure? failure;

  const FinancialAnalyticsState({
    this.status = FinancialAnalyticsStatus.initial,
    this.summary = const RialFinancialSummaryEntity(),
    this.failure,
  });

  FinancialAnalyticsState copyWith({
    FinancialAnalyticsStatus? status,
    RialFinancialSummaryEntity? summary,
    Failure? Function()? failure,
  }) {
    return FinancialAnalyticsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [status, summary, failure];
}
