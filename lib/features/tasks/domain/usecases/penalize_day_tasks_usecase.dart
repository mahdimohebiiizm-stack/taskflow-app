import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';
import 'package:task_flow/features/tasks/domain/repositories/task_repository.dart';

/// Marks uncompleted tasks for today as penalized in SQLite storage,
/// or rolls them over to the next day without penalty when [PenalizeDayTasksParams.isVacationMode] is active.
class PenalizeDayTasksUseCase
    implements UseCase<List<TaskEntity>, PenalizeDayTasksParams> {
  final TaskRepository _repository;

  const PenalizeDayTasksUseCase(this._repository);

  @override
  Future<Result<List<TaskEntity>, Failure>> call(
    PenalizeDayTasksParams params,
  ) async {
    final tasksResult = await _repository.getTasks();
    switch (tasksResult) {
      case Err<List<TaskEntity>, Failure>(failure: final failure):
        return Err(failure);
      case Success<List<TaskEntity>, Failure>(value: final allTasks):
        final now = params.now ?? DateTime.now();
        final todayMidnight = DateTime(now.year, now.month, now.day);
        final tomorrowMidnight = DateTime(now.year, now.month, now.day + 1);

        // در حالت استراحت (Vacation Mode): هیچ جریمه‌ای ثبت نمی‌شود و تسک‌ها/عادت‌های ناتمام بدون جریمه به روز بعد تمدید می‌شوند.
        if (params.isVacationMode) {
          for (final task in allTasks) {
            if (task.status == TaskStatus.done) {
              continue;
            }
            final effective = (task.dueDate ?? task.createdAt).toLocal();
            final taskDate =
                DateTime(effective.year, effective.month, effective.day);
            final isPastUnfinished = taskDate.isBefore(todayMidnight);
            final isTodayUnfinished = task.isScheduledForDate(now);

            if (params.penalizeToday && (isTodayUnfinished || isPastUnfinished)) {
              final rolledOver = task.rollOverToDate(
                tomorrowMidnight,
                updatedAt: now,
              );
              await _repository.saveTask(rolledOver);
            } else if (params.includePastDays && isPastUnfinished) {
              final rolledOver = task.rollOverToDate(
                todayMidnight,
                updatedAt: now,
              );
              await _repository.saveTask(rolledOver);
            }
          }
          return const Success(<TaskEntity>[]);
        }

        final toPenalizeIds = <String>[];
        final updatedList = <TaskEntity>[];

        for (final task in allTasks) {
          if (task.status == TaskStatus.done || task.isPenalized) {
            continue;
          }

          final effective = (task.dueDate ?? task.createdAt).toLocal();
          final taskDate =
              DateTime(effective.year, effective.month, effective.day);

          // If task has scheduledEndDateTime extending across midnight into the future, do not penalize prematurely
          final isStillActiveOvernight = task.scheduledEndDateTime != null &&
              now.isBefore(task.scheduledEndDateTime!);

          final isPastUnfinished =
              taskDate.isBefore(todayMidnight) && !isStillActiveOvernight;
          final isTodayUnfinished = task.isScheduledForDate(now);

          final shouldPenalize =
              (params.includePastDays && isPastUnfinished) ||
              (params.penalizeToday && isTodayUnfinished);

          if (shouldPenalize) {
            toPenalizeIds.add(task.id);
            updatedList.add(task.penalize(updatedAt: now));
          }
        }

        if (toPenalizeIds.isEmpty) {
          return const Success([]);
        }

        final batchResult =
            await _repository.batchPenalizeTasks(toPenalizeIds, now);
        switch (batchResult) {
          case Err(failure: final err):
            return Err(err);
          case Success():
            return Success(updatedList);
        }
    }
  }
}

class PenalizeDayTasksParams extends Equatable {
  final DateTime? now;
  final bool includePastDays;
  final bool penalizeToday;
  final bool isVacationMode;

  const PenalizeDayTasksParams({
    this.now,
    this.includePastDays = true,
    this.penalizeToday = true,
    this.isVacationMode = false,
  });

  @override
  List<Object?> get props => [
        now,
        includePastDays,
        penalizeToday,
        isVacationMode,
      ];
}
