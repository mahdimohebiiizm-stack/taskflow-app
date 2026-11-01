import 'package:sqflite/sqflite.dart';
import 'package:task_flow/core/error/exceptions.dart';
import 'package:task_flow/features/analytics/domain/entities/analytics_summary_entity.dart';
import 'package:task_flow/features/analytics/domain/entities/daily_expense_entity.dart';
import 'package:task_flow/features/analytics/domain/entities/task_ratio_entity.dart';
import 'package:task_flow/features/tasks/data/models/expense_item_model.dart';
import 'package:task_flow/features/tasks/data/models/task_model.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';
import 'package:task_flow/features/tasks/domain/entities/money.dart';
import 'package:task_flow/features/tasks/domain/entities/task_status.dart';

abstract interface class AnalyticsLocalDataSource {
  Future<AnalyticsSummaryEntity> getAnalyticsSummary({
    Currency targetCurrency = Currency.irt,
    DateTime? referenceDate,
  });
}

class AnalyticsLocalDataSourceImpl implements AnalyticsLocalDataSource {
  final Database _database;

  const AnalyticsLocalDataSourceImpl({
    required Database database,
    dynamic currencyConverter,
  }) : _database = database;

  static String _weekdayToPersian(int weekday) {
    return switch (weekday) {
      DateTime.saturday => 'شنبه',
      DateTime.sunday => '۱شنبه',
      DateTime.monday => '۲شنبه',
      DateTime.tuesday => '۳شنبه',
      DateTime.wednesday => '۴شنبه',
      DateTime.thursday => '۵شنبه',
      DateTime.friday => 'جمعه',
      _ => 'روز',
    };
  }

  @override
  Future<AnalyticsSummaryEntity> getAnalyticsSummary({
    Currency targetCurrency = Currency.irt,
    DateTime? referenceDate,
  }) async {
    try {
      final now = referenceDate ?? DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Execute all SQLite analytics & heatmap queries concurrently via Future.wait
      final queryResults = await Future.wait<List<Map<String, Object?>>>([
        _database.rawQuery('''
          SELECT ${TaskModel.colStatus}, COUNT(*) as count
          FROM ${TaskModel.tableName}
          GROUP BY ${TaskModel.colStatus}
        '''),
        _database.query(
          ExpenseItemModel.tableName,
          orderBy: '${ExpenseItemModel.colIncurredAt} ASC',
        ),
        _database.query(
          TaskModel.tableName,
          columns: <String>[
            TaskModel.colStatus,
            TaskModel.colIsPenalized,
            TaskModel.colDueDate,
            TaskModel.colCreatedAt,
            TaskModel.colUpdatedAt,
          ],
          where: '${TaskModel.colStatus} = ?',
          whereArgs: <Object?>[TaskStatus.done.storageKey],
        ),
      ]);

      final taskStatusRows = queryResults[0];
      final expenseRows = queryResults[1];
      final completedTaskRows = queryResults[2];

      var totalTasks = 0;
      var completedTasks = 0;
      var inProgressTasks = 0;
      var todoTasks = 0;

      for (final row in taskStatusRows) {
        final statusKey = row[TaskModel.colStatus] as String?;
        final count = (row['count'] as num?)?.toInt() ?? 0;
        totalTasks += count;
        if (statusKey == TaskStatus.done.storageKey) {
          completedTasks = count;
        } else if (statusKey == TaskStatus.inProgress.storageKey) {
          inProgressTasks = count;
        } else if (statusKey == TaskStatus.todo.storageKey) {
          todoTasks = count;
        }
      }

      final taskRatio = TaskRatioEntity(
        totalCount: totalTasks,
        completedCount: completedTasks,
        inProgressCount: inProgressTasks,
        todoCount: todoTasks,
      );

      // Aggregate GitHub-style daily activity heatmap counts (YYYY-MM-DD -> count)
      final heatmapCounts = <String, int>{};
      for (final row in completedTaskRows) {
        final isPenalized = (row[TaskModel.colIsPenalized] as int? ?? 0) != 0;
        if (isPenalized) continue;
        final rawDue = row[TaskModel.colDueDate] as String?;
        final rawUpdated = row[TaskModel.colUpdatedAt] as String?;
        final rawCreated = row[TaskModel.colCreatedAt] as String?;
        final rawIso = (rawDue != null && rawDue.isNotEmpty)
            ? rawDue
            : ((rawUpdated != null && rawUpdated.isNotEmpty)
                ? rawUpdated
                : (rawCreated ?? ''));
        final parsed = DateTime.tryParse(rawIso)?.toLocal();
        if (parsed == null) continue;
        final dayKey =
            '${parsed.year.toString().padLeft(4, '0')}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
        heatmapCounts[dayKey] = (heatmapCounts[dayKey] ?? 0) + 1;
      }

      final allExpenses = expenseRows.map((row) {
        final rawDate = row[ExpenseItemModel.colIncurredAt] as String;
        final date = DateTime.tryParse(rawDate) ?? now;
        final amount = (row[ExpenseItemModel.colAmountMinorUnits] as num).toInt();
        return (
          date: date,
          money: Money.reconstitute(amountMinorUnits: amount, currency: Currency.irt),
        );
      }).toList(growable: false);

      // 3. Build 7-day chronological expense data points
      final dailyExpenses = <DailyExpenseEntity>[];
      var total7DaysMinor = 0;

      for (var i = 6; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        final dayStart = DateTime(day.year, day.month, day.day, 0, 0, 0);
        final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);

        final expensesForDay = allExpenses.where((e) {
          final local = e.date.toLocal();
          return local.isAfter(dayStart.subtract(const Duration(milliseconds: 1))) &&
              local.isBefore(dayEnd.add(const Duration(milliseconds: 1)));
        }).map((e) => e.money);

        var daySumMinor = 0;
        for (final m in expensesForDay) {
          daySumMinor += m.amountMinorUnits;
        }

        final dayTotalMoney = Money.reconstitute(
          amountMinorUnits: daySumMinor,
          currency: Currency.irt,
        );

        total7DaysMinor += dayTotalMoney.amountMinorUnits;

        dailyExpenses.add(
          DailyExpenseEntity(
            date: day,
            dayLabel: _weekdayToPersian(day.weekday),
            amount: dayTotalMoney,
            expenseCount: expensesForDay.length,
          ),
        );
      }

      // 4. Build month-to-date expense
      final monthStart = DateTime(now.year, now.month, 1, 0, 0, 0);
      final expensesForMonth = allExpenses.where((e) {
        final local = e.date.toLocal();
        return local.isAfter(monthStart.subtract(const Duration(milliseconds: 1)));
      }).map((e) => e.money);

      var monthSumMinor = 0;
      for (final m in expensesForMonth) {
        monthSumMinor += m.amountMinorUnits;
      }

      final monthlyTotal = Money.reconstitute(
        amountMinorUnits: monthSumMinor,
        currency: Currency.irt,
      );

      return AnalyticsSummaryEntity(
        last7DaysExpenses: dailyExpenses,
        total7DaysExpense: Money.reconstitute(
          amountMinorUnits: total7DaysMinor,
          currency: Currency.irt,
        ),
        monthlyExpense: monthlyTotal,
        taskRatio: taskRatio,
        targetCurrency: Currency.irt,
        activityHeatmapCounts: heatmapCounts,
      );
    } catch (error) {
      throw LocalDatabaseException(
        message: 'Failed to aggregate analytics data from SQLite.',
        cause: error,
      );
    }
  }
}
