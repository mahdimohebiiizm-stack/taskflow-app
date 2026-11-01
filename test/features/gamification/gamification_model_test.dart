import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/features/gamification/data/models/gamification_model.dart';
import 'package:task_flow/features/gamification/domain/entities/gamification_profile_entity.dart';

void main() {
  group('GamificationModel & GamificationProfileEntity (Phase 7 XP Economy)', () {
    test('instantiates with defaults and streakFreezes = 0', () {
      const model = GamificationModel();
      expect(model.totalXp, equals(0));
      expect(model.level, equals(1));
      expect(model.title, equals('تازه‌کار'));
      expect(model.streakFreezes, equals(0));
    });

    test('supports custom streakFreezes count', () {
      const model = GamificationModel(
        totalXp: 1250,
        level: 3,
        title: 'برنامه‌ریز حرفه‌ای',
        streakFreezes: 2,
      );
      expect(model.totalXp, equals(1250));
      expect(model.level, equals(3));
      expect(model.title, equals('برنامه‌ریز حرفه‌ای'));
      expect(model.streakFreezes, equals(2));
    });

    test('fromEntity creates valid model preserving streakFreezes', () {
      const entity = GamificationProfileEntity(
        totalXp: 600,
        level: 2,
        title: 'نوظهور',
        streakFreezes: 1,
      );
      final model = GamificationModel.fromEntity(entity);
      expect(model.totalXp, equals(600));
      expect(model.level, equals(2));
      expect(model.title, equals('نوظهور'));
      expect(model.streakFreezes, equals(1));
    });

    test('toMap serializes streak_freezes and all columns correctly', () {
      const model = GamificationModel(
        totalXp: 750,
        level: 2,
        title: 'برنامه‌ریز نوظهور',
        streakFreezes: 3,
      );
      final map = model.toMap(id: 'test_player');
      expect(map[GamificationModel.colId], equals('test_player'));
      expect(map[GamificationModel.colTotalXp], equals(750));
      expect(map[GamificationModel.colLevel], equals(2));
      expect(map[GamificationModel.colTitle], equals('برنامه‌ریز نوظهور'));
      expect(map[GamificationModel.colStreakFreezes], equals(3));
      expect(map[GamificationModel.colUpdatedAt], isA<String>());
    });

    test('fromMap deserializes streak_freezes properly', () {
      final map = <String, dynamic>{
        GamificationModel.colTotalXp: 1500,
        GamificationModel.colLevel: 4,
        GamificationModel.colTitle: 'استاد تمرکز',
        GamificationModel.colStreakFreezes: 5,
      };
      final model = GamificationModel.fromMap(map);
      expect(model.totalXp, equals(1500));
      expect(model.level, equals(4));
      expect(model.title, equals('استاد تمرکز'));
      expect(model.streakFreezes, equals(5));
    });

    test('fromJson and toJson roundtrip preserves streakFreezes', () {
      const original = GamificationModel(
        totalXp: 2000,
        level: 5,
        title: 'افسانه بهره‌وری',
        streakFreezes: 4,
      );
      final json = original.toJson();
      final revived = GamificationModel.fromJson(json);
      expect(revived.totalXp, equals(original.totalXp));
      expect(revived.level, equals(original.level));
      expect(revived.title, equals(original.title));
      expect(revived.streakFreezes, equals(original.streakFreezes));
    });

    test('copyWith updates streakFreezes appropriately', () {
      const entity = GamificationProfileEntity(
        totalXp: 500,
        streakFreezes: 0,
      );
      final updated = entity.copyWith(
        totalXp: 0,
        streakFreezes: 1,
      );
      expect(updated.totalXp, equals(0));
      expect(updated.streakFreezes, equals(1));
    });
  });
}
