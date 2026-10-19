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
import '../features/clients/models/client.dart';
import '../features/clients/models/client_enums.dart';
import '../features/plans/models/plan.dart';
import '../features/plans/models/plan_category.dart';
import '../features/policies/models/policy.dart';
import '../features/riders/models/rider.dart';

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

/// Tracks global pointer activity so active vault timers reset across routes.
final userActivityProvider = StateProvider<int>((Ref ref) => 0);

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

/// Loads active clients and decrypts their personal fields through the repository.
final clientListProvider = FutureProvider<List<Client>>((Ref ref) async {
  final repository = await ref.watch(clientRepositoryProvider.future);
  return repository.findAll();
});

/// Loads one client, decrypting personal fields through the repository.
final clientByIdProvider = FutureProvider.family<Client?, String>((
  Ref ref,
  String id,
) async {
  final repository = await ref.watch(clientRepositoryProvider.future);
  return repository.findById(id);
});

/// Selected role filter; null includes both client roles.
final clientFilterProvider = StateProvider<ClientRole?>((Ref ref) => null);

/// Search text applied to decrypted client fields in memory.
final clientSearchQueryProvider = StateProvider<String>((Ref ref) => '');

/// Combines loaded clients with role and in-memory decrypted-field searching.
final filteredClientsProvider = Provider<AsyncValue<List<Client>>>((Ref ref) {
  final clients = ref.watch(clientListProvider);
  final role = ref.watch(clientFilterProvider);
  final query = ref.watch(clientSearchQueryProvider).trim().toLowerCase();

  return clients.whenData(
    (List<Client> values) => values
        .where((Client client) {
          if (role != null && client.role != role) {
            return false;
          }
          if (query.isEmpty) {
            return true;
          }
          return client.name.toLowerCase().contains(query) ||
              (client.phone?.toLowerCase().contains(query) ?? false) ||
              (client.email?.toLowerCase().contains(query) ?? false);
        })
        .toList(growable: false),
  );
});

/// Counts active policies for one client without querying encrypted columns.
final clientPolicyCountProvider = FutureProvider.family<int, String>((
  Ref ref,
  String clientId,
) async {
  final repository = await ref.watch(policyRepositoryProvider.future);
  final policies = await repository.findByClientId(clientId);
  return policies.length;
});

/// Loads active policy counts for the current clients using repository APIs.
final clientPolicyCountsProvider = FutureProvider<Map<String, int>>((
  Ref ref,
) async {
  final clients = await ref.watch(clientListProvider.future);
  final repository = await ref.watch(policyRepositoryProvider.future);
  final counts = await Future.wait(
    clients.map((Client client) async {
      final id = client.id;
      if (id == null) {
        throw StateError('A persisted client must have an identifier');
      }
      final policies = await repository.findByClientId(id);
      return MapEntry<String, int>(id, policies.length);
    }),
  );
  return Map<String, int>.fromEntries(counts);
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

/// Loads active policies belonging to one client.
final policiesByClientProvider = FutureProvider.family<List<Policy>, String>((
  Ref ref,
  String clientId,
) async {
  final repository = await ref.watch(policyRepositoryProvider.future);
  return repository.findByClientId(clientId);
});

/// Loads one policy by UUID.
final policyByIdProvider = FutureProvider.family<Policy?, String>((
  Ref ref,
  String id,
) async {
  final repository = await ref.watch(policyRepositoryProvider.future);
  return repository.findById(id);
});

/// Loads active plans belonging to one policy.
final plansByPolicyProvider = FutureProvider.family<List<Plan>, String>((
  Ref ref,
  String policyId,
) async {
  final repository = await ref.watch(planRepositoryProvider.future);
  return repository.findByPolicyId(policyId);
});

/// Loads one plan by UUID.
final planByIdProvider = FutureProvider.family<Plan?, String>((
  Ref ref,
  String id,
) async {
  final repository = await ref.watch(planRepositoryProvider.future);
  return repository.findById(id);
});

/// Loads active riders belonging to one plan.
final ridersByPlanProvider = FutureProvider.family<List<Rider>, String>((
  Ref ref,
  String planId,
) async {
  final repository = await ref.watch(riderRepositoryProvider.future);
  return repository.findByPlanId(planId);
});

/// Loads one rider by UUID.
final riderByIdProvider = FutureProvider.family<Rider?, String>((
  Ref ref,
  String id,
) async {
  final repository = await ref.watch(riderRepositoryProvider.future);
  return repository.findById(id);
});

/// Category selected by a policy-specific plan browser.
final planCategoryFilterProvider = StateProvider.family<PlanCategory?, String>((
  Ref ref,
  String policyId,
) {
  return null;
});

/// Loads archived clients for the archive screen.
final archivedClientsProvider = FutureProvider<List<Client>>((Ref ref) async {
  final repository = await ref.watch(clientRepositoryProvider.future);
  return repository.findAllArchived();
});

/// Loads archived policies for the archive screen.
final archivedPoliciesProvider = FutureProvider<List<Policy>>((Ref ref) async {
  final repository = await ref.watch(policyRepositoryProvider.future);
  return repository.findAllArchived();
});

/// Loads archived plans for the archive screen.
final archivedPlansProvider = FutureProvider<List<Plan>>((Ref ref) async {
  final repository = await ref.watch(planRepositoryProvider.future);
  return repository.findAllArchived();
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
