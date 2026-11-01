import 'package:equatable/equatable.dart';

class GamificationState extends Equatable {
  final int totalXp;
  final int lastDeltaXp;
  final int level;
  final String title;
  final int streakFreezes;

  const GamificationState({
    this.totalXp = 0,
    this.lastDeltaXp = 0,
    this.level = 1,
    this.title = 'تازه‌کار',
    this.streakFreezes = 0,
  });

  GamificationState copyWith({
    int? totalXp,
    int? lastDeltaXp,
    int? level,
    String? title,
    int? streakFreezes,
  }) {
    return GamificationState(
      totalXp: totalXp ?? this.totalXp,
      lastDeltaXp: lastDeltaXp ?? this.lastDeltaXp,
      level: level ?? this.level,
      title: title ?? this.title,
      streakFreezes: streakFreezes ?? this.streakFreezes,
    );
  }

  @override
  List<Object?> get props => [totalXp, lastDeltaXp, level, title, streakFreezes];
}
