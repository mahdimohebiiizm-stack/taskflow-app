/// Base exception for Data layer adapters.
/// Data sources throw [AppException] subtypes, which Repositories catch and translate into [Failure]s.
sealed class AppException implements Exception {
  final String message;
  final Object? cause;

  const AppException({
    required this.message,
    this.cause,
  });

  @override
  String toString() => '$runtimeType(message: $message, cause: $cause)';
}

/// Thrown when a SQLite query, transaction, or constraint fails.
final class LocalDatabaseException extends AppException {
  const LocalDatabaseException({
    required super.message,
    super.cause,
  });
}

/// Thrown when an expected database record is not found.
final class RecordNotFoundException extends AppException {
  final String recordId;

  const RecordNotFoundException({
    required this.recordId,
    required super.message,
    super.cause,
  });
}
