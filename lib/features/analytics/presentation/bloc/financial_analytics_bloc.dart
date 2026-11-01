import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/features/analytics/domain/entities/rial_financial_summary_entity.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_event.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_state.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_tasks_usecase.dart';

/// کنترلر مستقل تحلیل مالی بر پایه معماری CQRS و واحد پولی ریال (IRR).
///
/// این BLoC تسک‌های دارای تراکنش مالی را از سایر تسک‌ها تفکیک کرده و تمامی
/// محاسبات بودجه، جریان نقدی و سهم هزینه‌ها را صرفاً بر پایه ریال (۱ تومان = ۱۰ ریال) انجام می‌دهد.
class FinancialAnalyticsBloc
    extends Bloc<FinancialAnalyticsEvent, FinancialAnalyticsState> {
  final GetTasksUseCase? _getTasksUseCase;
  List<TaskEntity> _cachedTasks = const <TaskEntity>[];

  FinancialAnalyticsBloc({
    GetTasksUseCase? getTasksUseCase,
  })  : _getTasksUseCase = getTasksUseCase,
        super(const FinancialAnalyticsState()) {
    on<FinancialAnalyticsLoadRequested>(_onLoadRequested);
    on<FinancialAnalyticsTasksProjected>(_onTasksProjected);
    on<FinancialAnalyticsBudgetChanged>(_onBudgetChanged);
    on<FinancialAnalyticsBudgetAdjusted>(_onBudgetAdjusted);
  }

  Future<void> _onLoadRequested(
    FinancialAnalyticsLoadRequested event,
    Emitter<FinancialAnalyticsState> emit,
  ) async {
    final useCase = _getTasksUseCase;
    if (useCase == null) {
      final projected = projectRialSummary(
        tasks: _cachedTasks,
        budgetRials: state.summary.totalBudgetRials,
      );
      emit(
        state.copyWith(
          status: FinancialAnalyticsStatus.success,
          summary: projected,
          failure: () => null,
        ),
      );
      return;
    }

    emit(state.copyWith(status: FinancialAnalyticsStatus.loading));
    final result = await useCase(const GetTasksParams());
    result.fold(
      onSuccess: (tasks) {
        _cachedTasks = tasks;
        final summary = projectRialSummary(
          tasks: tasks,
          budgetRials: state.summary.totalBudgetRials,
        );
        emit(
          state.copyWith(
            status: FinancialAnalyticsStatus.success,
            summary: summary,
            failure: () => null,
          ),
        );
      },
      onFailure: (f) => emit(
        state.copyWith(
          status: FinancialAnalyticsStatus.failure,
          failure: () => f,
        ),
      ),
    );
  }

  void _onTasksProjected(
    FinancialAnalyticsTasksProjected event,
    Emitter<FinancialAnalyticsState> emit,
  ) {
    _cachedTasks = event.tasks;
    final budget = event.customBudgetRials ?? state.summary.totalBudgetRials;
    final summary = projectRialSummary(
      tasks: event.tasks,
      budgetRials: budget,
    );
    emit(
      state.copyWith(
        status: FinancialAnalyticsStatus.success,
        summary: summary,
        failure: () => null,
      ),
    );
  }

  void _onBudgetChanged(
    FinancialAnalyticsBudgetChanged event,
    Emitter<FinancialAnalyticsState> emit,
  ) {
    final sanitizedBudget = event.newBudgetRials < 0 ? 0 : event.newBudgetRials;
    final summary = projectRialSummary(
      tasks: _cachedTasks,
      budgetRials: sanitizedBudget,
    );
    emit(
      state.copyWith(
        status: FinancialAnalyticsStatus.success,
        summary: summary,
        failure: () => null,
      ),
    );
  }

  void _onBudgetAdjusted(
    FinancialAnalyticsBudgetAdjusted event,
    Emitter<FinancialAnalyticsState> emit,
  ) {
    final currentBudget = state.summary.totalBudgetRials;
    final updatedBudget =
        (currentBudget + event.deltaRials).clamp(0, 999999999999);
    final summary = state.summary.copyWith(totalBudgetRials: updatedBudget);
    emit(
      state.copyWith(
        status: FinancialAnalyticsStatus.success,
        summary: summary,
        failure: () => null,
      ),
    );
  }


  /// متد خالص (Pure Projection) برای جداسازی تسک‌های مالی و محاسبه شاخص‌ها به ریال
  static RialFinancialSummaryEntity projectRialSummary({
    required List<TaskEntity> tasks,
    int budgetRials = RialFinancialSummaryEntity.defaultMonthlyBudgetRials,
  }) {
    final financialTasks = tasks
        .where((task) => task.totalExpenses.amountMinorUnits > 0)
        .toList(growable: false);

    int totalSpentRials = 0;
    int todaySpentRials = 0;
    int completedSpentRials = 0;
    int pendingSpentRials = 0;

    for (final task in financialTasks) {
      final taskRials = task.totalExpenses.amountMinorUnits *
          RialFinancialSummaryEntity.tomanToRialMultiplier;
      totalSpentRials += taskRials;

      if (task.isScheduledForToday) {
        todaySpentRials += taskRials;
      }
      if (task.status == TaskStatus.done) {
        completedSpentRials += taskRials;
      } else {
        pendingSpentRials += taskRials;
      }
    }

    final sortedFinancialTasks = List<TaskEntity>.of(financialTasks)
      ..sort(
        (a, b) => b.totalExpenses.amountMinorUnits
            .compareTo(a.totalExpenses.amountMinorUnits),
      );

    final flows = sortedFinancialTasks.map((task) {
      final taskRials = task.totalExpenses.amountMinorUnits *
          RialFinancialSummaryEntity.tomanToRialMultiplier;
      final share = totalSpentRials > 0
          ? (taskRials / totalSpentRials).clamp(0.0, 1.0)
          : 0.0;
      return RialTaskFlowItem(
        entityTaskId: task.id,
        title: task.title,
        amountRials: taskRials,
        isCompleted: task.status == TaskStatus.done,
        shareRatio: share,
      );
    }).toList(growable: false);

    return RialFinancialSummaryEntity(
      totalBudgetRials: budgetRials,
      totalSpentRials: totalSpentRials,
      todaySpentRials: todaySpentRials,
      completedTasksSpentRials: completedSpentRials,
      pendingTasksSpentRials: pendingSpentRials,
      financialTasksCount: financialTasks.length,
      taskFlows: flows,
    );
  }
}
