import 'package:equatable/equatable.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';

sealed class FinancialAnalyticsEvent extends Equatable {
  const FinancialAnalyticsEvent();

  @override
  List<Object?> get props => const [];
}

/// درخواست بارگذاری و تحلیل جریان‌های مالی ریالی از مخزن تسک‌ها (CQRS Query)
final class FinancialAnalyticsLoadRequested extends FinancialAnalyticsEvent {
  const FinancialAnalyticsLoadRequested();
}

/// به‌روزرسانی مستقیم مدل خواندنی ریالی بر اساس لیست تسک‌های فعلی
final class FinancialAnalyticsTasksProjected extends FinancialAnalyticsEvent {
  final List<TaskEntity> tasks;
  final int? customBudgetRials;

  const FinancialAnalyticsTasksProjected({
    required this.tasks,
    this.customBudgetRials,
  });

  @override
  List<Object?> get props => [tasks, customBudgetRials];
}

/// تغییر سقف بودجه ریالی
final class FinancialAnalyticsBudgetChanged extends FinancialAnalyticsEvent {
  final int newBudgetRials;

  const FinancialAnalyticsBudgetChanged(this.newBudgetRials);

  @override
  List<Object?> get props => [newBudgetRials];
}

/// تعدیل پویای بودجه ریالی (مثلاً پاداش +۵۰,۰۰۰ ریال برای انجام تسک یا جریمه -۱۰,۰۰۰ ریال برای موعد گذشته)
final class FinancialAnalyticsBudgetAdjusted extends FinancialAnalyticsEvent {
  final int deltaRials;
  final String? reason;

  const FinancialAnalyticsBudgetAdjusted({
    required this.deltaRials,
    this.reason,
  });

  @override
  List<Object?> get props => [deltaRials, reason];
}

