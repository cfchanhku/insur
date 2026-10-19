/// Stable audit identifiers; renaming a value would break existing logs.
enum AuditEventType {
  appSetup,
  loginSuccess,
  loginFail,
  logout,
  autoLock,
  recoveryUsed,
  recoveryKeyRotated,
  create,
  update,
  archive,
  restore,
  delete,
  exportPdf,
  backup,
  restoreDb,
  migration,
  purge;

  /// Returns the stable snake_case identifier serialized in audit entries.
  String get value => switch (this) {
    AuditEventType.appSetup => 'app_setup',
    AuditEventType.loginSuccess => 'login_success',
    AuditEventType.loginFail => 'login_fail',
    AuditEventType.logout => 'logout',
    AuditEventType.autoLock => 'auto_lock',
    AuditEventType.recoveryUsed => 'recovery_used',
    AuditEventType.recoveryKeyRotated => 'recovery_key_rotated',
    AuditEventType.create => 'create',
    AuditEventType.update => 'update',
    AuditEventType.archive => 'archive',
    AuditEventType.restore => 'restore',
    AuditEventType.delete => 'delete',
    AuditEventType.exportPdf => 'export_pdf',
    AuditEventType.backup => 'backup',
    AuditEventType.restoreDb => 'restore_db',
    AuditEventType.migration => 'migration',
    AuditEventType.purge => 'purge',
  };

  /// Returns the localization key associated with this event type.
  String get labelKey => 'audit_event_$value';

  /// Parses a stable serialized event identifier.
  static AuditEventType fromString(String value) {
    return switch (value) {
      'app_setup' => AuditEventType.appSetup,
      'login_success' => AuditEventType.loginSuccess,
      'login_fail' => AuditEventType.loginFail,
      'logout' => AuditEventType.logout,
      'auto_lock' => AuditEventType.autoLock,
      'recovery_used' => AuditEventType.recoveryUsed,
      'recovery_key_rotated' => AuditEventType.recoveryKeyRotated,
      'create' => AuditEventType.create,
      'update' => AuditEventType.update,
      'archive' => AuditEventType.archive,
      'restore' => AuditEventType.restore,
      'delete' => AuditEventType.delete,
      'export_pdf' => AuditEventType.exportPdf,
      'backup' => AuditEventType.backup,
      'restore_db' => AuditEventType.restoreDb,
      'migration' => AuditEventType.migration,
      'purge' => AuditEventType.purge,
      _ => throw ArgumentError('Unknown audit event type'),
    };
  }
}
