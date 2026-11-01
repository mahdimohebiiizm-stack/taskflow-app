/// Represents the urgency/importance level of a [TaskEntity].
enum TaskPriority {
  low('low', 'Low', 1),
  medium('medium', 'Medium', 2),
  high('high', 'High', 3),
  critical('critical', 'Critical', 4);

  /// Persistent storage key used in SQLite.
  final String storageKey;

  /// Human-readable display label.
  final String label;

  /// Numeric weight for deterministic SQL/in-memory sorting (higher = more urgent).
  final int weight;

  const TaskPriority(this.storageKey, this.label, this.weight);

  /// Parses a [storageKey] from persistent storage into a [TaskPriority].
  static TaskPriority fromStorageKey(String key) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.storageKey == key,
      orElse: () => throw ArgumentError.value(
        key,
        'key',
        'Unknown TaskPriority storage key',
      ),
    );
  }
}
