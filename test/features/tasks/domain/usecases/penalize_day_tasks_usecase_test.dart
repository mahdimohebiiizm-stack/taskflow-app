import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';
import 'package:task_flow/features/tasks/domain/usecases/penalize_day_tasks_usecase.dart';

class _MockTaskRepository implements TaskRepository {
  List<TaskEntity> tasks = [];
  final List<TaskEntity> savedTasks = [];

  @override
  Future<Result<List<TaskEntity>, Failure>> getTasks({
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? scheduledDate,
  }) async {
    return Success(tasks);
  }

  @override
  Future<Result<TaskEntity, Failure>> saveTask(TaskEntity task) async {
    savedTasks.add(task);
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      tasks[idx] = task;
    } else {
      tasks.add(task);
    }
    return Success(task);
  }

  @override
  Future<Result<void, Failure>> batchPenalizeTasks(
    List<String> taskIds,
    DateTime updatedAt,
  ) async {
    for (var i = 0; i < tasks.length; i++) {
      if (taskIds.contains(tasks[i].id)) {
        tasks[i] = tasks[i].penalize(updatedAt: updatedAt);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void, Failure>> batchRevertPenalizedTasks(
    List<String> taskIds,
    DateTime updatedAt,
  ) async {
    return const Success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _MockTaskRepository repository;
  late PenalizeDayTasksUseCase useCase;

  setUp(() {
    repository = _MockTaskRepository();
    useCase = PenalizeDayTasksUseCase(repository);
  });

  test('PenalizeDayTasksUseCase should auto-penalize unfinished past days tasks while skipping done tasks', () async {
    final now = DateTime(2026, 10, 11, 10, 0);
    final yesterday = DateTime(2026, 10, 10, 15, 0);

    final pastTaskUnfinished = (TaskEntity.create(
      id: 'past-1',
      title: 'کار دیروز ناتمام',
      dueDate: yesterday,
      status: TaskStatus.todo,
      createdAt: yesterday,
    ) as Success<TaskEntity, dynamic>).value;

    final pastTaskDone = (TaskEntity.create(
      id: 'past-done',
      title: 'کار دیروز تکمیل‌شده',
      dueDate: yesterday,
      status: TaskStatus.done,
      createdAt: yesterday,
    ) as Success<TaskEntity, dynamic>).value;

    final todayTask = (TaskEntity.create(
      id: 'today-1',
      title: 'کار امروز',
      dueDate: now,
      status: TaskStatus.todo,
      createdAt: now,
    ) as Success<TaskEntity, dynamic>).value;

    repository.tasks = [pastTaskUnfinished, pastTaskDone, todayTask];

    final result = await useCase(
      PenalizeDayTasksParams(
        now: now,
        includePastDays: true,
        penalizeToday: false,
      ),
    );

    expect(result, isA<Success<List<TaskEntity>, Failure>>());
    final penalizedList = (result as Success<List<TaskEntity>, Failure>).value;

    expect(penalizedList.length, equals(1));
    expect(penalizedList.first.id, equals('past-1'));
    expect(penalizedList.first.isPenalized, isTrue);

    // Ensure today task is not penalized when penalizeToday is false
    final updatedToday = repository.tasks.firstWhere((t) => t.id == 'today-1');
    expect(updatedToday.isPenalized, isFalse);
  });

  test('PenalizeDayTasksUseCase should NOT penalize midnight-crossing task before its end time', () async {
    // Task scheduled on Oct 10 from 23:00 to 01:00 (into Oct 11)
    final yesterday = DateTime(2026, 10, 10, 22, 0);
    final nowBeforeEnd = DateTime(2026, 10, 11, 0, 30); // 00:30 AM on Oct 11

    final overnightTask = (TaskEntity.create(
      id: 'overnight-1',
      title: 'مطالعه شبانه',
      dueDate: yesterday,
      startTime: '23:00',
      endTime: '01:00',
      status: TaskStatus.inProgress,
      createdAt: yesterday,
    ) as Success<TaskEntity, dynamic>).value;

    repository.tasks = [overnightTask];

    final result = await useCase(
      PenalizeDayTasksParams(
        now: nowBeforeEnd,
        includePastDays: true,
        penalizeToday: false,
      ),
    );

    expect(result, isA<Success<List<TaskEntity>, Failure>>());
    final penalizedList = (result as Success<List<TaskEntity>, Failure>).value;
    expect(penalizedList, isEmpty);
  });

  test('PenalizeDayTasksUseCase should penalize today unfinished tasks on DayEnded', () async {
    final now = DateTime(2026, 10, 11, 23, 0);

    final todayTaskUnfinished = (TaskEntity.create(
      id: 'today-unfinished',
      title: 'کار امروز ناتمام',
      dueDate: now,
      status: TaskStatus.inProgress,
      createdAt: now,
    ) as Success<TaskEntity, dynamic>).value;

    repository.tasks = [todayTaskUnfinished];

    final result = await useCase(
      PenalizeDayTasksParams(
        now: now,
        includePastDays: true,
        penalizeToday: true,
      ),
    );

    expect(result, isA<Success<List<TaskEntity>, Failure>>());
    final penalizedList = (result as Success<List<TaskEntity>, Failure>).value;

    expect(penalizedList.length, equals(1));
    expect(penalizedList.first.id, equals('today-unfinished'));
    expect(penalizedList.first.isPenalized, isTrue);
  });

  test('PenalizeDayTasksUseCase in Vacation Mode should record zero penalties and automatically roll over unfinished routines to next day', () async {
    final now = DateTime(2026, 10, 11, 23, 0);

    final routineTask = (TaskEntity.create(
      id: 'habit-routine-1',
      title: 'مطالعه روزانه ۳۰ دقیقه',
      dueDate: now,
      tags: const ['عادت'],
      status: TaskStatus.todo,
      createdAt: now,
    ) as Success<TaskEntity, dynamic>).value;

    expect(
      routineTask.isOverdue(now.add(const Duration(hours: 2)), isVacationMode: true),
      isFalse,
    );

    repository.tasks = [routineTask];

    final result = await useCase(
      PenalizeDayTasksParams(
        now: now,
        includePastDays: true,
        penalizeToday: true,
        isVacationMode: true,
      ),
    );

    expect(result, isA<Success<List<TaskEntity>, Failure>>());
    final penalizedList = (result as Success<List<TaskEntity>, Failure>).value;
    expect(penalizedList, isEmpty);

    final rolledOverTask = repository.tasks.first;
    expect(rolledOverTask.isPenalized, isFalse);
    expect(rolledOverTask.dueDate!.year, equals(2026));
    expect(rolledOverTask.dueDate!.month, equals(10));
    expect(rolledOverTask.dueDate!.day, equals(12));
  });
}
