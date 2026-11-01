import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/sub_task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

void main() {
  final baseTime = DateTime.utc(2026, 10, 10, 12, 0);
  final laterTime = DateTime.utc(2026, 10, 10, 14, 0);

  SubTaskEntity buildSubTask({
    required String id,
    String title = 'Sub-task item',
    bool isCompleted = false,
  }) {
    final result = SubTaskEntity.create(
      id: id,
      title: title,
      isCompleted: isCompleted,
    );
    return (result as Success<SubTaskEntity, DomainFailure>).value;
  }

  group('TaskEntity Creation & Validation Invariants', () {
    test('should fail with ValidationFailure when title is empty or whitespace',
        () {
      final result = TaskEntity.create(
        id: 'task-1',
        title: '   ',
        createdAt: baseTime,
      );

      expect(result.isFailure, isTrue);
      expect(
        result,
        isA<Err<TaskEntity, DomainFailure>>().having(
          (e) => e.failure,
          'failure',
          isA<ValidationFailure>(),
        ),
      );
    });

    test(
        'should fail with IncompleteSubTasksFailure when created directly as Done with incomplete sub-tasks',
        () {
      final subTask = buildSubTask(id: 'sub-1', isCompleted: false);

      final result = TaskEntity.create(
        id: 'task-1',
        title: 'Release v1.0',
        status: TaskStatus.done,
        subTasks: [subTask],
        createdAt: baseTime,
      );

      expect(result.isFailure, isTrue);
      expect(
        result,
        isA<Err<TaskEntity, DomainFailure>>().having(
          (e) => e.failure,
          'failure',
          const IncompleteSubTasksFailure(remainingSubTasks: 1),
        ),
      );
    });
  });

  group('TaskEntity State Transitions (Domain Invariant Option C)', () {
    test('should allow flexible transition from To Do -> In Progress', () {
      final task = (TaskEntity.create(
        id: 'task-1',
        title: 'Design Clean Architecture',
        status: TaskStatus.todo,
        priority: TaskPriority.high,
        createdAt: baseTime,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      final result = task.transitionStatus(
        TaskStatus.inProgress,
        updatedAt: laterTime,
      );

      expect(result.isSuccess, isTrue);
      final updated = (result as Success<TaskEntity, DomainFailure>).value;
      expect(updated.status, TaskStatus.inProgress);
      expect(updated.updatedAt, laterTime);
    });

    test(
        'should block transition to Done and return IncompleteSubTasksFailure when any sub-task is incomplete',
        () {
      final subTasks = [
        buildSubTask(id: 'sub-1', title: 'Write Domain Models', isCompleted: true),
        buildSubTask(id: 'sub-2', title: 'Write Unit Tests', isCompleted: false),
      ];

      final task = (TaskEntity.create(
        id: 'task-1',
        title: 'Complete Sprint 1',
        status: TaskStatus.inProgress,
        subTasks: subTasks,
        createdAt: baseTime,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      final result = task.transitionStatus(
        TaskStatus.done,
        updatedAt: laterTime,
      );

      expect(result.isFailure, isTrue);
      expect(
        result,
        isA<Err<TaskEntity, DomainFailure>>().having(
          (e) => e.failure,
          'failure',
          const IncompleteSubTasksFailure(remainingSubTasks: 1),
        ),
      );
    });

    test(
        'should allow transition to Done when all sub-tasks are completed',
        () {
      final subTasks = [
        buildSubTask(id: 'sub-1', isCompleted: true),
        buildSubTask(id: 'sub-2', isCompleted: true),
      ];

      final task = (TaskEntity.create(
        id: 'task-1',
        title: 'Complete Sprint 1',
        status: TaskStatus.inProgress,
        subTasks: subTasks,
        createdAt: baseTime,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      final result = task.transitionStatus(
        TaskStatus.done,
        updatedAt: laterTime,
      );

      expect(result.isSuccess, isTrue);
      final updated = (result as Success<TaskEntity, DomainFailure>).value;
      expect(updated.status, TaskStatus.done);
      expect(updated.completionProgress, 1.0);
    });

    test(
        'should automatically revert parent Task from Done to In Progress when a completed SubTask is unchecked',
        () {
      final subTasks = [
        buildSubTask(id: 'sub-1', isCompleted: true),
        buildSubTask(id: 'sub-2', isCompleted: true),
      ];

      final doneTask = (TaskEntity.create(
        id: 'task-1',
        title: 'Deploy Production Release',
        status: TaskStatus.done,
        subTasks: subTasks,
        createdAt: baseTime,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      // Action: Uncheck 'sub-2'
      final toggleResult = doneTask.toggleSubTask(
        'sub-2',
        updatedAt: laterTime,
      );

      expect(toggleResult.isSuccess, isTrue);
      final updatedTask =
          (toggleResult as Success<TaskEntity, DomainFailure>).value;

      expect(updatedTask.status, TaskStatus.inProgress);
      expect(updatedTask.incompleteSubTasksCount, 1);
      expect(updatedTask.completionProgress, 0.5);
    });

    test(
        'should automatically revert parent Task from Done to In Progress when a new incomplete SubTask is added',
        () {
      final doneTask = (TaskEntity.create(
        id: 'task-1',
        title: 'Security Audit',
        status: TaskStatus.done,
        subTasks: [buildSubTask(id: 'sub-1', isCompleted: true)],
        createdAt: baseTime,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      final newIncompleteSubTask = buildSubTask(
        id: 'sub-2',
        title: 'Verify OWASP Top 10 controls',
        isCompleted: false,
      );

      final addResult = doneTask.addSubTask(
        newIncompleteSubTask,
        updatedAt: laterTime,
      );

      expect(addResult.isSuccess, isTrue);
      final updatedTask =
          (addResult as Success<TaskEntity, DomainFailure>).value;

      expect(updatedTask.status, TaskStatus.inProgress);
      expect(updatedTask.subTasks.length, 2);
      expect(updatedTask.hasIncompleteSubTasks, isTrue);
    });

    test(
        'All-Day task is NOT overdue at midday of its scheduled date and only overdue after 23:59:59',
        () {
      final scheduledDate = DateTime(2026, 10, 18);
      final allDayTask = (TaskEntity.create(
        id: 'task-allday-1',
        title: 'Review Product Roadmap',
        dueDate: scheduledDate,
        createdAt: scheduledDate,
      ) as Success<TaskEntity, DomainFailure>)
          .value;

      expect(allDayTask.isAllDay, isTrue);

      // 14:30 in the middle of the day -> NOT overdue
      final midday = DateTime(2026, 10, 18, 14, 30);
      expect(allDayTask.isOverdue(midday), isFalse);

      // 23:59:59 on the same day -> NOT overdue
      final endOfDay = DateTime(2026, 10, 18, 23, 59, 59);
      expect(allDayTask.isOverdue(endOfDay), isFalse);

      // 00:00:01 next morning -> Overdue
      final nextMorning = DateTime(2026, 10, 19, 0, 0, 1);
      expect(allDayTask.isOverdue(nextMorning), isTrue);

      // Vacation Mode -> Never overdue even next morning
      expect(allDayTask.isOverdue(nextMorning, isVacationMode: true), isFalse);
    });
  });
}
