import 'package:equatable/equatable.dart';

/// Base sealed class for all domain and infrastructure failures.
/// Using Dart 3 [sealed] classes enables exhaustive pattern matching in BLoCs and UI.
sealed class Failure extends Equatable {
  final String message;
  final String code;

  const Failure({
    required this.message,
    required this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Base class for business rule / domain invariant violations.
sealed class DomainFailure extends Failure {
  const DomainFailure({
    required super.message,
    required super.code,
  });
}

/// Returned when an entity field fails domain validation (e.g., empty title).
final class ValidationFailure extends DomainFailure {
  const ValidationFailure({
    required super.message,
    super.code = 'DOMAIN_VALIDATION_ERROR',
  });
}

/// Returned when attempting to transition a Task to [TaskStatus.done]
/// while one or more child SubTasks remain incomplete.
final class IncompleteSubTasksFailure extends DomainFailure {
  final int remainingSubTasks;

  const IncompleteSubTasksFailure({
    required this.remainingSubTasks,
    super.message =
        'Cannot mark task as Done while sub-tasks remain incomplete.',
    super.code = 'INCOMPLETE_SUBTASKS_INVARIANT',
  });

  @override
  List<Object?> get props => [message, code, remainingSubTasks];
}

/// Returned when a requested Task, SubTask, or Expense does not exist.
final class NotFoundFailure extends DomainFailure {
  final String entityId;

  const NotFoundFailure({
    required this.entityId,
    required super.message,
    super.code = 'ENTITY_NOT_FOUND',
  });

  @override
  List<Object?> get props => [message, code, entityId];
}

/// Returned when a financial value or exchange rate violates domain rules
/// (e.g., negative expense amount or non-positive exchange rate ratio).
final class FinancialValidationFailure extends DomainFailure {
  const FinancialValidationFailure({
    required super.message,
    super.code = 'FINANCIAL_VALIDATION_ERROR',
  });
}

/// Returned when attempting direct arithmetic between two different currencies
/// without applying an explicit [ExchangeRateEntity].
final class CurrencyMismatchFailure extends DomainFailure {
  final String leftCurrencyCode;
  final String rightCurrencyCode;

  const CurrencyMismatchFailure({
    required this.leftCurrencyCode,
    required this.rightCurrencyCode,
    super.message =
        'Cannot perform direct arithmetic on different currencies without conversion.',
    super.code = 'CURRENCY_MISMATCH_ERROR',
  });

  @override
  List<Object?> get props =>
      [message, code, leftCurrencyCode, rightCurrencyCode];
}

/// Returned when converting or aggregating expenses into a target currency
/// for which no offline exchange rate has been configured.
final class MissingExchangeRateFailure extends DomainFailure {
  final String sourceCurrencyCode;
  final String targetCurrencyCode;

  const MissingExchangeRateFailure({
    required this.sourceCurrencyCode,
    required this.targetCurrencyCode,
    required super.message,
    super.code = 'MISSING_EXCHANGE_RATE',
  });

  @override
  List<Object?> get props =>
      [message, code, sourceCurrencyCode, targetCurrencyCode];
}

/// Returned when a local SQLite persistence operation fails.
final class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required super.message,
    super.code = 'LOCAL_DATABASE_ERROR',
  });
}
