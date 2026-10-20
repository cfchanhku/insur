/// Manages the master key and purpose-separated session keys.
///
/// The Argon2id-derived master key is stored in `FlutterSecureStorage`; a
/// separate Argon2id verifier allows passphrase changes without changing the
/// database encryption key. HKDF derives database, field, and audit keys from
/// the stable master key for use only in memory.
///
/// The session moves from uninitialized to unlocked after setup, from locked
/// to unlocked after successful authentication, and back to locked on manual
/// lock. This class does not own an inactivity timer; the application should
/// call [lock] when its auto-lock policy expires. Biometric authentication is a
/// separate gate that reads the master key after successful biometric-only
/// authentication. The secure-storage plugin must be configured separately if
/// OS-level biometric gating of its contents is required.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../audit/audit_event_type.dart';
import 'backoff_policy.dart';
import 'field_crypto.dart';
import 'kdf.dart';
import 'key_backup_material.dart';
import 'key_derivation.dart';
import 'recovery_key.dart';
import 'recovery_key_exception.dart';

/// Current state of master-key setup and session access.
enum KeyManagerState { uninitialized, locked, unlocked }

/// Stores the master key securely and derives in-memory application subkeys.
class KeyManager {
  /// Creates a manager using operating-system secure storage and biometrics.
  KeyManager({
    required FlutterSecureStorage secureStorage,
    required LocalAuthentication localAuth,
  }) : _secureStorage = secureStorage,
       _localAuth = localAuth;

  static const String _keyMasterKey = 'insur.master_key.v1';
  static const String _keyMasterSalt = 'insur.master_salt.v1';
  static const String _keyPassphraseCredential =
      'insur.passphrase_credential.v1';
  static const String _keyPassphraseResetRequired =
      'insur.passphrase_reset_required.v1';
  static const String _keyBiometricEnabled = 'insur.biometric_enabled.v1';
  static const String _keyKdfParams = 'insur.kdf_params.v1';
  static const String _keyRecoveryWrappedMasterKey =
      'insur.recovery.wrapped_mk.v1';
  static const String _keyRecoverySalt = 'insur.recovery.salt.v1';
  static const String _keyRecoveryVerificationHash =
      'insur.recovery.verification_hash.v1';

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

  /// Receives lifecycle audit events; handlers must not block key operations.
  void Function(AuditEventType eventType, {Map<String, Object?>? metadata})?
  onAudit;

  KeyManagerState _state = KeyManagerState.uninitialized;
  int _failedAttempts = 0;
  Duration _currentBackoff = Duration.zero;
  Uint8List? _masterKey;
  Uint8List? _dbKey;
  Uint8List? _fieldKey;
  Uint8List? _auditKey;

  /// Current key-manager lifecycle state.
  KeyManagerState get state => _state;

  /// Whether key material is currently available in memory.
  bool get isUnlocked => _state == KeyManagerState.unlocked;

  /// Number of failed passphrase attempts since the app started.
  int get failedAttempts => _failedAttempts;

  /// Delay applied before the next passphrase verification.
  Duration get currentBackoff => _currentBackoff;

  /// Returns whether a non-empty master key is present in secure storage.
  ///
  /// If initialized and not already unlocked, the manager enters the locked
  /// state.
  Future<bool> isInitialized() async {
    final storedMasterKey = await _secureStorage.read(key: _keyMasterKey);
    final initialized = storedMasterKey != null && storedMasterKey.isNotEmpty;

    if (_state != KeyManagerState.unlocked) {
      _state = initialized
          ? KeyManagerState.locked
          : KeyManagerState.uninitialized;
    }
    return initialized;
  }

  /// Creates and stores a new master key using [passphrase].
  ///
  /// The passphrase must contain at least twelve Unicode characters. A
  /// temporary UTF-8 buffer is cleared on a best-effort basis; Dart's immutable
  /// [String] and internal cryptographic copies cannot be explicitly erased.
  Future<void> setup({required String passphrase}) async {
    if (passphrase.runes.length < 12) {
      throw ArgumentError.value(
        passphrase.runes.length,
        'passphrase.length',
        'Must be at least 12 characters',
      );
    }
    if (await isInitialized()) {
      throw StateError('Already initialized');
    }

    final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
    final salt = Kdf.generateSalt();
    Uint8List? masterKey;
    Uint8List? credential;
    try {
      masterKey = await Kdf.deriveMasterKey(passphrase: passphrase, salt: salt);
      credential = _encodeCredential(salt, masterKey);

      await _secureStorage.write(
        key: _keyMasterSalt,
        value: base64Encode(salt),
      );
      await _secureStorage.write(
        key: _keyKdfParams,
        value: Kdf.paramsDescription(),
      );
      await _secureStorage.write(
        key: _keyPassphraseCredential,
        value: base64Encode(credential),
      );
      await _secureStorage.write(key: _keyBiometricEnabled, value: 'false');
      await _secureStorage.delete(key: _keyPassphraseResetRequired);
      // Write the master key last; its presence marks setup as complete.
      await _secureStorage.write(
        key: _keyMasterKey,
        value: base64Encode(masterKey),
      );

      await _deriveAndHoldSubkeys(masterKey);
      _state = KeyManagerState.unlocked;
      _failedAttempts = 0;
      _currentBackoff = Duration.zero;
      onAudit?.call(AuditEventType.appSetup);
    } finally {
      passphraseBytes.fillRange(0, passphraseBytes.length, 0);
      salt.fillRange(0, salt.length, 0);
      masterKey?.fillRange(0, masterKey.length, 0);
      credential?.fillRange(0, credential.length, 0);
    }
  }

  /// Attempts to unlock with [passphrase], returning false on a mismatch.
  ///
  /// The current backoff is applied before checking the passphrase. Ten failed
  /// attempts require an app restart before another verification can proceed.
  Future<bool> unlock({required String passphrase}) async {
    await lock();
    if (!await isInitialized()) {
      throw StateError('Not initialized');
    }
    if (await isPassphraseResetRequired()) {
      throw StateError('Passphrase reset is required');
    }

    if (_currentBackoff > Duration.zero) {
      await Future<void>.delayed(_currentBackoff);
    }
    if (BackoffPolicy.shouldRequireRestart(_failedAttempts)) {
      onAudit?.call(
        AuditEventType.loginFail,
        metadata: <String, Object?>{'attempts': _failedAttempts},
      );
      return false;
    }

    final saltValue = await _secureStorage.read(key: _keyMasterSalt);
    final masterKeyValue = await _secureStorage.read(key: _keyMasterKey);
    if (saltValue == null ||
        saltValue.isEmpty ||
        masterKeyValue == null ||
        masterKeyValue.isEmpty) {
      throw StateError('Stored key material is incomplete');
    }

    final passphraseBytes = Uint8List.fromList(utf8.encode(passphrase));
    Uint8List? legacySalt;
    try {
      legacySalt = Uint8List.fromList(base64Decode(saltValue));
    } on FormatException {
      passphraseBytes.fillRange(0, passphraseBytes.length, 0);
      throw StateError('Stored key material is invalid');
    }
    Uint8List? masterKey;
    Uint8List? credential;
    Uint8List? verifierSalt;
    Uint8List? expectedVerifier;
    try {
      masterKey = Uint8List.fromList(base64Decode(masterKeyValue));
      final credentialValue = await _secureStorage.read(
        key: _keyPassphraseCredential,
      );
      if (credentialValue == null) {
        verifierSalt = Uint8List.fromList(legacySalt);
        expectedVerifier = Uint8List.fromList(masterKey);
      } else {
        credential = Uint8List.fromList(base64Decode(credentialValue));
        if (credential.length != Kdf.saltLength + Kdf.keyLength) {
          throw StateError('Stored key material is invalid');
        }
        verifierSalt = Uint8List.fromList(
          credential.sublist(0, Kdf.saltLength),
        );
        expectedVerifier = Uint8List.fromList(
          credential.sublist(Kdf.saltLength),
        );
      }
    } on FormatException {
      passphraseBytes.fillRange(0, passphraseBytes.length, 0);
      legacySalt.fillRange(0, legacySalt.length, 0);
      throw StateError('Stored key material is invalid');
    }

    try {
      if (legacySalt.length != Kdf.saltLength ||
          masterKey.length != Kdf.keyLength ||
          verifierSalt.length != Kdf.saltLength ||
          expectedVerifier.length != Kdf.keyLength) {
        throw StateError('Stored key material is invalid');
      }
      final isValid = await Kdf.verify(
        passphrase: passphrase,
        salt: verifierSalt,
        expectedKey: expectedVerifier,
      );
      if (!isValid) {
        _failedAttempts++;
        _currentBackoff = BackoffPolicy.forAttempts(_failedAttempts);
        onAudit?.call(
          AuditEventType.loginFail,
          metadata: <String, Object?>{'attempts': _failedAttempts},
        );
        return false;
      }

      if (credential == null) {
        final migratedCredential = _encodeCredential(legacySalt, masterKey);
        try {
          await _secureStorage.write(
            key: _keyPassphraseCredential,
            value: base64Encode(migratedCredential),
          );
        } finally {
          migratedCredential.fillRange(0, migratedCredential.length, 0);
        }
      }
      await _deriveAndHoldSubkeys(masterKey);
      _state = KeyManagerState.unlocked;
      _failedAttempts = 0;
      _currentBackoff = Duration.zero;
      onAudit?.call(AuditEventType.loginSuccess);
      return true;
    } finally {
      passphraseBytes.fillRange(0, passphraseBytes.length, 0);
      legacySalt.fillRange(0, legacySalt.length, 0);
      masterKey.fillRange(0, masterKey.length, 0);
      credential?.fillRange(0, credential.length, 0);
      verifierSalt.fillRange(0, verifierSalt.length, 0);
      expectedVerifier.fillRange(0, expectedVerifier.length, 0);
    }
  }

  /// Checks whether [passphrase] matches the current verifier without
  /// changing the session state or failed-login counter.
  Future<bool> verifyPassphrase({required String passphrase}) async {
    return _verifyCurrentPassphrase(passphrase);
  }

  /// Replaces the login passphrase while preserving the vault master key.
  ///
  /// The combined salt and verifier are stored as one secure-storage value so
  /// an interrupted update cannot leave a mismatched pair.
  Future<void> changePassphrase({
    required String currentPassphrase,
    required String newPassphrase,
  }) async {
    if (_state != KeyManagerState.unlocked) {
      throw StateError('Not unlocked');
    }
    if (await isPassphraseResetRequired()) {
      throw StateError('Passphrase reset is required');
    }
    _validatePassphrase(newPassphrase);
    if (!await _verifyCurrentPassphrase(currentPassphrase)) {
      throw StateError('Passphrase verification failed');
    }
    await _storeNewPassphraseVerifier(newPassphrase);
    onAudit?.call(AuditEventType.passphraseChanged);
  }

  /// Sets a replacement passphrase after the vault was unlocked with recovery.
  ///
  /// The master key and all database subkeys remain unchanged.
  Future<void> setPassphraseAfterRecovery({
    required String newPassphrase,
  }) async {
    if (_state != KeyManagerState.unlocked) {
      throw StateError('Not unlocked');
    }
    _validatePassphrase(newPassphrase);
    await _storeNewPassphraseVerifier(newPassphrase);
    await _secureStorage.delete(key: _keyPassphraseResetRequired);
    onAudit?.call(AuditEventType.passphraseChanged);
  }

  /// Indicates whether recovery authentication still requires a new
  /// passphrase before ordinary unlock is permitted.
  Future<bool> isPassphraseResetRequired() async =>
      await _secureStorage.read(key: _keyPassphraseResetRequired) == 'true';

  /// Persists whether biometric-only unlock was explicitly enabled.
  Future<void> setBiometricEnabled({required bool enabled}) async {
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enabled ? 'true' : 'false',
    );
  }

  /// Returns whether biometric unlock was explicitly enabled on this device.
  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Authenticates biometrically and loads the stored master key on success.
  ///
  /// Returns false for unsuccessful authentication or recognized plugin
  /// failures. Throws [UnsupportedError] when biometric authentication is not
  /// available; secure-storage and unexpected failures are not hidden.
  Future<bool> unlockWithBiometric() async {
    await lock();
    if (!await isInitialized()) {
      throw StateError('Not initialized');
    }
    if (await isPassphraseResetRequired() || !await isBiometricEnabled()) {
      return false;
    }

    late final bool authenticated;
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!canCheckBiometrics || !isDeviceSupported) {
        throw UnsupportedError('Biometric not available');
      }

      authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock Insurance Policy Manager',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
    if (!authenticated) {
      return false;
    }

    final masterKeyValue = await _secureStorage.read(key: _keyMasterKey);
    if (masterKeyValue == null || masterKeyValue.isEmpty) {
      throw StateError('Stored key material is incomplete');
    }

    late final Uint8List masterKey;
    try {
      masterKey = Uint8List.fromList(base64Decode(masterKeyValue));
    } on FormatException {
      throw StateError('Stored key material is invalid');
    }
    try {
      if (masterKey.length != Kdf.keyLength) {
        throw StateError('Stored key material is invalid');
      }
      await _deriveAndHoldSubkeys(masterKey);
      _state = KeyManagerState.unlocked;
      _failedAttempts = 0;
      _currentBackoff = Duration.zero;
      onAudit?.call(
        AuditEventType.loginSuccess,
        metadata: <String, Object?>{'method': 'biometric'},
      );
      return true;
    } finally {
      masterKey.fillRange(0, masterKey.length, 0);
    }
  }

  /// Clears all in-memory keys and changes the state to locked.
  ///
  /// The securely stored master key remains available for a later unlock.
  Future<void> lock() async {
    final wasUnlocked = _state == KeyManagerState.unlocked;
    _clearInMemoryKeys();
    _state = KeyManagerState.locked;
    if (wasUnlocked) {
      onAudit?.call(AuditEventType.autoLock);
    }
  }

  /// Locks the session and optionally removes all managed secure-storage data.
  Future<void> logout({bool wipe = false}) async {
    _clearInMemoryKeys();
    _state = KeyManagerState.locked;
    if (wipe) {
      await _secureStorage.delete(key: _keyMasterKey);
      await _secureStorage.delete(key: _keyMasterSalt);
      await _secureStorage.delete(key: _keyPassphraseCredential);
      await _secureStorage.delete(key: _keyPassphraseResetRequired);
      await _secureStorage.delete(key: _keyBiometricEnabled);
      await _secureStorage.delete(key: _keyKdfParams);
      await _deleteRecoveryMaterial();
    }
    _state = KeyManagerState.uninitialized;
    _failedAttempts = 0;
    _currentBackoff = Duration.zero;
    onAudit?.call(AuditEventType.logout);
  }

  /// Database encryption key; valid only while the manager is unlocked.
  Uint8List get dbKey => _keyForState(_dbKey);

  /// Field encryption key; valid only while the manager is unlocked.
  Uint8List get fieldKey => _keyForState(_fieldKey);

  /// Audit authentication key; valid only while the manager is unlocked.
  Uint8List get auditKey => _keyForState(_auditKey);

  /// Exports disposable key state for inclusion inside an encrypted backup.
  ///
  /// The caller must encrypt this state immediately and call [KeyBackupMaterial.clear].
  /// The master key is never returned while the manager is locked.
  Future<KeyBackupMaterial> exportBackupMaterial() async {
    if (_state != KeyManagerState.unlocked || _masterKey == null) {
      throw StateError('Not unlocked');
    }
    final saltValue = await _secureStorage.read(key: _keyMasterSalt);
    final paramsValue = await _secureStorage.read(key: _keyKdfParams);
    if (saltValue == null ||
        paramsValue == null ||
        paramsValue != Kdf.paramsDescription()) {
      throw StateError('Stored key metadata is invalid');
    }

    Uint8List? masterSalt;
    Uint8List? passphraseVerifier;
    Uint8List? credential;
    Uint8List? recoverySalt;
    Uint8List? recoveryWrappedMasterKey;
    Uint8List? recoveryVerificationHash;
    try {
      final credentialValue = await _secureStorage.read(
        key: _keyPassphraseCredential,
      );
      if (credentialValue == null) {
        masterSalt = Uint8List.fromList(base64Decode(saltValue));
        passphraseVerifier = Uint8List.fromList(_masterKey!);
      } else {
        credential = Uint8List.fromList(base64Decode(credentialValue));
        if (credential.length != Kdf.saltLength + Kdf.keyLength) {
          throw StateError('Stored key metadata is invalid');
        }
        masterSalt = Uint8List.fromList(credential.sublist(0, Kdf.saltLength));
        passphraseVerifier = Uint8List.fromList(
          credential.sublist(Kdf.saltLength),
        );
      }
      if (masterSalt.length != Kdf.saltLength ||
          passphraseVerifier.length != Kdf.keyLength) {
        throw StateError('Stored key metadata is invalid');
      }
      final recoverySaltValue = await _secureStorage.read(
        key: _keyRecoverySalt,
      );
      final wrappedMasterKeyValue = await _secureStorage.read(
        key: _keyRecoveryWrappedMasterKey,
      );
      final verificationHashValue = await _secureStorage.read(
        key: _keyRecoveryVerificationHash,
      );
      final presentCount = <String?>[
        recoverySaltValue,
        wrappedMasterKeyValue,
        verificationHashValue,
      ].where((String? value) => value != null).length;
      if (presentCount != 0 && presentCount != 3) {
        throw StateError('Stored recovery metadata is incomplete');
      }
      if (presentCount == 3) {
        recoverySalt = Uint8List.fromList(base64Decode(recoverySaltValue!));
        recoveryWrappedMasterKey = Uint8List.fromList(
          base64Decode(wrappedMasterKeyValue!),
        );
        recoveryVerificationHash = Uint8List.fromList(
          base64Decode(verificationHashValue!),
        );
        if (recoverySalt.length != RecoveryKey.saltLength ||
            recoveryWrappedMasterKey.length != Kdf.keyLength + 28 ||
            recoveryVerificationHash.length != 32) {
          throw StateError('Stored recovery metadata is invalid');
        }
      }
      return KeyBackupMaterial(
        masterKey: _masterKey!,
        masterSalt: masterSalt,
        passphraseVerifier: passphraseVerifier,
        kdfParameters: paramsValue,
        recoverySalt: recoverySalt,
        recoveryWrappedMasterKey: recoveryWrappedMasterKey,
        recoveryVerificationHash: recoveryVerificationHash,
      );
    } on FormatException {
      throw StateError('Stored key metadata is invalid');
    } finally {
      masterSalt?.fillRange(0, masterSalt.length, 0);
      passphraseVerifier?.fillRange(0, passphraseVerifier.length, 0);
      credential?.fillRange(0, credential.length, 0);
      recoverySalt?.fillRange(0, recoverySalt.length, 0);
      recoveryWrappedMasterKey?.fillRange(
        0,
        recoveryWrappedMasterKey.length,
        0,
      );
      recoveryVerificationHash?.fillRange(
        0,
        recoveryVerificationHash.length,
        0,
      );
    }
  }

  /// Installs authenticated backup key state into platform secure storage.
  ///
  /// The stable master key and current passphrase verifier are restored
  /// independently. Existing different vault credentials must be explicitly
  /// wiped before importing a backup.
  Future<void> restoreBackupMaterial(
    KeyBackupMaterial material, {
    bool replaceExisting = false,
  }) async {
    _validateBackupMaterial(material);
    final currentMasterKey = await _secureStorage.read(key: _keyMasterKey);
    if (currentMasterKey != null) {
      Uint8List? decodedMasterKey;
      try {
        decodedMasterKey = Uint8List.fromList(base64Decode(currentMasterKey));
        if (!_constantTimeEquals(decodedMasterKey, material.masterKey) &&
            !replaceExisting) {
          throw StateError(
            'Existing vault credentials differ; wipe the vault before restore',
          );
        }
      } on FormatException {
        throw StateError('Stored key metadata is invalid');
      } finally {
        decodedMasterKey?.fillRange(0, decodedMasterKey.length, 0);
      }
    }

    _clearInMemoryKeys();
    _state = KeyManagerState.uninitialized;
    _failedAttempts = 0;
    _currentBackoff = Duration.zero;

    await _secureStorage.write(
      key: _keyMasterSalt,
      value: base64Encode(material.masterSalt),
    );
    final credential = _encodeCredential(
      material.masterSalt,
      material.passphraseVerifier,
    );
    try {
      await _secureStorage.write(
        key: _keyPassphraseCredential,
        value: base64Encode(credential),
      );
    } finally {
      credential.fillRange(0, credential.length, 0);
    }
    await _secureStorage.write(
      key: _keyKdfParams,
      value: material.kdfParameters,
    );
    await _deleteRecoveryMaterial();
    if (material.hasRecoveryKey) {
      await _secureStorage.write(
        key: _keyRecoverySalt,
        value: base64Encode(material.recoverySalt!),
      );
      await _secureStorage.write(
        key: _keyRecoveryVerificationHash,
        value: base64Encode(material.recoveryVerificationHash!),
      );
      await _secureStorage.write(
        key: _keyRecoveryWrappedMasterKey,
        value: base64Encode(material.recoveryWrappedMasterKey!),
      );
    }
    await _secureStorage.write(
      key: _keyMasterKey,
      value: base64Encode(material.masterKey),
    );
    await _secureStorage.delete(key: _keyPassphraseResetRequired);
    await _secureStorage.delete(key: _keyBiometricEnabled);
    _state = KeyManagerState.locked;
  }

  /// Creates a field encryption helper using the in-memory field key.
  FieldCrypto createFieldCrypto() {
    return FieldCrypto(fieldKey: fieldKey);
  }

  /// Generates and stores a recovery-key-wrapped copy of the current master key.
  ///
  /// The passphrase is checked against the current master key before creating
  /// recovery material. The returned recovery key is the only plaintext copy;
  /// the caller must display it once and ensure it is recorded offline.
  Future<String> setupRecoveryKey({required String passphrase}) async {
    if (_state != KeyManagerState.unlocked || _masterKey == null) {
      throw StateError('Not unlocked');
    }
    if (!await _verifyCurrentPassphrase(passphrase)) {
      throw StateError('Passphrase verification failed');
    }

    return _createRecoveryKey();
  }

  Future<String> _createRecoveryKey() async {
    final recoveryKey = RecoveryKey.generate();
    final salt = RecoveryKey.generateSalt();
    Uint8List? recoveryKek;
    Uint8List? wrappedMasterKey;
    Uint8List? verificationHash;
    try {
      recoveryKek = await RecoveryKey.deriveRecoveryKek(
        recoveryKey: recoveryKey,
        salt: salt,
      );
      wrappedMasterKey = await RecoveryKey.wrapMasterKey(
        masterKey: _masterKey!,
        recoveryKek: recoveryKek,
      );
      verificationHash = RecoveryKey.computeVerificationHash(
        recoveryKey: recoveryKey,
        salt: salt,
      );

      await _secureStorage.write(
        key: _keyRecoverySalt,
        value: base64Encode(salt),
      );
      await _secureStorage.write(
        key: _keyRecoveryVerificationHash,
        value: base64Encode(verificationHash),
      );
      // The wrapped key is written last and marks recovery setup as complete.
      await _secureStorage.write(
        key: _keyRecoveryWrappedMasterKey,
        value: base64Encode(wrappedMasterKey),
      );
      return recoveryKey;
    } finally {
      salt.fillRange(0, salt.length, 0);
      recoveryKek?.fillRange(0, recoveryKek.length, 0);
      wrappedMasterKey?.fillRange(0, wrappedMasterKey.length, 0);
      verificationHash?.fillRange(0, verificationHash.length, 0);
    }
  }

  /// Fast-checks a recovery key entered to confirm it was recorded correctly.
  Future<bool> confirmRecoveryKey({required String recoveryKey}) async {
    final storedSalt = await _secureStorage.read(key: _keyRecoverySalt);
    final storedHash = await _secureStorage.read(
      key: _keyRecoveryVerificationHash,
    );
    if (storedSalt == null || storedHash == null) {
      return false;
    }

    Uint8List? salt;
    Uint8List? expectedHash;
    Uint8List? actualHash;
    try {
      salt = Uint8List.fromList(base64Decode(storedSalt));
      expectedHash = Uint8List.fromList(base64Decode(storedHash));
      if (salt.length != RecoveryKey.saltLength || expectedHash.length != 32) {
        return false;
      }
      actualHash = RecoveryKey.computeVerificationHash(
        recoveryKey: recoveryKey,
        salt: salt,
      );
      return _constantTimeEquals(actualHash, expectedHash);
    } on FormatException {
      return false;
    } finally {
      salt?.fillRange(0, salt.length, 0);
      expectedHash?.fillRange(0, expectedHash.length, 0);
      actualHash?.fillRange(0, actualHash.length, 0);
    }
  }

  /// Unlocks the vault using the offline [recoveryKey].
  ///
  /// On success, the caller must prompt the user to set a new passphrase
  /// through a future passphrase-change flow. An incorrect key returns false.
  Future<bool> recoveryKeyLogin({required String recoveryKey}) async {
    if (_state == KeyManagerState.unlocked) {
      throw StateError('Already unlocked');
    }

    final String normalizedKey;
    try {
      normalizedKey = RecoveryKey.normalize(recoveryKey);
    } on FormatException {
      return false;
    }

    final storedSalt = await _secureStorage.read(key: _keyRecoverySalt);
    final storedWrappedMasterKey = await _secureStorage.read(
      key: _keyRecoveryWrappedMasterKey,
    );
    final storedHash = await _secureStorage.read(
      key: _keyRecoveryVerificationHash,
    );
    if (storedSalt == null ||
        storedWrappedMasterKey == null ||
        storedHash == null) {
      return false;
    }

    Uint8List? salt;
    Uint8List? wrappedMasterKey;
    Uint8List? expectedHash;
    Uint8List? actualHash;
    Uint8List? recoveryKek;
    Uint8List? masterKey;
    try {
      salt = Uint8List.fromList(base64Decode(storedSalt));
      wrappedMasterKey = Uint8List.fromList(
        base64Decode(storedWrappedMasterKey),
      );
      expectedHash = Uint8List.fromList(base64Decode(storedHash));
      if (salt.length != RecoveryKey.saltLength ||
          wrappedMasterKey.length < 28 ||
          expectedHash.length != 32) {
        return false;
      }

      actualHash = RecoveryKey.computeVerificationHash(
        recoveryKey: normalizedKey,
        salt: salt,
      );
      if (!_constantTimeEquals(actualHash, expectedHash)) {
        return false;
      }

      recoveryKek = await RecoveryKey.deriveRecoveryKek(
        recoveryKey: normalizedKey,
        salt: salt,
      );
      try {
        masterKey = await RecoveryKey.unwrapMasterKey(
          wrappedMasterKey: wrappedMasterKey,
          recoveryKek: recoveryKek,
        );
      } on RecoveryKeyException {
        return false;
      }
      await _deriveAndHoldSubkeys(masterKey);
      await _secureStorage.write(
        key: _keyPassphraseResetRequired,
        value: 'true',
      );
      _state = KeyManagerState.unlocked;
      _failedAttempts = 0;
      _currentBackoff = Duration.zero;
      onAudit?.call(AuditEventType.recoveryUsed);
      return true;
    } on FormatException {
      return false;
    } finally {
      salt?.fillRange(0, salt.length, 0);
      wrappedMasterKey?.fillRange(0, wrappedMasterKey.length, 0);
      expectedHash?.fillRange(0, expectedHash.length, 0);
      actualHash?.fillRange(0, actualHash.length, 0);
      recoveryKek?.fillRange(0, recoveryKek.length, 0);
      masterKey?.fillRange(0, masterKey.length, 0);
    }
  }

  /// Returns whether a wrapped recovery master key is present.
  Future<bool> hasRecoveryKey() async {
    final storedKey = await _secureStorage.read(
      key: _keyRecoveryWrappedMasterKey,
    );
    return storedKey != null && storedKey.isNotEmpty;
  }

  /// Replaces the current recovery key after verifying [passphrase].
  ///
  /// Existing recovery metadata is restored if writing the replacement fails.
  /// A rotation event is sent to [onAudit] after the replacement is stored.
  Future<String> regenerateRecoveryKey({required String passphrase}) async {
    if (_state != KeyManagerState.unlocked) {
      throw StateError('Not unlocked');
    }
    if (!await _verifyCurrentPassphrase(passphrase)) {
      throw StateError('Passphrase verification failed');
    }

    final oldSalt = await _secureStorage.read(key: _keyRecoverySalt);
    final oldHash = await _secureStorage.read(
      key: _keyRecoveryVerificationHash,
    );
    final oldWrappedKey = await _secureStorage.read(
      key: _keyRecoveryWrappedMasterKey,
    );
    if (oldSalt == null || oldHash == null || oldWrappedKey == null) {
      throw StateError('Stored recovery metadata is incomplete');
    }
    try {
      final recoveryKey = await _createRecoveryKey();
      onAudit?.call(AuditEventType.recoveryKeyRotated);
      return recoveryKey;
    } on Exception {
      await _secureStorage.write(key: _keyRecoverySalt, value: oldSalt);
      await _secureStorage.write(
        key: _keyRecoveryVerificationHash,
        value: oldHash,
      );
      await _secureStorage.write(
        key: _keyRecoveryWrappedMasterKey,
        value: oldWrappedKey,
      );
      rethrow;
    }
  }

  Uint8List _keyForState(Uint8List? key) {
    if (_state != KeyManagerState.unlocked || key == null) {
      throw StateError('Not unlocked');
    }
    return key;
  }

  Future<void> _deriveAndHoldSubkeys(Uint8List masterKey) async {
    Uint8List? dbKey;
    Uint8List? fieldKey;
    Uint8List? auditKey;
    try {
      dbKey = await SubKeyDeriver.deriveDbKey(masterKey);
      fieldKey = await SubKeyDeriver.deriveFieldKey(masterKey);
      auditKey = await SubKeyDeriver.deriveAuditKey(masterKey);

      _clearInMemoryKeys();
      _masterKey = Uint8List.fromList(masterKey);
      _dbKey = dbKey;
      _fieldKey = fieldKey;
      _auditKey = auditKey;
      dbKey = null;
      fieldKey = null;
      auditKey = null;
    } finally {
      dbKey?.fillRange(0, dbKey.length, 0);
      fieldKey?.fillRange(0, fieldKey.length, 0);
      auditKey?.fillRange(0, auditKey.length, 0);
    }
  }

  void _clearInMemoryKeys() {
    _masterKey?.fillRange(0, _masterKey!.length, 0);
    _dbKey?.fillRange(0, _dbKey!.length, 0);
    _fieldKey?.fillRange(0, _fieldKey!.length, 0);
    _auditKey?.fillRange(0, _auditKey!.length, 0);
    _masterKey = null;
    _dbKey = null;
    _fieldKey = null;
    _auditKey = null;
  }

  Future<bool> _verifyCurrentPassphrase(String passphrase) async {
    final saltValue = await _secureStorage.read(key: _keyMasterSalt);
    final masterKeyValue = await _secureStorage.read(key: _keyMasterKey);
    if (saltValue == null || masterKeyValue == null) {
      return false;
    }

    Uint8List? salt;
    Uint8List? expectedVerifier;
    Uint8List? credential;
    try {
      final credentialValue = await _secureStorage.read(
        key: _keyPassphraseCredential,
      );
      if (credentialValue == null) {
        salt = Uint8List.fromList(base64Decode(saltValue));
        expectedVerifier = Uint8List.fromList(base64Decode(masterKeyValue));
      } else {
        credential = Uint8List.fromList(base64Decode(credentialValue));
        if (credential.length != Kdf.saltLength + Kdf.keyLength) {
          return false;
        }
        salt = Uint8List.fromList(credential.sublist(0, Kdf.saltLength));
        expectedVerifier = Uint8List.fromList(
          credential.sublist(Kdf.saltLength),
        );
      }
      if (salt.length != Kdf.saltLength ||
          expectedVerifier.length != Kdf.keyLength) {
        return false;
      }
      return await Kdf.verify(
        passphrase: passphrase,
        salt: salt,
        expectedKey: expectedVerifier,
      );
    } on FormatException {
      return false;
    } finally {
      salt?.fillRange(0, salt.length, 0);
      expectedVerifier?.fillRange(0, expectedVerifier.length, 0);
      credential?.fillRange(0, credential.length, 0);
    }
  }

  Future<void> _deleteRecoveryMaterial() async {
    await _secureStorage.delete(key: _keyRecoveryWrappedMasterKey);
    await _secureStorage.delete(key: _keyRecoverySalt);
    await _secureStorage.delete(key: _keyRecoveryVerificationHash);
  }

  Future<void> _storeNewPassphraseVerifier(String passphrase) async {
    final salt = Kdf.generateSalt();
    Uint8List? verifier;
    Uint8List? credential;
    try {
      verifier = await Kdf.deriveMasterKey(passphrase: passphrase, salt: salt);
      credential = _encodeCredential(salt, verifier);
      await _secureStorage.write(
        key: _keyPassphraseCredential,
        value: base64Encode(credential),
      );
    } finally {
      salt.fillRange(0, salt.length, 0);
      verifier?.fillRange(0, verifier.length, 0);
      credential?.fillRange(0, credential.length, 0);
    }
  }

  static Uint8List _encodeCredential(Uint8List salt, Uint8List verifier) {
    if (salt.length != Kdf.saltLength || verifier.length != Kdf.keyLength) {
      throw ArgumentError('Passphrase credential has invalid fields');
    }
    return Uint8List.fromList(<int>[...salt, ...verifier]);
  }

  static void _validatePassphrase(String passphrase) {
    if (passphrase.runes.length < 12) {
      throw ArgumentError.value(
        passphrase.runes.length,
        'passphrase.length',
        'Must be at least 12 characters',
      );
    }
  }

  static void _validateBackupMaterial(KeyBackupMaterial material) {
    if (material.masterKey.length != Kdf.keyLength ||
        material.masterSalt.length != Kdf.saltLength ||
        material.passphraseVerifier.length != Kdf.keyLength ||
        material.kdfParameters != Kdf.paramsDescription()) {
      throw const FormatException('Backup key material is invalid');
    }

    final recoveryValueCount = <Uint8List?>[
      material.recoverySalt,
      material.recoveryWrappedMasterKey,
      material.recoveryVerificationHash,
    ].where((Uint8List? value) => value != null).length;
    if (recoveryValueCount != 0 && recoveryValueCount != 3) {
      throw const FormatException('Backup recovery material is incomplete');
    }
    if (material.hasRecoveryKey &&
        (material.recoverySalt!.length != RecoveryKey.saltLength ||
            material.recoveryWrappedMasterKey!.length != Kdf.keyLength + 28 ||
            material.recoveryVerificationHash!.length != 32)) {
      throw const FormatException('Backup recovery material is invalid');
    }
  }

  static bool _constantTimeEquals(Uint8List left, Uint8List right) {
    if (left.length != right.length) {
      return false;
    }
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}
