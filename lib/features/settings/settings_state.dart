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
    this.lastBackupAt,
    this.lastBackupPath = '',
    this.lastBackupSizeBytes,
  });

  final String language;
  final String themeMode;
  final int autoLockMinutes;
  final bool biometricEnabled;
  final String autoBackupFrequency;
  final String backupFolder;
  final int maxFailedAttempts;
  final DateTime? lastBackupAt;
  final String lastBackupPath;
  final int? lastBackupSizeBytes;

  /// Returns a copy with only the supplied values changed.
  SettingsState copyWith({
    String? language,
    String? themeMode,
    int? autoLockMinutes,
    bool? biometricEnabled,
    String? autoBackupFrequency,
    String? backupFolder,
    int? maxFailedAttempts,
    DateTime? lastBackupAt,
    String? lastBackupPath,
    int? lastBackupSizeBytes,
  }) {
    return SettingsState(
      language: language ?? this.language,
      themeMode: themeMode ?? this.themeMode,
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoBackupFrequency: autoBackupFrequency ?? this.autoBackupFrequency,
      backupFolder: backupFolder ?? this.backupFolder,
      maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      lastBackupPath: lastBackupPath ?? this.lastBackupPath,
      lastBackupSizeBytes: lastBackupSizeBytes ?? this.lastBackupSizeBytes,
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
    'lastBackupAt': lastBackupAt?.toUtc().toIso8601String(),
    'lastBackupPath': lastBackupPath,
    'lastBackupSizeBytes': lastBackupSizeBytes,
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
    final lastBackupAt = json['lastBackupAt'];
    final lastBackupPath = json['lastBackupPath'];
    final lastBackupSizeBytes = json['lastBackupSizeBytes'];

    if (language is! String ||
        themeMode is! String ||
        autoLockMinutes is! int ||
        biometricEnabled is! bool ||
        autoBackupFrequency is! String ||
        backupFolder is! String ||
        maxFailedAttempts is! int ||
        (lastBackupAt != null && lastBackupAt is! String) ||
        lastBackupPath is! String ||
        (lastBackupSizeBytes != null && lastBackupSizeBytes is! int)) {
      throw ArgumentError('Settings JSON contains missing or invalid values');
    }

    final parsedLastBackupAt = lastBackupAt == null
        ? null
        : DateTime.tryParse(lastBackupAt as String);
    if (lastBackupAt != null && parsedLastBackupAt == null) {
      throw ArgumentError('Settings JSON contains an invalid backup timestamp');
    }
    return SettingsState(
      language: language,
      themeMode: themeMode,
      autoLockMinutes: autoLockMinutes,
      biometricEnabled: biometricEnabled,
      autoBackupFrequency: autoBackupFrequency,
      backupFolder: backupFolder,
      maxFailedAttempts: maxFailedAttempts,
      lastBackupAt: parsedLastBackupAt,
      lastBackupPath: lastBackupPath,
      lastBackupSizeBytes: lastBackupSizeBytes as int?,
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
        other.maxFailedAttempts == maxFailedAttempts &&
        other.lastBackupAt == lastBackupAt &&
        other.lastBackupPath == lastBackupPath &&
        other.lastBackupSizeBytes == lastBackupSizeBytes;
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
    lastBackupAt,
    lastBackupPath,
    lastBackupSizeBytes,
  );
}
