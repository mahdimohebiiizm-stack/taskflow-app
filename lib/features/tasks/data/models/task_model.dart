import 'dart:collection';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/features/tasks/data/models/expense_item_model.dart';
import 'package:task_flow/features/tasks/data/models/sub_task_model.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

/// Data Transfer Object (DTO) for [TaskEntity] persistence in SQLite.
class TaskModel extends Equatable {
  static const String tableName = 'tasks';
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colDescription = 'description';
  static const String colStatus = 'status';
  static const String colPriority = 'priority';
  static const String colPriorityWeight = 'priority_weight';
  static const String colDueDate = 'due_date';
  static const String colStartTime = 'start_time';
  static const String colEndTime = 'end_time';
  static const String colIsPenalized = 'is_penalized';
  static const String colParentTaskId = 'parent_task_id';
  static const String colWorkspaceId = 'workspace_id';
  static const String colTags = 'tags';
  static const String colSortOrder = 'sort_order';
  static const String colRecurrenceRule = 'recurrence_rule';
  static const String colReminderDateTime = 'reminder_date_time';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';

  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final int priorityWeight;
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
  final UnmodifiableListView<SubTaskModel> subTasks;
  final UnmodifiableListView<ExpenseItemModel> expenses;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
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
    List<String> tags = const [],
    this.sortOrder = 0,
    this.recurrenceRule,
    this.reminderDateTime,
    required List<SubTaskModel> subTasks,
    List<ExpenseItemModel> expenses = const [],
    required this.createdAt,
    required this.updatedAt,
  })  : priorityWeight = priority.weight,
        tags = UnmodifiableListView(List<String>.of(tags)),
        subTasks = UnmodifiableListView(List<SubTaskModel>.of(subTasks)),
        expenses = UnmodifiableListView(List<ExpenseItemModel>.of(expenses));

  /// Deterministically maps a domain [TaskEntity] into a [TaskModel].
  factory TaskModel.fromEntity(TaskEntity entity) {
    final mappedSubTasks = <SubTaskModel>[
      for (var i = 0; i < entity.subTasks.length; i++)
        SubTaskModel.fromEntity(
          entity.subTasks[i],
          taskId: entity.id,
          position: i,
        ),
    ];

    final mappedExpenses = <ExpenseItemModel>[
      for (var i = 0; i < entity.expenses.length; i++)
        ExpenseItemModel.fromEntity(
          entity.expenses[i],
          taskId: entity.id,
          position: i,
        ),
    ];

    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      priority: entity.priority,
      dueDate: entity.dueDate,
      startTime: entity.startTime,
      endTime: entity.endTime,
      isPenalized: entity.isPenalized,
      parentTaskId: entity.parentTaskId,
      workspaceId: entity.workspaceId,
      tags: List<String>.of(entity.tags),
      sortOrder: entity.sortOrder,
      recurrenceRule: entity.recurrenceRule,
      reminderDateTime: entity.reminderDateTime,
      subTasks: mappedSubTasks,
      expenses: mappedExpenses,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  static List<String> _parseTags(Object? rawTags) {
    if (rawTags == null) return const <String>[];
    if (rawTags is List) {
      return rawTags
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    final str = rawTags.toString().trim();
    if (str.isEmpty || str == '[]') return const <String>[];
    if (str.startsWith('[')) {
      try {
        final decoded = jsonDecode(str);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false);
        }
      } catch (_) {}
    }
    return str
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  /// Deterministically parses a SQLite row [Map] and its associated [subTasks]
  /// and [expenses] into a [TaskModel].
  /// Throws [LocalDatabaseException] if any field is missing, invalid, or corrupted.
  factory TaskModel.fromMap(
    Map<String, Object?> map, {
    List<SubTaskModel> subTasks = const [],
    List<ExpenseItemModel> expenses = const [],
  }) {
    try {
      final id = map[colId] as String?;
      final title = map[colTitle] as String?;
      final description = (map[colDescription] as String?) ?? '';
      final rawStatus = map[colStatus] as String?;
      final rawPriority = map[colPriority] as String?;
      final rawDueDate = map[colDueDate] as String?;
      final startTime = map[colStartTime] as String?;
      final endTime = map[colEndTime] as String?;
      final rawIsPenalized = map[colIsPenalized];
      final isPenalized =
          rawIsPenalized == 1 || rawIsPenalized == true || rawIsPenalized == '1';
      final rawParentTaskId = map[colParentTaskId] as String?;
      final parentTaskId =
          (rawParentTaskId != null && rawParentTaskId.trim().isNotEmpty)
              ? rawParentTaskId.trim()
              : null;
      final rawWorkspaceId = map[colWorkspaceId] as String?;
      final workspaceId =
          (rawWorkspaceId != null && rawWorkspaceId.trim().isNotEmpty)
              ? rawWorkspaceId.trim()
              : TaskWorkspaces.defaultWorkspace;
      final tags = _parseTags(map[colTags]);
      final rawSortOrder = map[colSortOrder];
      final sortOrder = rawSortOrder is int
          ? rawSortOrder
          : (rawSortOrder != null ? int.tryParse(rawSortOrder.toString()) ?? 0 : 0);
      final rawRecurrenceRule = map[colRecurrenceRule] as String?;
      final recurrenceRule = TaskRecurrenceRules.normalize(rawRecurrenceRule);
      final rawReminderDateTime = map[colReminderDateTime] as String?;
      final reminderDateTime =
          (rawReminderDateTime != null && rawReminderDateTime.trim().isNotEmpty)
              ? DateTime.parse(rawReminderDateTime)
              : null;
      final rawCreatedAt = map[colCreatedAt] as String?;
      final rawUpdatedAt = map[colUpdatedAt] as String?;

      if (id == null || id.trim().isEmpty) {
        throw const LocalDatabaseException(
          message: 'Corrupted tasks row: missing or empty "id".',
        );
      }
      if (title == null || title.trim().isEmpty) {
        throw const LocalDatabaseException(
          message: 'Corrupted tasks row: missing or empty "title".',
        );
      }
      if (rawStatus == null) {
        throw const LocalDatabaseException(
          message: 'Corrupted tasks row: missing "status".',
        );
      }
      if (rawPriority == null) {
        throw const LocalDatabaseException(
          message: 'Corrupted tasks row: missing "priority".',
        );
      }
      if (rawCreatedAt == null) {
        throw const LocalDatabaseException(
          message: 'Corrupted tasks row: missing "created_at".',
        );
      }
      if (rawUpdatedAt == null) {
        throw const LocalDatabaseException(
          message: 'Corrupted tasks row: missing "updated_at".',
        );
      }

      final status = TaskStatus.fromStorageKey(rawStatus);
      final priority = TaskPriority.fromStorageKey(rawPriority);
      final dueDate = rawDueDate != null ? DateTime.parse(rawDueDate) : null;
      final createdAt = DateTime.parse(rawCreatedAt);
      final updatedAt = DateTime.parse(rawUpdatedAt);

      final orderedSubTasks = List<SubTaskModel>.of(subTasks)
        ..sort((a, b) => a.position.compareTo(b.position));

      final orderedExpenses = List<ExpenseItemModel>.of(expenses)
        ..sort((a, b) => a.position.compareTo(b.position));

      return TaskModel(
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
        subTasks: orderedSubTasks,
        expenses: orderedExpenses,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (error) {
      if (error is LocalDatabaseException) {
        rethrow;
      }
      throw LocalDatabaseException(
        message: 'Failed to deserialize TaskModel from SQLite map.',
        cause: error,
      );
    }
  }

  /// Serializes the parent task columns into a SQLite-compatible [Map].
  Map<String, Object?> toTaskTableMap() {
    return <String, Object?>{
      colId: id,
      colTitle: title,
      colDescription: description,
      colStatus: status.storageKey,
      colPriority: priority.storageKey,
      colPriorityWeight: priorityWeight,
      colDueDate: dueDate?.toIso8601String(),
      colStartTime: startTime,
      colEndTime: endTime,
      colIsPenalized: isPenalized ? 1 : 0,
      colParentTaskId: parentTaskId,
      colWorkspaceId: workspaceId,
      colTags: jsonEncode(tags),
      colSortOrder: sortOrder,
      colRecurrenceRule: recurrenceRule,
      colReminderDateTime: reminderDateTime?.toIso8601String(),
      colCreatedAt: createdAt.toIso8601String(),
      colUpdatedAt: updatedAt.toIso8601String(),
    };
  }

  /// Deterministically converts this [TaskModel] and its child collections into a domain [TaskEntity].
  TaskEntity toEntity() {
    final orderedSubTasks = List<SubTaskModel>.of(subTasks)
      ..sort((a, b) => a.position.compareTo(b.position));

    final orderedExpenses = List<ExpenseItemModel>.of(expenses)
      ..sort((a, b) => a.position.compareTo(b.position));

    return TaskEntity.reconstitute(
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
      tags: List<String>.of(tags),
      sortOrder: sortOrder,
      recurrenceRule: recurrenceRule,
      reminderDateTime: reminderDateTime,
      subTasks: orderedSubTasks.map((model) => model.toEntity()).toList(),
      expenses: orderedExpenses.map((model) => model.toEntity()).toList(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// True if a task is an all-day task (no specific start or end time-block assigned).
  bool get isAllDay =>
      (startTime == null || startTime!.trim().isEmpty) &&
      (endTime == null || endTime!.trim().isEmpty);

  /// Evaluates whether the task is past its scheduled time and not yet Done.
  /// If a task is [isAllDay], it is ONLY overdue if [referenceTime] is strictly past 23:59:59 of its scheduled date.
  bool isOverdue(DateTime referenceTime, {bool isVacationMode = false}) {
    return toEntity().isOverdue(referenceTime, isVacationMode: isVacationMode);
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        priority,
        priorityWeight,
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
