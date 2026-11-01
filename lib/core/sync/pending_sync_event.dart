import 'package:equatable/equatable.dart';

/// نوع رویدادهای دامنه در سیستم Event Sourcing آفلاین-فرست
class SyncEventTypes {
  static const String taskCreated = 'TASK_CREATED';
  static const String taskUpdated = 'TASK_UPDATED';
  static const String taskStatusTransitioned = 'TASK_STATUS_TRANSITIONED';
  static const String subTaskToggled = 'SUBTASK_TOGGLED';
  static const String taskExpenseAdded = 'TASK_EXPENSE_ADDED';
  static const String taskDeleted = 'TASK_DELETED';
  static const String dayPenalized = 'DAY_PENALIZED';
  static const String dayPenaltyReverted = 'DAY_PENALTY_REVERTED';
  static const String settingsUpdated = 'SETTINGS_UPDATED';
}

/// مدل تغییرناپذیر رویداد در انتظار همگام‌سازی ابری (Event Sourcing Entry)
/// بدون وابستگی یا تغییر در جداول SQLite فعلی.
class PendingSyncEvent extends Equatable {
  final String id;
  final String entityId;
  final String eventType;
  final Map<String, dynamic> payload;
  final DateTime occurredAtUtc;
  final int retryCount;
  final bool isSynced;

  const PendingSyncEvent({
    required this.id,
    required this.entityId,
    required this.eventType,
    this.payload = const <String, dynamic>{},
    required this.occurredAtUtc,
    this.retryCount = 0,
    this.isSynced = false,
  });

  PendingSyncEvent copyWith({
    String? id,
    String? entityId,
    String? eventType,
    Map<String, dynamic>? payload,
    DateTime? occurredAtUtc,
    int? retryCount,
    bool? isSynced,
  }) {
    return PendingSyncEvent(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      eventType: eventType ?? this.eventType,
      payload: payload ?? this.payload,
      occurredAtUtc: occurredAtUtc ?? this.occurredAtUtc,
      retryCount: retryCount ?? this.retryCount,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'entityId': entityId,
      'eventType': eventType,
      'payload': Map<String, dynamic>.from(payload),
      'occurredAtUtc': occurredAtUtc.toUtc().toIso8601String(),
      'retryCount': retryCount,
      'isSynced': isSynced,
    };
  }

  factory PendingSyncEvent.fromMap(Map<String, dynamic> map) {
    return PendingSyncEvent(
      id: map['id'] as String,
      entityId: map['entityId'] as String,
      eventType: map['eventType'] as String,
      payload: map['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(map['payload'] as Map<String, dynamic>)
          : const <String, dynamic>{},
      occurredAtUtc: DateTime.parse(map['occurredAtUtc'] as String).toUtc(),
      retryCount: (map['retryCount'] as int?) ?? 0,
      isSynced: (map['isSynced'] as bool?) ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        entityId,
        eventType,
        payload,
        occurredAtUtc,
        retryCount,
        isSynced,
      ];
}
