import 'package:equatable/equatable.dart';
import 'package:task_flow/features/analytics/domain/entities/daily_expense_entity.dart';
import 'package:task_flow/features/analytics/domain/entities/task_ratio_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';

/// Comprehensive analytics summary containing weekly trend, monthly spend,
/// task completion ratios, and GitHub-style daily activity heatmap counts.
class AnalyticsSummaryEntity extends Equatable {
  final List<DailyExpenseEntity> last7DaysExpenses;
  final Money total7DaysExpense;
  final Money monthlyExpense;
  final TaskRatioEntity taskRatio;
  final Currency targetCurrency;
  final Map<String, int> activityHeatmapCounts;

  const AnalyticsSummaryEntity({
    required this.last7DaysExpenses,
    required this.total7DaysExpense,
    required this.monthlyExpense,
    required this.taskRatio,
    required this.targetCurrency,
    this.activityHeatmapCounts = const <String, int>{},
  });

  @override
  List<Object?> get props => [
        last7DaysExpenses,
        total7DaysExpense,
        monthlyExpense,
        taskRatio,
        targetCurrency,
        activityHeatmapCounts,
      ];
}
