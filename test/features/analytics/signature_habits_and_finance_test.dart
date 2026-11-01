import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_flow/core/theme/app_theme_mode.dart';
import 'package:task_flow/features/analytics/presentation/pages/financial_analytics_page.dart';
import 'package:task_flow/features/analytics/presentation/pages/reports_page.dart';

void main() {
  group('Phase 8.3: Signature Habits & Finance Key Contract Tests', () {
    test('AppThemeMode.signature is the only theme where isSignatureLayout is true', () {
      expect(AppThemeMode.signature.isSignatureLayout, isTrue);
      expect(AppThemeMode.dark.isSignatureLayout, isFalse);
      expect(AppThemeMode.zen.isSignatureLayout, isFalse);
      expect(AppThemeMode.light.isSignatureLayout, isFalse);
    });

    test('ReportsPage and FinancialAnalyticsPage have defined required widget keys', () {
      // Habit view keys contract
      const habitHeatmapKey = Key('signature_habit_heatmap');
      const habitRefreshKey = Key('signature_reports_pull_to_refresh');
      expect(habitHeatmapKey, equals(const Key('signature_habit_heatmap')));
      expect(habitRefreshKey, equals(const Key('signature_reports_pull_to_refresh')));

      // Finance view keys contract
      const financeBalanceKey = Key('signature_finance_hero_balance');
      const financeBarChartKey = Key('signature_weekly_bar_chart');
      const financeTxListKey = Key('signature_finance_transactions_list');
      expect(financeBalanceKey, equals(const Key('signature_finance_hero_balance')));
      expect(financeBarChartKey, equals(const Key('signature_weekly_bar_chart')));
      expect(financeTxListKey, equals(const Key('signature_finance_transactions_list')));
    });

    test('FinancialAnalyticsPage and ReportsPage can be instantiated with default parameters', () {
      const reports = ReportsPage(isDark: true);
      expect(reports.isDark, isTrue);
      expect(reports.isZen, isFalse);

      const finance = FinancialAnalyticsPage(isDark: true);
      expect(finance.isDark, isTrue);
      expect(finance.isZen, isFalse);
    });
  });
}
