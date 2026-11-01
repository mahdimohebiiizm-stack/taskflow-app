import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/core/widgets/signature_empty_state.dart';

void main() {
  group('Phase Audit Part 2 — UI/UX Polish & Micro-Interactions Tests', () {
    testWidgets('SignatureEmptyState renders icon and message in accessible #9CA3AF', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignatureEmptyState(
              icon: CupertinoIcons.wind,
              message: 'امروز هیچ کاری ثبت نشده',
            ),
          ),
        ),
      );

      expect(find.byType(SignatureEmptyState), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.wind), findsOneWidget);
      expect(find.text('امروز هیچ کاری ثبت نشده'), findsOneWidget);

      final icon = tester.widget<Icon>(find.byIcon(CupertinoIcons.wind));
      expect(icon.size, 48);
      expect(icon.color, const Color(0xFF3A3F50));

      final text = tester.widget<Text>(find.text('امروز هیچ کاری ثبت نشده'));
      expect(text.style?.color, const Color(0xFF9CA3AF));
    });

    testWidgets('SignatureEmptyState handles custom transaction empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SignatureEmptyState(
              icon: CupertinoIcons.wind,
              message: 'تراکنشی یافت نشد',
            ),
          ),
        ),
      );

      expect(find.text('تراکنشی یافت نشد'), findsOneWidget);
      final text = tester.widget<Text>(find.text('تراکنشی یافت نشد'));
      expect(text.style?.color, const Color(0xFF9CA3AF));
    });
  });
}
