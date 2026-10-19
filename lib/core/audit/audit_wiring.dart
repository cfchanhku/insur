/// Connects key-manager lifecycle events to persistent audit storage.
library;

import 'package:logging/logging.dart';

import '../database/repositories/audit_repository.dart';
import '../security/key_manager.dart';

/// Installs the fire-and-forget key-manager audit callback.
class AuditWiring {
  const AuditWiring._();

  /// Loads the existing chain and connects [keyManager] to [auditRepository].
  static Future<void> connect({
    required KeyManager keyManager,
    required AuditRepository auditRepository,
  }) async {
    await auditRepository.initialize();
    keyManager.onAudit = (eventType, {metadata}) async {
      try {
        await auditRepository.append(eventType: eventType, metadata: metadata);
      } catch (_) {
        assert(() {
          Logger(
            'insur.audit',
          ).warning('Unable to persist a key-manager audit event');
          return true;
        }(), 'Log audit persistence failures in debug builds only');
      }
    };
  }
}
