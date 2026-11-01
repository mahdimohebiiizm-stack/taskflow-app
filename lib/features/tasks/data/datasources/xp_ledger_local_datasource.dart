import 'package:sqflite/sqflite.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/features/tasks/data/models/xp_ledger_model.dart';

abstract interface class XpLedgerLocalDataSource {
  Future<XpLedgerModel> recordXp(XpLedgerModel entry);
  Future<List<XpLedgerModel>> getXpEntries({String? source});
  Future<int> getTotalXp();
}

class XpLedgerLocalDataSourceImpl implements XpLedgerLocalDataSource {
  final Database _database;

  const XpLedgerLocalDataSourceImpl({required Database database})
      : _database = database;

  @override
  Future<XpLedgerModel> recordXp(XpLedgerModel entry) async {
    try {
      await _database.insert(
        XpLedgerModel.tableName,
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return entry;
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to record XP entry in SQLite.',
        cause: e,
      );
    }
  }

  @override
  Future<List<XpLedgerModel>> getXpEntries({String? source}) async {
    try {
      final List<Map<String, Object?>> rows;
      if (source != null) {
        rows = await _database.query(
          XpLedgerModel.tableName,
          where: '${XpLedgerModel.colSource} = ?',
          whereArgs: [source],
          orderBy: '${XpLedgerModel.colCreatedAt} DESC',
        );
      } else {
        rows = await _database.query(
          XpLedgerModel.tableName,
          orderBy: '${XpLedgerModel.colCreatedAt} DESC',
        );
      }
      return rows.map(XpLedgerModel.fromMap).toList(growable: false);
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to retrieve XP entries from SQLite.',
        cause: e,
      );
    }
  }

  @override
  Future<int> getTotalXp() async {
    try {
      final result = await _database.rawQuery(
        'SELECT SUM(${XpLedgerModel.colXpAmount}) as total FROM ${XpLedgerModel.tableName}',
      );
      if (result.isEmpty || result.first['total'] == null) {
        return 0;
      }
      return result.first['total'] as int;
    } catch (e) {
      throw LocalDatabaseException(
        message: 'Failed to calculate total XP from SQLite.',
        cause: e,
      );
    }
  }
}
