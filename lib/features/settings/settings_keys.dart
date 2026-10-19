/// Defines persisted keys and defaults for local application preferences.
class SettingsKeys {
  const SettingsKeys._();

  static const String language = 'settings.language';
  static const String themeMode = 'settings.theme_mode';
  static const String autoLockMinutes = 'settings.auto_lock_minutes';
  static const String biometricEnabled = 'settings.biometric_enabled';
  static const String autoBackupFrequency = 'settings.auto_backup_frequency';
  static const String backupFolder = 'settings.backup_folder';
  static const String maxFailedAttempts = 'settings.max_failed_attempts';

  static const String defaultLanguage = 'en';
  static const String defaultThemeMode = 'system';
  static const int defaultAutoLockMinutes = 15;
  static const bool defaultBiometricEnabled = false;
  static const String defaultAutoBackupFrequency = 'off';
  static const String defaultBackupFolder = '';
  static const int defaultMaxFailedAttempts = 10;
}
