/// Riverpod providers for secure storage, vault state, and data repositories.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../core/audit/audit_wiring.dart';
import '../core/database/database.dart';
import '../core/database/repositories/audit_repository.dart';
import '../core/database/repositories/client_repository.dart';
import '../core/database/repositories/plan_repository.dart';
import '../core/database/repositories/policy_repository.dart';
import '../core/database/repositories/rider_repository.dart';
import '../core/security/field_crypto.dart';
import '../core/security/key_manager.dart';

/// Platform-backed encrypted storage for vault key material.
final secureStorageProvider = Provider<FlutterSecureStorage>(
  (Ref ref) => const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  ),
);

/// Platform biometric authentication adapter.
final localAuthProvider = Provider<LocalAuthentication>(
  (Ref ref) => LocalAuthentication(),
);

/// Creates a KeyManager without automatically unlocking the vault.
final keyManagerProvider = FutureProvider<KeyManager>((Ref ref) async {
  return KeyManager(
    secureStorage: ref.watch(secureStorageProvider),
    localAuth: ref.watch(localAuthProvider),
  );
});

/// Mirrors mutable KeyManager state so key-dependent providers are refreshed.
final keyManagerStateProvider = StateProvider<KeyManagerState>(
  (Ref ref) => KeyManagerState.uninitialized,
);

/// Opens SQLCipher only while the key manager is unlocked.
final appDatabaseProvider = FutureProvider<AppDatabase>((Ref ref) async {
  final state = ref.watch(keyManagerStateProvider);
  final keyManager = await ref.watch(keyManagerProvider.future);
  if (state != KeyManagerState.unlocked ||
      keyManager.state != KeyManagerState.unlocked) {
    throw StateError('KeyManager must be unlocked before opening the database');
  }

  final database = await AppDatabase.open(
    dbKey: keyManager.dbKey,
    path: await _getDatabasePath(),
  );
  ref.onDispose(() {
    unawaited(database.close());
  });
  return database;
});

/// Initializes the persistent audit chain and connects KeyManager events.
final auditRepositoryProvider = FutureProvider<AuditRepository>((
  Ref ref,
) async {
  final database = await ref.watch(appDatabaseProvider.future);
  final repository = AuditRepository(db: database);
  await AuditWiring.connect(
    keyManager: await ref.watch(keyManagerProvider.future),
    auditRepository: repository,
  );
  return repository;
});

/// Creates field encryption using the unlocked session's derived field key.
final fieldCryptoProvider = FutureProvider<FieldCrypto>((Ref ref) async {
  final state = ref.watch(keyManagerStateProvider);
  final keyManager = await ref.watch(keyManagerProvider.future);
  if (state != KeyManagerState.unlocked ||
      keyManager.state != KeyManagerState.unlocked) {
    throw StateError('KeyManager must be unlocked');
  }
  return FieldCrypto(fieldKey: keyManager.fieldKey);
});

/// Provides the client repository after the vault is unlocked.
final clientRepositoryProvider = FutureProvider<ClientRepository>((
  Ref ref,
) async {
  final database = await ref.watch(appDatabaseProvider.future);
  final fieldCrypto = await ref.watch(fieldCryptoProvider.future);
  final audit = await ref.watch(auditRepositoryProvider.future);
  return ClientRepository(db: database, fieldCrypto: fieldCrypto, audit: audit);
});

/// Provides the policy repository after the vault is unlocked.
final policyRepositoryProvider = FutureProvider<PolicyRepository>((
  Ref ref,
) async {
  final database = await ref.watch(appDatabaseProvider.future);
  final fieldCrypto = await ref.watch(fieldCryptoProvider.future);
  final audit = await ref.watch(auditRepositoryProvider.future);
  return PolicyRepository(db: database, fieldCrypto: fieldCrypto, audit: audit);
});

/// Provides the plan repository after the vault is unlocked.
final planRepositoryProvider = FutureProvider<PlanRepository>((Ref ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  final fieldCrypto = await ref.watch(fieldCryptoProvider.future);
  final audit = await ref.watch(auditRepositoryProvider.future);
  return PlanRepository(db: database, fieldCrypto: fieldCrypto, audit: audit);
});

/// Provides the rider repository after the vault is unlocked.
final riderRepositoryProvider = FutureProvider<RiderRepository>((
  Ref ref,
) async {
  final database = await ref.watch(appDatabaseProvider.future);
  final fieldCrypto = await ref.watch(fieldCryptoProvider.future);
  final audit = await ref.watch(auditRepositoryProvider.future);
  return RiderRepository(db: database, fieldCrypto: fieldCrypto, audit: audit);
});

/// Resolves the platform's application-support directory for the local DB.
///
/// `path_provider` maps this to the appropriate per-application location on
/// desktop and mobile platforms.
Future<String> _getDatabasePath() async {
  final supportDirectory = await getApplicationSupportDirectory();
  final appDirectory = Directory(path.join(supportDirectory.path, 'insur'));
  await appDirectory.create(recursive: true);
  return path.join(appDirectory.path, 'insur.db');
}
