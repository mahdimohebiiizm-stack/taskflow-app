import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/xp_ledger_entry_entity.dart';

abstract interface class XpLedgerRepository {
  Future<Result<XpLedgerEntryEntity, Failure>> recordXp(
    XpLedgerEntryEntity entry,
  );
  Future<Result<List<XpLedgerEntryEntity>, Failure>> getXpEntries({
    String? source,
  });
  Future<Result<int, Failure>> getTotalXp();
}
