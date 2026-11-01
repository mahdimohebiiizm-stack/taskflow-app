import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/expense_item_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';

/// Data Transfer Object (DTO) for [ExpenseItemEntity] persistence in SQLite.
class ExpenseItemModel extends Equatable {
  static const String tableName = 'task_expenses';
  static const String colId = 'id';
  static const String colTaskId = 'task_id';
  static const String colTitle = 'title';
  static const String colAmountMinorUnits = 'amount_minor_units';
  static const String colCurrencyCode = 'currency_code';
  static const String colIncurredAt = 'incurred_at';
  static const String colPosition = 'position';

  final String id;
  final String taskId;
  final String title;
  final int amountMinorUnits;
  final Currency currency;
  final DateTime incurredAt;
  final int position;

  const ExpenseItemModel({
    required this.id,
    required this.taskId,
    required this.title,
    required this.amountMinorUnits,
    required this.currency,
    required this.incurredAt,
    required this.position,
  });

  /// Deterministically maps a domain [ExpenseItemEntity] into an [ExpenseItemModel].
  factory ExpenseItemModel.fromEntity(
    ExpenseItemEntity entity, {
    required String taskId,
    required int position,
  }) {
    return ExpenseItemModel(
      id: entity.id,
      taskId: taskId,
      title: entity.title,
      amountMinorUnits: entity.money.amountMinorUnits,
      currency: entity.money.currency,
      incurredAt: entity.incurredAt,
      position: position,
    );
  }

  /// Deterministically parses a SQLite row [Map] into an [ExpenseItemModel].
  /// Throws [LocalDatabaseException] if any column is missing, negative, or corrupted.
  factory ExpenseItemModel.fromMap(Map<String, Object?> map) {
    try {
      final id = map[colId] as String?;
      final taskId = map[colTaskId] as String?;
      final title = map[colTitle] as String?;
      final rawAmount = map[colAmountMinorUnits];
      final rawCurrency = map[colCurrencyCode] as String?;
      final rawIncurredAt = map[colIncurredAt] as String?;
      final rawPosition = map[colPosition];

      if (id == null || id.trim().isEmpty) {
        throw const LocalDatabaseException(
          message: 'Corrupted task_expenses row: missing or empty "id".',
        );
      }
      if (taskId == null || taskId.trim().isEmpty) {
        throw const LocalDatabaseException(
          message: 'Corrupted task_expenses row: missing or empty "task_id".',
        );
      }
      if (title == null || title.trim().isEmpty) {
        throw const LocalDatabaseException(
          message: 'Corrupted task_expenses row: missing or empty "title".',
        );
      }
      if (rawAmount is! int || rawAmount <= 0) {
        throw LocalDatabaseException(
          message:
              'Corrupted task_expenses row: invalid "amount_minor_units" ($rawAmount).',
        );
      }
      if (rawCurrency == null) {
        throw const LocalDatabaseException(
          message: 'Corrupted task_expenses row: missing "currency_code".',
        );
      }
      if (rawIncurredAt == null) {
        throw const LocalDatabaseException(
          message: 'Corrupted task_expenses row: missing "incurred_at".',
        );
      }

      final currency = Currency.fromCode(rawCurrency);
      final incurredAt = DateTime.parse(rawIncurredAt);
      final position = rawPosition is int ? rawPosition : 0;

      return ExpenseItemModel(
        id: id,
        taskId: taskId,
        title: title,
        amountMinorUnits: rawAmount,
        currency: currency,
        incurredAt: incurredAt,
        position: position,
      );
    } catch (error) {
      if (error is LocalDatabaseException) {
        rethrow;
      }
      throw LocalDatabaseException(
        message: 'Failed to deserialize ExpenseItemModel from SQLite map.',
        cause: error,
      );
    }
  }

  /// Serializes this model into a SQLite-compatible [Map].
  Map<String, Object?> toMap() {
    return <String, Object?>{
      colId: id,
      colTaskId: taskId,
      colTitle: title,
      colAmountMinorUnits: amountMinorUnits,
      colCurrencyCode: currency.code,
      colIncurredAt: incurredAt.toIso8601String(),
      colPosition: position,
    };
  }

  /// Deterministically converts this [ExpenseItemModel] into a domain [ExpenseItemEntity].
  ExpenseItemEntity toEntity() {
    return ExpenseItemEntity.reconstitute(
      id: id,
      title: title,
      money: Money.reconstitute(
        amountMinorUnits: amountMinorUnits,
        currency: currency,
      ),
      incurredAt: incurredAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        title,
        amountMinorUnits,
        currency,
        incurredAt,
        position,
      ];
}
