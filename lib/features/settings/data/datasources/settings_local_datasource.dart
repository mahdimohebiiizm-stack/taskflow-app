import 'dart:collection';

import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/theme/app_theme_mode.dart';
import 'package:task_flow/features/settings/data/models/user_settings_model.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

abstract interface class SettingsLocalDataSource {
  Future<UserSettingsModel> getSettings();
  Future<UserSettingsModel> saveSettings(UserSettingsModel settings);
  Future<UserSettingsModel> recordSuccessfulStreakDay({String? dateIso});
  Future<UserSettingsModel> recordFailedStreakDay({String? dateIso});
  Future<UserSettingsModel> recalculateStreakFromTasksDatabase();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final Database _database;

  const SettingsLocalDataSourceImpl({required Database database})
      : _database = database;

  @override
  Future<UserSettingsModel> getSettings() async {
    try {
      final rows = await _database.query(AppDatabase.settingsTableName);
      if (rows.isEmpty) {
        const defaultSettings = UserSettingsModel(
          defaultCurrency: Currency.irt,
          themeMode: AppThemeMode.signature,
          userName: 'مهدی',
          hasSeenOnboarding: false,
        );
        await saveSettings(defaultSettings);
        return defaultSettings;
      }

      final map = <String, String>{};
      for (final row in rows) {
        final k = row[AppDatabase.settingsColKey] as String?;
        final v = row[AppDatabase.settingsColValue] as String?;
        if (k != null && v != null) {
          map[k] = v;
        }
      }

      return UserSettingsModel.fromKeyValueMap(map);
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to read user settings from SQLite.',
        cause: error,
      );
    }
  }

  @override
  Future<UserSettingsModel> saveSettings(UserSettingsModel settings) async {
    try {
      final map = settings.toKeyValueMap();
      final batch = _database.batch();
      for (final entry in map.entries) {
        batch.insert(
          AppDatabase.settingsTableName,
          {
            AppDatabase.settingsColKey: entry.key,
            AppDatabase.settingsColValue: entry.value,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      return settings;
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to save user settings in SQLite.',
        cause: error,
      );
    }
  }

  @override
  Future<UserSettingsModel> recordSuccessfulStreakDay({String? dateIso}) async {
    final current = await getSettings();
    final updatedEntity = current.recordSuccessfulStreakDay(dateIso: dateIso);
    final updatedModel = UserSettingsModel.fromEntity(updatedEntity);
    return saveSettings(updatedModel);
  }

  @override
  Future<UserSettingsModel> recordFailedStreakDay({String? dateIso}) async {
    final current = await getSettings();
    final updatedEntity = current.recordFailedStreakDay(dateIso: dateIso);
    final updatedModel = UserSettingsModel.fromEntity(updatedEntity);
    return saveSettings(updatedModel);
  }

  @override
  Future<UserSettingsModel> recalculateStreakFromTasksDatabase() async {
    try {
      final current = await getSettings();
      final taskRows = await _database.query(TaskModel.tableName);
      if (taskRows.isEmpty) {
        return current;
      }

      // Group tasks by calendar day (YYYY-MM-DD) sorted chronologically.
      final byDay = SplayTreeMap<String, List<Map<String, Object?>>>();
      for (final row in taskRows) {
        final rawDue = row[TaskModel.colDueDate] as String?;
        final rawCreated = row[TaskModel.colCreatedAt] as String?;
        final rawIso = (rawDue != null && rawDue.isNotEmpty)
            ? rawDue
            : (rawCreated ?? '');
        final parsed = DateTime.tryParse(rawIso)?.toLocal();
        if (parsed == null) continue;
        final dayKey =
            '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
        byDay.putIfAbsent(dayKey, () => <Map<String, Object?>>[]).add(row);
      }

      UserSettingsEntity simulated = current.copyWith(
        streakCount: 0,
        streakFreezeCount: 0,
        xpPoints: 0,
        lastStreakDate: () => null,
      );

      for (final entry in byDay.entries) {
        final dayKey = entry.key;
        final dayTasks = entry.value;
        if (dayTasks.isEmpty) continue;

        final allDoneAndUnpenalized = dayTasks.every((row) {
          final status = row[TaskModel.colStatus] as String?;
          final isPenalized = (row[TaskModel.colIsPenalized] as int? ?? 0) != 0;
          return status == TaskStatus.done.storageKey && !isPenalized;
        });

        final hasAnyPenalizedOrDone = dayTasks.any((row) {
          final status = row[TaskModel.colStatus] as String?;
          final isPenalized = (row[TaskModel.colIsPenalized] as int? ?? 0) != 0;
          return status == TaskStatus.done.storageKey || isPenalized;
        });

        if (allDoneAndUnpenalized) {
          simulated = simulated.recordSuccessfulStreakDay(dateIso: dayKey);
        } else if (hasAnyPenalizedOrDone) {
          simulated = simulated.recordFailedStreakDay(dateIso: dayKey);
        }
      }

      final model = UserSettingsModel.fromEntity(simulated);
      return saveSettings(model);
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to recalculate streak from SQLite tasks.',
        cause: error,
      );
    }
  }
}
