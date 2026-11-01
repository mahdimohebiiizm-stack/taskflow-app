import 'package:equatable/equatable.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

/// Base sealed class for all events dispatched to [TaskBloc].
sealed class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => const [];
}

/// Requests loading tasks from local persistence, optionally filtered by [statusFilter] and [scheduledDate].
final class TasksLoadRequested extends TaskEvent {
  final TaskStatus? statusFilter;
  final DateTime? scheduledDate;
  final bool preserveCurrentFilter;

  const TasksLoadRequested({
    this.statusFilter,
    this.scheduledDate,
    this.preserveCurrentFilter = false,
  });

  @override
  List<Object?> get props => [statusFilter, scheduledDate, preserveCurrentFilter];
}

/// Updates the active [TaskStatus] filter on the task board (null means "All").
final class TaskStatusFilterChanged extends TaskEvent {
  final TaskStatus? statusFilter;

  const TaskStatusFilterChanged(this.statusFilter);

  @override
  List<Object?> get props => [statusFilter];
}

/// Updates the active [scheduledDate] filter on the board (null means all dates).
final class TaskScheduledDateChanged extends TaskEvent {
  final DateTime? scheduledDate;

  const TaskScheduledDateChanged(this.scheduledDate);

  @override
  List<Object?> get props => [scheduledDate];
}

/// Updates the active workspace/folder filter (null or 'all' means all workspaces).
final class TaskWorkspaceFilterChanged extends TaskEvent {
  final String? workspaceId;

  const TaskWorkspaceFilterChanged(this.workspaceId);

  @override
  List<Object?> get props => [workspaceId];
}

/// Updates the active tag filter (null means all tags).
final class TaskTagFilterChanged extends TaskEvent {
  final String? tag;

  const TaskTagFilterChanged(this.tag);

  @override
  List<Object?> get props => [tag];
}

/// Requests manual Drag & Drop reordering of tasks in the list.
final class TasksReordered extends TaskEvent {
  final int oldIndex;
  final int newIndex;

  const TasksReordered({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// Requests creating a new task along with its optional 1-level sub-task titles,
/// hierarchical [parentTaskId], [workspaceId], [tags], [recurrenceRule], [reminderDateTime],
/// time block (start/end time), and optional initial expense in integer minor units.
final class TaskCreated extends TaskEvent {
  final String? id;
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? startTime;
  final String? endTime;
  final String? parentTaskId;
  final String workspaceId;
  final List<String> tags;
  final int sortOrder;
  final String? recurrenceRule;
  final DateTime? reminderDateTime;
  final List<String> subTaskTitles;
  final int? initialExpenseMinorUnits;
  final Currency initialExpenseCurrency;
  final DateTime? createdAt;

  const TaskCreated({
    this.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.startTime,
    this.endTime,
    this.parentTaskId,
    this.workspaceId = TaskWorkspaces.defaultWorkspace,
    this.tags = const [],
    this.sortOrder = 0,
    this.recurrenceRule,
    this.reminderDateTime,
    this.subTaskTitles = const [],
    this.initialExpenseMinorUnits,
    this.initialExpenseCurrency = Currency.irt,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        priority,
        dueDate,
        startTime,
        endTime,
        parentTaskId,
        workspaceId,
        tags,
        sortOrder,
        recurrenceRule,
        reminderDateTime,
        subTaskTitles,
        initialExpenseMinorUnits,
        initialExpenseCurrency,
        createdAt,
      ];
}

/// Requests concluding the active day: marks all uncompleted tasks for today as penalized.
final class DayEnded extends TaskEvent {
  final DateTime? timestamp;

  const DayEnded({this.timestamp});

  @override
  List<Object?> get props => [timestamp];
}

/// Requests transitioning an existing task to [targetStatus].
final class TaskStatusTransitioned extends TaskEvent {
  final String taskId;
  final TaskStatus targetStatus;
  final DateTime? timestamp;

  const TaskStatusTransitioned({
    required this.taskId,
    required this.targetStatus,
    this.timestamp,
  });

  @override
  List<Object?> get props => [taskId, targetStatus, timestamp];
}

/// Requests toggling the completion state of a child sub-task.
final class SubTaskToggled extends TaskEvent {
  final String taskId;
  final String subTaskId;
  final DateTime? timestamp;

  const SubTaskToggled({
    required this.taskId,
    required this.subTaskId,
    this.timestamp,
  });

  @override
  List<Object?> get props => [taskId, subTaskId, timestamp];
}

/// Requests deleting a task and cascading deletion to its child sub-tasks and expenses.
final class TaskDeleted extends TaskEvent {
  final String taskId;

  const TaskDeleted({required this.taskId});

  @override
  List<Object?> get props => [taskId];
}

/// Requests adding a new financial expense item to a task using integer minor units.
final class TaskExpenseAdded extends TaskEvent {
  final String taskId;
  final String? expenseId;
  final String title;
  final int amountMinorUnits;
  final Currency currency;
  final DateTime? incurredAt;

  const TaskExpenseAdded({
    required this.taskId,
    this.expenseId,
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

/// Requests undoing the most recent day ended action within the grace period (e.g. 5s).
final class DayEndedUndone extends TaskEvent {
  final List<String>? taskIds;
  final DateTime? timestamp;

  const DayEndedUndone({this.taskIds, this.timestamp});

  @override
  List<Object?> get props => [taskIds, timestamp];
}

/// Clears the transient failure state after the UI has acknowledged/displayed it.
final class TaskErrorCleared extends TaskEvent {
  const TaskErrorCleared();
}

/// Updates the active Vacation Mode status on [TaskBloc] so nightly penalties are bypassed.
final class TaskVacationModeChanged extends TaskEvent {
  final bool isVacationMode;

  const TaskVacationModeChanged(this.isVacationMode);

  @override
  List<Object?> get props => [isVacationMode];
}

/// Requests editing an existing task's title, description, priority, due date, or time block.
final class TaskEdited extends TaskEvent {
  final String taskId;
  final String title;
  final String? description;
  final TaskPriority? priority;
  final DateTime? dueDate;
  final String? startTime;
  final String? endTime;
  final String? workspaceId;
  final List<String>? tags;
  final bool clearTimeBlock;

  const TaskEdited({
    required this.taskId,
    required this.title,
    this.description,
    this.priority,
    this.dueDate,
    this.startTime,
    this.endTime,
    this.workspaceId,
    this.tags,
    this.clearTimeBlock = false,
  });

  @override
  List<Object?> get props => [
        taskId,
        title,
        description,
        priority,
        dueDate,
        startTime,
        endTime,
        workspaceId,
        tags,
        clearTimeBlock,
      ];
}

/// Requests rescheduling an existing task to a new due date (e.g. today, tomorrow, or custom date).
final class TaskRescheduled extends TaskEvent {
  final String taskId;
  final DateTime newDueDate;

  const TaskRescheduled({
    required this.taskId,
    required this.newDueDate,
  });

  @override
  List<Object?> get props => [taskId, newDueDate];
}

/// Triggered periodically or on app resume to proactively detect tasks that transitioned to overdue.
final class TaskOverdueCheckRequested extends TaskEvent {
  final DateTime? timestamp;

  const TaskOverdueCheckRequested({this.timestamp});

  @override
  List<Object?> get props => [timestamp];
}


