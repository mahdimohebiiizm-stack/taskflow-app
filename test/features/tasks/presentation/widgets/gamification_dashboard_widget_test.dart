import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/features/tasks/presentation/widgets/gamification_dashboard_widget.dart';

void main() {
  Widget buildTestableWidget({
    int streakCount = 0,
    int totalXp = 0,
    int level = 1,
    String title = 'تازه‌کار',
    int budgetRials = 0,
    DashboardTriState? forcedTriState,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: GamificationDashboardWidget(
          streakCount: streakCount,
          totalXp: totalXp,
          level: level,
          title: title,
          budgetRials: budgetRials,
          forcedTriState: forcedTriState,
        ),
      ),
    );
  }

  group('GamificationDashboardWidget - Minimal Date/Greeting Header Tests (Phase 5.2)', () {
    testWidgets('renders Day/Date and simple greeting, with NO Level/XP bar, NO Streak Flame, and NO budget card', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          streakCount: 5,
          totalXp: 200,
          level: 5,
          title: 'استاد بهره‌وری',
          budgetRials: 50000,
          forcedTriState: DashboardTriState.hot,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Minimal header components exist
      expect(find.byKey(const Key('gamification_dashboard_widget')), findsOneWidget);
      expect(find.byKey(const Key('dashboard_date_text')), findsOneWidget);
      expect(find.byKey(const Key('dashboard_simple_greeting_text')), findsOneWidget);

      // Verify Level & Title header is COMPLETELY REMOVED from the dashboard
      expect(find.byKey(const Key('gamification_level_title')), findsNothing);

      // Verify XP Progress Bar is COMPLETELY REMOVED from the dashboard
      expect(find.byKey(const Key('gamification_xp_bar')), findsNothing);

      // Verify Streak Flame Badges are COMPLETELY REMOVED from the dashboard
      expect(find.byKey(const Key('gamification_streak_hot')), findsNothing);
      expect(find.byKey(const Key('gamification_streak_cold')), findsNothing);
      expect(find.byKey(const Key('gamification_streak_neutral')), findsNothing);

      // Verify Budget Card is COMPLETELY REMOVED
      expect(find.byKey(const Key('gamification_budget_card')), findsNothing);
      expect(find.textContaining('بودجه امروز'), findsNothing);
    });

    testWidgets('renders properly inside a SliverPersistentHeader', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                const SliverPersistentHeader(
                  pinned: true,
                  delegate: GamificationDashboardSliverDelegate(
                    streakCount: 4,
                    totalXp: 150,
                    level: 4,
                    title: 'مبارز زمان',
                    budgetRials: 75000,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => ListTile(title: Text('Task $index')),
                    childCount: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GamificationDashboardWidget), findsOneWidget);
      expect(find.byKey(const Key('dashboard_date_text')), findsOneWidget);
      expect(find.text('Task 0'), findsOneWidget);
      expect(find.byKey(const Key('gamification_xp_bar')), findsNothing);
      expect(find.byKey(const Key('gamification_streak_hot')), findsNothing);
    });
  });
}
