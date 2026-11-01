import 'package:equatable/equatable.dart';
import 'package:task_flow/core/utils/persian_number_formatter.dart';

/// آیتم تفکیکی جریان مالی یک تسک بر پایه ریال (CQRS Read Model)
class RialTaskFlowItem extends Equatable {
  final String taskId;
  final String title;
  final int amountRials;
  final bool isCompleted;
  final double shareRatio;

  const RialTaskFlowItem({
    required this.entityTaskId,
    required this.title,
    required this.amountRials,
    required this.isCompleted,
    required this.shareRatio,
  }) : taskId = entityTaskId;

  final String entityTaskId;

  String get formattedRials => RialFinancialSummaryEntity.formatRials(amountRials);

  @override
  List<Object?> get props => [
        taskId,
        title,
        amountRials,
        isCompleted,
        shareRatio,
      ];
}

/// مدل خواندنی (CQRS Read Model) برای تحلیل اختصاصی مالی صرفاً بر پایه ریال (IRR)
class RialFinancialSummaryEntity extends Equatable {
  /// ضریب تبدیل تومان به ریال (۱ تومان = ۱۰ ریال)
  static const int tomanToRialMultiplier = 10;

  /// سقف بودجه پیش‌فرض ماهانه به ریال (۵۰,۰۰۰,۰۰۰ ریال معادل ۵ میلیون تومان)
  static const int defaultMonthlyBudgetRials = 50000000;

  final int totalBudgetRials;
  final int totalSpentRials;
  final int todaySpentRials;
  final int completedTasksSpentRials;
  final int pendingTasksSpentRials;
  final int financialTasksCount;
  final List<RialTaskFlowItem> taskFlows;

  const RialFinancialSummaryEntity({
    this.totalBudgetRials = defaultMonthlyBudgetRials,
    this.totalSpentRials = 0,
    this.todaySpentRials = 0,
    this.completedTasksSpentRials = 0,
    this.pendingTasksSpentRials = 0,
    this.financialTasksCount = 0,
    this.taskFlows = const <RialTaskFlowItem>[],
  });

  RialFinancialSummaryEntity copyWith({
    int? totalBudgetRials,
    int? totalSpentRials,
    int? todaySpentRials,
    int? completedTasksSpentRials,
    int? pendingTasksSpentRials,
    int? financialTasksCount,
    List<RialTaskFlowItem>? taskFlows,
  }) {
    return RialFinancialSummaryEntity(
      totalBudgetRials: totalBudgetRials ?? this.totalBudgetRials,
      totalSpentRials: totalSpentRials ?? this.totalSpentRials,
      todaySpentRials: todaySpentRials ?? this.todaySpentRials,
      completedTasksSpentRials:
          completedTasksSpentRials ?? this.completedTasksSpentRials,
      pendingTasksSpentRials:
          pendingTasksSpentRials ?? this.pendingTasksSpentRials,
      financialTasksCount: financialTasksCount ?? this.financialTasksCount,
      taskFlows: taskFlows ?? this.taskFlows,
    );
  }


  /// بودجه باقی‌مانده به ریال
  int get remainingBudgetRials => totalBudgetRials - totalSpentRials;

  /// آیا بودجه در وضعیت امن است؟
  bool get isWithinBudget => remainingBudgetRials >= 0;

  /// نسبت مصرف بودجه بین ۰.۰ تا ۱.۰
  double get budgetUsageRatio {
    if (totalBudgetRials <= 0) return 0.0;
    return (totalSpentRials / totalBudgetRials).clamp(0.0, 1.0);
  }

  /// میانگین هزینه هر تسک مالی به ریال
  int get averagePerFinancialTaskRials {
    if (financialTasksCount <= 0) return 0;
    return totalSpentRials ~/ financialTasksCount;
  }

  /// فرمت کردن عدد ریالی با جداکننده سه‌رقمی و ارقام فارسی (مثال: ۱۲,۰۰۰,۰۰۰ ریال)
  static String formatRials(int amountRials) {
    final isNegative = amountRials < 0;
    final absStr = amountRials.abs().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < absStr.length; i++) {
      if (i > 0 && (absStr.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(absStr[i]);
    }
    final formatted = isNegative ? '-${buffer.toString()}' : buffer.toString();
    return toPersianDigits('$formatted ریال');
  }

  @override
  List<Object?> get props => [
        totalBudgetRials,
        totalSpentRials,
        todaySpentRials,
        completedTasksSpentRials,
        pendingTasksSpentRials,
        financialTasksCount,
        taskFlows,
      ];
}
