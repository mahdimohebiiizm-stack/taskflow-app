import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/features/tasks/domain/entities/sub_task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/core/utils/jalali_date_formatter.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

/// Displays a single [TaskEntity] with its priority badge, due date,
/// status selector, completion progress bar, and interactive 1-level sub-tasks.
class TaskCard extends StatelessWidget {
  final TaskEntity task;
  final ValueChanged<TaskStatus> onStatusChanged;
  final ValueChanged<String> onSubTaskToggled;
  final VoidCallback onDeletePressed;

  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusChanged,
    required this.onSubTaskToggled,
    required this.onDeletePressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = _priorityColor(task.priority, theme.colorScheme);
    final bool isDone = task.status == TaskStatus.done;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color cardColor = isDone
        ? (isDark ? const Color(0xFF141416) : const Color(0xFFE5E5EA))
        : (isDark ? const Color(0xFF1C1C1E) : Colors.white);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Card(
        key: Key('task_card_${task.id}'),
        color: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      style: (theme.textTheme.titleMedium ??
                              const TextStyle())
                          .copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: isDone
                            ? (isDark
                                ? const Color(0xFF636366)
                                : const Color(0xFF8E8E93))
                            : theme.textTheme.titleMedium?.color,
                      ),
                      child: Text(task.title),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _PriorityBadge(
                    priority: task.priority,
                    color: priorityColor,
                  ),
                  IconButton(
                    key: Key('delete_task_${task.id}'),
                    icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'Delete task',
                  onPressed: onDeletePressed,
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                task.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                PopupMenuButton<TaskStatus>(
                  key: Key('status_menu_${task.id}'),
                  initialValue: task.status,
                  tooltip: 'Change status',
                  onSelected: (status) {
                    if (status == TaskStatus.done) {
                      if (task.priority == TaskPriority.critical ||
                          task.priority == TaskPriority.high) {
                        HapticFeedback.mediumImpact();
                      } else {
                        HapticFeedback.lightImpact();
                      }
                      SoundAndHapticService.instance
                          .playTaskCompletionFeedback();
                    }
                    onStatusChanged(status);
                  },
                  itemBuilder: (context) => TaskStatus.values
                      .map(
                        (status) => PopupMenuItem<TaskStatus>(
                          key: Key('status_option_${task.id}_${status.storageKey}'),
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(growable: false),
                  child: Chip(
                    avatar: Icon(
                      _statusIcon(task.status),
                      size: 18,
                    ),
                    label: Text(task.status.label),
                  ),
                ),
                if (task.dueDate != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.event_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(task.dueDate!),
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
              ],
            ),
            if (task.subTasks.isNotEmpty) ...<Widget>[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Sub-tasks (${task.completedSubTasksCount}/${task.subTasks.length})',
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    '${(task.completionProgress * 100).round()}%',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  key: Key('progress_bar_${task.id}'),
                  value: task.completionProgress,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              for (final SubTaskEntity subTask in task.subTasks)
                CheckboxListTile(
                  key: Key('sub_task_tile_${task.id}_${subTask.id}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: subTask.isCompleted,
                  title: Text(
                    subTask.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      decoration: subTask.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  onChanged: (_) {
                    HapticFeedback.lightImpact();
                    SoundAndHapticService.instance.playTaskCompletionFeedback();
                    onSubTaskToggled(subTask.id);
                  },
                ),
            ],
          ],
        ),
      ),
    ),
  );
}

  static Color _priorityColor(TaskPriority priority, ColorScheme scheme) {
    return switch (priority) {
      TaskPriority.low => scheme.secondary,
      TaskPriority.medium => scheme.primary,
      TaskPriority.high => scheme.tertiary,
      TaskPriority.critical => scheme.error,
    };
  }

  static IconData _statusIcon(TaskStatus status) {
    return switch (status) {
      TaskStatus.todo => Icons.radio_button_unchecked,
      TaskStatus.inProgress => Icons.timelapse,
      TaskStatus.done => Icons.check_circle_outline,
    };
  }

  static String _formatDate(DateTime date) {
    return JalaliDateFormatter.formatDate(date);
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  final Color color;

  const _PriorityBadge({
    required this.priority,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        priority.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
