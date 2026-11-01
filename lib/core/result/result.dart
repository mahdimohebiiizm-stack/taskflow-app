import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';

/// A type-safe functional Result union using native Dart 3 sealed classes.
/// Eliminates the need for code generation (`freezed`) or heavy external FP libraries.
sealed class Result<T, F extends Failure> extends Equatable {
  const Result();

  /// Returns true if this result is a [Success].
  bool get isSuccess => this is Success<T, F>;

  /// Returns true if this result is an [Err].
  bool get isFailure => this is Err<T, F>;

  /// Pattern-matches both branches into a single return value [R].
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(F failure) onFailure,
  }) {
    return switch (this) {
      Success<T, F>(value: final v) => onSuccess(v),
      Err<T, F>(failure: final f) => onFailure(f),
    };
  }

  /// Transforms the success value while preserving any failure.
  Result<U, F> map<U>(U Function(T value) transform) {
    return switch (this) {
      Success<T, F>(value: final v) => Success<U, F>(transform(v)),
      Err<T, F>(failure: final f) => Err<U, F>(f),
    };
  }
}

/// Represents a successful operation containing [value].
final class Success<T, F extends Failure> extends Result<T, F> {
  final T value;

  const Success(this.value);

  @override
  List<Object?> get props => [value];
}

/// Represents a failed operation containing [failure].
final class Err<T, F extends Failure> extends Result<T, F> {
  final F failure;

  const Err(this.failure);

  @override
  List<Object?> get props => [failure];
}
