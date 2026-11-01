import 'package:equatable/equatable.dart';

/// Origin of awarded or deducted XP.
enum XpSource {
  taskCompletion('task_completion'),
  pomodoroSession('pomodoro_session'),
  streakBonus('streak_bonus'),
  manual('manual');

  final String value;
  const XpSource(this.value);

  static XpSource fromString(String val) {
    return XpSource.values.firstWhere(
      (e) => e.value == val,
      orElse: () => XpSource.manual,
    );
  }
}

/// Domain entity representing an audit log entry in the user's XP ledger.
class XpLedgerEntryEntity extends Equatable {
  final String id;
  final XpSource source;
  final String? referenceId;
  final int xpAmount;
  final String description;
  final DateTime createdAt;

  const XpLedgerEntryEntity({
    required this.id,
    required this.source,
    this.referenceId,
    required this.xpAmount,
    required this.description,
    required this.createdAt,
  });

  XpLedgerEntryEntity copyWith({
    String? id,
    XpSource? source,
    String? Function()? referenceId,
    int? xpAmount,
    String? description,
    DateTime? createdAt,
  }) {
    return XpLedgerEntryEntity(
      id: id ?? this.id,
      source: source ?? this.source,
      referenceId: referenceId != null ? referenceId() : this.referenceId,
      xpAmount: xpAmount ?? this.xpAmount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        source,
        referenceId,
        xpAmount,
        description,
        createdAt,
      ];
}
