import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// ساختار داده Payload نوتیفیکیشن برای هدایت کاربر به جزئیات تسک پس از کلیک روی آلارم
class TaskNotificationPayload extends Equatable {
  final String taskId;
  final String title;
  final String description;
  final String? dueDateIso;
  final String? recurrenceRule;

  const TaskNotificationPayload({
    required this.taskId,
    required this.title,
    this.description = '',
    this.dueDateIso,
    this.recurrenceRule,
  });

  factory TaskNotificationPayload.fromTask(TaskEntity task) {
    return TaskNotificationPayload(
      taskId: task.id,
      title: task.title,
      description: task.description,
      dueDateIso: task.dueDate?.toIso8601String(),
      recurrenceRule: task.recurrenceRule,
    );
  }

  String toJsonString() {
    return jsonEncode(<String, Object?>{
      'taskId': taskId,
      'title': title,
      'description': description,
      'dueDateIso': dueDateIso,
      'recurrenceRule': recurrenceRule,
    });
  }

  static TaskNotificationPayload? tryParse(String? rawPayload) {
    if (rawPayload == null || rawPayload.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is Map<String, dynamic>) {
        final taskId = (decoded['taskId'] as String?)?.trim() ?? '';
        final title = (decoded['title'] as String?)?.trim() ?? '';
        if (taskId.isEmpty) return null;
        return TaskNotificationPayload(
          taskId: taskId,
          title: title.isEmpty ? 'یادآوری تسک' : title,
          description: (decoded['description'] as String?) ?? '',
          dueDateIso: decoded['dueDateIso'] as String?,
          recurrenceRule: decoded['recurrenceRule'] as String?,
        );
      }
    } catch (_) {
      // Fallback: treat plain string payload as taskId
      return TaskNotificationPayload(
        taskId: rawPayload.trim(),
        title: 'یادآوری تسک',
      );
    }
    return null;
  }

  @override
  List<Object?> get props => [
        taskId,
        title,
        description,
        dueDateIso,
        recurrenceRule,
      ];
}

/// رکورد زمان‌بندی آلارم برای رصد وضعیت و تست‌پذیری قطعی
class ScheduledTaskReminder extends Equatable {
  final int notificationId;
  final String taskId;
  final String title;
  final DateTime scheduledAt;
  final TaskNotificationPayload payload;

  const ScheduledTaskReminder({
    required this.notificationId,
    required this.taskId,
    required this.title,
    required this.scheduledAt,
    required this.payload,
  });

  @override
  List<Object?> get props => [
        notificationId,
        taskId,
        title,
        scheduledAt,
        payload,
      ];
}

/// سرویس زیرساختی مدیریت نوتیفیکیشن‌ها، مجوزهای اندروید ۱۳+ و زمان‌بندی دقیق آلارم‌ها
class NotificationService {
  static const String channelId = 'task_flow_reminders_channel';
  static const String channelName = 'یادآور تسک‌ها و عادت‌ها';
  static const String channelDescription =
      'اعلان و آلارم دقیق برای سررسید تسک‌ها و روتین‌های روزانه';

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<TaskNotificationPayload> _tapController =
      StreamController<TaskNotificationPayload>.broadcast();
  final Map<String, ScheduledTaskReminder> _scheduledReminders =
      <String, ScheduledTaskReminder>{};

  TaskNotificationPayload? _pendingLaunchPayload;
  bool _isInitialized = false;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// استریم رویداد کلیک کاربر روی نوتیفیکیشن برای نمایش جزئیات تسک در UI
  Stream<TaskNotificationPayload> get onNotificationTapped =>
      _tapController.stream;

  /// فهرست آلارم‌های زمان‌بندی‌شده فعلی (خواندنی)
  Map<String, ScheduledTaskReminder> get scheduledReminders =>
      Map<String, ScheduledTaskReminder>.unmodifiable(_scheduledReminders);

  bool get isInitialized => _isInitialized;

  /// دریافت و پاکسازی Payload اولیه‌ای که قبل از آماده شدن UI کلیک شده است
  TaskNotificationPayload? consumePendingPayload() {
    final payload = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    return payload;
  }

  /// تولید شناسه عددی ۳۱ بیتی یکتا و قطعی از روی رشته UUID تسک
  static int notificationIdForTask(String taskId) {
    var hash = 0x811c9dc5;
    for (var i = 0; i < taskId.length; i++) {
      hash ^= taskId.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash == 0 ? 1 : hash;
  }

  /// راه‌اندازی اولیه تایم‌زون‌ها، کانال نوتیفیکیشن و درخواست مجوز در اندروید ۱۳ به بالا
  Future<void> initialize() async {
    if (_isInitialized) return;
    tz_data.initializeTimeZones();
    _isInitialized = true;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'مشاهده تسک',
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
      );

      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse != null) {
        handleRawPayload(launchDetails.notificationResponse!.payload);
      }

      await requestPermissions();
    } catch (_) {
      // در محیط‌های تست بدون پلتفرم نیتیو، خطای کانال پلتفرم به صورت ایمن مهار می‌شود
    }
  }

  /// درخواست مجوز نوتیفیکیشن و آلارم دقیق برای اندروید ۱۳+ و iOS
  Future<bool> requestPermissions() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted =
            await androidPlugin.requestNotificationsPermission() ?? false;
        await androidPlugin.requestExactAlarmsPermission();
        return granted;
      }

      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        return await iosPlugin.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void _onNotificationResponse(NotificationResponse response) {
    handleRawPayload(response.payload);
  }

  /// پردازش رشته Payload و انتشار رویداد برای باز کردن دیالوگ/شیت تسک مربوطه
  void handleRawPayload(String? rawPayload) {
    final parsed = TaskNotificationPayload.tryParse(rawPayload);
    if (parsed == null) return;
    _pendingLaunchPayload = parsed;
    if (!_tapController.isClosed) {
      _tapController.add(parsed);
    }
  }

  /// زمان‌بندی دقیق نوتیفیکیشن (`zonedSchedule`) برای تسک بر اساس `reminderDateTime`
  Future<void> scheduleTaskReminder(TaskEntity task) async {
    final reminderAt = task.reminderDateTime;
    if (reminderAt == null) {
      await cancelTaskReminder(task.id);
      return;
    }

    if (!_isInitialized) {
      tz_data.initializeTimeZones();
      _isInitialized = true;
    }

    final notificationId = notificationIdForTask(task.id);
    final payload = TaskNotificationPayload.fromTask(task);
    final localReminder = reminderAt.toLocal();

    _scheduledReminders[task.id] = ScheduledTaskReminder(
      notificationId: notificationId,
      taskId: task.id,
      title: task.title,
      scheduledAt: localReminder,
      payload: payload,
    );

    final now = DateTime.now();
    final effectiveScheduleTime = localReminder.isAfter(now)
        ? localReminder
        : now.add(const Duration(seconds: 5));

    try {
      final scheduledTz = tz.TZDateTime.from(effectiveScheduleTime, tz.local);
      final bodyText = task.description.trim().isNotEmpty
          ? task.description.trim()
          : (task.hasRecurrence
              ? 'یادآور تسک تکرارشونده (${task.recurrenceLabelFa})'
              : 'زمان انجام تسک «${task.title}» فرا رسیده است.');

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      await _plugin.zonedSchedule(
        notificationId,
        '⏰ یادآور: ${task.title}',
        bodyText,
        scheduledTz,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload.toJsonString(),
      );
    } catch (_) {
      // مهار ایمن در محیط‌های تست بدون کانال نیتیو
    }
  }

  /// لغو نوتیفیکیشن زمان‌بندی‌شده هنگام تکمیل یا حذف تسک
  Future<void> cancelTaskReminder(String taskId) async {
    _scheduledReminders.remove(taskId);
    final notificationId = notificationIdForTask(taskId);
    try {
      await _plugin.cancel(notificationId);
    } catch (_) {}
  }

  /// زمان‌بندی یک اعلان تستی برای بررسی عملکرد نوتیفیکیشن در پس‌زمینه (دقیقاً ۵ ثانیه بعد)
  Future<void> scheduleTestNotification({
    int seconds = 5,
    String title = 'زندگیساز',
    String body = 'این یک تست نوتیفیکیشن در پسزمینه است! 🚀',
  }) async {
    if (!_isInitialized) {
      tz_data.initializeTimeZones();
      _isInitialized = true;
    }

    try {
      final scheduledTz =
          tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      );

      const testNotificationId = 888888;
      await _plugin.zonedSchedule(
        testNotificationId,
        title,
        body,
        scheduledTz,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // مهار ایمن در محیط‌های تست بدون کانال نیتیو
    }
  }

  Future<void> dispose() async {
    await _tapController.close();
  }
}
