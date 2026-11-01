import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:task_flow/core/result/result.dart';
import 'package:task_flow/core/theme/app_accent_color.dart';
import 'package:task_flow/core/theme/app_theme_mode.dart';
import 'package:task_flow/core/usecases/usecase.dart';
import 'package:task_flow/features/settings/domain/entities/user_settings_entity.dart';
import 'package:task_flow/features/settings/domain/usecases/get_settings_usecase.dart';
import 'package:task_flow/features/settings/domain/usecases/update_settings_usecase.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_event.dart';
import 'package:task_flow/features/settings/presentation/bloc/settings_state.dart';
import 'package:task_flow/features/tasks/domain/entities/currency.dart';

class MockGetSettingsUseCase extends Mock implements GetSettingsUseCase {}
class MockUpdateSettingsUseCase extends Mock implements UpdateSettingsUseCase {}

void main() {
  late MockGetSettingsUseCase mockGetSettings;
  late MockUpdateSettingsUseCase mockUpdateSettings;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(const UpdateSettingsParams(UserSettingsEntity.defaults));
  });

  setUp(() {
    mockGetSettings = MockGetSettingsUseCase();
    mockUpdateSettings = MockUpdateSettingsUseCase();
  });

  SettingsBloc buildBloc() => SettingsBloc(
        getSettingsUseCase: mockGetSettings,
        updateSettingsUseCase: mockUpdateSettings,
      );

  group('SettingsBloc Tests', () {
    test('initial state has default settings', () {
      final bloc = buildBloc();
      expect(bloc.state.status, equals(SettingsStatus.initial));
      expect(bloc.state.settings, equals(UserSettingsEntity.defaults));
    });

    blocTest<SettingsBloc, SettingsState>(
      'emits [loading, success] when SettingsLoadRequested succeeds',
      build: () {
        when(() => mockGetSettings(any())).thenAnswer(
          (_) async => const Success(
            UserSettingsEntity(
              defaultCurrency: Currency.irt,
              isDarkMode: false,
              userName: 'مهدی',
            ),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SettingsLoadRequested()),
      expect: () => [
        const SettingsState(status: SettingsStatus.loading),
        const SettingsState(
          status: SettingsStatus.success,
          settings: UserSettingsEntity(
            defaultCurrency: Currency.irt,
            isDarkMode: false,
            userName: 'مهدی',
          ),
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'updates default currency and persists when SettingsDefaultCurrencyChanged dispatched',
      build: () {
        when(() => mockUpdateSettings(any())).thenAnswer(
          (inv) async => Success(
            (inv.positionalArguments.first as UpdateSettingsParams).settings,
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SettingsDefaultCurrencyChanged(Currency.irt)),
      expect: () => [
        SettingsState(
          status: SettingsStatus.initial,
          settings: UserSettingsEntity.defaults.copyWith(defaultCurrency: Currency.irt),
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'toggles theme mode and persists when SettingsThemeModeToggled dispatched',
      build: () {
        when(() => mockUpdateSettings(any())).thenAnswer(
          (inv) async => Success(
            (inv.positionalArguments.first as UpdateSettingsParams).settings,
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SettingsThemeModeToggled(false)),
      expect: () => [
        SettingsState(
          status: SettingsStatus.initial,
          settings: UserSettingsEntity.defaults.copyWith(isDarkMode: false),
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'changes theme mode to Zen and persists when SettingsThemeModeChanged dispatched',
      build: () {
        when(() => mockUpdateSettings(any())).thenAnswer(
          (inv) async => Success(
            (inv.positionalArguments.first as UpdateSettingsParams).settings,
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SettingsThemeModeChanged(AppThemeMode.zen)),
      expect: () => [
        SettingsState(
          status: SettingsStatus.initial,
          settings: UserSettingsEntity.defaults.copyWith(themeMode: AppThemeMode.zen),
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'updates accent color and persists when SettingsAccentColorChanged dispatched',
      build: () {
        when(() => mockUpdateSettings(any())).thenAnswer(
          (inv) async => Success(
            (inv.positionalArguments.first as UpdateSettingsParams).settings,
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const SettingsAccentColorChanged(AppAccentColor.forestGreen)),
      expect: () => [
        SettingsState(
          status: SettingsStatus.initial,
          settings: UserSettingsEntity.defaults.copyWith(accentColor: AppAccentColor.forestGreen),
        ),
      ],
    );
  });
}
