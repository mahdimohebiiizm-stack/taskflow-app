import 'package:equatable/equatable.dart';
import 'package:task_flow/core/error/failures.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';

/// Child entity representing a single financial expense entry recorded on a [TaskEntity].
class ExpenseItemEntity extends Equatable {
  final String id;
  final String title;
  final Money money;
  final DateTime incurredAt;

  const ExpenseItemEntity._({
    required this.id,
    required this.title,
    required this.money,
    required this.incurredAt,
  });

  /// Factory method enforcing domain validation rules on creation.
  static Result<ExpenseItemEntity, DomainFailure> create({
    required String id,
    required String title,
    required Money money,
    required DateTime incurredAt,
  }) {
    final trimmedId = id.trim();
    final trimmedTitle = title.trim();

    if (trimmedId.isEmpty) {
      return const Err(
        ValidationFailure(message: 'Expense ID cannot be empty.'),
      );
    }

    if (trimmedTitle.isEmpty) {
      return const Err(
        ValidationFailure(message: 'Expense title cannot be empty.'),
      );
    }

    if (money.amountMinorUnits <= 0) {
      return const Err(
        FinancialValidationFailure(
          message: 'Expense amount must be greater than zero.',
        ),
      );
    }

    return Success(
      ExpenseItemEntity._(
        id: trimmedId,
        title: trimmedTitle,
        money: money,
        incurredAt: incurredAt,
      ),
    );
  }

  /// Reconstitutes a validated [ExpenseItemEntity] from persistent storage.
  factory ExpenseItemEntity.reconstitute({
    required String id,
    required String title,
    required Money money,
    required DateTime incurredAt,
  }) {
    return ExpenseItemEntity._(
      id: id,
      title: title,
      money: money,
      incurredAt: incurredAt,
    );
  }

  @override
  List<Object?> get props => [id, title, money, incurredAt];
}
