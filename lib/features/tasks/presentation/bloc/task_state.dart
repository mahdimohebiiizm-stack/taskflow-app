import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

/// Represents the lifecycle status of asynchronous operations in [TaskBloc].
enum TaskViewStatus {
  initial,
  loading,
  success,
  failure,
}

/// Single Immutable State for [TaskBloc].
///
/// Preserves the loaded [tasks] list, [selectedFilter], [selectedWorkspaceId], and [selectedTag]
/// across state transitions so that domain validation errors never wipe or flicker the UI board.
class TaskState extends Equatable {
  final TaskViewStatus status;
  final UnmodifiableListView<TaskEntity> tasks;
  final UnmodifiableListView<String> lastPenalizedTaskIds;
  final UnmodifiableListView<String> notifiedOverdueTaskIds;
  final TaskStatus? selectedFilter;
  final DateTime? selectedDate;
  final String? selectedWorkspaceId;
  final String? selectedTag;
  final bool isVacationMode;
  final Failure? failure;

  TaskState({
    this.status = TaskViewStatus.initial,
    List<TaskEntity> tasks = const <TaskEntity>[],
    List<String> lastPenalizedTaskIds = const <String>[],
    List<String> notifiedOverdueTaskIds = const <String>[],
    this.selectedFilter,
    this.selectedDate,
    this.selectedWorkspaceId,
    this.selectedTag,
    this.isVacationMode = false,
    this.failure,
  })  : tasks = UnmodifiableListView(List<TaskEntity>.of(tasks)),
        lastPenalizedTaskIds =
            UnmodifiableListView(List<String>.of(lastPenalizedTaskIds)),
        notifiedOverdueTaskIds =
            UnmodifiableListView(List<String>.of(notifiedOverdueTaskIds));

  bool _matchesWorkspaceAndTag(TaskEntity task) {
    final ws = selectedWorkspaceId?.trim();
    if (ws != null && ws.isNotEmpty && ws != TaskWorkspaces.all) {
      if (task.workspaceId != ws) {
        return false;
      }
    }
    final tg = selectedTag?.trim();
    if (tg != null && tg.isNotEmpty) {
      if (!task.tags.contains(tg)) {
        return false;
      }
    }
    return true;
  }

  /// Returns tasks matching [selectedFilter], [selectedDate], [selectedWorkspaceId], and [selectedTag].
  List<TaskEntity> get filteredTasks {
    return tasks.where((task) {
      final matchesStatus =
          selectedFilter == null || task.status == selectedFilter;
      final matchesDate =
          selectedDate == null || task.isScheduledForDate(selectedDate!);
      return matchesStatus && matchesDate && _matchesWorkspaceAndTag(task);
    }).toList(growable: false);
  }

  /// Returns nested child tasks (`parentTaskId == parentId`) ordered by `sortOrder` and `createdAt`.
  List<TaskEntity> childTasksOf(String parentId) {
    final children =
        tasks.where((t) => t.parentTaskId == parentId).toList();
    children.sort((a, b) {
      if (a.sortOrder != b.sortOrder) {
        return a.sortOrder.compareTo(b.sortOrder);
      }
      return a.createdAt.compareTo(b.createdAt);
    });
    return List.unmodifiable(children);
  }

  /// Returns all unique tags available across loaded tasks plus default quick tags.
  List<String> get availableTags {
    final tagSet = <String>{'مهم', 'فوری', 'عادت', 'پروژه'};
    for (final task in tasks) {
      tagSet.addAll(task.tags);
    }
    return tagSet.toList(growable: false);
  }

  /// Returns tasks specifically scheduled for today (matching active workspace/tag filter),
  /// sorted by manual Drag & Drop [sortOrder] (when set) or chronologically by time block.
  List<TaskEntity> get todayTasks {
    final allMatchingToday = tasks
        .where(
          (task) => task.isScheduledForToday && _matchesWorkspaceAndTag(task),
        )
        .toList();

    final matchingIds = allMatchingToday.map((t) => t.id).toSet();

    // Top-level tasks for today (child tasks whose parent is already in today's list
    // are rendered nested inside their parent's tree view).
    final list = allMatchingToday.where((task) {
      final pid = task.parentTaskId;
      if (pid == null || pid.isEmpty) return true;
      return !matchingIds.contains(pid);
    }).toList();

    list.sort((a, b) {
      if (a.sortOrder != b.sortOrder) {
        return a.sortOrder.compareTo(b.sortOrder);
      }
      final aMin = a.startTimeMinutes;
      final bMin = b.startTimeMinutes;
      if (aMin != null && bMin != null) {
        return aMin.compareTo(bMin);
      }
      if (aMin != null) return -1;
      if (bMin != null) return 1;
      final pCmp = b.priority.weight.compareTo(a.priority.weight);
      if (pCmp != 0) return pCmp;
      return a.createdAt.compareTo(b.createdAt);
    });
    return List.unmodifiable(list);
  }

  /// List of today's tasks that are marked as penalized.
  /// When [isVacationMode] is active, no tasks are treated as penalized.
  List<TaskEntity> get todayPenalizedTasks => isVacationMode
      ? const <TaskEntity>[]
      : todayTasks.where((task) => task.isPenalized).toList(growable: false);

  /// List of tasks that are currently overdue.
  /// When [isVacationMode] is active, returns an empty list (routines/tasks are never overdue).
  List<TaskEntity> get overdueTasks {
    if (isVacationMode) return const <TaskEntity>[];
    final now = DateTime.now();
    return tasks
        .where((task) =>
            task.status != TaskStatus.done &&
            task.isOverdue(now, isVacationMode: isVacationMode))
        .toList(growable: false);
  }

  /// True if at least one task exists for today, all are marked Done, and none are penalized.
  bool get isAllTodayTasksCompleted =>
      todayTasks.isNotEmpty &&
      todayTasks.every((task) => task.status == TaskStatus.done) &&
      todayPenalizedCount == 0;

  /// Count of today's penalized tasks.
  int get todayPenalizedCount => todayPenalizedTasks.length;

  /// True when a domain or infrastructure [failure] is present.
  bool get hasError => failure != null;

  /// Count of tasks currently in [TaskStatus.todo].
  int get todoCount =>
      tasks.where((task) => task.status == TaskStatus.todo).length;

  /// Count of tasks currently in [TaskStatus.inProgress].
  int get inProgressCount =>
      tasks.where((task) => task.status == TaskStatus.inProgress).length;

  /// Count of tasks currently in [TaskStatus.done].
  int get doneCount =>
      tasks.where((task) => task.status == TaskStatus.done).length;

  /// Count of today's tasks currently in [TaskStatus.done].
  int get todayDoneCount =>
      todayTasks.where((task) => task.status == TaskStatus.done).length;

  /// Normalized completion progress of today's tasks in `[0.0, 1.0]`.
  double get todayCompletionRatio =>
      todayTasks.isEmpty ? 0.0 : todayDoneCount / todayTasks.length;

  /// Computes the aggregate expenses across all loaded [tasks] directly in Toman.
  Money get totalBoardExpenses {
    var totalMinor = 0;
    for (final task in tasks) {
      totalMinor += task.totalExpenses.amountMinorUnits;
    }
    return Money.reconstitute(
      amountMinorUnits: totalMinor,
      currency: Currency.irt,
    );
  }

  /// Backward-compatible helper returning aggregate expenses in Toman.
  Result<Money, DomainFailure> totalBoardExpensesIn([
    Currency targetCurrency = Currency.irt,
    dynamic exchangeRates,
  ]) {
    return Success(totalBoardExpenses);
  }

  /// Creates a new immutable [TaskState] while allowing nullable fields to be explicitly cleared.
  TaskState copyWith({
    TaskViewStatus? status,
    List<TaskEntity>? tasks,
    List<String>? lastPenalizedTaskIds,
    List<String>? notifiedOverdueTaskIds,
    TaskStatus? Function()? selectedFilter,
    DateTime? Function()? selectedDate,
    String? Function()? selectedWorkspaceId,
    String? Function()? selectedTag,
    bool? isVacationMode,
    Failure? Function()? failure,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      lastPenalizedTaskIds:
          lastPenalizedTaskIds ?? this.lastPenalizedTaskIds,
      notifiedOverdueTaskIds:
          notifiedOverdueTaskIds ?? this.notifiedOverdueTaskIds,
      selectedFilter:
          selectedFilter != null ? selectedFilter() : this.selectedFilter,
      selectedDate:
          selectedDate != null ? selectedDate() : this.selectedDate,
      selectedWorkspaceId: selectedWorkspaceId != null
          ? selectedWorkspaceId()
          : this.selectedWorkspaceId,
      selectedTag: selectedTag != null ? selectedTag() : this.selectedTag,
      isVacationMode: isVacationMode ?? this.isVacationMode,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
        status,
        tasks,
        lastPenalizedTaskIds,
        notifiedOverdueTaskIds,
        selectedFilter,
        selectedDate,
        selectedWorkspaceId,
        selectedTag,
        isVacationMode,
        failure,
      ];
}
