import 'package:task_flow/features/tasks/domain/entities/xp_ledger_entry_entity.dart';

/// Data Transfer Object (DTO) for [XpLedgerEntryEntity] persistence in SQLite.
class XpLedgerModel extends XpLedgerEntryEntity {
  static const String tableName = 'xp_ledger';
  static const String colId = 'id';
  static const String colSource = 'source';
  static const String colReferenceId = 'reference_id';
  static const String colXpAmount = 'xp_amount';
  static const String colDescription = 'description';
  static const String colCreatedAt = 'created_at';

  const XpLedgerModel({
    required super.id,
    required super.source,
    super.referenceId,
    required super.xpAmount,
    required super.description,
    required super.createdAt,
  });

  factory XpLedgerModel.fromEntity(XpLedgerEntryEntity entity) {
    return XpLedgerModel(
      id: entity.id,
      source: entity.source,
      referenceId: entity.referenceId,
      xpAmount: entity.xpAmount,
      description: entity.description,
      createdAt: entity.createdAt,
    );
  }

  factory XpLedgerModel.fromMap(Map<String, Object?> map) {
    return XpLedgerModel(
      id: map[colId] as String,
      source: XpSource.fromString(map[colSource] as String? ?? 'manual'),
      referenceId: map[colReferenceId] as String?,
      xpAmount: map[colXpAmount] as int? ?? 0,
      description: map[colDescription] as String? ?? '',
      createdAt: DateTime.parse(map[colCreatedAt] as String),
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      colId: id,
      colSource: source.value,
      colReferenceId: referenceId,
      colXpAmount: xpAmount,
      colDescription: description,
      colCreatedAt: createdAt.toIso8601String(),
    };
  }
}
