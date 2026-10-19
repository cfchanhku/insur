/// Immutable snapshot of persisted, non-secret application settings.
library;

import 'settings_keys.dart';

/// The current user-configurable settings.
class SettingsState {
  /// Creates settings, using the project's approved defaults when omitted.
  const SettingsState({
    this.language = SettingsKeys.defaultLanguage,
    this.themeMode = SettingsKeys.defaultThemeMode,
    this.autoLockMinutes = SettingsKeys.defaultAutoLockMinutes,
    this.biometricEnabled = SettingsKeys.defaultBiometricEnabled,
    this.autoBackupFrequency = SettingsKeys.defaultAutoBackupFrequency,
    this.backupFolder = SettingsKeys.defaultBackupFolder,
    this.maxFailedAttempts = SettingsKeys.defaultMaxFailedAttempts,
  });

  final String language;
  final String themeMode;
  final int autoLockMinutes;
  final bool biometricEnabled;
  final String autoBackupFrequency;
  final String backupFolder;
  final int maxFailedAttempts;

  /// Returns a copy with only the supplied values changed.
  SettingsState copyWith({
    String? language,
    String? themeMode,
    int? autoLockMinutes,
    bool? biometricEnabled,
    String? autoBackupFrequency,
    String? backupFolder,
    int? maxFailedAttempts,
  }) {
    return SettingsState(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoBackupFrequency: autoBackupFrequency ?? this.autoBackupFrequency,
      backupFolder: backupFolder ?? this.backupFolder,
      maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
    );
  }

  /// Serializes settings to a JSON-compatible map.
  Map<String, Object?> toJson() => <String, Object?>{
    'language': language,
    'themeMode': themeMode,
    'autoLockMinutes': autoLockMinutes,
    'biometricEnabled': biometricEnabled,
    'autoBackupFrequency': autoBackupFrequency,
    'backupFolder': backupFolder,
    'maxFailedAttempts': maxFailedAttempts,
  };

  /// Creates settings from a JSON-compatible map, rejecting invalid fields.
  factory SettingsState.fromJson(Map<String, Object?> json) {
    final language = json['language'];
    final themeMode = json['themeMode'];
    final autoLockMinutes = json['autoLockMinutes'];
    final biometricEnabled = json['biometricEnabled'];
    final autoBackupFrequency = json['autoBackupFrequency'];
    final backupFolder = json['backupFolder'];
    final maxFailedAttempts = json['maxFailedAttempts'];

    if (language is! String ||
        themeMode is! String ||
        autoLockMinutes is! int ||
        biometricEnabled is! bool ||
        autoBackupFrequency is! String ||
        backupFolder is! String ||
        maxFailedAttempts is! int) {
      throw ArgumentError('Settings JSON contains missing or invalid values');
    }

    return SettingsState(
      language: language,
      themeMode: themeMode,
      autoLockMinutes: autoLockMinutes,
      biometricEnabled: biometricEnabled,
      autoBackupFrequency: autoBackupFrequency,
      backupFolder: backupFolder,
      maxFailedAttempts: maxFailedAttempts,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SettingsState &&
        other.language == language &&
        other.themeMode == themeMode &&
        other.autoLockMinutes == autoLockMinutes &&
        other.biometricEnabled == biometricEnabled &&
        other.autoBackupFrequency == autoBackupFrequency &&
        other.backupFolder == backupFolder &&
        other.maxFailedAttempts == maxFailedAttempts;
  }

  @override
  int get hashCode => Object.hash(
    language,
    themeMode,
    autoLockMinutes,
    biometricEnabled,
    autoBackupFrequency,
    backupFolder,
    maxFailedAttempts,
  );
}
