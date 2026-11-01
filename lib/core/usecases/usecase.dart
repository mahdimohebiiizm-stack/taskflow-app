import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';

/// Base contract for all Domain UseCases.
/// Enforces a uniform input/output boundary returning a [Result] instead of throwing exceptions.
abstract interface class UseCase<Type, Params> {
  Future<Result<Type, Failure>> call(Params params);
}

/// Parameter placeholder for UseCases that do not require input arguments.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
