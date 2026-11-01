import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/expense_item_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/sub_task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

/// Validates domain invariants and persists a new [TaskEntity] via [TaskRepository].
class CreateTaskUseCase implements UseCase<TaskEntity, CreateTaskParams> {
  final TaskRepository _repository;

  const CreateTaskUseCase(this._repository);

  @override
  Future<Result<TaskEntity, Failure>> call(CreateTaskParams params) async {
    final creationResult = TaskEntity.create(
      id: params.id,
      title: params.title,
      description: params.description,
      status: params.status,
      priority: params.priority,
      dueDate: params.dueDate,
      startTime: params.startTime,
      endTime: params.endTime,
      isPenalized: params.isPenalized,
      parentTaskId: params.parentTaskId,
      workspaceId: params.workspaceId,
      tags: params.tags,
      sortOrder: params.sortOrder,
      recurrenceRule: params.recurrenceRule,
      reminderDateTime: params.reminderDateTime,
      subTasks: params.subTasks,
      expenses: params.expenses,
      createdAt: params.createdAt ?? DateTime.now().toUtc(),
    );

    return switch (creationResult) {
      Err<TaskEntity, DomainFailure>(failure: final domainFailure) =>
        Err(domainFailure),
      Success<TaskEntity, DomainFailure>(value: final validTask) =>
        await _repository.saveTask(validTask),
    };
  }
}

class CreateTaskParams extends Equatable {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? startTime;
  final String? endTime;
  final bool isPenalized;
  final String? parentTaskId;
  final String workspaceId;
  final List<String> tags;
  final int sortOrder;
  final String? recurrenceRule;
  final DateTime? reminderDateTime;
  final List<SubTaskEntity> subTasks;
  final List<ExpenseItemEntity> expenses;
  final DateTime? createdAt;

  const CreateTaskParams({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.startTime,
    this.endTime,
    this.isPenalized = false,
    this.parentTaskId,
    this.workspaceId = TaskWorkspaces.defaultWorkspace,
    this.tags = const [],
    this.sortOrder = 0,
    this.recurrenceRule,
    this.reminderDateTime,
    this.subTasks = const [],
    this.expenses = const [],
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        priority,
        dueDate,
        startTime,
        endTime,
        isPenalized,
        parentTaskId,
        workspaceId,
        tags,
        sortOrder,
        recurrenceRule,
        reminderDateTime,
        subTasks,
        expenses,
        createdAt,
      ];
}
