/// Represents the workflow lifecycle state of a [TaskEntity].
enum TaskStatus {
  todo('todo', 'To Do'),
  inProgress('in_progress', 'In Progress'),
  done('done', 'Done');

  /// Persistent storage key used in SQLite.
  final String storageKey;

  /// Human-readable display label.
  final String label;

  const TaskStatus(this.storageKey, this.label);

  /// Parses a [storageKey] from persistent storage into a [TaskStatus].
  static TaskStatus fromStorageKey(String key) {
    return TaskStatus.values.firstWhere(
      (status) => status.storageKey == key,
      orElse: () => throw ArgumentError.value(
        key,
        'key',
        'Unknown TaskStatus storage key',
      ),
    );
  }
}
