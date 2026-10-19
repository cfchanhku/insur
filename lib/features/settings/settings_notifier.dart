/// Loads and persists user-configurable settings.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/app_providers.dart';
import 'settings_keys.dart';
import 'settings_state.dart';

/// Coordinates settings persistence and exposes the current settings state.
class SettingsNotifier extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final repository = await ref.watch(configRepositoryProvider.future);
    final values = await repository.getAll();
    const defaults = SettingsState();

    final language = values[SettingsKeys.language] ?? defaults.language;
    final themeMode = values[SettingsKeys.themeMode] ?? defaults.themeMode;
    final autoLockMinutes = _parseInt(
      values[SettingsKeys.autoLockMinutes],
      defaults.autoLockMinutes,
      SettingsKeys.autoLockMinutes,
    );
    final biometricEnabled = _parseBool(
      values[SettingsKeys.biometricEnabled],
      defaults.biometricEnabled,
      SettingsKeys.biometricEnabled,
    );
    final autoBackupFrequency =
        values[SettingsKeys.autoBackupFrequency] ??
        defaults.autoBackupFrequency;
    final backupFolder =
        values[SettingsKeys.backupFolder] ?? defaults.backupFolder;
    final maxFailedAttempts = _parseInt(
      values[SettingsKeys.maxFailedAttempts],
      defaults.maxFailedAttempts,
      SettingsKeys.maxFailedAttempts,
    );
    final lastBackupAtValue = values[SettingsKeys.lastBackupAt];
    final lastBackupAt = lastBackupAtValue == null
        ? null
        : DateTime.tryParse(lastBackupAtValue);
    if (lastBackupAtValue != null && lastBackupAt == null) {
      throw const FormatException('Invalid stored backup timestamp');
    }
    final lastBackupPath =
        values[SettingsKeys.lastBackupPath] ?? defaults.lastBackupPath;
    final lastBackupSizeValue = values[SettingsKeys.lastBackupSizeBytes];
    final lastBackupSizeBytes = lastBackupSizeValue == null
        ? null
        : int.tryParse(lastBackupSizeValue);
    if (lastBackupSizeValue != null &&
        (lastBackupSizeBytes == null || lastBackupSizeBytes < 0)) {
      throw const FormatException('Invalid stored backup size');
    }

    _validateLanguage(language);
    _validateThemeMode(themeMode);
    _validateAutoLockMinutes(autoLockMinutes);
    _validateAutoBackupFrequency(autoBackupFrequency);
    _validateMaxFailedAttempts(maxFailedAttempts);

    return SettingsState(
      language: language,
      themeMode: themeMode,
      autoLockMinutes: autoLockMinutes,
      biometricEnabled: biometricEnabled,
      autoBackupFrequency: autoBackupFrequency,
      backupFolder: backupFolder,
      maxFailedAttempts: maxFailedAttempts,
      lastBackupAt: lastBackupAt,
      lastBackupPath: lastBackupPath,
      lastBackupSizeBytes: lastBackupSizeBytes,
    );
  }

  /// Persists and applies [language].
  Future<void> updateLanguage(String language) async {
    _validateLanguage(language);
    await _update(
      SettingsKeys.language,
      language,
      (SettingsState current) => current.copyWith(language: language),
    );
  }

  /// Persists and applies [themeMode].
  Future<void> updateThemeMode(String themeMode) async {
    _validateThemeMode(themeMode);
    await _update(
      SettingsKeys.themeMode,
      themeMode,
      (SettingsState current) => current.copyWith(themeMode: themeMode),
    );
  }

  /// Persists the auto-lock duration in minutes.
  Future<void> updateAutoLockMinutes(int minutes) async {
    _validateAutoLockMinutes(minutes);
    await _update(
      SettingsKeys.autoLockMinutes,
      '$minutes',
      (SettingsState current) => current.copyWith(autoLockMinutes: minutes),
    );
  }

  /// Persists whether biometric unlock is enabled by the user.
  // This positional signature is part of the settings notifier contract.
  // ignore: avoid_positional_boolean_parameters
  Future<void> updateBiometricEnabled(bool enabled) async {
    await _update(
      SettingsKeys.biometricEnabled,
      '$enabled',
      (SettingsState current) => current.copyWith(biometricEnabled: enabled),
    );
  }

  /// Persists the selected auto-backup frequency.
  Future<void> updateAutoBackupFrequency(String frequency) async {
    _validateAutoBackupFrequency(frequency);
    await _update(
      SettingsKeys.autoBackupFrequency,
      frequency,
      (SettingsState current) =>
          current.copyWith(autoBackupFrequency: frequency),
    );
  }

  /// Persists the selected local backup folder.
  Future<void> updateBackupFolder(String path) async {
    await _update(
      SettingsKeys.backupFolder,
      path,
      (SettingsState current) => current.copyWith(backupFolder: path),
    );
  }

  /// Persists the preferred maximum failed-attempt count.
  ///
  /// Login enforcement remains governed by the existing KeyManager policy.
  Future<void> updateMaxFailedAttempts(int attempts) async {
    _validateMaxFailedAttempts(attempts);
    await _update(
      SettingsKeys.maxFailedAttempts,
      '$attempts',
      (SettingsState current) => current.copyWith(maxFailedAttempts: attempts),
    );
  }

  /// Persists the last successful backup path and UTC timestamp atomically.
  Future<void> recordBackup({
    required String path,
    required DateTime at,
    required int sizeBytes,
  }) async {
    if (path.isEmpty) {
      throw ArgumentError.value(path, 'path', 'Must not be empty');
    }
    if (sizeBytes <= 0) {
      throw ArgumentError.value(sizeBytes, 'sizeBytes', 'Must be positive');
    }
    final previousState = state;
    final current = state.valueOrNull;
    if (current == null) {
      throw StateError('Settings are not loaded');
    }
    final utcAt = at.toUtc();
    try {
      final repository = await ref.read(configRepositoryProvider.future);
      await repository.setAll(<String, String>{
        SettingsKeys.lastBackupAt: utcAt.toIso8601String(),
        SettingsKeys.lastBackupPath: path,
        SettingsKeys.lastBackupSizeBytes: '$sizeBytes',
      });
      state = AsyncData<SettingsState>(
        current.copyWith(
          lastBackupAt: utcAt,
          lastBackupPath: path,
          lastBackupSizeBytes: sizeBytes,
        ),
      );
    } on Exception catch (error, stackTrace) {
      state = AsyncError<SettingsState>(
        error,
        stackTrace,
      ).copyWithPrevious(previousState);
      rethrow;
    }
  }

  Future<void> _update(
    String key,
    String value,
    SettingsState Function(SettingsState current) update,
  ) async {
    final previousState = state;
    final current = state.valueOrNull;
    if (current == null) {
      throw StateError('Settings are not loaded');
    }

    try {
      final repository = await ref.read(configRepositoryProvider.future);
      await repository.set(key, value);
      state = AsyncData<SettingsState>(update(current));
    } on Exception catch (error, stackTrace) {
      state = AsyncError<SettingsState>(
        error,
        stackTrace,
      ).copyWithPrevious(previousState);
      rethrow;
    }
  }
}

/// Provides settings state and asynchronous update operations.
final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

int _parseInt(String? value, int defaultValue, String key) {
  if (value == null) {
    return defaultValue;
  }
  final parsed = int.tryParse(value);
  if (parsed == null) {
    throw FormatException('Invalid stored setting: $key');
  }
  return parsed;
}

bool _parseBool(String? value, bool defaultValue, String key) {
  if (value == null) {
    return defaultValue;
  }
  if (value == 'true') {
    return true;
  }
  if (value == 'false') {
    return false;
  }
  throw FormatException('Invalid stored setting: $key');
}

void _validateLanguage(String language) {
  if (language != 'en' && language != 'zh-Hant') {
    throw ArgumentError.value(language, 'language', 'Unsupported language');
  }
}

void _validateThemeMode(String themeMode) {
  if (themeMode != 'system' && themeMode != 'light' && themeMode != 'dark') {
    throw ArgumentError.value(themeMode, 'themeMode', 'Unsupported theme');
  }
}

void _validateAutoLockMinutes(int minutes) {
  if (minutes != 5 && minutes != 15 && minutes != 30) {
    throw ArgumentError.value(
      minutes,
      'minutes',
      'Must be 5, 15, or 30 minutes',
    );
  }
}

void _validateAutoBackupFrequency(String frequency) {
  if (frequency != 'off' && frequency != 'daily' && frequency != 'weekly') {
    throw ArgumentError.value(
      frequency,
      'frequency',
      'Unsupported auto-backup frequency',
    );
  }
}

void _validateMaxFailedAttempts(int attempts) {
  if (attempts != 5 && attempts != 10 && attempts != 20) {
    throw ArgumentError.value(
      attempts,
      'attempts',
      'Must be 5, 10, or 20 attempts',
    );
  }
}
