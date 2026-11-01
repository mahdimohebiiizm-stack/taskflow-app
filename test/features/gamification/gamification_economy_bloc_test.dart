import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_bloc.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_event.dart';
import 'package:task_flow/features/gamification/presentation/bloc/gamification_state.dart';

void main() {
  group('GamificationBloc - XP Economy & Streak Freeze Store (Phase 7)', () {
    blocTest<GamificationBloc, GamificationState>(
      'successfully buys a streak freeze when user has >= 500 XP',
      build: () => GamificationBloc(),
      seed: () => const GamificationState(
        totalXp: 600,
        level: 13,
        title: 'استاد اعظم',
        streakFreezes: 0,
      ),
      act: (bloc) => bloc.add(const BuyStreakFreezeEvent()),
      expect: () => [
        isA<GamificationState>()
            .having((s) => s.totalXp, 'totalXp', 100)
            .having((s) => s.streakFreezes, 'streakFreezes', 1)
            .having((s) => s.lastDeltaXp, 'lastDeltaXp', -500),
      ],
    );

    blocTest<GamificationBloc, GamificationState>(
      'ignores BuyStreakFreezeEvent when user has < 500 XP',
      build: () => GamificationBloc(),
      seed: () => const GamificationState(
        totalXp: 450,
        level: 10,
        title: 'استاد اعظم',
        streakFreezes: 1,
      ),
      act: (bloc) => bloc.add(const BuyStreakFreezeEvent()),
      expect: () => <GamificationState>[],
    );

    blocTest<GamificationBloc, GamificationState>(
      'GamificationInitialized correctly sets streakFreezes and totalXp',
      build: () => GamificationBloc(),
      act: (bloc) => bloc.add(
        const GamificationInitialized(
          totalXp: 1200,
          streakFreezes: 3,
        ),
      ),
      expect: () => [
        isA<GamificationState>()
            .having((s) => s.totalXp, 'totalXp', 1200)
            .having((s) => s.streakFreezes, 'streakFreezes', 3),
      ],
    );
  });
}
