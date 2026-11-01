import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/features/settings/presentation/widgets/player_profile_card.dart';
import 'package:task_flow/features/tasks/presentation/widgets/gamification_dashboard_widget.dart';

void main() {
  Widget buildTestableWidget({
    int streakCount = 0,
    int totalXp = 0,
    int level = 1,
    String title = 'تازه‌کار',
    DashboardTriState? forcedTriState,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PlayerProfileCard(
          streakCount: streakCount,
          totalXp: totalXp,
          level: level,
          title: title,
          forcedTriState: forcedTriState,
        ),
      ),
    );
  }

  group('PlayerProfileCard - Settings Tab Profile Tests (Phase 5.2)', () {
    testWidgets('renders Cold State correctly when streak is 0', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          streakCount: 0,
          totalXp: 20,
          level: 1,
          title: 'تازه‌کار',
          forcedTriState: DashboardTriState.cold,
        ),
      );
      await tester.pumpAndSettle();

      // Verify PlayerProfileCard container
      expect(find.byKey(const Key('settings_player_profile_card')), findsOneWidget);

      // Verify Cold streak badge
      expect(find.byKey(const Key('gamification_streak_cold')), findsOneWidget);
      expect(find.byKey(const Key('gamification_streak_hot')), findsNothing);
      expect(find.textContaining('استمرار غیرفعال'), findsOneWidget);

      // Verify Level and Title
      expect(find.byKey(const Key('gamification_level_title')), findsOneWidget);
      expect(find.textContaining('سطح ۱'), findsOneWidget);
      expect(find.textContaining('تازه‌کار'), findsOneWidget);

      // Verify XP progress bar
      expect(find.byKey(const Key('gamification_xp_bar')), findsOneWidget);
    });

    testWidgets('renders Hot State correctly when streak > 3', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          streakCount: 7,
          totalXp: 350,
          level: 8,
          title: 'استاد بهره‌وری',
          forcedTriState: DashboardTriState.hot,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Hot streak flame badge
      expect(find.byKey(const Key('gamification_streak_hot')), findsOneWidget);
      expect(find.byKey(const Key('gamification_streak_cold')), findsNothing);

      // Verify flame emoji and text
      expect(find.textContaining('🔥'), findsOneWidget);
      expect(find.textContaining('روز استمرار آتشین'), findsOneWidget);

      // Verify title & level
      expect(find.textContaining('استاد بهره‌وری'), findsOneWidget);
      expect(find.textContaining('سطح ۸'), findsOneWidget);
    });

    testWidgets('renders Neutral State correctly when streak is between 1 and 3', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          streakCount: 2,
          totalXp: 80,
          level: 2,
          title: 'برنامه‌ریز نوظهور',
          forcedTriState: DashboardTriState.neutral,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gamification_streak_neutral')), findsOneWidget);
      expect(find.byKey(const Key('gamification_streak_cold')), findsNothing);
      expect(find.byKey(const Key('gamification_streak_hot')), findsNothing);
      expect(find.textContaining('⚡'), findsOneWidget);
      expect(find.textContaining('روز استمرار'), findsOneWidget);
    });

    testWidgets('computes dynamic TriState automatically from streak value', (tester) async {
      // Streak = 0 -> Cold
      await tester.pumpWidget(buildTestableWidget(streakCount: 0));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gamification_streak_cold')), findsOneWidget);

      // Streak = 2 -> Neutral
      await tester.pumpWidget(buildTestableWidget(streakCount: 2));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gamification_streak_neutral')), findsOneWidget);

      // Streak = 5 -> Hot
      await tester.pumpWidget(buildTestableWidget(streakCount: 5));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gamification_streak_hot')), findsOneWidget);
    });
  });
}
