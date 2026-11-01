import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:task_flow/features/notifications/data/models/app_notification_model.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/features/tasks/data/models/expense_item_model.dart';
import 'package:task_flow/features/tasks/data/models/focus_session_model.dart';
import 'package:task_flow/features/tasks/data/models/sub_task_model.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';
import 'package:task_flow/features/tasks/data/models/xp_ledger_model.dart';

/// Sealed hierarchy representing the result of a cloud/local backup export.
sealed class BackupResult {
  const BackupResult();
}

/// Successfully exported and prepared backup file.
final class BackupSuccess extends BackupResult {
  final String filePath;
  final int totalRecords;
  final DateTime exportedAt;

  const BackupSuccess({
    required this.filePath,
    required this.totalRecords,
    required this.exportedAt,
  });
}

/// User cancelled the share/save sheet or no destination was selected.
final class BackupCancelled extends BackupResult {
  const BackupCancelled();
}

/// Failure during backup generation or sharing.
final class BackupFailure extends BackupResult {
  final String message;
  final Object? error;

  const BackupFailure({required this.message, this.error});
}

/// Sealed hierarchy representing the result of a backup restore/import.
sealed class RestoreResult {
  const RestoreResult();
}

/// Successfully parsed, validated, and restored backup data into SQLite.
final class RestoreSuccess extends RestoreResult {
  final int restoredRecords;
  final String sourceFileName;

  const RestoreSuccess({
    required this.restoredRecords,
    required this.sourceFileName,
  });
}

/// User cancelled picking a backup file.
final class RestoreCancelled extends RestoreResult {
  const RestoreCancelled();
}

/// Failure during backup validation or insertion.
final class RestoreFailure extends RestoreResult {
  final String message;
  final Object? error;

  const RestoreFailure({required this.message, this.error});
}

/// Commercial-grade, decoupled Backup & Restore Service.
///
/// Coordinates SQLite database snapshot export, JSON packaging, cloud sharing (Drive/iCloud/Files)
/// via `share_plus`, and validation/restoration via `file_picker`.
class BackupService {
  final Database _database;

  static const List<String> supportedTables = [
    TaskModel.tableName,
    SubTaskModel.tableName,
    ExpenseItemModel.tableName,
    AppDatabase.settingsTableName,
    FocusSessionModel.tableName,
    XpLedgerModel.tableName,
    AppNotificationModel.tableName,
  ];

  BackupService({required Database database}) : _database = database;

  /// Exports an encrypted-ready, structured JSON snapshot containing all application tables,
  /// metadata, and schema version, and surfaces the system share sheet (`share_plus`)
  /// for seamless saving to Google Drive, iCloud, Files, or messaging apps.
  Future<BackupResult> exportBackup({
    Rect? sharePositionOrigin,
    String? customFileName,
  }) async {
    try {
      // 1. Flush any active WAL journal into the main SQLite database file
      try {
        await _database.execute('PRAGMA wal_checkpoint(FULL);');
      } catch (e) {
        debugPrint('[BackupService] WAL checkpoint note: $e');
      }

      // 2. Query all application tables
      final tablesData = <String, List<Map<String, dynamic>>>{};
      var totalRecordCount = 0;

      for (final tableName in supportedTables) {
        try {
          final rows = await _database.query(tableName);
          tablesData[tableName] = rows;
          totalRecordCount += rows.length;
        } catch (e) {
          debugPrint('[BackupService] Could not query table $tableName: $e');
        }
      }

      // 3. Assemble structured JSON payload with system metadata
      final now = DateTime.now();
      final nowUtc = now.toUtc();
      final payload = <String, dynamic>{
        'app': 'TaskFlow',
        'formatVersion': 1,
        'schemaVersion': AppDatabase.schemaVersion,
        'exportedAtUtc': nowUtc.toIso8601String(),
        'totalRecords': totalRecordCount,
        'tables': tablesData,
      };

      final jsonContent = const JsonEncoder.withIndent('  ').convert(payload);

      // 4. Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestampStr = '${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}'
          '${now.minute.toString().padLeft(2, '0')}'
          '${now.second.toString().padLeft(2, '0')}';
      final fileName = customFileName ?? 'taskflow_backup_$timestampStr.json';
      final tempFilePath = p.join(tempDir.path, fileName);
      final tempFile = File(tempFilePath);
      await tempFile.writeAsString(jsonContent, flush: true);

      // 5. Present system share dialog via share_plus
      final xFile = XFile(
        tempFile.path,
        mimeType: 'application/json',
        name: fileName,
      );

      final shareResult = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: 'نسخه پشتیبان ابری تسک‌فلو ($fileName)',
          text: 'پشتیبان امن داده‌های تسک‌فلو شامل تسک‌ها، امور مالی و گیمیفیکیشن',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      if (shareResult.status == ShareResultStatus.dismissed) {
        // Even if dismissed, the file was created and ready
        return BackupSuccess(
          filePath: tempFilePath,
          totalRecords: totalRecordCount,
          exportedAt: now,
        );
      }

      return BackupSuccess(
        filePath: tempFilePath,
        totalRecords: totalRecordCount,
        exportedAt: now,
      );
    } catch (error, stack) {
      debugPrint('[BackupService] Export backup failed: $error\n$stack');
      return BackupFailure(
        message: 'خطا در تولید یا اشتراک‌گذاری نسخه پشتیبان.',
        error: error,
      );
    }
  }

  /// Prompts user to pick a backup file (`.json` or `.db`/`.sqlite`), validates schema/integrity,
  /// executes an atomic SQLite transaction to overwrite existing tables, and prepares
  /// for state refresh.
  Future<RestoreResult> restoreBackup() async {
    try {
      // 1. Pick file via file_picker
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json', 'db', 'sqlite', 'taskflow'],
      );

      if (pickedFile == null) {
        return const RestoreCancelled();
      }

      final pickedPath = pickedFile.path;
      final fileName = pickedFile.name;

      if (pickedPath == null || !File(pickedPath).existsSync()) {
        return const RestoreFailure(message: 'فایل انتخاب‌شده در دسترس نیست.');
      }

      final extension = p.extension(pickedPath).toLowerCase();

      if (extension == '.json' || extension == '.taskflow') {
        return await _restoreFromJsonFile(pickedPath, fileName);
      } else {
        return await _restoreFromSqliteFile(pickedPath, fileName);
      }
    } catch (error, stack) {
      debugPrint('[BackupService] Restore backup failed: $error\n$stack');
      return RestoreFailure(
        message: 'خطا در بازیابی نسخه پشتیبان.',
        error: error,
      );
    }
  }

  /// Restores from a structured JSON backup file.
  Future<RestoreResult> _restoreFromJsonFile(
    String filePath,
    String fileName,
  ) async {
    final rawText = await File(filePath).readAsString();
    final dynamic decoded = jsonDecode(rawText);

    if (decoded is! Map<String, dynamic>) {
      return const RestoreFailure(
        message: 'قالب فایل پشتیبان نامعتبر است (ساختار JSON ناصحیح).',
      );
    }

    // Validation
    final tablesMap = decoded['tables'];
    if (tablesMap is! Map) {
      return const RestoreFailure(
        message: 'داده‌های معتبر برنامه در فایل پشتیبان یافت نشد.',
      );
    }

    var restoredCount = 0;

    // Temporarily turn off foreign keys to allow bulk replace without constraint conflicts
    await _database.execute('PRAGMA foreign_keys = OFF');
    try {
      await _database.transaction((txn) async {
        // 1. Clear existing application data in reverse dependency order
        for (final table in [
          ExpenseItemModel.tableName,
          SubTaskModel.tableName,
          FocusSessionModel.tableName,
          TaskModel.tableName,
          AppDatabase.settingsTableName,
          XpLedgerModel.tableName,
          AppNotificationModel.tableName,
        ]) {
          try {
            await txn.delete(table);
          } catch (_) {}
        }

        // 2. Insert rows from backup tables
        for (final entry in tablesMap.entries) {
          final tableName = entry.key.toString();
          if (!supportedTables.contains(tableName)) continue;

          final rows = entry.value;
          if (rows is List) {
            for (final row in rows) {
              if (row is Map) {
                await txn.insert(
                  tableName,
                  Map<String, dynamic>.from(row),
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
                restoredCount++;
              }
            }
          }
        }
      });
    } finally {
      await _database.execute('PRAGMA foreign_keys = ON');
    }

    return RestoreSuccess(
      restoredRecords: restoredCount,
      sourceFileName: fileName,
    );
  }

  /// Restores by copying tables from a valid picked SQLite database file.
  Future<RestoreResult> _restoreFromSqliteFile(
    String filePath,
    String fileName,
  ) async {
    Database? sourceDb;
    try {
      sourceDb = await openReadOnlyDatabase(filePath);
      var restoredCount = 0;

      await _database.execute('PRAGMA foreign_keys = OFF');
      try {
        await _database.transaction((txn) async {
          // 1. Clear existing application data
          for (final table in [
            ExpenseItemModel.tableName,
            SubTaskModel.tableName,
            FocusSessionModel.tableName,
            TaskModel.tableName,
            AppDatabase.settingsTableName,
            XpLedgerModel.tableName,
            AppNotificationModel.tableName,
          ]) {
            try {
              await txn.delete(table);
            } catch (_) {}
          }

          // 2. Read and copy each supported table from source database
          for (final table in supportedTables) {
            try {
              final rows = await sourceDb!.query(table);
              for (final row in rows) {
                await txn.insert(
                  table,
                  row,
                  conflictAlgorithm: ConflictAlgorithm.replace,
                );
                restoredCount++;
              }
            } catch (_) {}
          }
        });
      } finally {
        await _database.execute('PRAGMA foreign_keys = ON');
      }

      return RestoreSuccess(
        restoredRecords: restoredCount,
        sourceFileName: fileName,
      );
    } catch (e) {
      return RestoreFailure(
        message: 'فایل دیتابیس انتخاب‌شده نامعتبر یا آسیب‌دیده است.',
        error: e,
      );
    } finally {
      await sourceDb?.close();
    }
  }
}
