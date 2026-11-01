import 'package:task_flow/features/gamification/domain/entities/gamification_profile_entity.dart';

class GamificationModel extends GamificationProfileEntity {
  static const String tableName = 'gamification_profile';
  static const String colId = 'id';
  static const String colTotalXp = 'total_xp';
  static const String colLevel = 'level';
  static const String colTitle = 'title';
  static const String colStreakFreezes = 'streak_freezes';
  static const String colUpdatedAt = 'updated_at';

  const GamificationModel({
    super.totalXp = 0,
    super.level = 1,
    super.title = 'تازه‌کار',
    super.streakFreezes = 0,
  });

  factory GamificationModel.fromEntity(GamificationProfileEntity entity) {
    return GamificationModel(
      totalXp: entity.totalXp,
      level: entity.level,
      title: entity.title,
      streakFreezes: entity.streakFreezes,
    );
  }

  factory GamificationModel.fromMap(Map<String, dynamic> map) {
    return GamificationModel(
      totalXp: (map[colTotalXp] as num?)?.toInt() ?? 0,
      level: (map[colLevel] as num?)?.toInt() ?? 1,
      title: (map[colTitle] as String?) ?? 'تازه‌کار',
      streakFreezes: (map[colStreakFreezes] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap({String id = 'user_gamification_profile'}) {
    return {
      colId: id,
      colTotalXp: totalXp,
      colLevel: level,
      colTitle: title,
      colStreakFreezes: streakFreezes,
      colUpdatedAt: DateTime.now().toUtc().toIso8601String(),
    };
  }

  factory GamificationModel.fromJson(Map<String, dynamic> json) =>
      GamificationModel.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}

typedef GamificationProfileModel = GamificationModel;
