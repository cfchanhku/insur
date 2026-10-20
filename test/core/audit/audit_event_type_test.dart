import 'package:flutter_test/flutter_test.dart';
import 'package:insur/core/audit/audit_event_type.dart';

void main() {
  const expectedValues = <AuditEventType, String>{
    AuditEventType.appSetup: 'app_setup',
    AuditEventType.loginSuccess: 'login_success',
    AuditEventType.loginFail: 'login_fail',
    AuditEventType.logout: 'logout',
    AuditEventType.autoLock: 'auto_lock',
    AuditEventType.recoveryUsed: 'recovery_used',
    AuditEventType.recoveryKeyRotated: 'recovery_key_rotated',
    AuditEventType.passphraseChanged: 'passphrase_changed',
    AuditEventType.create: 'create',
    AuditEventType.update: 'update',
    AuditEventType.archive: 'archive',
    AuditEventType.restore: 'restore',
    AuditEventType.delete: 'delete',
    AuditEventType.exportPdf: 'export_pdf',
    AuditEventType.backup: 'backup',
    AuditEventType.restoreDb: 'restore_db',
    AuditEventType.migration: 'migration',
    AuditEventType.purge: 'purge',
  };

  group('AuditEventType', () {
    test('serializes every event as its stable snake_case identifier', () {
      for (final entry in expectedValues.entries) {
        expect(entry.key.value, entry.value);
      }
    });

    test('parses every stable event identifier', () {
      for (final entry in expectedValues.entries) {
        expect(AuditEventType.fromString(entry.value), entry.key);
      }
    });

    test('rejects an unknown event identifier', () {
      expect(
        () => AuditEventType.fromString('unknown_event'),
        throwsArgumentError,
      );
    });
  });
}
