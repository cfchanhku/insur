import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/database/repositories/config_repository.dart';
import 'package:insur/features/settings/settings_keys.dart';
import 'package:insur/features/settings/settings_notifier.dart';
import 'package:insur/features/settings/settings_state.dart';
import 'package:insur/providers/app_providers.dart';

class _ConfigWriteException implements Exception {}

class _MemoryConfigRepository implements ConfigRepository {
  _MemoryConfigRepository([Map<String, String>? initialValues])
    : values = <String, String>{...?initialValues};

  final Map<String, String> values;
  bool failWrites = false;

  @override
  Future<String?> get(String key) async => values[key];

  @override
  Future<void> set(String key, String value) async {
    if (failWrites) {
      throw _ConfigWriteException();
    }
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<Map<String, String>> getAll() async => Map<String, String>.of(values);

  @override
  Future<void> clear() async => values.clear();
}

ProviderContainer _container(_MemoryConfigRepository repository) =>
    ProviderContainer(
      overrides: <Override>[
        configRepositoryProvider.overrideWith((Ref ref) async => repository),
      ],
    );

void main() {
  test('loads defaults from an empty config table', () async {
    final repository = _MemoryConfigRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    expect(
      await container.read(settingsProvider.future),
      const SettingsState(),
    );
  });

  test('loads previously persisted settings', () async {
    final repository = _MemoryConfigRepository(<String, String>{
      SettingsKeys.language: 'zh-Hant',
      SettingsKeys.themeMode: 'dark',
      SettingsKeys.autoLockMinutes: '5',
      SettingsKeys.biometricEnabled: 'true',
      SettingsKeys.autoBackupFrequency: 'weekly',
      SettingsKeys.backupFolder: r'C:\backups',
      SettingsKeys.maxFailedAttempts: '20',
    });
    final container = _container(repository);
    addTearDown(container.dispose);

    expect(
      await container.read(settingsProvider.future),
      const SettingsState(
        language: 'zh-Hant',
        themeMode: 'dark',
        autoLockMinutes: 5,
        biometricEnabled: true,
        autoBackupFrequency: 'weekly',
        backupFolder: r'C:\backups',
        maxFailedAttempts: 20,
      ),
    );
  });

  test(
    'rejects invalid persisted settings rather than hiding corruption',
    () async {
      final repository = _MemoryConfigRepository(<String, String>{
        SettingsKeys.language: 'unsupported',
      });
      final container = _container(repository);
      addTearDown(container.dispose);

      await expectLater(
        container.read(settingsProvider.future),
        throwsArgumentError,
      );
    },
  );

  test('updates language in config and state', () async {
    await _checkUpdate(
      SettingsKeys.language,
      'zh-Hant',
      (SettingsNotifier notifier) => notifier.updateLanguage('zh-Hant'),
    );
  });

  test('updates theme mode in config and state', () async {
    await _checkUpdate(
      SettingsKeys.themeMode,
      'dark',
      (SettingsNotifier notifier) => notifier.updateThemeMode('dark'),
    );
  });

  test('updates auto-lock duration in config and state', () async {
    await _checkUpdate(
      SettingsKeys.autoLockMinutes,
      '5',
      (SettingsNotifier notifier) => notifier.updateAutoLockMinutes(5),
    );
  });

  test('updates biometric preference in config and state', () async {
    await _checkUpdate(
      SettingsKeys.biometricEnabled,
      'true',
      (SettingsNotifier notifier) => notifier.updateBiometricEnabled(true),
    );
  });

  test('updates auto-backup frequency in config and state', () async {
    await _checkUpdate(
      SettingsKeys.autoBackupFrequency,
      'daily',
      (SettingsNotifier notifier) =>
          notifier.updateAutoBackupFrequency('daily'),
    );
  });

  test('updates backup folder in config and state', () async {
    await _checkUpdate(
      SettingsKeys.backupFolder,
      r'C:\backups',
      (SettingsNotifier notifier) => notifier.updateBackupFolder(r'C:\backups'),
    );
  });

  test('updates failed-attempt preference in config and state', () async {
    await _checkUpdate(
      SettingsKeys.maxFailedAttempts,
      '20',
      (SettingsNotifier notifier) => notifier.updateMaxFailedAttempts(20),
    );
  });

  test('rejects values outside the supported settings options', () async {
    final repository = _MemoryConfigRepository();
    final container = _container(repository);
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    await expectLater(
      container.read(settingsProvider.notifier).updateAutoLockMinutes(10),
      throwsArgumentError,
    );
    expect(repository.values, isEmpty);
  });

  test(
    'sets an async error and preserves previous values on write failure',
    () async {
      final repository = _MemoryConfigRepository();
      final container = _container(repository);
      addTearDown(container.dispose);
      final initialState = await container.read(settingsProvider.future);
      repository.failWrites = true;

      await expectLater(
        container.read(settingsProvider.notifier).updateThemeMode('dark'),
        throwsA(isA<_ConfigWriteException>()),
      );

      final result = container.read(settingsProvider);
      expect(result.hasError, isTrue);
      expect(result.valueOrNull, initialState);
    },
  );

  test('SettingsState copies, compares, and serializes all fields', () {
    const state = SettingsState(language: 'zh-Hant', autoLockMinutes: 5);
    final restored = SettingsState.fromJson(state.toJson());

    expect(restored, state);
    expect(restored.hashCode, state.hashCode);
    expect(state.copyWith(themeMode: 'dark').themeMode, 'dark');
  });
}

Future<void> _checkUpdate(
  String key,
  String value,
  Future<void> Function(SettingsNotifier notifier) update,
) async {
  final repository = _MemoryConfigRepository();
  final container = _container(repository);
  addTearDown(container.dispose);
  await container.read(settingsProvider.future);

  await update(container.read(settingsProvider.notifier));

  expect(repository.values[key], value);
  expect(container.read(settingsProvider).hasValue, isTrue);
}
