import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/exchange_rate_entity.dart';

/// Data Transfer Object (DTO) for offline [ExchangeRateEntity] persistence in SQLite.
class ExchangeRateModel extends Equatable {
  static const String tableName = 'exchange_rates';
  static const String colSourceCurrency = 'source_currency';
  static const String colTargetCurrency = 'target_currency';
  static const String colRateNumerator = 'rate_numerator';
  static const String colRateDenominator = 'rate_denominator';
  static const String colUpdatedAt = 'updated_at';

  final Currency sourceCurrency;
  final Currency targetCurrency;
  final int rateNumerator;
  final int rateDenominator;
  final DateTime updatedAt;

  const ExchangeRateModel({
    required this.sourceCurrency,
    required this.targetCurrency,
    required this.rateNumerator,
    required this.rateDenominator,
    required this.updatedAt,
  });

  /// Deterministically maps a domain [ExchangeRateEntity] into an [ExchangeRateModel].
  factory ExchangeRateModel.fromEntity(ExchangeRateEntity entity) {
    return ExchangeRateModel(
      sourceCurrency: entity.sourceCurrency,
      targetCurrency: entity.targetCurrency,
      rateNumerator: entity.rateNumerator,
      rateDenominator: entity.rateDenominator,
      updatedAt: entity.updatedAt,
    );
  }

  /// Deterministically parses a SQLite row [Map] into an [ExchangeRateModel].
  factory ExchangeRateModel.fromMap(Map<String, Object?> map) {
    try {
      final rawSource = map[colSourceCurrency] as String?;
      final rawTarget = map[colTargetCurrency] as String?;
      final rawNumerator = map[colRateNumerator];
      final rawDenominator = map[colRateDenominator];
      final rawUpdatedAt = map[colUpdatedAt] as String?;

      if (rawSource == null || rawTarget == null) {
        throw const LocalDatabaseException(
          message: 'Corrupted exchange_rates row: missing currency codes.',
        );
      }
      if (rawNumerator is! int ||
          rawDenominator is! int ||
          rawNumerator <= 0 ||
          rawDenominator <= 0) {
        throw const LocalDatabaseException(
          message:
              'Corrupted exchange_rates row: rate numerator and denominator must be positive integers.',
        );
      }
      if (rawUpdatedAt == null) {
        throw const LocalDatabaseException(
          message: 'Corrupted exchange_rates row: missing "updated_at".',
        );
      }

      return ExchangeRateModel(
        sourceCurrency: Currency.fromCode(rawSource),
        targetCurrency: Currency.fromCode(rawTarget),
        rateNumerator: rawNumerator,
        rateDenominator: rawDenominator,
        updatedAt: DateTime.parse(rawUpdatedAt),
      );
    } catch (error) {
      if (error is LocalDatabaseException) {
        rethrow;
      }
      throw LocalDatabaseException(
        message: 'Failed to deserialize ExchangeRateModel from SQLite map.',
        cause: error,
      );
    }
  }

  /// Serializes this model into a SQLite-compatible [Map].
  Map<String, Object?> toMap() {
    return <String, Object?>{
      colSourceCurrency: sourceCurrency.code,
      colTargetCurrency: targetCurrency.code,
      colRateNumerator: rateNumerator,
      colRateDenominator: rateDenominator,
      colUpdatedAt: updatedAt.toIso8601String(),
    };
  }

  /// Deterministically converts this [ExchangeRateModel] into a domain [ExchangeRateEntity].
  ExchangeRateEntity toEntity() {
    return ExchangeRateEntity.reconstitute(
      sourceCurrency: sourceCurrency,
      targetCurrency: targetCurrency,
      rateNumerator: rateNumerator,
      rateDenominator: rateDenominator,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        sourceCurrency,
        targetCurrency,
        rateNumerator,
        rateDenominator,
        updatedAt,
      ];
}
