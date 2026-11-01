import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:task_flow/core/sync/pending_sync_event.dart';
import 'package:uuid/uuid.dart';

/// وضعیت لحظه‌ای موتور همگام‌سازی ابری
class SyncStatusSnapshot extends Equatable {
  final int pendingCount;
  final int syncedCount;
  final bool isSyncing;
  final bool isOnline;
  final DateTime? lastSyncedAtUtc;

  const SyncStatusSnapshot({
    this.pendingCount = 0,
    this.syncedCount = 0,
    this.isSyncing = false,
    this.isOnline = true,
    this.lastSyncedAtUtc,
  });

  @override
  List<Object?> get props => [
        pendingCount,
        syncedCount,
        isSyncing,
        isOnline,
        lastSyncedAtUtc,
      ];
}

typedef MockCloudDispatcher = Future<bool> Function(PendingSyncEvent event);

/// سرویس همگام‌سازی پس‌زمینه (Offline-First Event Sourcing Sync Engine)
///
/// بدون دستکاری جداول SQLite فعلی، تمامی رویدادهای تغییر کاربر را در صف
/// `PendingSyncEvent` ثبت کرده و در صورت برقراری اتصال اینترنت، به صورت
/// سایلنت (Silent Background Sync) به بک‌اند ابری (Mock) ارسال می‌کند.
class BackgroundSyncService {
  final Uuid _uuid;
  final MockCloudDispatcher _cloudDispatcher;
  final List<PendingSyncEvent> _eventLog = <PendingSyncEvent>[];
  final StreamController<SyncStatusSnapshot> _statusController =
      StreamController<SyncStatusSnapshot>.broadcast();

  bool _isOnline;
  bool _isSyncing = false;
  DateTime? _lastSyncedAtUtc;

  BackgroundSyncService({
    Uuid uuid = const Uuid(),
    bool initialOnlineState = true,
    MockCloudDispatcher? cloudDispatcher,
  })  : _uuid = uuid,
        _isOnline = initialOnlineState,
        _cloudDispatcher = cloudDispatcher ?? _defaultMockCloudDispatcher;

  static Future<bool> _defaultMockCloudDispatcher(
    PendingSyncEvent event,
  ) async {
    // شبیه‌سازی ارسال غیرمسدودکننده و سایلنت به سرور ابری (Mock Cloud Endpoint)
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return true;
  }

  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAtUtc => _lastSyncedAtUtc;

  /// تغییر وضعیت اتصال شبکه و اجرای خودکار همگام‌سازی در صورت آنلاین شدن
  void setOnlineStatus(bool online, {bool autoFlush = true}) {
    _isOnline = online;
    _emitStatus();
    if (_isOnline && autoFlush) {
      unawaited(flushPendingEvents());
    }
  }

  /// لیست رویدادهای در انتظار ارسال (Unsynced)
  List<PendingSyncEvent> get pendingEvents => _eventLog
      .where((event) => !event.isSynced)
      .toList(growable: false);

  /// لیست رویدادهایی که با موفقیت با ابر همگام شده‌اند
  List<PendingSyncEvent> get syncedEvents => _eventLog
      .where((event) => event.isSynced)
      .toList(growable: false);

  /// کل تاریخچه Event Sourcing
  List<PendingSyncEvent> get allEvents =>
      List<PendingSyncEvent>.unmodifiable(_eventLog);

  Stream<SyncStatusSnapshot> get statusStream => _statusController.stream;

  SyncStatusSnapshot get currentStatus => SyncStatusSnapshot(
        pendingCount: pendingEvents.length,
        syncedCount: syncedEvents.length,
        isSyncing: _isSyncing,
        isOnline: _isOnline,
        lastSyncedAtUtc: _lastSyncedAtUtc,
      );

  /// ثبت مستقیم یک `PendingSyncEvent` در لاگ Event Sourcing
  PendingSyncEvent recordEvent(
    PendingSyncEvent event, {
    bool autoFlush = true,
  }) {
    _eventLog.add(event);
    _emitStatus();
    if (_isOnline && autoFlush) {
      unawaited(flushPendingEvents());
    }
    return event;
  }

  /// ساخت و ثبت رویداد جدید از تغییرات کاربر
  PendingSyncEvent enqueue({
    required String entityId,
    required String eventType,
    Map<String, dynamic> payload = const <String, dynamic>{},
    DateTime? occurredAtUtc,
    bool autoFlush = true,
  }) {
    final event = PendingSyncEvent(
      id: _uuid.v4(),
      entityId: entityId,
      eventType: eventType,
      payload: payload,
      occurredAtUtc: (occurredAtUtc ?? DateTime.now()).toUtc(),
    );
    return recordEvent(event, autoFlush: autoFlush);
  }

  /// ارسال سایلنت تمامی رویدادهای در انتظار به بک‌اند (Mock) در صورت وجود اینترنت
  Future<int> flushPendingEvents() async {
    if (!_isOnline || _isSyncing) {
      return 0;
    }

    final unsynced = pendingEvents;
    if (unsynced.isEmpty) {
      return 0;
    }

    _isSyncing = true;
    _emitStatus();

    int syncedInBatch = 0;
    try {
      for (final event in unsynced) {
        if (!_isOnline) break;
        final index = _eventLog.indexWhere((e) => e.id == event.id);
        if (index == -1 || _eventLog[index].isSynced) continue;

        try {
          final success = await _cloudDispatcher(event);
          if (success) {
            _eventLog[index] = _eventLog[index].copyWith(isSynced: true);
            syncedInBatch++;
            _lastSyncedAtUtc = DateTime.now().toUtc();
          } else {
            _eventLog[index] = _eventLog[index].copyWith(
              retryCount: _eventLog[index].retryCount + 1,
            );
          }
        } catch (_) {
          _eventLog[index] = _eventLog[index].copyWith(
            retryCount: _eventLog[index].retryCount + 1,
          );
        }
      }
    } finally {
      _isSyncing = false;
      _emitStatus();
    }

    return syncedInBatch;
  }

  void clearAll() {
    _eventLog.clear();
    _emitStatus();
  }

  void _emitStatus() {
    if (!_statusController.isClosed) {
      _statusController.add(currentStatus);
    }
  }

  Future<void> dispose() async {
    await _statusController.close();
  }
}
