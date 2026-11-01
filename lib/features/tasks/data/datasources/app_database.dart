import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/features/gamification/data/models/gamification_model.dart';
import 'package:task_flow/features/notifications/data/models/app_notification_model.dart';
import 'package:task_flow/features/tasks/data/models/expense_item_model.dart';
import 'package:task_flow/features/tasks/data/models/focus_session_model.dart';
import 'package:task_flow/features/tasks/data/models/sub_task_model.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';
import 'package:task_flow/features/tasks/data/models/xp_ledger_model.dart';

/// Manages SQLite connection lifecycle, foreign-key enforcement, and schema migrations.
final class AppDatabase {
  /// Schema Version 10: Persistent Gamification Profile & Streak Freezes.
  static const int schemaVersion = 10;
  static const String defaultDatabaseFileName = 'task_flow_v1.db';
  static const String settingsTableName = 'app_settings';
  static const String settingsColKey = 'key';
  static const String settingsColValue = 'value';

  const AppDatabase._();

  /// Opens and configures a SQLite [Database] instance.
  ///
  /// Pass [databasePath] (e.g., [inMemoryDatabasePath]) for isolated testing,
  /// or leave null to resolve the platform database directory.
  static Future<Database> open({
    String? databasePath,
    DatabaseFactory? databaseFactory,
    int version = schemaVersion,
  }) async {
    try {
      final factory = databaseFactory ?? databaseFactorySqflitePlugin;
      final resolvedPath = databasePath ??
          p.join(await factory.getDatabasesPath(), defaultDatabaseFileName);

      return await factory.openDatabase(
        resolvedPath,
        options: OpenDatabaseOptions(
          version: version,
          onConfigure: configureDatabase,
          onCreate: (db, targetVersion) async {
            await createV1Schema(db);
            if (targetVersion >= 2) {
              await upgradeSchema(db, 1, targetVersion);
            }
          },
          onUpgrade: (db, oldVersion, newVersion) =>
              upgradeSchema(db, oldVersion, newVersion),
        ),
      );
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to open and initialize SQLite database.',
        cause: error,
      );
    }
  }

  /// Enables strict relational integrity (`PRAGMA foreign_keys = ON`).
  static Future<void> configureDatabase(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Creates the full schema up to [schemaVersion].
  static Future<void> createSchema(DatabaseExecutor db) async {
    await createV1Schema(db);
    await upgradeSchema(db, 1, schemaVersion);
  }

  /// Creates the baseline Version 1 schema (`tasks` and `sub_tasks`).
  static Future<void> createV1Schema(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${TaskModel.tableName} (
        ${TaskModel.colId} TEXT PRIMARY KEY NOT NULL,
        ${TaskModel.colTitle} TEXT NOT NULL,
        ${TaskModel.colDescription} TEXT NOT NULL DEFAULT '',
        ${TaskModel.colStatus} TEXT NOT NULL,
        ${TaskModel.colPriority} TEXT NOT NULL,
        ${TaskModel.colPriorityWeight} INTEGER NOT NULL,
        ${TaskModel.colDueDate} TEXT NULL,
        ${TaskModel.colCreatedAt} TEXT NOT NULL,
        ${TaskModel.colUpdatedAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${SubTaskModel.tableName} (
        ${SubTaskModel.colId} TEXT PRIMARY KEY NOT NULL,
        ${SubTaskModel.colTaskId} TEXT NOT NULL,
        ${SubTaskModel.colTitle} TEXT NOT NULL,
        ${SubTaskModel.colIsCompleted} INTEGER NOT NULL DEFAULT 0,
        ${SubTaskModel.colPosition} INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (${SubTaskModel.colTaskId})
          REFERENCES ${TaskModel.tableName} (${TaskModel.colId})
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_tasks_status_priority_due
      ON ${TaskModel.tableName} (
        ${TaskModel.colStatus},
        ${TaskModel.colPriorityWeight} DESC,
        ${TaskModel.colDueDate} ASC
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sub_tasks_task_id_position
      ON ${SubTaskModel.tableName} (
        ${SubTaskModel.colTaskId},
        ${SubTaskModel.colPosition} ASC
      )
    ''');
  }

  /// Non-destructive migration handler upgrading existing databases without data loss.
  static Future<void> upgradeSchema(
    DatabaseExecutor db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2 && newVersion >= 2) {
      // 1. Multi-line expenses table linked to tasks with ON DELETE CASCADE.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${ExpenseItemModel.tableName} (
          ${ExpenseItemModel.colId} TEXT PRIMARY KEY NOT NULL,
          ${ExpenseItemModel.colTaskId} TEXT NOT NULL,
          ${ExpenseItemModel.colTitle} TEXT NOT NULL,
          ${ExpenseItemModel.colAmountMinorUnits} INTEGER NOT NULL,
          ${ExpenseItemModel.colCurrencyCode} TEXT NOT NULL,
          ${ExpenseItemModel.colIncurredAt} TEXT NOT NULL,
          ${ExpenseItemModel.colPosition} INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (${ExpenseItemModel.colTaskId})
            REFERENCES ${TaskModel.tableName} (${TaskModel.colId})
            ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_expenses_task_id_position
        ON ${ExpenseItemModel.tableName} (
          ${ExpenseItemModel.colTaskId},
          ${ExpenseItemModel.colPosition} ASC
        )
      ''');
    }

    if (oldVersion < 3 && newVersion >= 3) {
      // 3. User settings key-value persistence table.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $settingsTableName (
          $settingsColKey TEXT PRIMARY KEY NOT NULL,
          $settingsColValue TEXT NOT NULL
        )
      ''');
    }

    if (oldVersion < 4 && newVersion >= 4) {
      // 4. Time-blocking (start_time, end_time) and Gamification (is_penalized).
      await db.execute(
        'ALTER TABLE ${TaskModel.tableName} ADD COLUMN ${TaskModel.colStartTime} TEXT NULL',
      );
      await db.execute(
        'ALTER TABLE ${TaskModel.tableName} ADD COLUMN ${TaskModel.colEndTime} TEXT NULL',
      );
      await db.execute(
        'ALTER TABLE ${TaskModel.tableName} ADD COLUMN ${TaskModel.colIsPenalized} INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 5 && newVersion >= 5) {
      // 5. Total currency eradication: drop exchange_rates table.
      await db.execute('DROP TABLE IF EXISTS exchange_rates');
    }

    if (oldVersion < 6 && newVersion >= 6) {
      // 6. Core Task Engine: hierarchical parent_task_id, workspace_id, tags, and manual sort_order.
      await db.execute(
        'ALTER TABLE ${TaskModel.tableName} ADD COLUMN ${TaskModel.colParentTaskId} TEXT NULL '
        'REFERENCES ${TaskModel.tableName} (${TaskModel.colId}) ON DELETE CASCADE',
      );
      await db.execute(
        "ALTER TABLE ${TaskModel.tableName} ADD COLUMN ${TaskModel.colWorkspaceId} TEXT NOT NULL DEFAULT 'default'",
      );
      await db.execute(
        "ALTER TABLE ${TaskModel.tableName} ADD COLUMN ${TaskModel.colTags} TEXT NOT NULL DEFAULT '[]'",
      );
      await db.execute(
        'ALTER TABLE ${TaskModel.tableName} ADD COLUMN ${TaskModel.colSortOrder} INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_tasks_workspace_parent_order
        ON ${TaskModel.tableName} (
          ${TaskModel.colWorkspaceId},
          ${TaskModel.colParentTaskId},
          ${TaskModel.colSortOrder} ASC
        )
      ''');
    }

    if (oldVersion < 7 && newVersion >= 7) {
      // 7. Reminders & Recurring Tasks Engine: recurrence_rule and reminder_date_time.
      await db.execute(
        'ALTER TABLE ${TaskModel.tableName} ADD COLUMN ${TaskModel.colRecurrenceRule} TEXT NULL',
      );
      await db.execute(
        'ALTER TABLE ${TaskModel.tableName} ADD COLUMN ${TaskModel.colReminderDateTime} TEXT NULL',
      );
    }

    if (oldVersion < 8 && newVersion >= 8) {
      // 8. Pomodoro Deep Work Focus Sessions & Dopamine XP Ledger.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${FocusSessionModel.tableName} (
          ${FocusSessionModel.colId} TEXT PRIMARY KEY NOT NULL,
          ${FocusSessionModel.colTaskId} TEXT NULL,
          ${FocusSessionModel.colTargetMinutes} INTEGER NOT NULL,
          ${FocusSessionModel.colActualMinutes} INTEGER NOT NULL,
          ${FocusSessionModel.colStartedAt} TEXT NOT NULL,
          ${FocusSessionModel.colEndedAt} TEXT NULL,
          ${FocusSessionModel.colStatus} TEXT NOT NULL,
          ${FocusSessionModel.colEarnedXp} INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (${FocusSessionModel.colTaskId})
            REFERENCES ${TaskModel.tableName} (${TaskModel.colId})
            ON DELETE SET NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_focus_sessions_task_id
        ON ${FocusSessionModel.tableName} (${FocusSessionModel.colTaskId})
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_focus_sessions_started_at
        ON ${FocusSessionModel.tableName} (${FocusSessionModel.colStartedAt} DESC)
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${XpLedgerModel.tableName} (
          ${XpLedgerModel.colId} TEXT PRIMARY KEY NOT NULL,
          ${XpLedgerModel.colSource} TEXT NOT NULL,
          ${XpLedgerModel.colReferenceId} TEXT NULL,
          ${XpLedgerModel.colXpAmount} INTEGER NOT NULL,
          ${XpLedgerModel.colDescription} TEXT NOT NULL DEFAULT '',
          ${XpLedgerModel.colCreatedAt} TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_xp_ledger_created_at
        ON ${XpLedgerModel.tableName} (${XpLedgerModel.colCreatedAt} DESC)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_xp_ledger_source
        ON ${XpLedgerModel.tableName} (${XpLedgerModel.colSource})
      ''');
    }

    if (oldVersion < 9 && newVersion >= 9) {
      // 9. Persistent Notification Center & Inbox.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${AppNotificationModel.tableName} (
          ${AppNotificationModel.colId} TEXT PRIMARY KEY NOT NULL,
          ${AppNotificationModel.colTitle} TEXT NOT NULL,
          ${AppNotificationModel.colMessage} TEXT NOT NULL,
          ${AppNotificationModel.colType} TEXT NOT NULL,
          ${AppNotificationModel.colIsRead} INTEGER NOT NULL DEFAULT 0,
          ${AppNotificationModel.colTimestamp} TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_app_notifications_timestamp
        ON ${AppNotificationModel.tableName} (${AppNotificationModel.colTimestamp} DESC)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_app_notifications_is_read
        ON ${AppNotificationModel.tableName} (${AppNotificationModel.colIsRead} ASC)
      ''');
    }

    if (oldVersion < 10 && newVersion >= 10) {
      // 10. Persistent Gamification Profile & Streak Freezes.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${GamificationModel.tableName} (
          ${GamificationModel.colId} TEXT PRIMARY KEY NOT NULL,
          ${GamificationModel.colTotalXp} INTEGER NOT NULL DEFAULT 0,
          ${GamificationModel.colLevel} INTEGER NOT NULL DEFAULT 1,
          ${GamificationModel.colTitle} TEXT NOT NULL DEFAULT 'تازه‌کار',
          ${GamificationModel.colStreakFreezes} INTEGER NOT NULL DEFAULT 0,
          ${GamificationModel.colUpdatedAt} TEXT NOT NULL
        )
      ''');
    }
  }
}

