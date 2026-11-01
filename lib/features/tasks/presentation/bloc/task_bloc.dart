import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/notifications/notification_service.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/core/services/widget_sync_service.dart';
import 'package:task_flow/core/sync/background_sync_service.dart';
import 'package:task_flow/core/sync/pending_sync_event.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_bloc.dart';
import 'package:task_flow/features/analytics/presentation/bloc/financial_analytics_event.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:task_flow/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:task_flow/features/notifications/domain/repositories/notification_repository.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:task_flow/features/notifications/presentation/bloc/notification_event.dart';
import 'package:task_flow/features/tasks/domain/entities/expense_item_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/entities/sub_task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';
import 'package:task_flow/features/tasks/domain/usecases/add_task_expense_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/penalize_day_tasks_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/revert_day_penalty_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/toggle_sub_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/transition_task_status_usecase.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_event.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_state.dart';
import 'package:uuid/uuid.dart';

/// Presentation-layer state controller orchestrating Task & Financial workflows via Domain UseCases.
///
/// Receives all dependencies exclusively through constructor injection.
class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase _getTasksUseCase;
  final CreateTaskUseCase _createTaskUseCase;
  final TransitionTaskStatusUseCase _transitionTaskStatusUseCase;
  final ToggleSubTaskUseCase _toggleSubTaskUseCase;
  final DeleteTaskUseCase _deleteTaskUseCase;
  final AddTaskExpenseUseCase? _addTaskExpenseUseCase;
  final PenalizeDayTasksUseCase? _penalizeDayTasksUseCase;
  final RevertDayPenaltyUseCase? _revertDayPenaltyUseCase;
  final TaskRepository? _taskRepository;
  final NotificationService? _notificationService;
  final NotificationRepository? _notificationRepository;
  final NotificationBloc? _notificationBloc;
  final FinancialAnalyticsBloc? _financialAnalyticsBloc;
  final GamificationBloc? _gamificationBloc;
  final SoundAndHapticService _soundService;
  final WidgetSyncService _widgetSyncService;
  final BackgroundSyncService _backgroundSyncService;
  final Uuid _uuid;
  Timer? _overdueTimer;

  TaskBloc({
    required GetTasksUseCase getTasksUseCase,
    required CreateTaskUseCase createTaskUseCase,
    required TransitionTaskStatusUseCase transitionTaskStatusUseCase,
    required ToggleSubTaskUseCase toggleSubTaskUseCase,
    required DeleteTaskUseCase deleteTaskUseCase,
    AddTaskExpenseUseCase? addTaskExpenseUseCase,
    PenalizeDayTasksUseCase? penalizeDayTasksUseCase,
    RevertDayPenaltyUseCase? revertDayPenaltyUseCase,
    TaskRepository? taskRepository,
    NotificationService? notificationService,
    NotificationRepository? notificationRepository,
    NotificationBloc? notificationBloc,
    FinancialAnalyticsBloc? financialAnalyticsBloc,
    GamificationBloc? gamificationBloc,
    SoundAndHapticService? soundService,
    WidgetSyncService? widgetSyncService,
    BackgroundSyncService? backgroundSyncService,
    dynamic upsertExchangeRateUseCase,
    dynamic getExchangeRatesUseCase,
    Uuid uuid = const Uuid(),
    bool? enablePeriodicTicker,
  })  : _getTasksUseCase = getTasksUseCase,
        _createTaskUseCase = createTaskUseCase,
        _transitionTaskStatusUseCase = transitionTaskStatusUseCase,
        _toggleSubTaskUseCase = toggleSubTaskUseCase,
        _deleteTaskUseCase = deleteTaskUseCase,
        _addTaskExpenseUseCase = addTaskExpenseUseCase,
        _penalizeDayTasksUseCase = penalizeDayTasksUseCase,
        _revertDayPenaltyUseCase = revertDayPenaltyUseCase,
        _taskRepository = taskRepository,
        _notificationService = notificationService,
        _notificationRepository = notificationRepository,
        _notificationBloc = notificationBloc,
        _financialAnalyticsBloc = financialAnalyticsBloc,
        _gamificationBloc = gamificationBloc,
        _soundService = soundService ?? SoundAndHapticService.instance,
        _widgetSyncService = widgetSyncService ?? WidgetSyncService.instance,
        _backgroundSyncService =
            backgroundSyncService ?? BackgroundSyncService(uuid: uuid),
        _uuid = uuid,
        super(TaskState()) {
    on<TasksLoadRequested>(_onTasksLoadRequested);
    on<TaskStatusFilterChanged>(_onTaskStatusFilterChanged);
    on<TaskScheduledDateChanged>(_onTaskScheduledDateChanged);
    on<TaskWorkspaceFilterChanged>(_onTaskWorkspaceFilterChanged);
    on<TaskTagFilterChanged>(_onTaskTagFilterChanged);
    on<TasksReordered>(_onTasksReordered);
    on<TaskCreated>(_onTaskCreated);
    on<TaskStatusTransitioned>(_onTaskStatusTransitioned);
    on<SubTaskToggled>(_onSubTaskToggled);
    on<TaskDeleted>(_onTaskDeleted);
    on<TaskExpenseAdded>(_onTaskExpenseAdded);
    on<DayEnded>(_onDayEnded);
    on<DayEndedUndone>(_onDayEndedUndone);
    on<TaskErrorCleared>(_onTaskErrorCleared);
    on<TaskVacationModeChanged>(_onTaskVacationModeChanged);
    on<TaskEdited>(_onTaskEdited);
    on<TaskRescheduled>(_onTaskRescheduled);
    on<TaskOverdueCheckRequested>(_onTaskOverdueCheckRequested);

    final bool shouldTick = enablePeriodicTicker ??
        (!Platform.environment.containsKey('FLUTTER_TEST'));
    if (shouldTick) {
      _overdueTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        add(const TaskOverdueCheckRequested());
      });
    }
  }

  @override
  Future<void> close() {
    _overdueTimer?.cancel();
    return super.close();
  }

  BackgroundSyncService get syncService => _backgroundSyncService;

  Future<void> _onTaskEdited(
    TaskEdited event,
    Emitter<TaskState> emit,
  ) async {
    final trimmedTitle = event.title.trim();
    if (trimmedTitle.isEmpty) return;

    final existingIdx = state.tasks.indexWhere((t) => t.id == event.taskId);
    if (existingIdx == -1) return;
    final existing = state.tasks[existingIdx];

    final updatedResult = TaskEntity.create(
      id: existing.id,
      title: trimmedTitle,
      description: event.description ?? existing.description,
      status: existing.status,
      priority: event.priority ?? existing.priority,
      dueDate: event.dueDate ?? existing.dueDate,
      startTime: event.clearTimeBlock
          ? null
          : (event.startTime ?? existing.startTime),
      endTime: event.clearTimeBlock
          ? null
          : (event.endTime ?? existing.endTime),
      isPenalized: existing.isPenalized,
      parentTaskId: existing.parentTaskId,
      workspaceId: event.workspaceId ?? existing.workspaceId,
      tags: event.tags ?? existing.tags.toList(),
      sortOrder: existing.sortOrder,
      recurrenceRule: existing.recurrenceRule,
      reminderDateTime: existing.reminderDateTime,
      subTasks: existing.subTasks.toList(),
      expenses: existing.expenses.toList(),
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );

    if (updatedResult is Success<TaskEntity, DomainFailure>) {
      final updatedTask = updatedResult.value;
      final updatedList = List<TaskEntity>.of(state.tasks);
      updatedList[existingIdx] = updatedTask;
      emit(
        state.copyWith(
          status: TaskViewStatus.success,
          tasks: updatedList,
          failure: () => null,
        ),
      );
      if (_taskRepository != null) {
        await _taskRepository.saveTask(updatedTask);
      }
    }
  }

  Future<void> _onTaskRescheduled(
    TaskRescheduled event,
    Emitter<TaskState> emit,
  ) async {
    final existingIdx = state.tasks.indexWhere((t) => t.id == event.taskId);
    if (existingIdx == -1) return;
    final existing = state.tasks[existingIdx];

    final updatedResult = TaskEntity.create(
      id: existing.id,
      title: existing.title,
      description: existing.description,
      status: existing.status,
      priority: existing.priority,
      dueDate: event.newDueDate,
      startTime: existing.startTime,
      endTime: existing.endTime,
      isPenalized: false,
      parentTaskId: existing.parentTaskId,
      workspaceId: existing.workspaceId,
      tags: existing.tags.toList(),
      sortOrder: existing.sortOrder,
      recurrenceRule: existing.recurrenceRule,
      reminderDateTime: existing.reminderDateTime,
      subTasks: existing.subTasks.toList(),
      expenses: existing.expenses.toList(),
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );

    if (updatedResult is Success<TaskEntity, DomainFailure>) {
      final updatedTask = updatedResult.value;
      final updatedList = List<TaskEntity>.of(state.tasks);
      updatedList[existingIdx] = updatedTask;
      emit(
        state.copyWith(
          status: TaskViewStatus.success,
          tasks: updatedList,
          failure: () => null,
        ),
      );
      if (_taskRepository != null) {
        await _taskRepository.saveTask(updatedTask);
      }
      _backgroundSyncService.enqueue(
        entityId: updatedTask.id,
        eventType: SyncEventTypes.taskUpdated,
        payload: <String, dynamic>{
          'action': 'rescheduled',
          'newDueDate': event.newDueDate.toIso8601String(),
        },
        occurredAtUtc: DateTime.now().toUtc(),
      );
    }
  }

  Future<void> _onTaskVacationModeChanged(
    TaskVacationModeChanged event,
    Emitter<TaskState> emit,
  ) async {
    if (event.isVacationMode) {
      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final rolledTasks = state.tasks.map((task) {
        if (task.status == TaskStatus.done) return task;
        final effective = (task.dueDate ?? task.createdAt).toLocal();
        final taskDate =
            DateTime(effective.year, effective.month, effective.day);
        if (taskDate.isBefore(todayMidnight) || task.isPenalized) {
          return task.rollOverToDate(todayMidnight, updatedAt: now);
        }
        return task;
      }).toList(growable: false);

      emit(
        state.copyWith(
          isVacationMode: true,
          tasks: rolledTasks,
          lastPenalizedTaskIds: const [],
        ),
      );
      if (_penalizeDayTasksUseCase != null) {
        await _penalizeDayTasksUseCase(
          PenalizeDayTasksParams(
            now: now,
            includePastDays: true,
            penalizeToday: false,
            isVacationMode: true,
          ),
        );
      }
    } else {
      emit(state.copyWith(isVacationMode: false));
    }
  }

  void _onTaskWorkspaceFilterChanged(
    TaskWorkspaceFilterChanged event,
    Emitter<TaskState> emit,
  ) {
    final normalized =
        (event.workspaceId == null || event.workspaceId == TaskWorkspaces.all)
            ? null
            : event.workspaceId;
    emit(
      state.copyWith(
        selectedWorkspaceId: () => normalized,
        failure: () => null,
      ),
    );
  }

  void _onTaskTagFilterChanged(
    TaskTagFilterChanged event,
    Emitter<TaskState> emit,
  ) {
    final normalized =
        (event.tag == null || event.tag!.trim().isEmpty) ? null : event.tag;
    emit(
      state.copyWith(
        selectedTag: () => normalized,
        failure: () => null,
      ),
    );
  }

  Future<void> _onTasksReordered(
    TasksReordered event,
    Emitter<TaskState> emit,
  ) async {
    final currentToday = List<TaskEntity>.of(state.todayTasks);
    if (event.oldIndex < 0 ||
        event.oldIndex >= currentToday.length ||
        event.newIndex < 0) {
      return;
    }

    var targetIndex = event.newIndex;
    if (event.oldIndex < targetIndex) {
      targetIndex -= 1;
    }
    targetIndex = targetIndex.clamp(0, currentToday.length - 1);
    if (event.oldIndex == targetIndex) return;

    final moved = currentToday.removeAt(event.oldIndex);
    currentToday.insert(targetIndex, moved);

    final now = DateTime.now().toUtc();
    final sortOrderMap = <String, int>{};
    for (var i = 0; i < currentToday.length; i++) {
      sortOrderMap[currentToday[i].id] = i + 1;
    }

    final updatedAllTasks = state.tasks.map((task) {
      final newOrder = sortOrderMap[task.id];
      if (newOrder != null) {
        return task.withSortOrder(newOrder, updatedAt: now);
      }
      return task;
    }).toList(growable: false);

    emit(
      state.copyWith(
        status: TaskViewStatus.success,
        tasks: updatedAllTasks,
        failure: () => null,
      ),
    );

    if (_taskRepository != null) {
      await _taskRepository.batchUpdateSortOrders(sortOrderMap, now);
    }
    _backgroundSyncService.enqueue(
      entityId: moved.id,
      eventType: SyncEventTypes.taskUpdated,
      payload: <String, dynamic>{
        'action': 'reordered',
        'newSortOrder': sortOrderMap[moved.id],
      },
      occurredAtUtc: now,
    );
  }

  Future<void> _onTasksLoadRequested(
    TasksLoadRequested event,
    Emitter<TaskState> emit,
  ) async {
    final nextFilter = event.preserveCurrentFilter
        ? state.selectedFilter
        : event.statusFilter;
    final nextDate = event.preserveCurrentFilter
        ? state.selectedDate
        : event.scheduledDate;

    emit(
      state.copyWith(
        status: TaskViewStatus.loading,
        selectedFilter: () => nextFilter,
        selectedDate: () => nextDate,
        failure: () => null,
      ),
    );

    if (_penalizeDayTasksUseCase != null) {
      await _penalizeDayTasksUseCase(
        PenalizeDayTasksParams(
          includePastDays: true,
          penalizeToday: false,
          isVacationMode: state.isVacationMode,
        ),
      );
    }

    final tasksResult = await _getTasksUseCase(
      GetTasksParams(
        status: nextFilter,
        scheduledDate: nextDate,
      ),
    );

    tasksResult.fold(
      onSuccess: (tasks) {
        emit(
          state.copyWith(
            status: TaskViewStatus.success,
            tasks: tasks,
            failure: () => null,
          ),
        );
      },
      onFailure: (failure) => emit(
        state.copyWith(
          status: TaskViewStatus.failure,
          failure: () => failure,
        ),
      ),
    );
  }

  void _onTaskScheduledDateChanged(
    TaskScheduledDateChanged event,
    Emitter<TaskState> emit,
  ) {
    emit(
      state.copyWith(
        selectedDate: () => event.scheduledDate,
        failure: () => null,
      ),
    );
  }

  void _onTaskStatusFilterChanged(
    TaskStatusFilterChanged event,
    Emitter<TaskState> emit,
  ) {
    emit(
      state.copyWith(
        selectedFilter: () => event.statusFilter,
        failure: () => null,
      ),
    );
  }

  Future<void> _onTaskCreated(
    TaskCreated event,
    Emitter<TaskState> emit,
  ) async {
    final now = event.createdAt ?? DateTime.now().toUtc();
    final subTasks = <SubTaskEntity>[];
    for (final rawTitle in event.subTaskTitles) {
      final trimmed = rawTitle.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      final subTaskResult = SubTaskEntity.create(
        id: _uuid.v4(),
        title: trimmed,
      );
      switch (subTaskResult) {
        case Err<SubTaskEntity, DomainFailure>(failure: final f):
          emit(
            state.copyWith(
              status: TaskViewStatus.failure,
              failure: () => f,
            ),
          );
          return;
        case Success<SubTaskEntity, DomainFailure>(value: final subTask):
          subTasks.add(subTask);
      }
    }

    final expenses = <ExpenseItemEntity>[];
    final rawExpenseAmount = event.initialExpenseMinorUnits;
    if (rawExpenseAmount != null && rawExpenseAmount > 0) {
      final moneyResult = Money.create(
        amountMinorUnits: rawExpenseAmount,
        currency: event.initialExpenseCurrency,
      );
      switch (moneyResult) {
        case Err<Money, DomainFailure>(failure: final f):
          emit(
            state.copyWith(
              status: TaskViewStatus.failure,
              failure: () => f,
            ),
          );
          return;
        case Success<Money, DomainFailure>(value: final validMoney):
          final expenseResult = ExpenseItemEntity.create(
            id: _uuid.v4(),
            title:
                event.title.trim().isEmpty ? 'هزینه تسک' : event.title.trim(),
            money: validMoney,
            incurredAt: now,
          );
          switch (expenseResult) {
            case Err<ExpenseItemEntity, DomainFailure>(failure: final f):
              emit(
                state.copyWith(
                  status: TaskViewStatus.failure,
                  failure: () => f,
                ),
              );
              return;
            case Success<ExpenseItemEntity, DomainFailure>(
                value: final validExpense
              ):
              expenses.add(validExpense);
          }
      }
    }

    final effectiveWorkspace = expenses.isNotEmpty &&
            event.workspaceId == TaskWorkspaces.defaultWorkspace
        ? TaskWorkspaces.financial
        : event.workspaceId;

    final taskId = event.id ?? _uuid.v4();
    final optimisticCreation = TaskEntity.create(
      id: taskId,
      title: event.title,
      description: event.description,
      priority: event.priority,
      dueDate: event.dueDate,
      startTime: event.startTime,
      endTime: event.endTime,
      parentTaskId: event.parentTaskId,
      workspaceId: effectiveWorkspace,
      tags: event.tags,
      sortOrder: event.sortOrder,
      recurrenceRule: event.recurrenceRule,
      reminderDateTime: event.reminderDateTime,
      subTasks: subTasks,
      expenses: expenses,
      createdAt: now,
    );

    if (optimisticCreation case Success(value: final previewTask)) {
      emit(
        state.copyWith(
          status: TaskViewStatus.success,
          tasks: <TaskEntity>[...state.tasks, previewTask],
          failure: () => null,
        ),
      );
    }

    final createResult = await _createTaskUseCase(
      CreateTaskParams(
        id: taskId,
        title: event.title,
        description: event.description,
        priority: event.priority,
        dueDate: event.dueDate,
        startTime: event.startTime,
        endTime: event.endTime,
        parentTaskId: event.parentTaskId,
        workspaceId: effectiveWorkspace,
        tags: event.tags,
        sortOrder: event.sortOrder,
        recurrenceRule: event.recurrenceRule,
        reminderDateTime: event.reminderDateTime,
        subTasks: subTasks,
        expenses: expenses,
        createdAt: now,
      ),
    );

    await createResult.fold(
      onSuccess: (createdTask) async {
        if (createdTask.reminderDateTime != null) {
          await _notificationService?.scheduleTaskReminder(createdTask);
        }
        _backgroundSyncService.enqueue(
          entityId: createdTask.id,
          eventType: SyncEventTypes.taskCreated,
          payload: <String, dynamic>{
            'title': createdTask.title,
            'priority': createdTask.priority.name,
            'workspaceId': createdTask.workspaceId,
            'parentTaskId': createdTask.parentTaskId,
            'tags': createdTask.tags,
            'recurrenceRule': createdTask.recurrenceRule,
            'reminderDateTime': createdTask.reminderDateTime?.toIso8601String(),
          },
          occurredAtUtc: now,
        );
        await _reloadTasksPreservingState(emit);
      },
      onFailure: (failure) async => emit(
        state.copyWith(
          status: TaskViewStatus.failure,
          failure: () => failure,
        ),
      ),
    );
  }

  Future<void> _onTaskStatusTransitioned(
    TaskStatusTransitioned event,
    Emitter<TaskState> emit,
  ) async {
    final wasAlreadyDone = state.tasks.any(
      (t) => t.id == event.taskId && t.status == TaskStatus.done,
    );

    final existingIdx = state.tasks.indexWhere((t) => t.id == event.taskId);
    if (existingIdx != -1) {
      final existingTask = state.tasks[existingIdx];
      if (!existingTask.hasRecurrence) {
        final optimisticTransition = existingTask.transitionStatus(
          event.targetStatus,
          updatedAt: event.timestamp ?? DateTime.now().toUtc(),
        );
        if (optimisticTransition case Success(value: final previewTask)) {
          _replaceTaskInState(previewTask, emit);
        }
      }
    }

    final result = await _transitionTaskStatusUseCase(
      TransitionTaskStatusParams(
        taskId: event.taskId,
        targetStatus: event.targetStatus,
        timestamp: event.timestamp,
      ),
    );

    await result.fold(
      onSuccess: (updatedTask) async {
        _backgroundSyncService.enqueue(
          entityId: updatedTask.id,
          eventType: SyncEventTypes.taskStatusTransitioned,
          payload: <String, dynamic>{
            'targetStatus': updatedTask.status.name,
          },
          occurredAtUtc: event.timestamp,
        );

        if (updatedTask.status == TaskStatus.done) {
          await _notificationService?.cancelTaskReminder(updatedTask.id);
        } else if (updatedTask.reminderDateTime != null) {
          await _notificationService?.scheduleTaskReminder(updatedTask);
        }

        if (updatedTask.status == TaskStatus.done && !wasAlreadyDone) {
          unawaited(_soundService.playSuccessChime());
          final earnedXp = (updatedTask.priority == TaskPriority.high ||
                  updatedTask.priority == TaskPriority.critical)
              ? 20
              : 10;
          final notification = AppNotificationEntity(
            id: _uuid.v4(),
            title: 'تکمیل تسک',
            message: "تسک '${updatedTask.title}' با موفقیت تمام شد! (+$earnedXp XP)",
            type: AppNotificationType.reward,
            timestamp: event.timestamp ?? DateTime.now().toUtc(),
          );
          if (_notificationRepository != null) {
            await _notificationRepository.saveNotification(notification);
          }
          _notificationBloc?.add(NotificationAdded(notification));

          // 🌟 THE FINANCIAL BRIDGE: Add +50,000 Rials to user's daily budget
          _financialAnalyticsBloc?.add(
            const FinancialAnalyticsBudgetAdjusted(
              deltaRials: 50000,
              reason: 'پاداش انجام تسک',
            ),
          );

          // 🌟 Gamification: Record XP & level up progression
          _gamificationBloc?.add(
            GamificationTaskCompleted(
              taskId: updatedTask.id,
              title: updatedTask.title,
              priority: updatedTask.priority,
            ),
          );
        }

        if (updatedTask.status == TaskStatus.done &&
            !wasAlreadyDone &&
            updatedTask.hasRecurrence) {
          final now = event.timestamp ?? DateTime.now().toUtc();
          final nextDueDate =
              updatedTask.computeNextDueDate(referenceDate: now);
          final nextReminder = updatedTask.computeNextReminderDateTime();

          final resetSubTasks = <SubTaskEntity>[];
          for (final st in updatedTask.subTasks) {
            final stRes = SubTaskEntity.create(
              id: _uuid.v4(),
              title: st.title,
              isCompleted: false,
            );
            if (stRes case Success(value: final freshSubTask)) {
              resetSubTasks.add(freshSubTask);
            }
          }

          final nextTaskId = _uuid.v4();
          final nextCreateResult = await _createTaskUseCase(
            CreateTaskParams(
              id: nextTaskId,
              title: updatedTask.title,
              description: updatedTask.description,
              status: TaskStatus.todo,
              priority: updatedTask.priority,
              dueDate: nextDueDate,
              startTime: updatedTask.startTime,
              endTime: updatedTask.endTime,
              isPenalized: false,
              parentTaskId: updatedTask.parentTaskId,
              workspaceId: updatedTask.workspaceId,
              tags: List<String>.of(updatedTask.tags),
              sortOrder: updatedTask.sortOrder,
              recurrenceRule: updatedTask.recurrenceRule,
              reminderDateTime: nextReminder,
              subTasks: resetSubTasks,
              expenses: const [],
              createdAt: now,
            ),
          );

          switch (nextCreateResult) {
            case Success(value: final nextRecurringTask):
              if (nextRecurringTask.reminderDateTime != null) {
                await _notificationService
                    ?.scheduleTaskReminder(nextRecurringTask);
              }
              _backgroundSyncService.enqueue(
                entityId: nextRecurringTask.id,
                eventType: SyncEventTypes.taskCreated,
                payload: <String, dynamic>{
                  'title': nextRecurringTask.title,
                  'recurrenceRule': nextRecurringTask.recurrenceRule,
                  'spawnedFromTaskId': updatedTask.id,
                },
                occurredAtUtc: now,
              );
              final updatedList = <TaskEntity>[
                for (final existing in state.tasks)
                  if (existing.id == updatedTask.id)
                    updatedTask
                  else
                    existing,
                nextRecurringTask,
              ];
              emit(
                state.copyWith(
                  status: TaskViewStatus.success,
                  tasks: updatedList,
                  failure: () => null,
                ),
              );
              return;
            case Err():
              break;
          }
        }

        _replaceTaskInState(updatedTask, emit);
      },
      onFailure: (failure) async => emit(
        state.copyWith(
          status: TaskViewStatus.failure,
          failure: () => failure,
        ),
      ),
    );
  }

  Future<void> _onSubTaskToggled(
    SubTaskToggled event,
    Emitter<TaskState> emit,
  ) async {
    final result = await _toggleSubTaskUseCase(
      ToggleSubTaskParams(
        taskId: event.taskId,
        subTaskId: event.subTaskId,
        timestamp: event.timestamp,
      ),
    );

    result.fold(
      onSuccess: (updatedTask) {
        _backgroundSyncService.enqueue(
          entityId: updatedTask.id,
          eventType: SyncEventTypes.subTaskToggled,
          payload: <String, dynamic>{
            'subTaskId': event.subTaskId,
          },
          occurredAtUtc: event.timestamp,
        );
        _replaceTaskInState(updatedTask, emit);
      },
      onFailure: (failure) => emit(
        state.copyWith(
          status: TaskViewStatus.failure,
          failure: () => failure,
        ),
      ),
    );
  }

  Future<void> _onTaskDeleted(
    TaskDeleted event,
    Emitter<TaskState> emit,
  ) async {
    final result = await _deleteTaskUseCase(
      DeleteTaskParams(taskId: event.taskId),
    );

    await result.fold(
      onSuccess: (_) async {
        await _notificationService?.cancelTaskReminder(event.taskId);
        _backgroundSyncService.enqueue(
          entityId: event.taskId,
          eventType: SyncEventTypes.taskDeleted,
        );
        final updatedList = state.tasks
            .where((task) =>
                task.id != event.taskId && task.parentTaskId != event.taskId)
            .toList(growable: false);
        emit(
          state.copyWith(
            status: TaskViewStatus.success,
            tasks: updatedList,
            failure: () => null,
          ),
        );
        _syncHomeWidget();
      },
      onFailure: (failure) async => emit(
        state.copyWith(
          status: TaskViewStatus.failure,
          failure: () => failure,
        ),
      ),
    );
  }

  Future<void> _onTaskExpenseAdded(
    TaskExpenseAdded event,
    Emitter<TaskState> emit,
  ) async {
    final useCase = _addTaskExpenseUseCase;
    if (useCase == null) {
      return;
    }

    final expenseId = event.expenseId ?? _uuid.v4();
    final result = await useCase(
      AddTaskExpenseParams(
        taskId: event.taskId,
        expenseId: expenseId,
        title: event.title,
        amountMinorUnits: event.amountMinorUnits,
        currency: event.currency,
        incurredAt: event.incurredAt,
      ),
    );

    result.fold(
      onSuccess: (updatedTask) {
        _backgroundSyncService.enqueue(
          entityId: updatedTask.id,
          eventType: SyncEventTypes.taskExpenseAdded,
          payload: <String, dynamic>{
            'expenseId': expenseId,
            'amountMinorUnits': event.amountMinorUnits,
          },
          occurredAtUtc: event.incurredAt,
        );
        _replaceTaskInState(updatedTask, emit);
      },
      onFailure: (failure) => emit(
        state.copyWith(
          status: TaskViewStatus.failure,
          failure: () => failure,
        ),
      ),
    );
  }

  Future<void> _onDayEnded(
    DayEnded event,
    Emitter<TaskState> emit,
  ) async {
    if (state.isVacationMode) {
      final now = event.timestamp ?? DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final tomorrowMidnight = DateTime(now.year, now.month, now.day + 1);

      if (_penalizeDayTasksUseCase != null) {
        await _penalizeDayTasksUseCase(
          PenalizeDayTasksParams(
            now: now,
            includePastDays: true,
            penalizeToday: true,
            isVacationMode: true,
          ),
        );
      }

      final rolledTasks = state.tasks.map((task) {
        if (task.status == TaskStatus.done) return task;
        final effective = (task.dueDate ?? task.createdAt).toLocal();
        final taskDate =
            DateTime(effective.year, effective.month, effective.day);
        final isPastOrToday =
            taskDate.isBefore(todayMidnight) || task.isScheduledForDate(now);
        if (isPastOrToday) {
          return task.rollOverToDate(tomorrowMidnight, updatedAt: now);
        }
        return task;
      }).toList(growable: false);

      emit(
        state.copyWith(
          tasks: rolledTasks,
          lastPenalizedTaskIds: const [],
        ),
      );
      return;
    }

    if (_penalizeDayTasksUseCase != null) {
      final penalizeResult = await _penalizeDayTasksUseCase(
        PenalizeDayTasksParams(now: event.timestamp),
      );
      switch (penalizeResult) {
        case Err(failure: final f):
          emit(
            state.copyWith(
              status: TaskViewStatus.failure,
              failure: () => f,
            ),
          );
          return;
        case Success(value: final penalizedTasks):
          if (penalizedTasks.isNotEmpty) {
            unawaited(_soundService.playErrorBuzz());
          }
          final penalizedIds =
              penalizedTasks.map((t) => t.id).toList(growable: false);
          _backgroundSyncService.enqueue(
            entityId: 'day_end',
            eventType: SyncEventTypes.dayPenalized,
            payload: <String, dynamic>{
              'penalizedTaskIds': penalizedIds,
            },
            occurredAtUtc: event.timestamp,
          );
          if (_notificationRepository != null) {
            for (final penalized in penalizedTasks) {
              final notification = AppNotificationEntity(
                id: _uuid.v4(),
                title: 'موعد گذشته و جریمه',
                message: "تسک '${penalized.title}' انجام نشد و موعد آن گذشت. (-۵ XP)",
                type: AppNotificationType.penalty,
                timestamp: event.timestamp ?? DateTime.now().toUtc(),
              );
              await _notificationRepository.saveNotification(notification);
              _notificationBloc?.add(NotificationAdded(notification));
            }
          }

          // 🌟 THE FINANCIAL BRIDGE: Deduct -10,000 Rials from budget per overdue task
          for (final penalized in penalizedTasks) {
            _financialAnalyticsBloc?.add(
              const FinancialAnalyticsBudgetAdjusted(
                deltaRials: -10000,
                reason: 'جریمه موعد گذشته',
              ),
            );
            _gamificationBloc?.add(
              GamificationTaskOverdue(
                taskId: penalized.id,
                title: penalized.title,
                penaltyXp: 5,
              ),
            );
          }

          emit(
            state.copyWith(
              lastPenalizedTaskIds: penalizedIds,
            ),
          );
      }
    }
    await _reloadTasksPreservingState(emit);
  }

  Future<void> _onDayEndedUndone(
    DayEndedUndone event,
    Emitter<TaskState> emit,
  ) async {
    final useCase = _revertDayPenaltyUseCase;
    if (useCase == null) return;

    final ids = event.taskIds ?? state.lastPenalizedTaskIds;
    if (ids.isEmpty) return;

    final result = await useCase(
      RevertDayPenaltyParams(taskIds: ids, now: event.timestamp),
    );
    switch (result) {
      case Err(failure: final f):
        emit(
          state.copyWith(
            status: TaskViewStatus.failure,
            failure: () => f,
          ),
        );
      case Success():
        _backgroundSyncService.enqueue(
          entityId: 'day_end_undo',
          eventType: SyncEventTypes.dayPenaltyReverted,
          payload: <String, dynamic>{
            'revertedTaskIds': ids,
          },
          occurredAtUtc: event.timestamp,
        );
        emit(state.copyWith(lastPenalizedTaskIds: const []));
        await _reloadTasksPreservingState(emit);
    }
  }

  void _onTaskErrorCleared(
    TaskErrorCleared event,
    Emitter<TaskState> emit,
  ) {
    emit(
      state.copyWith(
        status: TaskViewStatus.success,
        failure: () => null,
      ),
    );
  }

  void _syncHomeWidget() {
    final budget = _financialAnalyticsBloc?.state.summary.totalBudgetRials ?? 0;
    unawaited(
      _widgetSyncService.syncSnapshot(
        dailyBudgetRials: budget,
        tasks: state.tasks,
      ),
    );
  }

  void _replaceTaskInState(
    TaskEntity updatedTask,
    Emitter<TaskState> emit,
  ) {
    final updatedList = state.tasks
        .map((existing) =>
            existing.id == updatedTask.id ? updatedTask : existing)
        .toList(growable: false);

    emit(
      state.copyWith(
        status: TaskViewStatus.success,
        tasks: updatedList,
        failure: () => null,
      ),
    );
    _syncHomeWidget();
  }

  Future<void> _reloadTasksPreservingState(Emitter<TaskState> emit) async {
    final reloadResult = await _getTasksUseCase(
      GetTasksParams(
        status: state.selectedFilter,
        scheduledDate: state.selectedDate,
      ),
    );
    reloadResult.fold(
      onSuccess: (tasks) {
        emit(
          state.copyWith(
            status: TaskViewStatus.success,
            tasks: tasks,
            failure: () => null,
          ),
        );
        _syncHomeWidget();
      },
      onFailure: (failure) => emit(
        state.copyWith(
          status: TaskViewStatus.failure,
          failure: () => failure,
        ),
      ),
    );
  }

  /// Records a persistent overdue penalty notification.
  Future<void> logOverdueTaskNotification(TaskEntity task, {int penaltyXp = 5}) async {
    if (_notificationRepository != null) {
      final notification = AppNotificationEntity(
        id: _uuid.v4(),
        title: 'موعد گذشته',
        message: "تسک '${task.title}' انجام نشد و موعد آن گذشت. (-$penaltyXp XP)",
        type: AppNotificationType.penalty,
        timestamp: DateTime.now().toUtc(),
      );
      await _notificationRepository.saveNotification(notification);
      _notificationBloc?.add(NotificationAdded(notification));
    }
  }

  Future<void> _onTaskOverdueCheckRequested(
    TaskOverdueCheckRequested event,
    Emitter<TaskState> emit,
  ) async {
    final now = event.timestamp ?? DateTime.now();
    final overdueTasks = state.tasks.where((task) {
      return task.isOverdue(now, isVacationMode: state.isVacationMode) &&
          !state.notifiedOverdueTaskIds.contains(task.id);
    }).toList(growable: false);

    if (overdueTasks.isEmpty) return;

    unawaited(_soundService.playErrorBuzz());
    final newlyNotifiedIds = <String>[];
    for (final task in overdueTasks) {
      newlyNotifiedIds.add(task.id);
      final notification = AppNotificationEntity(
        id: _uuid.v4(),
        title: 'هشدار موعد تسک',
        message: "تسک '${task.title}' موعدش گذشت! سریعاً انجامش دهید.",
        type: AppNotificationType.warning,
        timestamp: now.toUtc(),
      );
      if (_notificationRepository != null) {
        await _notificationRepository.saveNotification(notification);
      }
      _notificationBloc?.add(NotificationAdded(notification));

      // 🌟 THE FINANCIAL BRIDGE: Deduct -10,000 Rials from budget per newly overdue task
      _financialAnalyticsBloc?.add(
        const FinancialAnalyticsBudgetAdjusted(
          deltaRials: -10000,
          reason: 'جریمه موعد گذشته',
        ),
      );
      _gamificationBloc?.add(
        GamificationTaskOverdue(
          taskId: task.id,
          title: task.title,
          penaltyXp: 5,
        ),
      );
    }

    emit(
      state.copyWith(
        notifiedOverdueTaskIds: [
          ...state.notifiedOverdueTaskIds,
          ...newlyNotifiedIds,
        ],
      ),
    );
  }
}
