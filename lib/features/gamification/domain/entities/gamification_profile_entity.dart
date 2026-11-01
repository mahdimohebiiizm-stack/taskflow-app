import 'package:equatable/equatable.dart';

/// Represents the player's progression, leveling, and economy inventory.
class GamificationProfileEntity extends Equatable {
  final int totalXp;
  final int level;
  final String title;
  final int streakFreezes;

  const GamificationProfileEntity({
    this.totalXp = 0,
    this.level = 1,
    this.title = 'تازه‌کار',
    this.streakFreezes = 0,
  });

  GamificationProfileEntity copyWith({
    int? totalXp,
    int? level,
    String? title,
    int? streakFreezes,
  }) {
    return GamificationProfileEntity(
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      title: title ?? this.title,
      streakFreezes: streakFreezes ?? this.streakFreezes,
    );
  }

  @override
  List<Object?> get props => [totalXp, level, title, streakFreezes];
}
