/// Defines local user preferences for the application.
library;

// TODO(insur): Implement — see docs/IMPLEMENTATION_PLAN.md

/// Non-secret settings that control presentation and lock behavior.
class AppSettings {
  /// Creates application settings.
  const AppSettings({
    required this.localeTag,
    required this.autoLockMinutes,
    required this.biometricEnabled,
  });

  /// Selected locale tag, such as `en` or `zh-Hant`.
  final String localeTag;

  /// Inactivity period before locking the vault.
  final int autoLockMinutes;

  /// Whether biometric unlock is enabled on supported platforms.
  final bool biometricEnabled;
}
