import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/analytics/domain/usecases/get_analytics_summary_usecase.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_event.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final GetAnalyticsSummaryUseCase getAnalyticsSummaryUseCase;

  AnalyticsBloc({
    required this.getAnalyticsSummaryUseCase,
  }) : super(const AnalyticsState()) {
    on<AnalyticsLoadRequested>(_onAnalyticsLoadRequested);
    on<AnalyticsTargetCurrencyChanged>(_onAnalyticsTargetCurrencyChanged);
    on<AnalyticsRefreshed>(_onAnalyticsRefreshed);
  }

  Future<void> _onAnalyticsLoadRequested(
    AnalyticsLoadRequested event,
    Emitter<AnalyticsState> emit,
  ) async {
    final currency = event.targetCurrency ?? state.targetCurrency;
    emit(
      state.copyWith(
        status: AnalyticsStatus.loading,
        targetCurrency: currency,
      ),
    );

    final result = await getAnalyticsSummaryUseCase(
      GetAnalyticsSummaryParams(
        targetCurrency: currency,
        referenceDate: event.referenceDate,
      ),
    );

    switch (result) {
      case Success(value: final summary):
        emit(
          state.copyWith(
            status: AnalyticsStatus.success,
            summary: () => summary,
            failure: () => null,
          ),
        );
      case Err(failure: final f):
        emit(
          state.copyWith(
            status: AnalyticsStatus.failure,
            failure: () => f,
          ),
        );
    }
  }

  Future<void> _onAnalyticsTargetCurrencyChanged(
    AnalyticsTargetCurrencyChanged event,
    Emitter<AnalyticsState> emit,
  ) async {
    add(AnalyticsLoadRequested(targetCurrency: event.newCurrency));
  }

  Future<void> _onAnalyticsRefreshed(
    AnalyticsRefreshed event,
    Emitter<AnalyticsState> emit,
  ) async {
    add(AnalyticsLoadRequested(targetCurrency: state.targetCurrency));
  }
}
