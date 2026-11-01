import 'package:equatable/equatable.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';

/// Aggregated expense data point for a single calendar day.
class DailyExpenseEntity extends Equatable {
  final DateTime date;
  final String dayLabel;
  final Money amount;
  final int expenseCount;

  const DailyExpenseEntity({
    required this.date,
    required this.dayLabel,
    required this.amount,
    this.expenseCount = 0,
  });

  @override
  List<Object?> get props => [date, dayLabel, amount, expenseCount];
}
