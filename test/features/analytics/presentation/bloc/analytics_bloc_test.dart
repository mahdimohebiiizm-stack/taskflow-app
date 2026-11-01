import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:task_flow/features/analytics/domain/entities/daily_expense_entity.dart';
import 'package:task_flow/features/analytics/domain/entities/task_ratio_entity.dart';
import 'package:task_flow/features/analytics/domain/usecases/get_analytics_summary_usecase.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_bloc.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_event.dart';
import 'package:task_flow/features/analytics/presentation/bloc/analytics_state.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';

class MockGetAnalyticsSummaryUseCase extends Mock
    implements GetAnalyticsSummaryUseCase {}

void main() {
  late MockGetAnalyticsSummaryUseCase mockUseCase;

  final sampleSummary = AnalyticsSummaryEntity(
    last7DaysExpenses: [
      DailyExpenseEntity(
        date: DateTime.utc(2026, 10, 11),
        dayLabel: 'یکشنبه',
        amount: Money.reconstitute(amountMinorUnits: 500000, currency: Currency.irt),
      ),
    ],
    total7DaysExpense: Money.reconstitute(amountMinorUnits: 500000, currency: Currency.irt),
    monthlyExpense: Money.reconstitute(amountMinorUnits: 1500000, currency: Currency.irt),
    taskRatio: const TaskRatioEntity(
      totalCount: 10,
      completedCount: 8,
      inProgressCount: 2,
      todoCount: 0,
    ),
    targetCurrency: Currency.irt,
  );

  setUpAll(() {
    registerFallbackValue(
      const GetAnalyticsSummaryParams(targetCurrency: Currency.irt),
    );
  });

  setUp(() {
    mockUseCase = MockGetAnalyticsSummaryUseCase();
  });

  AnalyticsBloc buildBloc() =>
      AnalyticsBloc(getAnalyticsSummaryUseCase: mockUseCase);

  group('AnalyticsBloc Tests', () {
    test('initial state has default status and target currency', () {
      final bloc = buildBloc();
      expect(bloc.state.status, equals(AnalyticsStatus.initial));
      expect(bloc.state.targetCurrency, equals(Currency.irt));
      expect(bloc.state.summary, isNull);
    });

    blocTest<AnalyticsBloc, AnalyticsState>(
      'emits [loading, success] with AnalyticsSummary when AnalyticsLoadRequested succeeds',
      build: () {
        when(() => mockUseCase(any())).thenAnswer(
          (_) async => Success(sampleSummary),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AnalyticsLoadRequested()),
      expect: () => [
        const AnalyticsState(
          status: AnalyticsStatus.loading,
          targetCurrency: Currency.irt,
        ),
        AnalyticsState(
          status: AnalyticsStatus.success,
          summary: sampleSummary,
          targetCurrency: Currency.irt,
        ),
      ],
    );

    blocTest<AnalyticsBloc, AnalyticsState>(
      'emits [loading, failure] when usecase fails',
      build: () {
        when(() => mockUseCase(any())).thenAnswer(
          (_) async => const Err(DatabaseFailure(message: 'Query error')),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AnalyticsLoadRequested()),
      expect: () => [
        const AnalyticsState(
          status: AnalyticsStatus.loading,
          targetCurrency: Currency.irt,
        ),
        const AnalyticsState(
          status: AnalyticsStatus.failure,
          targetCurrency: Currency.irt,
          failure: DatabaseFailure(message: 'Query error'),
        ),
      ],
    );
  });
}
