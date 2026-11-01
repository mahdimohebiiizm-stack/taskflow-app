import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/data/datasources/xp_ledger_local_datasource.dart';
import 'package:task_flow/features/tasks/data/models/xp_ledger_model.dart';
import 'package:task_flow/features/tasks/domain/entities/xp_ledger_entry_entity.dart';
import 'package:task_flow/features/tasks/domain/repositories/xp_ledger_repository.dart';

class XpLedgerRepositoryImpl implements XpLedgerRepository {
  final XpLedgerLocalDataSource _localDataSource;

  const XpLedgerRepositoryImpl({
    required XpLedgerLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  @override
  Future<Result<XpLedgerEntryEntity, Failure>> recordXp(
    XpLedgerEntryEntity entry,
  ) async {
    try {
      final model = XpLedgerModel.fromEntity(entry);
      final saved = await _localDataSource.recordXp(model);
      return Success(saved);
    } on LocalDatabaseException catch (e) {
      return Err(DatabaseFailure(message: e.message));
    } catch (e) {
      return Err(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<List<XpLedgerEntryEntity>, Failure>> getXpEntries({
    String? source,
  }) async {
    try {
      final list = await _localDataSource.getXpEntries(source: source);
      return Success(list);
    } on LocalDatabaseException catch (e) {
      return Err(DatabaseFailure(message: e.message));
    } catch (e) {
      return Err(DatabaseFailure(message: e.toString()));
    }
  }

  @override
  Future<Result<int, Failure>> getTotalXp() async {
    try {
      final total = await _localDataSource.getTotalXp();
      return Success(total);
    } on LocalDatabaseException catch (e) {
      return Err(DatabaseFailure(message: e.message));
    } catch (e) {
      return Err(DatabaseFailure(message: e.toString()));
    }
  }
}
