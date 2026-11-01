import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

/// Constants used for sharing data with iOS App Groups and Android AppWidget containers.
abstract final class WidgetPayloadKeys {
  /// iOS App Group ID matching Xcode Signing & Capabilities
  static const String appGroupId = 'group.com.example.taskFlow';

  /// iOS Widget Extension identifier / kind
  static const String iOSWidgetKind = 'TaskFlowWidget';

  /// Android AppWidgetProvider class name
  static const String androidWidgetProvider = 'TaskFlowWidgetProvider';

  // Data keys
  static const String streakCount = 'streak_count';
  static const String dailyBudgetRials = 'daily_budget_rials';
  static const String dailyBudgetFormatted = 'daily_budget_formatted';
  static const String pendingTasksCount = 'pending_tasks_count';
  static const String pendingTasksJson = 'pending_tasks_json';

  static const String task1Title = 'task_1_title';
  static const String task1Priority = 'task_1_priority';
  static const String task2Title = 'task_2_title';
  static const String task2Priority = 'task_2_priority';
  static const String task3Title = 'task_3_title';
  static const String task3Priority = 'task_3_priority';

  static const String lastSyncedAt = 'last_synced_at';
}

/// Abstraction for the native HomeWidget plugin calls to enable clean testing and decoupling.
abstract class HomeWidgetDriver {
  Future<bool?> saveWidgetData<T>(String id, T? data, {String? appGroupId});
  Future<bool?> updateWidget({
    String? name,
    String? androidName,
    String? iOSName,
    String? qualifiedAndroidName,
  });
}

/// Production implementation delegating directly to `HomeWidget`.
class DefaultHomeWidgetDriver implements HomeWidgetDriver {
  const DefaultHomeWidgetDriver();

  @override
  Future<bool?> saveWidgetData<T>(String id, T? data, {String? appGroupId}) {
    return HomeWidget.saveWidgetData<T>(id, data, appGroupId: appGroupId);
  }

  @override
  Future<bool?> updateWidget({
    String? name,
    String? androidName,
    String? iOSName,
    String? qualifiedAndroidName,
  }) {
    return HomeWidget.updateWidget(
      name: name,
      androidName: androidName,
      iOSName: iOSName,
      qualifiedAndroidName: qualifiedAndroidName,
    );
  }
}

/// Enterprise-grade, decoupled service responsible for serializing the application's core state
/// (Current Streak, Today's Budget in Rials, and Top 3 Pending Tasks) into native iOS/Android shared containers.
class WidgetSyncService {
  static WidgetSyncService? _instance;

  /// Singleton accessor with lazy instantiation.
  static WidgetSyncService get instance => _instance ??= WidgetSyncService();

  @visibleForTesting
  static void setMockInstance(WidgetSyncService? mock) {
    _instance = mock;
  }

  final HomeWidgetDriver _driver;
  final String appGroupId;
  final String iOSWidgetKind;
  final String androidWidgetProvider;

  int _cachedStreakCount = 0;
  int _cachedDailyBudgetRials = 0;
  List<TaskEntity> _cachedTasks = const <TaskEntity>[];

  WidgetSyncService({
    HomeWidgetDriver? driver,
    this.appGroupId = WidgetPayloadKeys.appGroupId,
    this.iOSWidgetKind = WidgetPayloadKeys.iOSWidgetKind,
    this.androidWidgetProvider = WidgetPayloadKeys.androidWidgetProvider,
  }) : _driver = driver ?? const DefaultHomeWidgetDriver();

  int get streakCount => _cachedStreakCount;
  int get dailyBudgetRials => _cachedDailyBudgetRials;
  List<TaskEntity> get cachedTasks => List<TaskEntity>.unmodifiable(_cachedTasks);

  /// Synchronizes an entire application state snapshot to native widgets.
  Future<bool> syncSnapshot({
    int? streakCount,
    int? dailyBudgetRials,
    List<TaskEntity>? tasks,
  }) async {
    if (streakCount != null) _cachedStreakCount = streakCount;
    if (dailyBudgetRials != null) _cachedDailyBudgetRials = dailyBudgetRials;
    if (tasks != null) _cachedTasks = List<TaskEntity>.from(tasks);

    return _pushToNative();
  }

  /// Updates only the streak count and immediately propagates the new state to native widgets.
  Future<bool> updateStreak(int streak) async {
    _cachedStreakCount = streak;
    return _pushToNative();
  }

  /// Updates only the daily budget (in Rials) and pushes to native widgets.
  Future<bool> updateBudget(int budgetRials) async {
    _cachedDailyBudgetRials = budgetRials;
    return _pushToNative();
  }

  /// Updates tasks and propagates the top 3 highest priority pending tasks to native widgets.
  Future<bool> updateTasks(List<TaskEntity> tasks) async {
    _cachedTasks = List<TaskEntity>.from(tasks);
    return _pushToNative();
  }

  /// Serializes cached state to the native shared container and signals widgets to reload.
  ///
  /// Wrapped in a try-catch for graceful degradation (logs errors without crashing).
  Future<bool> _pushToNative() async {
    try {
      // Filter out completed tasks
      final pendingTasks = _cachedTasks
          .where((t) => t.status != TaskStatus.done)
          .toList();

      // Sort pending tasks: Critical -> High -> Medium -> Low, then by Due Date ascending
      pendingTasks.sort((a, b) {
        final priorityCompare = b.priority.index.compareTo(a.priority.index);
        if (priorityCompare != 0) return priorityCompare;
        if (a.dueDate != null && b.dueDate != null) {
          return a.dueDate!.compareTo(b.dueDate!);
        }
        return 0;
      });

      final top3 = pendingTasks.take(3).toList();
      final formattedBudget = '$_cachedDailyBudgetRials ریال';

      final top3JsonList = top3.map((task) => <String, dynamic>{
        'id': task.id,
        'title': task.title,
        'priority': task.priority.name,
        'dueDate': task.dueDate?.toIso8601String(),
      }).toList();
      final tasksJsonString = jsonEncode(top3JsonList);

      // 1. Save core metrics
      await _driver.saveWidgetData<int>(WidgetPayloadKeys.streakCount, _cachedStreakCount, appGroupId: appGroupId);
      await _driver.saveWidgetData<int>(WidgetPayloadKeys.dailyBudgetRials, _cachedDailyBudgetRials, appGroupId: appGroupId);
      await _driver.saveWidgetData<String>(WidgetPayloadKeys.dailyBudgetFormatted, formattedBudget, appGroupId: appGroupId);
      await _driver.saveWidgetData<int>(WidgetPayloadKeys.pendingTasksCount, pendingTasks.length, appGroupId: appGroupId);
      await _driver.saveWidgetData<String>(WidgetPayloadKeys.pendingTasksJson, tasksJsonString, appGroupId: appGroupId);

      // 2. Save individual top 3 tasks for direct native widget binding
      await _driver.saveWidgetData<String>(
        WidgetPayloadKeys.task1Title,
        top3.isNotEmpty ? top3[0].title : '',
        appGroupId: appGroupId,
      );
      await _driver.saveWidgetData<String>(
        WidgetPayloadKeys.task1Priority,
        top3.isNotEmpty ? top3[0].priority.name : '',
        appGroupId: appGroupId,
      );

      await _driver.saveWidgetData<String>(
        WidgetPayloadKeys.task2Title,
        top3.length > 1 ? top3[1].title : '',
        appGroupId: appGroupId,
      );
      await _driver.saveWidgetData<String>(
        WidgetPayloadKeys.task2Priority,
        top3.length > 1 ? top3[1].priority.name : '',
        appGroupId: appGroupId,
      );

      await _driver.saveWidgetData<String>(
        WidgetPayloadKeys.task3Title,
        top3.length > 2 ? top3[2].title : '',
        appGroupId: appGroupId,
      );
      await _driver.saveWidgetData<String>(
        WidgetPayloadKeys.task3Priority,
        top3.length > 2 ? top3[2].priority.name : '',
        appGroupId: appGroupId,
      );

      await _driver.saveWidgetData<String>(
        WidgetPayloadKeys.lastSyncedAt,
        DateTime.now().toUtc().toIso8601String(),
        appGroupId: appGroupId,
      );

      // 3. Trigger native widget update
      await _driver.updateWidget(
        name: iOSWidgetKind,
        androidName: androidWidgetProvider,
        iOSName: iOSWidgetKind,
      );

      return true;
    } catch (error, stack) {
      debugPrint('[WidgetSyncService] Native widget sync failed: $error\n$stack');
      return false;
    }
  }
}
