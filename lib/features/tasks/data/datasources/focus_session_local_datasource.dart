import 'package:sqflite/sqflite.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/features/tasks/data/models/focus_session_model.dart';

abstract interface class FocusSessionLocalDataSource {
  Future<FocusSessionModel> saveFocusSession(FocusSessionModel session);
  Future<List<FocusSessionModel>> getFocusSessions({String? taskId});
  Future<FocusSessionModel?> getFocusSessionById(String id);
}

class FocusSessionLocalDataSourceImpl implements FocusSessionLocalDataSource {
  final Database _database;

  const FocusSessionLocalDataSourceImpl({required Database database})
      : _database = database;

  @override
  Future<FocusSessionModel> saveFocusSession(FocusSessionModel session) async {
    try {
      await _database.insert(
        FocusSessionModel.tableName,
        session.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return session;
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to persist focus session to SQLite.',
        cause: e,
      );
    }
  }

  @override
  Future<List<FocusSessionModel>> getFocusSessions({String? taskId}) async {
    try {
      final List<Map<String, Object?>> rows;
      if (taskId != null) {
        rows = await _database.query(
          FocusSessionModel.tableName,
          where: '${FocusSessionModel.colTaskId} = ?',
          whereArgs: [taskId],
          orderBy: '${FocusSessionModel.colStartedAt} DESC',
        );
      } else {
        rows = await _database.query(
          FocusSessionModel.tableName,
          orderBy: '${FocusSessionModel.colStartedAt} DESC',
        );
      }
      return rows.map(FocusSessionModel.fromMap).toList(growable: false);
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to retrieve focus sessions from SQLite.',
        cause: e,
      );
    }
  }

  @override
  Future<FocusSessionModel?> getFocusSessionById(String id) async {
    try {
      final rows = await _database.query(
        FocusSessionModel.tableName,
        where: '${FocusSessionModel.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return FocusSessionModel.fromMap(rows.first);
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to retrieve focus session $id from SQLite.',
        cause: e,
      );
    }
  }
}
