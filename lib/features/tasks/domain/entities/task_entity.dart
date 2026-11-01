import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/expense_item_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/entities/sub_task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

/// شناسه‌ها و برچسب‌های استاندارد فضاهای کاری (Workspaces / Folders)
final class TaskWorkspaces {
  static const String all = 'all';
  static const String defaultWorkspace = 'default';
  static const String personal = 'personal';
  static const String work = 'work';
  static const String financial = 'financial';

  static const List<String> allFilterOrder = <String>[
    all,
    defaultWorkspace,
    personal,
    work,
    financial,
  ];

  static const List<String> selectableWorkspaces = <String>[
    defaultWorkspace,
    personal,
    work,
    financial,
  ];

  static String labelFa(String workspaceId) {
    return switch (workspaceId.trim().toLowerCase()) {
      all => 'همه',
      personal => 'شخصی',
      work => 'کاری',
      financial => 'مالی',
      _ => 'عمومی',
    };
  }
}

/// قواعد تکرار استاندارد برای تسک‌های تکرارشونده (Recurring Tasks)
final class TaskRecurrenceRules {
  static const String none = 'none';
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';

  static const List<String> selectableRules = <String>[
    none,
    daily,
    weekly,
    monthly,
  ];

  static String? normalize(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim().toLowerCase();
    if (cleaned.isEmpty || cleaned == none) return null;
    return switch (cleaned) {
      daily => daily,
      weekly => weekly,
      monthly => monthly,
      _ => null,
    };
  }

  static String labelFa(String? rule) {
    return switch (normalize(rule)) {
      daily => 'روزانه',
      weekly => 'هفتگی',
      monthly => 'ماهانه',
      _ => 'بدون تکرار',
    };
  }

  static DateTime advanceDateByRule(DateTime base, String rule) {
    final normalized = normalize(rule);
    return switch (normalized) {
      daily => DateTime(
          base.year,
          base.month,
          base.day + 1,
          base.hour,
          base.minute,
          base.second,
          base.millisecond,
        ),
      weekly => DateTime(
          base.year,
          base.month,
          base.day + 7,
          base.hour,
          base.minute,
          base.second,
          base.millisecond,
        ),
      monthly => _addOneMonthClamped(base),
      _ => base,
    };
  }

  static DateTime _addOneMonthClamped(DateTime base) {
    final targetYear = base.month == 12 ? base.year + 1 : base.year;
    final targetMonth = base.month == 12 ? 1 : base.month + 1;
    final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final clampedDay =
        base.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : base.day;
    return DateTime(
      targetYear,
      targetMonth,
      clampedDay,
      base.hour,
      base.minute,
      base.second,
      base.millisecond,
    );
  }
}

/// Aggregate Root representing a Task, its 1-level [SubTaskEntity] collection,
/// hierarchical tree link ([parentTaskId]), workspace/category ([workspaceId]),
/// [tags], manual [sortOrder], [recurrenceRule], [reminderDateTime], and
/// multi-line [ExpenseItemEntity] financial records.
///
/// Encapsulates all domain invariants so that invalid state transitions or
/// invalid financial calculations are impossible across the application.
class TaskEntity extends Equatable {
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
  final UnmodifiableListView<String> tags;
  final int sortOrder;
  final String? recurrenceRule;
  final DateTime? reminderDateTime;
  final UnmodifiableListView<SubTaskEntity> subTasks;
  final UnmodifiableListView<ExpenseItemEntity> expenses;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskEntity._({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.dueDate,
    this.startTime,
    this.endTime,
    this.isPenalized = false,
    this.parentTaskId,
    this.workspaceId = TaskWorkspaces.defaultWorkspace,
    required this.tags,
    this.sortOrder = 0,
    this.recurrenceRule,
    this.reminderDateTime,
    required this.subTasks,
    required this.expenses,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory method that validates all domain invariants before instantiating a [TaskEntity].
  static Result<TaskEntity, DomainFailure> create({
    required String id,
    required String title,
    String description = '',
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    String? startTime,
    String? endTime,
    bool isPenalized = false,
    String? parentTaskId,
    String workspaceId = TaskWorkspaces.defaultWorkspace,
    List<String> tags = const [],
    int sortOrder = 0,
    String? recurrenceRule,
    DateTime? reminderDateTime,
    List<SubTaskEntity> subTasks = const [],
    List<ExpenseItemEntity> expenses = const [],
    required DateTime createdAt,
    DateTime? updatedAt,
  }) {
    final trimmedId = id.trim();
    final trimmedTitle = title.trim();

    if (trimmedId.isEmpty) {
      return const Err(
        ValidationFailure(message: 'Task ID cannot be empty.'),
      );
    }

    if (trimmedTitle.isEmpty) {
      return const Err(
        ValidationFailure(message: 'Task title cannot be empty.'),
      );
    }

    final normalizedParentId =
        (parentTaskId != null && parentTaskId.trim().isNotEmpty)
            ? parentTaskId.trim()
            : null;
    if (normalizedParentId == trimmedId) {
      return const Err(
        ValidationFailure(message: 'Task cannot be its own parent.'),
      );
    }

    final normalizedWorkspace = workspaceId.trim().isEmpty
        ? TaskWorkspaces.defaultWorkspace
        : workspaceId.trim();

    final normalizedTags = tags
        .map((t) => t.trim().replaceAll('#', ''))
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList(growable: false);

    final normalizedRecurrence = TaskRecurrenceRules.normalize(recurrenceRule);

    final incompleteCount =
        subTasks.where((subTask) => !subTask.isCompleted).length;

    if (status == TaskStatus.done && incompleteCount > 0) {
      return Err(
        IncompleteSubTasksFailure(remainingSubTasks: incompleteCount),
      );
    }

    return Success(
      TaskEntity._(
        id: trimmedId,
        title: trimmedTitle,
        description: description.trim(),
        status: status,
        priority: priority,
        dueDate: dueDate,
        startTime: startTime?.trim(),
        endTime: endTime?.trim(),
        isPenalized: isPenalized,
        parentTaskId: normalizedParentId,
        workspaceId: normalizedWorkspace,
        tags: UnmodifiableListView(normalizedTags),
        sortOrder: sortOrder,
        recurrenceRule: normalizedRecurrence,
        reminderDateTime: reminderDateTime,
        subTasks: UnmodifiableListView(List<SubTaskEntity>.of(subTasks)),
        expenses: UnmodifiableListView(List<ExpenseItemEntity>.of(expenses)),
        createdAt: createdAt,
        updatedAt: updatedAt ?? createdAt,
      ),
    );
  }

  /// Reconstitutes a [TaskEntity] from persistent storage.
  factory TaskEntity.reconstitute({
    required String id,
    required String title,
    required String description,
    required TaskStatus status,
    required TaskPriority priority,
    required DateTime? dueDate,
    String? startTime,
    String? endTime,
    bool isPenalized = false,
    String? parentTaskId,
    String workspaceId = TaskWorkspaces.defaultWorkspace,
    List<String> tags = const [],
    int sortOrder = 0,
    String? recurrenceRule,
    DateTime? reminderDateTime,
    required List<SubTaskEntity> subTasks,
    List<ExpenseItemEntity> expenses = const [],
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final normalizedParentId =
        (parentTaskId != null && parentTaskId.trim().isNotEmpty)
            ? parentTaskId.trim()
            : null;
    final normalizedWorkspace = workspaceId.trim().isEmpty
        ? TaskWorkspaces.defaultWorkspace
        : workspaceId.trim();
    final normalizedTags = tags
        .map((t) => t.trim().replaceAll('#', ''))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    final normalizedRecurrence = TaskRecurrenceRules.normalize(recurrenceRule);

    return TaskEntity._(
      id: id,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: dueDate,
      startTime: startTime,
      endTime: endTime,
      isPenalized: isPenalized,
      parentTaskId: normalizedParentId,
      workspaceId: normalizedWorkspace,
      tags: UnmodifiableListView(normalizedTags),
      sortOrder: sortOrder,
      recurrenceRule: normalizedRecurrence,
      reminderDateTime: reminderDateTime,
      subTasks: UnmodifiableListView(List<SubTaskEntity>.of(subTasks)),
      expenses: UnmodifiableListView(List<ExpenseItemEntity>.of(expenses)),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// True if this task has an active recurrence rule (`daily`, `weekly`, `monthly`).
  bool get hasRecurrence =>
      recurrenceRule != null && recurrenceRule!.trim().isNotEmpty;

  /// Persian display label for this task's recurrence rule.
  String get recurrenceLabelFa => TaskRecurrenceRules.labelFa(recurrenceRule);

  /// Computes the next occurrence's dueDate when a recurring task is completed.
  DateTime? computeNextDueDate({DateTime? referenceDate}) {
    if (!hasRecurrence) return null;
    final base = (dueDate ?? referenceDate ?? createdAt).toLocal();
    return TaskRecurrenceRules.advanceDateByRule(base, recurrenceRule!);
  }

  /// Computes the next occurrence's reminderDateTime when a recurring task is completed.
  DateTime? computeNextReminderDateTime() {
    if (!hasRecurrence || reminderDateTime == null) return null;
    return TaskRecurrenceRules.advanceDateByRule(
      reminderDateTime!.toLocal(),
      recurrenceRule!,
    );
  }

  /// True if this task is nested under another parent task (`parentTaskId != null`).
  bool get isNestedSubTask =>
      parentTaskId != null && parentTaskId!.trim().isNotEmpty;

  /// Persian display label for this task's workspace/folder.
  String get workspaceLabelFa => TaskWorkspaces.labelFa(workspaceId);

  /// Number of sub-tasks that are still incomplete (`isCompleted == false`).
  int get incompleteSubTasksCount =>
      subTasks.where((subTask) => !subTask.isCompleted).length;

  /// Number of completed sub-tasks (`isCompleted == true`).
  int get completedSubTasksCount =>
      subTasks.where((subTask) => subTask.isCompleted).length;

  /// True if at least one child [SubTaskEntity] is incomplete.
  bool get hasIncompleteSubTasks => incompleteSubTasksCount > 0;

  /// True if this task has one or more financial expenses attached.
  bool get isFinancialTask =>
      expenses.isNotEmpty || workspaceId == TaskWorkspaces.financial;

  /// Normalized completion ratio in `[0.0, 1.0]`.
  /// If there are no sub-tasks, returns `1.0` when [TaskStatus.done] and `0.0` otherwise.
  double get completionProgress {
    if (subTasks.isEmpty) {
      return status == TaskStatus.done ? 1.0 : 0.0;
    }
    return completedSubTasksCount / subTasks.length;
  }

  /// True if a task is an all-day task (no specific start or end time-block assigned).
  bool get isAllDay =>
      (startTime == null || startTime!.trim().isEmpty) &&
      (endTime == null || endTime!.trim().isEmpty);

  /// Computes the exact end moment of this task, accurately handling time-blocks that cross midnight.
  DateTime? get scheduledEndDateTime {
    final base = (dueDate ?? createdAt).toLocal();
    final startMin = startTimeMinutes;
    final endMin = endTimeMinutes;

    if (startMin != null && endMin != null) {
      final endHour = endMin ~/ 60;
      final endMinute = endMin % 60;
      if (endMin < startMin) {
        return DateTime(base.year, base.month, base.day + 1, endHour, endMinute);
      } else {
        return DateTime(base.year, base.month, base.day, endHour, endMinute);
      }
    }

    if (endMin != null) {
      final endHour = endMin ~/ 60;
      final endMinute = endMin % 60;
      return DateTime(base.year, base.month, base.day, endHour, endMinute);
    }

    if (startMin != null) {
      final startHour = startMin ~/ 60;
      final startMinute = startMin % 60;
      return DateTime(base.year, base.month, base.day, startHour, startMinute);
    }

    // All-day task without explicit time-block ends at 23:59:59.999 of the scheduled date
    return DateTime(base.year, base.month, base.day, 23, 59, 59, 999);
  }

  /// Evaluates whether the task is past its [scheduledEndDateTime] and not yet [TaskStatus.done].
  /// When [isVacationMode] is active, tasks and routines are never considered overdue.
  /// If a task is [isAllDay], it is ONLY overdue if [referenceTime] is strictly past 23:59:59 of its scheduled date.
  bool isOverdue(DateTime referenceTime, {bool isVacationMode = false}) {
    if (isVacationMode || status == TaskStatus.done) {
      return false;
    }
    final ref = referenceTime.toLocal();
    if (isAllDay) {
      final base = (dueDate ?? createdAt).toLocal();
      final endOfDay = DateTime(base.year, base.month, base.day, 23, 59, 59, 999);
      return ref.isAfter(endOfDay);
    }
    final end = scheduledEndDateTime;
    if (end == null) {
      return false;
    }
    return ref.isAfter(end);
  }

  /// Checks whether this task is scheduled for the specified calendar [date].
  bool isScheduledForDate(DateTime date) {
    final effective = (dueDate ?? createdAt).toLocal();
    final target = date.toLocal();
    return effective.year == target.year &&
        effective.month == target.month &&
        effective.day == target.day;
  }

  /// True if a valid time block (`startTime` and `endTime`) is defined.
  bool get hasTimeBlock =>
      startTime != null &&
      startTime!.trim().isNotEmpty &&
      endTime != null &&
      endTime!.trim().isNotEmpty;

  /// Human-readable time block string (e.g. "07:30 - 09:00").
  String? get timeBlockFormatted =>
      hasTimeBlock ? '${startTime!.trim()} - ${endTime!.trim()}' : null;

  /// Returns start time parsed as minutes from midnight for deterministic ordering.
  int? get startTimeMinutes {
    final raw = startTime?.trim();
    if (raw == null || !raw.contains(':')) return null;
    final parts = raw.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// Returns end time parsed as minutes from midnight.
  int? get endTimeMinutes {
    final raw = endTime?.trim();
    if (raw == null || !raw.contains(':')) return null;
    final parts = raw.split(':');
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// Marks this task as penalized when overdue or uncompleted at end of day.
  TaskEntity penalize({required DateTime updatedAt}) {
    return TaskEntity._(
      id: id,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: dueDate,
      startTime: startTime,
      endTime: endTime,
      isPenalized: true,
      parentTaskId: parentTaskId,
      workspaceId: workspaceId,
      tags: tags,
      sortOrder: sortOrder,
      recurrenceRule: recurrenceRule,
      reminderDateTime: reminderDateTime,
      subTasks: subTasks,
      expenses: expenses,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Rolls over (extends) an unfinished task/habit to [targetDate] without any penalty (`isPenalized: false`),
  /// used during Vacation Mode so routine tasks and habits are never marked overdue or penalized.
  TaskEntity rollOverToDate(
    DateTime targetDate, {
    required DateTime updatedAt,
  }) {
    final base = (dueDate ?? createdAt).toLocal();
    final extendedDueDate = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      base.hour,
      base.minute,
      base.second,
    );
    final extendedReminder = reminderDateTime == null
        ? null
        : DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
            reminderDateTime!.hour,
            reminderDateTime!.minute,
            reminderDateTime!.second,
          );
    return TaskEntity._(
      id: id,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: extendedDueDate,
      startTime: startTime,
      endTime: endTime,
      isPenalized: false,
      parentTaskId: parentTaskId,
      workspaceId: workspaceId,
      tags: tags,
      sortOrder: sortOrder,
      recurrenceRule: recurrenceRule,
      reminderDateTime: extendedReminder,
      subTasks: subTasks,
      expenses: expenses,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Updates manual sort order or workspace/tag metadata.
  TaskEntity withSortOrder(int newSortOrder, {required DateTime updatedAt}) {
    return TaskEntity._(
      id: id,
      title: title,
      description: description,
      status: status,
      priority: priority,
      dueDate: dueDate,
      startTime: startTime,
      endTime: endTime,
      isPenalized: isPenalized,
      parentTaskId: parentTaskId,
      workspaceId: workspaceId,
      tags: tags,
      sortOrder: newSortOrder,
      recurrenceRule: recurrenceRule,
      reminderDateTime: reminderDateTime,
      subTasks: subTasks,
      expenses: expenses,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Evaluates whether this task is scheduled for today.
  bool get isScheduledForToday => isScheduledForDate(DateTime.now());

  /// Transitions the task to [targetStatus] while enforcing Domain Invariant Option C.
  Result<TaskEntity, DomainFailure> transitionStatus(
    TaskStatus targetStatus, {
    required DateTime updatedAt,
  }) {
    if (targetStatus == status) {
      return Success(this);
    }

    if (targetStatus == TaskStatus.done && hasIncompleteSubTasks) {
      return Err(
        IncompleteSubTasksFailure(remainingSubTasks: incompleteSubTasksCount),
      );
    }

    return Success(
      TaskEntity._(
        id: id,
        title: title,
        description: description,
        status: targetStatus,
        priority: priority,
        dueDate: dueDate,
        startTime: startTime,
        endTime: endTime,
        isPenalized: isPenalized,
        parentTaskId: parentTaskId,
        workspaceId: workspaceId,
        tags: tags,
        sortOrder: sortOrder,
        recurrenceRule: recurrenceRule,
        reminderDateTime: reminderDateTime,
        subTasks: subTasks,
        expenses: expenses,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
  }

  /// Toggles the completion state of a child [SubTaskEntity] by [subTaskId].
  Result<TaskEntity, DomainFailure> toggleSubTask(
    String subTaskId, {
    required DateTime updatedAt,
  }) {
    final index = subTasks.indexWhere((s) => s.id == subTaskId);
    if (index == -1) {
      return Err(
        NotFoundFailure(
          entityId: subTaskId,
          message: 'SubTask with ID "$subTaskId" was not found in task "$id".',
        ),
      );
    }

    final updatedList = List<SubTaskEntity>.of(subTasks);
    final toggledSubTask = updatedList[index].toggle();
    updatedList[index] = toggledSubTask;

    final nextStatus =
        (status == TaskStatus.done && !toggledSubTask.isCompleted)
            ? TaskStatus.inProgress
            : status;

    return Success(
      TaskEntity._(
        id: id,
        title: title,
        description: description,
        status: nextStatus,
        priority: priority,
        dueDate: dueDate,
        startTime: startTime,
        endTime: endTime,
        isPenalized: isPenalized,
        parentTaskId: parentTaskId,
        workspaceId: workspaceId,
        tags: tags,
        sortOrder: sortOrder,
        recurrenceRule: recurrenceRule,
        reminderDateTime: reminderDateTime,
        subTasks: UnmodifiableListView(updatedList),
        expenses: expenses,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
  }

  /// Appends a new [SubTaskEntity] to this task.
  Result<TaskEntity, DomainFailure> addSubTask(
    SubTaskEntity subTask, {
    required DateTime updatedAt,
  }) {
    final duplicateExists =
        subTasks.any((existing) => existing.id == subTask.id);
    if (duplicateExists) {
      return Err(
        ValidationFailure(
          message:
              'SubTask with ID "${subTask.id}" already exists in task "$id".',
        ),
      );
    }

    final updatedList = List<SubTaskEntity>.of(subTasks)..add(subTask);
    final nextStatus = (status == TaskStatus.done && !subTask.isCompleted)
        ? TaskStatus.inProgress
        : status;

    return Success(
      TaskEntity._(
        id: id,
        title: title,
        description: description,
        status: nextStatus,
        priority: priority,
        dueDate: dueDate,
        startTime: startTime,
        endTime: endTime,
        isPenalized: isPenalized,
        parentTaskId: parentTaskId,
        workspaceId: workspaceId,
        tags: tags,
        sortOrder: sortOrder,
        recurrenceRule: recurrenceRule,
        reminderDateTime: reminderDateTime,
        subTasks: UnmodifiableListView(updatedList),
        expenses: expenses,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
  }

  /// Appends a new [ExpenseItemEntity] to this task's financial ledger.
  Result<TaskEntity, DomainFailure> addExpense(
    ExpenseItemEntity expense, {
    required DateTime updatedAt,
  }) {
    final duplicateExists =
        expenses.any((existing) => existing.id == expense.id);
    if (duplicateExists) {
      return Err(
        ValidationFailure(
          message:
              'Expense with ID "${expense.id}" already exists in task "$id".',
        ),
      );
    }

    final updatedExpenses = List<ExpenseItemEntity>.of(expenses)..add(expense);

    return Success(
      TaskEntity._(
        id: id,
        title: title,
        description: description,
        status: status,
        priority: priority,
        dueDate: dueDate,
        startTime: startTime,
        endTime: endTime,
        isPenalized: isPenalized,
        parentTaskId: parentTaskId,
        workspaceId: workspaceId,
        tags: tags,
        sortOrder: sortOrder,
        recurrenceRule: recurrenceRule,
        reminderDateTime: reminderDateTime,
        subTasks: subTasks,
        expenses: UnmodifiableListView(updatedExpenses),
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
  }

  /// Removes an [ExpenseItemEntity] by [expenseId] from this task.
  Result<TaskEntity, DomainFailure> removeExpense(
    String expenseId, {
    required DateTime updatedAt,
  }) {
    final index = expenses.indexWhere((e) => e.id == expenseId);
    if (index == -1) {
      return Err(
        NotFoundFailure(
          entityId: expenseId,
          message: 'Expense with ID "$expenseId" was not found in task "$id".',
        ),
      );
    }

    final updatedExpenses = List<ExpenseItemEntity>.of(expenses)
      ..removeAt(index);

    return Success(
      TaskEntity._(
        id: id,
        title: title,
        description: description,
        status: status,
        priority: priority,
        dueDate: dueDate,
        startTime: startTime,
        endTime: endTime,
        isPenalized: isPenalized,
        parentTaskId: parentTaskId,
        workspaceId: workspaceId,
        tags: tags,
        sortOrder: sortOrder,
        recurrenceRule: recurrenceRule,
        reminderDateTime: reminderDateTime,
        subTasks: subTasks,
        expenses: UnmodifiableListView(updatedExpenses),
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
  }

  /// Computes the sum of all [expenses] directly in Toman using pure integer arithmetic.
  Result<Money, DomainFailure> totalExpensesInCurrency([
    Currency targetCurrency = Currency.irt,
    dynamic exchangeRates,
  ]) {
    var totalMinor = 0;
    for (final expense in expenses) {
      totalMinor += expense.money.amountMinorUnits;
    }
    return Success(
      Money.reconstitute(
        amountMinorUnits: totalMinor,
        currency: Currency.irt,
      ),
    );
  }

  /// Direct getter for total expenses in Toman.
  Money get totalExpenses {
    var totalMinor = 0;
    for (final expense in expenses) {
      totalMinor += expense.money.amountMinorUnits;
    }
    return Money.reconstitute(
      amountMinorUnits: totalMinor,
      currency: Currency.irt,
    );
  }

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
        updatedAt,
      ];
}
