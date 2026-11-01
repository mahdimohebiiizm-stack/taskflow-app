import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/expense_item_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/entities/sub_task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/usecases/add_task_expense_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/create_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/delete_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/get_tasks_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/penalize_day_tasks_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/revert_day_penalty_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/toggle_sub_task_usecase.dart';
import 'package:task_flow/features/tasks/domain/usecases/transition_task_status_usecase.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_event.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_state.dart';

class MockGetTasksUseCase extends Mock implements GetTasksUseCase {}

class MockCreateTaskUseCase extends Mock implements CreateTaskUseCase {}

class MockTransitionTaskStatusUseCase extends Mock
    implements TransitionTaskStatusUseCase {}

class MockToggleSubTaskUseCase extends Mock implements ToggleSubTaskUseCase {}

class MockDeleteTaskUseCase extends Mock implements DeleteTaskUseCase {}

class MockAddTaskExpenseUseCase extends Mock implements AddTaskExpenseUseCase {}

class MockPenalizeDayTasksUseCase extends Mock
    implements PenalizeDayTasksUseCase {}

class MockRevertDayPenaltyUseCase extends Mock
    implements RevertDayPenaltyUseCase {}

void main() {
  late MockGetTasksUseCase mockGetTasks;
  late MockCreateTaskUseCase mockCreateTask;
  late MockTransitionTaskStatusUseCase mockTransitionStatus;
  late MockToggleSubTaskUseCase mockToggleSubTask;
  late MockDeleteTaskUseCase mockDeleteTask;
  late MockAddTaskExpenseUseCase mockAddExpense;
  late MockPenalizeDayTasksUseCase mockPenalizeDayTasks;
  late MockRevertDayPenaltyUseCase mockRevertDayPenalty;

  final baseTime = DateTime.utc(2026, 10, 10, 12, 0);
  final laterTime = DateTime.utc(2026, 10, 10, 13, 0);

  late TaskEntity sampleTaskWithIncompleteSubTask;
  late TaskEntity sampleDoneTask;

  setUpAll(() {
    registerFallbackValue(const GetTasksParams());
    registerFallbackValue(
      const CreateTaskParams(id: 'fallback', title: 'fallback'),
    );
    registerFallbackValue(
      const TransitionTaskStatusParams(
        taskId: 'fallback',
        targetStatus: TaskStatus.todo,
      ),
    );
    registerFallbackValue(
      const ToggleSubTaskParams(taskId: 'fallback', subTaskId: 'fallback'),
    );
    registerFallbackValue(const DeleteTaskParams(taskId: 'fallback'));
    registerFallbackValue(
      const AddTaskExpenseParams(
        taskId: 'fallback',
        expenseId: 'fallback',
        title: 'fallback',
        amountMinorUnits: 100,
        currency: Currency.irt,
      ),
    );
    registerFallbackValue(const PenalizeDayTasksParams());
    registerFallbackValue(
      const RevertDayPenaltyParams(taskIds: ['fallback']),
    );
  });

  setUp(() {
    mockGetTasks = MockGetTasksUseCase();
    mockCreateTask = MockCreateTaskUseCase();
    mockTransitionStatus = MockTransitionTaskStatusUseCase();
    mockToggleSubTask = MockToggleSubTaskUseCase();
    mockDeleteTask = MockDeleteTaskUseCase();
    mockAddExpense = MockAddTaskExpenseUseCase();
    mockPenalizeDayTasks = MockPenalizeDayTasksUseCase();
    mockRevertDayPenalty = MockRevertDayPenaltyUseCase();

    final incompleteSubTask = (SubTaskEntity.create(
      id: 'sub-1',
      title: 'Write BLoC Tests',
      isCompleted: false,
    ) as Success<SubTaskEntity, DomainFailure>)
        .value;

    final completedSubTask = incompleteSubTask.toggle();

    sampleTaskWithIncompleteSubTask = (TaskEntity.create(
      id: 'task-1',
      title: 'Verify Single Immutable State Pattern',
      status: TaskStatus.inProgress,
      priority: TaskPriority.high,
      subTasks: <SubTaskEntity>[incompleteSubTask],
      createdAt: baseTime,
    ) as Success<TaskEntity, DomainFailure>)
        .value;

    sampleDoneTask = (TaskEntity.create(
      id: 'task-2',
      title: 'Completed Task',
      status: TaskStatus.done,
      priority: TaskPriority.medium,
      subTasks: <SubTaskEntity>[completedSubTask],
      createdAt: baseTime,
    ) as Success<TaskEntity, DomainFailure>)
        .value;
  });

  TaskBloc buildBloc() {
    return TaskBloc(
      getTasksUseCase: mockGetTasks,
      createTaskUseCase: mockCreateTask,
      transitionTaskStatusUseCase: mockTransitionStatus,
      toggleSubTaskUseCase: mockToggleSubTask,
      deleteTaskUseCase: mockDeleteTask,
      addTaskExpenseUseCase: mockAddExpense,
      penalizeDayTasksUseCase: mockPenalizeDayTasks,
      revertDayPenaltyUseCase: mockRevertDayPenalty,
    );
  }

  group('TaskBloc — Single Immutable State & Non-Destructive Error Handling',
      () {
    blocTest<TaskBloc, TaskState>(
      'emits [loading, success] with loaded tasks when TasksLoadRequested succeeds',
      build: () {
        when(() => mockPenalizeDayTasks(any())).thenAnswer(
          (_) async => const Success(<TaskEntity>[]),
        );
        when(() => mockGetTasks(any())).thenAnswer(
          (_) async => Success(<TaskEntity>[
            sampleTaskWithIncompleteSubTask,
            sampleDoneTask,
          ]),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TasksLoadRequested()),
      expect: () => <TaskState>[
        TaskState(status: TaskViewStatus.loading),
        TaskState(
          status: TaskViewStatus.success,
          tasks: <TaskEntity>[
            sampleTaskWithIncompleteSubTask,
            sampleDoneTask,
          ],
        ),
      ],
    );

    blocTest<TaskBloc, TaskState>(
      'preserves existing tasks list in TaskState when transitioning to Done fails with IncompleteSubTasksFailure',
      build: () {
        when(() => mockTransitionStatus(any())).thenAnswer(
          (_) async => const Err(
            IncompleteSubTasksFailure(remainingSubTasks: 1),
          ),
        );
        return buildBloc();
      },
      seed: () => TaskState(
        status: TaskViewStatus.success,
        tasks: <TaskEntity>[sampleTaskWithIncompleteSubTask],
      ),
      act: (bloc) => bloc.add(
        TaskStatusTransitioned(
          taskId: 'task-1',
          targetStatus: TaskStatus.done,
          timestamp: laterTime,
        ),
      ),
      expect: () => <TaskState>[
        TaskState(
          status: TaskViewStatus.failure,
          tasks: <TaskEntity>[sampleTaskWithIncompleteSubTask],
          failure: const IncompleteSubTasksFailure(remainingSubTasks: 1),
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.tasks, hasLength(1));
        expect(bloc.state.hasError, isTrue);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'updates parent Task from Done to In Progress in-place when SubTaskToggled unchecks a sub-task',
      build: () {
        final rolledBackTask = (sampleDoneTask.toggleSubTask(
          'sub-1',
          updatedAt: laterTime,
        ) as Success<TaskEntity, DomainFailure>)
            .value;

        when(() => mockToggleSubTask(any())).thenAnswer(
          (_) async => Success(rolledBackTask),
        );
        return buildBloc();
      },
      seed: () => TaskState(
        status: TaskViewStatus.success,
        tasks: <TaskEntity>[sampleDoneTask],
      ),
      act: (bloc) => bloc.add(
        SubTaskToggled(
          taskId: 'task-2',
          subTaskId: 'sub-1',
          timestamp: laterTime,
        ),
      ),
      expect: () => <TaskState>[
        TaskState(
          status: TaskViewStatus.success,
          tasks: <TaskEntity>[
            (sampleDoneTask.toggleSubTask('sub-1', updatedAt: laterTime)
                    as Success<TaskEntity, DomainFailure>)
                .value,
          ],
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.tasks.first.status, equals(TaskStatus.inProgress));
        expect(bloc.state.tasks.first.subTasks.first.isCompleted, isFalse);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'filters visible tasks via filteredTasks when TaskStatusFilterChanged is dispatched and clears transient error on TaskErrorCleared',
      build: buildBloc,
      seed: () => TaskState(
        status: TaskViewStatus.failure,
        tasks: <TaskEntity>[
          sampleTaskWithIncompleteSubTask,
          sampleDoneTask,
        ],
        failure: const IncompleteSubTasksFailure(remainingSubTasks: 1),
      ),
      act: (bloc) {
        bloc
          ..add(const TaskErrorCleared())
          ..add(const TaskStatusFilterChanged(TaskStatus.done));
      },
      expect: () => <TaskState>[
        TaskState(
          status: TaskViewStatus.success,
          tasks: <TaskEntity>[
            sampleTaskWithIncompleteSubTask,
            sampleDoneTask,
          ],
        ),
        TaskState(
          status: TaskViewStatus.success,
          tasks: <TaskEntity>[
            sampleTaskWithIncompleteSubTask,
            sampleDoneTask,
          ],
          selectedFilter: TaskStatus.done,
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.filteredTasks, equals(<TaskEntity>[sampleDoneTask]));
        expect(bloc.state.inProgressCount, equals(1));
        expect(bloc.state.doneCount, equals(1));
      },
    );

    blocTest<TaskBloc, TaskState>(
      'records Toman expense on TaskExpenseAdded and computes totalBoardExpensesIn accurately',
      build: () {
        final expenseItem = (ExpenseItemEntity.create(
          id: 'exp-1',
          title: 'API Gateway License',
          money: Money.reconstitute(
            amountMinorUnits: 600000,
            currency: Currency.irt,
          ),
          incurredAt: laterTime,
        ) as Success<ExpenseItemEntity, DomainFailure>)
            .value;

        final taskWithExpense = (sampleTaskWithIncompleteSubTask.addExpense(
          expenseItem,
          updatedAt: laterTime,
        ) as Success<TaskEntity, DomainFailure>)
            .value;

        when(() => mockAddExpense(any())).thenAnswer(
          (_) async => Success(taskWithExpense),
        );

        return buildBloc();
      },
      seed: () => TaskState(
        status: TaskViewStatus.success,
        tasks: <TaskEntity>[sampleTaskWithIncompleteSubTask],
      ),
      act: (bloc) {
        bloc.add(
          TaskExpenseAdded(
            taskId: 'task-1',
            expenseId: 'exp-1',
            title: 'API Gateway License',
            amountMinorUnits: 600000,
            currency: Currency.irt,
            incurredAt: laterTime,
          ),
        );
      },
      verify: (bloc) {
        final totalResult = bloc.state.totalBoardExpensesIn(Currency.irt);
        expect(totalResult.isSuccess, isTrue);
        final totalMoney = (totalResult as Success<Money, DomainFailure>).value;
        expect(totalMoney.format(), equals('600,000 تومان'));
      },
    );

    blocTest<TaskBloc, TaskState>(
      'stores penalized task IDs on DayEnded and reverts them on DayEndedUndone',
      build: () {
        final penalizedTask = sampleTaskWithIncompleteSubTask.penalize(
          updatedAt: laterTime,
        );
        when(() => mockPenalizeDayTasks(any())).thenAnswer(
          (_) async => Success(<TaskEntity>[penalizedTask]),
        );
        when(() => mockRevertDayPenalty(any())).thenAnswer(
          (_) async => const Success(null),
        );
        var callCount = 0;
        when(() => mockGetTasks(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return Success(<TaskEntity>[penalizedTask]);
          }
          return Success(<TaskEntity>[sampleTaskWithIncompleteSubTask]);
        });
        return buildBloc();
      },
      seed: () => TaskState(
        status: TaskViewStatus.success,
        tasks: <TaskEntity>[sampleTaskWithIncompleteSubTask],
      ),
      act: (bloc) async {
        bloc.add(DayEnded(timestamp: laterTime));
        await Future<void>.delayed(Duration.zero);
        bloc.add(DayEndedUndone(timestamp: laterTime));
      },
      verify: (bloc) {
        verify(() => mockPenalizeDayTasks(any())).called(1);
        verify(() => mockRevertDayPenalty(any())).called(1);
        expect(bloc.state.lastPenalizedTaskIds, isEmpty);
        expect(bloc.state.tasks.single.isPenalized, isFalse);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'completing a recurring task (daily/weekly/monthly) automatically creates next occurrence and shifts dueDate & reminderDateTime',
      build: () {
        final dueDate = DateTime(2026, 10, 10, 9, 0);
        final reminder = DateTime(2026, 10, 10, 8, 45);
        final completedRecurring = (TaskEntity.create(
          id: 'rec-1',
          title: 'مطالعه روزانه',
          status: TaskStatus.done,
          priority: TaskPriority.high,
          dueDate: dueDate,
          recurrenceRule: TaskRecurrenceRules.daily,
          reminderDateTime: reminder,
          createdAt: baseTime,
        ) as Success<TaskEntity, DomainFailure>)
            .value;

        when(() => mockTransitionStatus(any())).thenAnswer(
          (_) async => Success(completedRecurring),
        );

        when(() => mockCreateTask(any())).thenAnswer((invocation) async {
          final params =
              invocation.positionalArguments.first as CreateTaskParams;
          final spawned = (TaskEntity.create(
            id: params.id,
            title: params.title,
            status: params.status,
            priority: params.priority,
            dueDate: params.dueDate,
            recurrenceRule: params.recurrenceRule,
            reminderDateTime: params.reminderDateTime,
            createdAt: params.createdAt ?? laterTime,
          ) as Success<TaskEntity, DomainFailure>)
              .value;
          return Success(spawned);
        });

        return buildBloc();
      },
      seed: () {
        final initialRecurring = (TaskEntity.create(
          id: 'rec-1',
          title: 'مطالعه روزانه',
          status: TaskStatus.todo,
          priority: TaskPriority.high,
          dueDate: DateTime(2026, 10, 10, 9, 0),
          recurrenceRule: TaskRecurrenceRules.daily,
          reminderDateTime: DateTime(2026, 10, 10, 8, 45),
          createdAt: baseTime,
        ) as Success<TaskEntity, DomainFailure>)
            .value;
        return TaskState(
          status: TaskViewStatus.success,
          tasks: <TaskEntity>[initialRecurring],
        );
      },
      act: (bloc) => bloc.add(
        TaskStatusTransitioned(
          taskId: 'rec-1',
          targetStatus: TaskStatus.done,
          timestamp: laterTime,
        ),
      ),
      verify: (bloc) {
        verify(() => mockCreateTask(any())).called(1);
        expect(bloc.state.tasks.length, 2);
        final doneInstance =
            bloc.state.tasks.firstWhere((t) => t.id == 'rec-1');
        final nextInstance =
            bloc.state.tasks.firstWhere((t) => t.id != 'rec-1');
        expect(doneInstance.status, TaskStatus.done);
        expect(nextInstance.status, TaskStatus.todo);
        expect(nextInstance.recurrenceRule, TaskRecurrenceRules.daily);
        expect(nextInstance.dueDate, DateTime(2026, 10, 11, 9, 0));
        expect(
          nextInstance.reminderDateTime,
          DateTime(2026, 10, 11, 8, 45),
        );
      },
    );

    blocTest<TaskBloc, TaskState>(
      'Vacation Mode rolls over uncompleted recurring tasks without penalty and without spawning duplicate instances',
      build: () {
        when(() => mockPenalizeDayTasks(any())).thenAnswer(
          (_) async => const Success(<TaskEntity>[]),
        );
        return buildBloc();
      },
      seed: () {
        final now = DateTime.now();
        final todayMorning = DateTime(now.year, now.month, now.day, 9, 0);
        final recurringToday = (TaskEntity.create(
          id: 'rec-vac-1',
          title: 'ورزش صبحگاهی',
          status: TaskStatus.todo,
          dueDate: todayMorning,
          recurrenceRule: TaskRecurrenceRules.weekly,
          reminderDateTime: DateTime(now.year, now.month, now.day, 8, 30),
          createdAt: todayMorning,
        ) as Success<TaskEntity, DomainFailure>)
            .value;
        return TaskState(
          status: TaskViewStatus.success,
          isVacationMode: true,
          tasks: <TaskEntity>[recurringToday],
        );
      },
      act: (bloc) => bloc.add(DayEnded(timestamp: DateTime.now())),
      verify: (bloc) {
        verifyNever(() => mockCreateTask(any()));
        expect(bloc.state.tasks.length, 1);
        final rolled = bloc.state.tasks.single;
        expect(rolled.isPenalized, isFalse);
        expect(rolled.recurrenceRule, TaskRecurrenceRules.weekly);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'triggers playSuccessChime when task transitions to Done',
      setUp: () {
        SoundAndHapticService.instance.resetStats();
      },
      build: () {
        when(
          () => mockTransitionStatus(
            const TransitionTaskStatusParams(
              taskId: 'task-1',
              targetStatus: TaskStatus.done,
            ),
          ),
        ).thenAnswer(
          (_) async => Success(sampleDoneTask),
        );
        when(() => mockPenalizeDayTasks(any())).thenAnswer(
          (_) async => const Success(<TaskEntity>[]),
        );
        when(() => mockGetTasks(any())).thenAnswer(
          (_) async => Success(<TaskEntity>[sampleDoneTask]),
        );
        return buildBloc();
      },
      seed: () => TaskState(
        status: TaskViewStatus.success,
        tasks: <TaskEntity>[sampleTaskWithIncompleteSubTask],
      ),
      act: (bloc) => bloc.add(
        const TaskStatusTransitioned(
          taskId: 'task-1',
          targetStatus: TaskStatus.done,
        ),
      ),
      verify: (bloc) {
        expect(
          SoundAndHapticService.instance.taskCompletionPlayCount,
          greaterThanOrEqualTo(1),
        );
        expect(
          SoundAndHapticService.instance.lastPlayedSound,
          equals(SoundEffectType.taskCompleted),
        );
      },
    );

    blocTest<TaskBloc, TaskState>(
      'triggers playErrorBuzz on DayEnded when penalized tasks exist',
      setUp: () {
        SoundAndHapticService.instance.resetStats();
      },
      build: () {
        when(() => mockPenalizeDayTasks(any())).thenAnswer(
          (_) async => Success(<TaskEntity>[sampleTaskWithIncompleteSubTask]),
        );
        when(() => mockGetTasks(any())).thenAnswer(
          (_) async => Success(<TaskEntity>[sampleTaskWithIncompleteSubTask]),
        );
        return buildBloc();
      },
      seed: () => TaskState(
        status: TaskViewStatus.success,
        tasks: <TaskEntity>[sampleTaskWithIncompleteSubTask],
      ),
      act: (bloc) => bloc.add(DayEnded(timestamp: DateTime.now())),
      verify: (bloc) {
        expect(
          SoundAndHapticService.instance.errorBuzzPlayCount,
          greaterThanOrEqualTo(1),
        );
        expect(
          SoundAndHapticService.instance.lastPlayedSound,
          equals(SoundEffectType.errorBuzz),
        );
      },
    );
  });
}
