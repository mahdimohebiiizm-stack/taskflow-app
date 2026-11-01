import 'package:flutter/material.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

/// Horizontal filter bar allowing the user to filter tasks by [TaskStatus] or view all.
class StatusFilterBar extends StatelessWidget {
  final TaskStatus? selectedFilter;
  final int totalCount;
  final int todoCount;
  final int inProgressCount;
  final int doneCount;
  final ValueChanged<TaskStatus?> onFilterSelected;

  const StatusFilterBar({
    super.key,
    required this.selectedFilter,
    required this.totalCount,
    required this.todoCount,
    required this.inProgressCount,
    required this.doneCount,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          FilterChip(
            key: const Key('filter_chip_all'),
            label: Text('All ($totalCount)'),
            selected: selectedFilter == null,
            onSelected: (_) => onFilterSelected(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const Key('filter_chip_todo'),
            label: Text('${TaskStatus.todo.label} ($todoCount)'),
            selected: selectedFilter == TaskStatus.todo,
            onSelected: (_) => onFilterSelected(TaskStatus.todo),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const Key('filter_chip_in_progress'),
            label: Text('${TaskStatus.inProgress.label} ($inProgressCount)'),
            selected: selectedFilter == TaskStatus.inProgress,
            onSelected: (_) => onFilterSelected(TaskStatus.inProgress),
          ),
          const SizedBox(width: 8),
          FilterChip(
            key: const Key('filter_chip_done'),
            label: Text('${TaskStatus.done.label} ($doneCount)'),
            selected: selectedFilter == TaskStatus.done,
            onSelected: (_) => onFilterSelected(TaskStatus.done),
          ),
        ],
      ),
    );
  }
}
