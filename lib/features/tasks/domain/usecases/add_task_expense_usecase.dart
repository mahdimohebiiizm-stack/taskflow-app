import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/expense_item_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

/// Validates and records a new [ExpenseItemEntity] on a [TaskEntity].
class AddTaskExpenseUseCase
    implements UseCase<TaskEntity, AddTaskExpenseParams> {
  final TaskRepository _repository;

  const AddTaskExpenseUseCase(this._repository);

  @override
  Future<Result<TaskEntity, Failure>> call(AddTaskExpenseParams params) async {
    final moneyResult = Money.create(
      amountMinorUnits: params.amountMinorUnits,
      currency: params.currency,
    );

    return switch (moneyResult) {
      Err<Money, DomainFailure>(failure: final f) => Err(f),
      Success<Money, DomainFailure>(value: final validMoney) =>
        await _createAndAttachExpense(validMoney, params),
    };
  }

  Future<Result<TaskEntity, Failure>> _createAndAttachExpense(
    Money validMoney,
    AddTaskExpenseParams params,
  ) async {
    final timestamp = params.incurredAt ?? DateTime.now().toUtc();
    final expenseResult = ExpenseItemEntity.create(
      id: params.expenseId,
      title: params.title,
      money: validMoney,
      incurredAt: timestamp,
    );

    return switch (expenseResult) {
      Err<ExpenseItemEntity, DomainFailure>(failure: final f) => Err(f),
      Success<ExpenseItemEntity, DomainFailure>(value: final validExpense) =>
        await _persistOnTask(validExpense, params.taskId, timestamp),
    };
  }

  Future<Result<TaskEntity, Failure>> _persistOnTask(
    ExpenseItemEntity validExpense,
    String taskId,
    DateTime timestamp,
  ) async {
    final taskResult = await _repository.getTaskById(taskId);

    return switch (taskResult) {
      Err<TaskEntity, Failure>(failure: final f) => Err(f),
      Success<TaskEntity, Failure>(value: final existingTask) =>
        switch (existingTask.addExpense(validExpense, updatedAt: timestamp)) {
          Err<TaskEntity, DomainFailure>(failure: final f) => Err(f),
          Success<TaskEntity, DomainFailure>(value: final updatedTask) =>
            await _repository.saveTask(updatedTask),
        },
    };
  }
}

class AddTaskExpenseParams extends Equatable {
  final String taskId;
  final String expenseId;
  final String title;
  final int amountMinorUnits;
  final Currency currency;
  final DateTime? incurredAt;

  const AddTaskExpenseParams({
    required this.taskId,
    required this.expenseId,
    required this.title,
    required this.amountMinorUnits,
    required this.currency,
    this.incurredAt,
  });

  @override
  List<Object?> get props => [
        taskId,
        expenseId,
        title,
        amountMinorUnits,
        currency,
        incurredAt,
      ];
}
