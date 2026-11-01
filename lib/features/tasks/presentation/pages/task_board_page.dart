import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:task_flow/core/theme/app_colors.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_event.dart';
import 'package:task_flow/features/tasks/presentation/bloc/task_state.dart';
import 'package:task_flow/features/tasks/presentation/widgets/create_task_sheet.dart';
import 'package:task_flow/features/tasks/presentation/widgets/status_filter_bar.dart';
import 'package:task_flow/features/tasks/presentation/widgets/task_card.dart';

/// Main Task Flow board page displaying status filter chips, task cards,
/// and non-destructive domain error notifications.
class TaskBoardPage extends StatelessWidget {
  const TaskBoardPage({super.key});

  void _openCreateTaskSheet(BuildContext context) {
    final taskBloc = context.read<TaskBloc>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.navBarDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CreateTaskSheet(
        onSubmitted: ({
          required title,
          required description,
          required priority,
          required dueDate,
          startTime,
          endTime,
          required subTaskTitles,
          initialExpenseMinorUnits,
          initialExpenseCurrency = Currency.irt,
          parentTaskId,
          workspaceId = 'default',
          tags = const <String>[],
          recurrenceRule,
          reminderDateTime,
        }) {
          taskBloc.add(
            TaskCreated(
              title: title,
              description: description,
              priority: priority,
              dueDate: dueDate,
              startTime: startTime,
              endTime: endTime,
              subTaskTitles: subTaskTitles,
              initialExpenseMinorUnits: initialExpenseMinorUnits,
              initialExpenseCurrency: initialExpenseCurrency,
              parentTaskId: parentTaskId,
              workspaceId: workspaceId,
              tags: tags,
              recurrenceRule: recurrenceRule,
              reminderDateTime: reminderDateTime,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('open_create_task_fab'),
        onPressed: () => _openCreateTaskSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listenWhen: (previous, current) =>
            current.failure != null && current.failure != previous.failure,
        listener: (context, state) {
          final failure = state.failure;
          if (failure != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  key: const Key('domain_failure_snackbar'),
                  content: Text(failure.message),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            context.read<TaskBloc>().add(const TaskErrorCleared());
          }
        },
        builder: (context, state) {
          final bloc = context.read<TaskBloc>();
          final visibleTasks = state.filteredTasks;

          return Column(
            children: <Widget>[
              StatusFilterBar(
                selectedFilter: state.selectedFilter,
                totalCount: state.tasks.length,
                todoCount: state.todoCount,
                inProgressCount: state.inProgressCount,
                doneCount: state.doneCount,
                onFilterSelected: (filter) =>
                    bloc.add(TaskStatusFilterChanged(filter)),
              ),
              if (state.status == TaskViewStatus.loading && state.tasks.isEmpty)
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (visibleTasks.isEmpty)
                const Expanded(
                  child: Center(
                    key: Key('empty_tasks_placeholder'),
                    child: Text('No tasks found for the selected filter.'),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: visibleTasks.length,
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      return TaskCard(
                        task: task,
                        onStatusChanged: (targetStatus) => bloc.add(
                          TaskStatusTransitioned(
                            taskId: task.id,
                            targetStatus: targetStatus,
                          ),
                        ),
                        onSubTaskToggled: (subTaskId) => bloc.add(
                          SubTaskToggled(
                            taskId: task.id,
                            subTaskId: subTaskId,
                          ),
                        ),
                        onDeletePressed: () => bloc.add(
                          TaskDeleted(taskId: task.id),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
