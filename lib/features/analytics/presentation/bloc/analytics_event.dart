import 'package:equatable/equatable.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

sealed class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

final class AnalyticsLoadRequested extends AnalyticsEvent {
  final Currency? targetCurrency;
  final DateTime? referenceDate;

  const AnalyticsLoadRequested({
    this.targetCurrency,
    this.referenceDate,
  });

  @override
  List<Object?> get props => [targetCurrency, referenceDate];
}

final class AnalyticsTargetCurrencyChanged extends AnalyticsEvent {
  final Currency newCurrency;

  const AnalyticsTargetCurrencyChanged(this.newCurrency);

  @override
  List<Object?> get props => [newCurrency];
}

final class AnalyticsRefreshed extends AnalyticsEvent {
  const AnalyticsRefreshed();
}
