import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:task_flow/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/tasks/data/datasources/app_database.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

void main() {
  late Database database;
  late SettingsLocalDataSource dataSource;
  late SettingsRepositoryImpl repository;

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() async {
    database = await AppDatabase.open(
      databasePath: inMemoryDatabasePath,
      databaseFactory: databaseFactoryFfi,
    );
    dataSource = SettingsLocalDataSourceImpl(database: database);
    repository = SettingsRepositoryImpl(localDataSource: dataSource);
  });

  tearDown(() async {
    await database.close();
  });

  group('SettingsRepositoryImpl SQLite Integration', () {
    test('returns default settings when database table is initially empty', () async {
      final result = await repository.getSettings();
      expect(result, isA<Success<UserSettingsEntity, dynamic>>());
      final settings = (result as Success<UserSettingsEntity, dynamic>).value;
      expect(settings.defaultCurrency, equals(Currency.irt));
      expect(settings.isDarkMode, isTrue);
      expect(settings.userName, equals('مهدی'));
      expect(settings.hasSeenOnboarding, isFalse);
    });

    test('persists updated settings and restores them across subsequent queries', () async {
      const updated = UserSettingsEntity(
        defaultCurrency: Currency.irt,
        isDarkMode: false,
        userName: 'مهدی رحیمی',
      );

      final saveResult = await repository.updateSettings(updated);
      expect(saveResult, isA<Success<UserSettingsEntity, dynamic>>());

      final readResult = await repository.getSettings();
      expect(readResult, isA<Success<UserSettingsEntity, dynamic>>());
      final loaded = (readResult as Success<UserSettingsEntity, dynamic>).value;
      expect(loaded.defaultCurrency, equals(Currency.irt));
      expect(loaded.isDarkMode, isFalse);
      expect(loaded.userName, equals('مهدی رحیمی'));
    });
  });
}
