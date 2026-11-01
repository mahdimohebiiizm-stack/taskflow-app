import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/services/sound_and_haptic_service.dart';
import 'package:task_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/task_entity.dart';
import 'package:task_flow/features/tasks/domain/entities/task_priority.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Axis 5 — 7-Day Streak & Streak Freeze Shield in SQLite', () {
    late Database db;
    late SettingsLocalDataSourceImpl settingsDataSource;
    late TaskLocalDataSourceImpl taskDataSource;

    setUp(() async {
      db = await AppDatabase.open(
        databasePath: inMemoryDatabasePath,
        databaseFactory: databaseFactoryFfi,
      );
      settingsDataSource = SettingsLocalDataSourceImpl(database: db);
      taskDataSource = TaskLocalDataSourceImpl(database: db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      '7 consecutive successful days award 1 Streak Freeze shield in SQLite, '
      'and a subsequent failed day consumes the shield without resetting streakCount to 0',
      () async {
        // Complete 6 consecutive days -> streak = 6, freeze shields = 0
        for (var day = 1; day <= 6; day++) {
          final updated = await settingsDataSource.recordSuccessfulStreakDay(
            dateIso: '2026-10-0$day',
          );
          expect(updated.streakCount, equals(day));
          expect(updated.streakFreezeCount, equals(0));
        }

        // Day 7 completed -> streak = 7, 1 Streak Freeze shield awarded in SQLite!
        final day7 = await settingsDataSource.recordSuccessfulStreakDay(
          dateIso: '2026-10-07',
        );
        expect(day7.streakCount, equals(7));
        expect(day7.streakFreezeCount, equals(1));
        expect(day7.hasStreakFreeze, isTrue);

        // Verify persisted in SQLite
        final persistedAfter7 = await settingsDataSource.getSettings();
        expect(persistedAfter7.streakCount, equals(7));
        expect(persistedAfter7.streakFreezeCount, equals(1));

        // Day 8 fails -> Streak Freeze shield breaks (1 -> 0), but streakCount remains 7!
        final afterMissedWithShield =
            await settingsDataSource.recordFailedStreakDay(
          dateIso: '2026-10-08',
        );
        expect(afterMissedWithShield.streakFreezeCount, equals(0));
        expect(afterMissedWithShield.streakCount, equals(7));

        // Day 9 fails with NO shield left -> streakCount resets to 0!
        final afterMissedWithoutShield =
            await settingsDataSource.recordFailedStreakDay(
          dateIso: '2026-10-09',
        );
        expect(afterMissedWithoutShield.streakFreezeCount, equals(0));
        expect(afterMissedWithoutShield.streakCount, equals(0));
      },
    );

    test(
      'recalculateStreakFromTasksDatabase evaluates 7-day streak and shield protection from SQLite tasks table',
      () async {
        // Insert 7 consecutive days of 100% completed tasks into SQLite
        for (var day = 1; day <= 7; day++) {
          final date = DateTime(2026, 10, day, 10, 0);
          final task = (TaskEntity.create(
            id: 'streak-task-$day',
            title: 'تسک روز $day',
            status: TaskStatus.done,
            priority: TaskPriority.medium,
            dueDate: date,
            createdAt: date.toUtc(),
          ) as Success<TaskEntity, dynamic>)
              .value;
          await taskDataSource.saveTask(TaskModel.fromEntity(task));
        }

        final after7Days =
            await settingsDataSource.recalculateStreakFromTasksDatabase();
        expect(after7Days.streakCount, equals(7));
        expect(after7Days.streakFreezeCount, equals(1));

        // Insert a penalized task on Day 8 -> shield is consumed, streak remains 7
        final day8Date = DateTime(2026, 10, 8, 10, 0);
        final failedTask = (TaskEntity.create(
          id: 'streak-task-8',
          title: 'تسک ناتمام روز ۸',
          status: TaskStatus.todo,
          isPenalized: true,
          priority: TaskPriority.medium,
          dueDate: day8Date,
          createdAt: day8Date.toUtc(),
        ) as Success<TaskEntity, dynamic>)
            .value;
        await taskDataSource.saveTask(TaskModel.fromEntity(failedTask));

        final afterDay8 =
            await settingsDataSource.recalculateStreakFromTasksDatabase();
        expect(afterDay8.streakCount, equals(7));
        expect(afterDay8.streakFreezeCount, equals(0));
      },
    );
  });

  group('Axis 6 — Leveling, XP & Titles System', () {
    test('resolves exact Persian titles, medals, and Golden Aura across streak tiers', () {
      // < 3 days -> "تازهکار"
      const tier0 = UserSettingsEntity(
        defaultCurrency: Currency.irt,
        isDarkMode: true,
        userName: 'مهدی',
        streakCount: 2,
      );
      expect(tier0.userTitle, equals('تازهکار'));
      expect(tier0.isGoldenAuraUnlocked, isFalse);

      // 3..13 days -> "برنامهریز" (Bronze Medal 🥉)
      const tier3 = UserSettingsEntity(
        defaultCurrency: Currency.irt,
        isDarkMode: true,
        userName: 'مهدی',
        streakCount: 3,
      );
      expect(tier3.userTitle, equals('برنامهریز'));
      expect(tier3.titleMedal, equals('🥉'));
      expect(tier3.isGoldenAuraUnlocked, isFalse);

      // 14..29 days -> "مبارز زمان" (Silver Medal 🥈)
      const tier14 = UserSettingsEntity(
        defaultCurrency: Currency.irt,
        isDarkMode: true,
        userName: 'مهدی',
        streakCount: 14,
      );
      expect(tier14.userTitle, equals('مبارز زمان'));
      expect(tier14.titleMedal, equals('🥈'));
      expect(tier14.isGoldenAuraUnlocked, isFalse);

      // >= 30 days -> "استاد بهرهوری" (Gold Medal 🥇 + Golden Aura)
      const tier30 = UserSettingsEntity(
        defaultCurrency: Currency.irt,
        isDarkMode: true,
        userName: 'مهدی',
        streakCount: 30,
      );
      expect(tier30.userTitle, equals('استاد بهرهوری'));
      expect(tier30.titleMedal, equals('🥇'));
      expect(tier30.isGoldenAuraUnlocked, isTrue);
      expect(tier30.hasActiveGoldenAura, isTrue);
    });
  });

  group('Axis 4 — Sound & Haptic Micro-interactions (audioplayers + HapticFeedback)', () {
    test('synthesizes valid WAV audio buffers and plays task completion & victory sounds', () async {
      final service = SoundAndHapticService.instance;
      service.resetStats();

      final playedTypes = <SoundEffectType>[];
      final playedByteLengths = <int>[];
      service.onPlayBytesSource = (BytesSource source, SoundEffectType type) async {
        playedTypes.add(type);
        playedByteLengths.add(source.bytes.length);
      };

      await service.playTaskCompletionFeedback();
      expect(service.taskCompletionPlayCount, equals(1));
      expect(service.lastPlayedSound, equals(SoundEffectType.taskCompleted));

      await service.playDailyVictoryFeedback();
      expect(service.dailyVictoryPlayCount, equals(1));
      expect(service.lastPlayedSound, equals(SoundEffectType.dailyVictory));

      expect(
        playedTypes,
        equals([SoundEffectType.taskCompleted, SoundEffectType.dailyVictory]),
      );
      expect(playedByteLengths.first, greaterThan(44));
      expect(playedByteLengths.last, greaterThan(44));

      service.onPlayBytesSource = null;
    });

    test('supports enterprise semantic audio methods: playSuccessChime, playLevelUpFanfare, playSoftTick, and playErrorBuzz', () async {
      final service = SoundAndHapticService.instance;
      service.resetStats();

      final playedTypes = <SoundEffectType>[];
      service.onPlayBytesSource = (BytesSource source, SoundEffectType type) async {
        playedTypes.add(type);
      };

      await service.playSuccessChime();
      expect(service.taskCompletionPlayCount, equals(1));
      expect(service.lastPlayedSound, equals(SoundEffectType.taskCompleted));

      await service.playLevelUpFanfare();
      expect(service.levelUpFanfarePlayCount, equals(1));
      expect(service.dailyVictoryPlayCount, equals(1));
      expect(service.lastPlayedSound, equals(SoundEffectType.dailyVictory));

      await service.playSoftTick();
      expect(service.softTickPlayCount, equals(1));
      expect(service.lastPlayedSound, equals(SoundEffectType.softTick));

      await service.playErrorBuzz();
      expect(service.errorBuzzPlayCount, equals(1));
      expect(service.lastPlayedSound, equals(SoundEffectType.errorBuzz));

      expect(
        playedTypes,
        equals([
          SoundEffectType.taskCompleted,
          SoundEffectType.dailyVictory,
          SoundEffectType.softTick,
          SoundEffectType.errorBuzz,
        ]),
      );

      // Verify PCM synthesizers produce valid RIFF WAV headers (starts with 'RIFF')
      final softTickWav = SoundAndHapticService.generateSoftTickWav();
      final errorBuzzWav = SoundAndHapticService.generateErrorBuzzWav();
      expect(softTickWav.length, greaterThan(44));
      expect(errorBuzzWav.length, greaterThan(44));
      expect(String.fromCharCodes(softTickWav.sublist(0, 4)), equals('RIFF'));
      expect(String.fromCharCodes(errorBuzzWav.sublist(0, 4)), equals('RIFF'));

      service.onPlayBytesSource = null;
    });
  });
}
