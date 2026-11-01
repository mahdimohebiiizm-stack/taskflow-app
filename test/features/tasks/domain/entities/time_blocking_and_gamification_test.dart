import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_state.dart';

void main() {
  final now = DateTime.now();

  group('TaskEntity — Time-blocking Architecture', () {
    test('should correctly store and expose time block and calculate minutes', () {
      final taskResult = TaskEntity.create(
        id: 'tb-1',
        title: 'برنامه‌ریزی صبحگاهی',
        startTime: '07:30',
        endTime: '09:00',
        createdAt: now,
      );

      expect(taskResult.isSuccess, isTrue);
      final task = (taskResult as Success<TaskEntity, dynamic>).value;
      expect(task.hasTimeBlock, isTrue);
      expect(task.startTime, equals('07:30'));
      expect(task.endTime, equals('09:00'));
      expect(task.timeBlockFormatted, equals('07:30 - 09:00'));
      expect(task.startTimeMinutes, equals(7 * 60 + 30)); // 450
      expect(task.endTimeMinutes, equals(9 * 60)); // 540
    });

    test('should mark task as penalized with penalize method', () {
      final task = (TaskEntity.create(
        id: 'tb-2',
        title: 'مطالعه روزانه',
        createdAt: now,
      ) as Success<TaskEntity, dynamic>).value;

      expect(task.isPenalized, isFalse);

      final penalizedTask = task.penalize(updatedAt: now.add(const Duration(hours: 1)));
      expect(penalizedTask.isPenalized, isTrue);
      expect(penalizedTask.id, equals('tb-2'));
      expect(penalizedTask.title, equals('مطالعه روزانه'));
    });
  });

  group('TaskState — Time Sorting & Gamification Engine', () {
    test('should sort today tasks chronologically by start time', () {
      final taskEarly = (TaskEntity.create(
        id: 't-early',
        title: 'ورزش صبحگاهی',
        dueDate: now,
        startTime: '06:00',
        endTime: '07:00',
        createdAt: now,
      ) as Success<TaskEntity, dynamic>).value;

      final taskMid = (TaskEntity.create(
        id: 't-mid',
        title: 'جلسه کاری',
        dueDate: now,
        startTime: '10:30',
        endTime: '11:30',
        createdAt: now,
      ) as Success<TaskEntity, dynamic>).value;

      final taskLate = (TaskEntity.create(
        id: 't-late',
        title: 'مرور اهداف شبانه',
        dueDate: now,
        startTime: '21:00',
        endTime: '22:00',
        createdAt: now,
      ) as Success<TaskEntity, dynamic>).value;

      final taskNoTime = (TaskEntity.create(
        id: 't-notime',
        title: 'کار بدون زمان مشخص',
        dueDate: now,
        priority: TaskPriority.critical,
        createdAt: now,
      ) as Success<TaskEntity, dynamic>).value;

      // Add them out of order
      final state = TaskState(
        tasks: [taskLate, taskEarly, taskNoTime, taskMid],
      );

      final sorted = state.todayTasks;
      expect(sorted, hasLength(4));
      // First 3 should be strictly sorted by startTime
      expect(sorted[0].id, equals('t-early'));
      expect(sorted[1].id, equals('t-mid'));
      expect(sorted[2].id, equals('t-late'));
      expect(sorted[3].id, equals('t-notime'));
    });

    test('should detect full reward state when all tasks are completed', () {
      final task1 = (TaskEntity.create(
        id: 'r-1',
        title: 'هدف اول',
        dueDate: now,
        status: TaskStatus.done,
        createdAt: now,
      ) as Success<TaskEntity, dynamic>).value;

      final task2 = (TaskEntity.create(
        id: 'r-2',
        title: 'هدف دوم',
        dueDate: now,
        status: TaskStatus.done,
        createdAt: now,
      ) as Success<TaskEntity, dynamic>).value;

      final state = TaskState(tasks: [task1, task2]);
      expect(state.isAllTodayTasksCompleted, isTrue);
      expect(state.todayCompletionRatio, equals(1.0));
    });

    test('should identify penalized tasks count and list correctly', () {
      final taskNormal = (TaskEntity.create(
        id: 'p-1',
        title: 'تسک عادی',
        dueDate: now,
        createdAt: now,
      ) as Success<TaskEntity, dynamic>).value;

      final taskPenalized = (TaskEntity.create(
        id: 'p-2',
        title: 'تسک معوقه',
        dueDate: now,
        isPenalized: true,
        createdAt: now,
      ) as Success<TaskEntity, dynamic>).value;

      final state = TaskState(tasks: [taskNormal, taskPenalized]);
      expect(state.todayPenalizedCount, equals(1));
      expect(state.todayPenalizedTasks.single.id, equals('p-2'));
      expect(state.isAllTodayTasksCompleted, isFalse);
    });

    test('should return false for isAllTodayTasksCompleted when all tasks are done but one is penalized', () {
      final taskDone = (TaskEntity.create(
        id: 'p-done',
        title: 'تسک انجام‌شده',
        dueDate: now,
        status: TaskStatus.done,
        createdAt: now,
      ) as Success<TaskEntity, dynamic>).value;

      final taskDonePenalized = (TaskEntity.create(
        id: 'p-penalized',
        title: 'تسک جریمه‌شده',
        dueDate: now,
        status: TaskStatus.done,
        isPenalized: true,
        createdAt: now,
      ) as Success<TaskEntity, dynamic>).value;

      final state = TaskState(tasks: [taskDone, taskDonePenalized]);
      expect(state.todayPenalizedCount, equals(1));
      expect(state.isAllTodayTasksCompleted, isFalse);
    });
  });
}
