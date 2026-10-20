/// Manages the master key and purpose-separated session keys.
///
/// A randomly generated master key is wrapped by a passphrase-derived KEK and
/// stored in `FlutterSecureStorage`. Passphrase changes re-wrap the same master
/// key, so database encryption and HKDF-derived subkeys remain stable.
///
/// The session moves from uninitialized to unlocked after setup, from locked
/// to unlocked after successful authentication, and back to locked on manual
/// lock. This class does not own an inactivity timer; the application should
/// call [lock] when its auto-lock policy expires. Biometric enrollment is
/// available, but biometric unlock is deferred until secure storage can enforce
/// platform-protected key access.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  /// Creates a manager using operating-system secure storage.
  KeyManager({required FlutterSecureStorage secureStorage})
    : _secureStorage = secureStorage;

  static const String _keyMasterKey = 'insur.master_key.v1';
  static const String _keyMasterSalt = 'insur.master_salt.v1';
  static const String _keyPassphraseCredential =
      'insur.passphrase_credential.v1';
  static const String _keyWrappedMasterCredential =
      'insur.master_key_credential.v2';
  static const String _keyPassphraseResetRequired =
      'insur.passphrase_reset_required.v1';
  static const String _keyBiometricEnabled = 'insur.biometric_enabled.v1';
  static const String _keyKdfParams = 'insur.kdf_params.v1';
  static const String _keyRecoveryWrappedMasterKey =
      'insur.recovery.wrapped_mk.v1';
  static const String _keyRecoverySalt = 'insur.recovery.salt.v1';
  static const String _keyRecoveryVerificationHash =
      'insur.recovery.verification_hash.v1';
  static const int _passphraseNonceLength = 12;
  static const int _passphraseTagLength = 16;
  static const String _passphraseWrappingAad = 'insur/master-key/passphrase/v2';

  final FlutterSecureStorage _secureStorage;

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

  /// Returns whether an old or wrapped master-key credential is stored.
  ///
  /// If initialized and not already unlocked, the manager enters the locked
  /// state.
  Future<bool> isInitialized() async {
    final wrappedCredential = await _secureStorage.read(
      key: _keyWrappedMasterCredential,
    );
    final legacyMasterKey = await _secureStorage.read(key: _keyMasterKey);
    final initialized =
        (wrappedCredential != null && wrappedCredential.isNotEmpty) ||
        (legacyMasterKey != null && legacyMasterKey.isNotEmpty);

    if (_state != KeyManagerState.unlocked) {
      _state = initialized
          ? KeyManagerState.locked
          : KeyManagerState.uninitialized;
    }
    return initialized;
  }

  /// Generates and stores a random master key wrapped by [passphrase].
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

    final salt = Kdf.generateSalt();
    Uint8List? kek;
    Uint8List? masterKey;
    Uint8List? wrappedCredential;
    try {
      masterKey = Kdf.generateMasterKey();
      kek = await Kdf.derivePassphraseKey(passphrase: passphrase, salt: salt);
      wrappedCredential = await _wrapMasterKeyCredential(
        masterKey: masterKey,
        kek: kek,
        salt: salt,
      );
      await _secureStorage.write(
        key: _keyKdfParams,
        value: Kdf.paramsDescription(),
      );
      await _secureStorage.write(key: _keyBiometricEnabled, value: 'false');
      await _secureStorage.delete(key: _keyPassphraseResetRequired);
      // The wrapped credential is the marker that setup completed.
      await _secureStorage.write(
        key: _keyWrappedMasterCredential,
        value: base64Encode(wrappedCredential),
      );
      await _deleteLegacyPassphraseMaterial();

      await _deriveAndHoldSubkeys(masterKey);
      _state = KeyManagerState.unlocked;
      _failedAttempts = 0;
      _currentBackoff = Duration.zero;
      onAudit?.call(AuditEventType.appSetup);
    } finally {
      salt.fillRange(0, salt.length, 0);
      kek?.fillRange(0, kek.length, 0);
      masterKey?.fillRange(0, masterKey.length, 0);
      wrappedCredential?.fillRange(0, wrappedCredential.length, 0);
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

    Uint8List? masterKey;
    try {
      masterKey = await _openMasterKey(passphrase);
      if (masterKey == null) {
        _failedAttempts++;
        _currentBackoff = BackoffPolicy.forAttempts(_failedAttempts);
        onAudit?.call(
          AuditEventType.loginFail,
          metadata: <String, Object?>{'attempts': _failedAttempts},
        );
        return false;
      }
      await _deriveAndHoldSubkeys(masterKey);
      _state = KeyManagerState.unlocked;
      _failedAttempts = 0;
      _currentBackoff = Duration.zero;
      onAudit?.call(AuditEventType.loginSuccess);
      return true;
    } finally {
      masterKey?.fillRange(0, masterKey.length, 0);
    }
  }

  /// Checks whether [passphrase] authenticates the current master-key
  /// credential without
  /// changing the session state or failed-login counter.
  Future<bool> verifyPassphrase({required String passphrase}) async {
    return _verifyCurrentPassphrase(passphrase);
  }

  /// Re-wraps the existing master key using the replacement passphrase.
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
    final verifiedMasterKey = await _openMasterKey(currentPassphrase);
    if (verifiedMasterKey == null) {
      throw StateError('Passphrase verification failed');
    }
    try {
      if (!_constantTimeEquals(verifiedMasterKey, _masterKey!)) {
        throw StateError('Stored master key does not match the active vault');
      }
      await _storeNewPassphraseCredential(newPassphrase, verifiedMasterKey);
      onAudit?.call(AuditEventType.passphraseChanged);
    } finally {
      verifiedMasterKey.fillRange(0, verifiedMasterKey.length, 0);
    }
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
    await _storeNewPassphraseCredential(newPassphrase, _masterKey!);
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

  /// Biometric unlock is deferred until platform-protected key storage exists.
  ///
  /// Biometric enrollment remains available, but the configured secure-storage
  /// abstraction cannot require biometric authorization to unwrap a key.
  Future<bool> unlockWithBiometric() async {
    await lock();
    throw UnsupportedError(
      'Biometric unlock requires platform-protected key storage',
    );
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
      await _secureStorage.delete(key: _keyWrappedMasterCredential);
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
    final paramsValue = await _secureStorage.read(key: _keyKdfParams);
    if (paramsValue == null || paramsValue != Kdf.paramsDescription()) {
      throw StateError('Stored key metadata is invalid');
    }

    Uint8List? masterSalt;
    Uint8List? passphraseVerifier;
    Uint8List? credential;
    Uint8List? wrappedPassphraseCredential;
    Uint8List? recoverySalt;
    Uint8List? recoveryWrappedMasterKey;
    Uint8List? recoveryVerificationHash;
    try {
      final wrappedCredentialValue = await _secureStorage.read(
        key: _keyWrappedMasterCredential,
      );
      if (wrappedCredentialValue != null) {
        wrappedPassphraseCredential = Uint8List.fromList(
          base64Decode(wrappedCredentialValue),
        );
        if (wrappedPassphraseCredential.length !=
            Kdf.saltLength +
                _passphraseNonceLength +
                Kdf.keyLength +
                _passphraseTagLength) {
          throw StateError('Stored key metadata is invalid');
        }
        masterSalt = Uint8List.fromList(
          wrappedPassphraseCredential.sublist(0, Kdf.saltLength),
        );
      } else {
        final saltValue = await _secureStorage.read(key: _keyMasterSalt);
        final credentialValue = await _secureStorage.read(
          key: _keyPassphraseCredential,
        );
        final legacyMasterKeyValue = await _secureStorage.read(
          key: _keyMasterKey,
        );
        if (saltValue == null || legacyMasterKeyValue == null) {
          throw StateError('Stored key metadata is invalid');
        }
        if (credentialValue == null) {
          masterSalt = Uint8List.fromList(base64Decode(saltValue));
          passphraseVerifier = Uint8List.fromList(
            base64Decode(legacyMasterKeyValue),
          );
        } else {
          credential = Uint8List.fromList(base64Decode(credentialValue));
          if (credential.length != Kdf.saltLength + Kdf.keyLength) {
            throw StateError('Stored key metadata is invalid');
          }
          masterSalt = Uint8List.fromList(
            credential.sublist(0, Kdf.saltLength),
          );
          passphraseVerifier = Uint8List.fromList(
            credential.sublist(Kdf.saltLength),
          );
        }
        if (masterSalt.length != Kdf.saltLength ||
            passphraseVerifier.length != Kdf.keyLength) {
          throw StateError('Stored key metadata is invalid');
        }
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
        wrappedPassphraseCredential: wrappedPassphraseCredential,
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
      wrappedPassphraseCredential?.fillRange(
        0,
        wrappedPassphraseCredential.length,
        0,
      );
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
  /// Wrapped credentials are restored as a single secure-storage value.
  /// Legacy v1/v2 credentials remain readable and are migrated after a
  /// successful passphrase unlock.
  Future<void> restoreBackupMaterial(
    KeyBackupMaterial material, {
    bool replaceExisting = false,
  }) async {
    _validateBackupMaterial(material);
    final currentMasterKey = await _secureStorage.read(key: _keyMasterKey);
    final currentWrappedCredential = await _secureStorage.read(
      key: _keyWrappedMasterCredential,
    );
    if (!replaceExisting &&
        (currentMasterKey != null || currentWrappedCredential != null)) {
      Uint8List? existingCredential;
      try {
        var sameVault = false;
        if (currentWrappedCredential != null &&
            material.wrappedPassphraseCredential != null) {
          existingCredential = Uint8List.fromList(
            base64Decode(currentWrappedCredential),
          );
          sameVault = _constantTimeEquals(
            existingCredential,
            material.wrappedPassphraseCredential!,
          );
        } else if (currentMasterKey != null &&
            currentWrappedCredential == null) {
          existingCredential = Uint8List.fromList(
            base64Decode(currentMasterKey),
          );
          sameVault = _constantTimeEquals(
            existingCredential,
            material.masterKey,
          );
        }
        if (!sameVault) {
          throw StateError(
            'Existing vault credentials differ; wipe the vault before restore',
          );
        }
      } on FormatException {
        throw StateError('Stored key metadata is invalid');
      } finally {
        existingCredential?.fillRange(0, existingCredential.length, 0);
      }
    }

    _clearInMemoryKeys();
    _state = KeyManagerState.uninitialized;
    _failedAttempts = 0;
    _currentBackoff = Duration.zero;

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
    if (material.hasWrappedPassphraseCredential) {
      await _secureStorage.write(
        key: _keyWrappedMasterCredential,
        value: base64Encode(material.wrappedPassphraseCredential!),
      );
      await _deleteLegacyPassphraseMaterial();
    } else {
      await _secureStorage.write(
        key: _keyMasterSalt,
        value: base64Encode(material.masterSalt),
      );
      final credential = _encodeCredential(
        material.masterSalt,
        material.passphraseVerifier!,
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
        key: _keyMasterKey,
        value: base64Encode(material.masterKey),
      );
      await _secureStorage.delete(key: _keyWrappedMasterCredential);
    }
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
    final masterKey = await _openMasterKey(passphrase);
    if (masterKey == null) {
      return false;
    }
    try {
      return _masterKey == null || _constantTimeEquals(masterKey, _masterKey!);
    } finally {
      masterKey.fillRange(0, masterKey.length, 0);
    }
  }

  Future<Uint8List?> _openMasterKey(String passphrase) async {
    final wrappedValue = await _secureStorage.read(
      key: _keyWrappedMasterCredential,
    );
    if (wrappedValue != null) {
      Uint8List? credential;
      Uint8List? salt;
      Uint8List? kek;
      try {
        credential = Uint8List.fromList(base64Decode(wrappedValue));
        const expectedLength =
            Kdf.saltLength +
            _passphraseNonceLength +
            Kdf.keyLength +
            _passphraseTagLength;
        if (credential.length != expectedLength) {
          throw StateError('Stored key material is invalid');
        }
        salt = Uint8List.fromList(credential.sublist(0, Kdf.saltLength));
        kek = await Kdf.derivePassphraseKey(passphrase: passphrase, salt: salt);
        const nonceStart = Kdf.saltLength;
        const ciphertextStart = nonceStart + _passphraseNonceLength;
        const tagStart = ciphertextStart + Kdf.keyLength;
        try {
          final plaintext = await AesGcm.with256bits().decrypt(
            SecretBox(
              credential.sublist(ciphertextStart, tagStart),
              nonce: credential.sublist(nonceStart, ciphertextStart),
              mac: Mac(credential.sublist(tagStart)),
            ),
            secretKey: SecretKey(kek),
            aad: utf8.encode(_passphraseWrappingAad),
          );
          try {
            final masterKey = Uint8List.fromList(plaintext);
            if (masterKey.length != Kdf.keyLength) {
              masterKey.fillRange(0, masterKey.length, 0);
              throw StateError('Stored key material is invalid');
            }
            return masterKey;
          } finally {
            plaintext.fillRange(0, plaintext.length, 0);
          }
        } on SecretBoxAuthenticationError {
          return null;
        }
      } on FormatException {
        throw StateError('Stored key material is invalid');
      } finally {
        credential?.fillRange(0, credential.length, 0);
        salt?.fillRange(0, salt.length, 0);
        kek?.fillRange(0, kek.length, 0);
      }
    }

    return _openLegacyMasterKey(passphrase);
  }

  Future<Uint8List?> _openLegacyMasterKey(String passphrase) async {
    final saltValue = await _secureStorage.read(key: _keyMasterSalt);
    final masterKeyValue = await _secureStorage.read(key: _keyMasterKey);
    if (saltValue == null || masterKeyValue == null) {
      throw StateError('Stored key material is incomplete');
    }

    Uint8List? salt;
    Uint8List? masterKey;
    Uint8List? verifier;
    Uint8List? credential;
    try {
      final verifierValue = await _secureStorage.read(
        key: _keyPassphraseCredential,
      );
      if (verifierValue == null) {
        salt = Uint8List.fromList(base64Decode(saltValue));
        verifier = Uint8List.fromList(base64Decode(masterKeyValue));
      } else {
        credential = Uint8List.fromList(base64Decode(verifierValue));
        if (credential.length != Kdf.saltLength + Kdf.keyLength) {
          throw StateError('Stored key material is invalid');
        }
        salt = Uint8List.fromList(credential.sublist(0, Kdf.saltLength));
        verifier = Uint8List.fromList(credential.sublist(Kdf.saltLength));
      }
      masterKey = Uint8List.fromList(base64Decode(masterKeyValue));
      if (salt.length != Kdf.saltLength ||
          verifier.length != Kdf.keyLength ||
          masterKey.length != Kdf.keyLength) {
        throw StateError('Stored key material is invalid');
      }
      if (!await Kdf.verify(
        passphrase: passphrase,
        salt: salt,
        expectedKey: verifier,
      )) {
        return null;
      }

      final kek = await Kdf.derivePassphraseKey(
        passphrase: passphrase,
        salt: salt,
      );
      try {
        final wrappedCredential = await _wrapMasterKeyCredential(
          masterKey: masterKey,
          kek: kek,
          salt: salt,
        );
        try {
          await _secureStorage.write(
            key: _keyWrappedMasterCredential,
            value: base64Encode(wrappedCredential),
          );
          await _deleteLegacyPassphraseMaterial();
        } finally {
          wrappedCredential.fillRange(0, wrappedCredential.length, 0);
        }
      } finally {
        kek.fillRange(0, kek.length, 0);
      }
      return Uint8List.fromList(masterKey);
    } on FormatException {
      throw StateError('Stored key material is invalid');
    } finally {
      salt?.fillRange(0, salt.length, 0);
      masterKey?.fillRange(0, masterKey.length, 0);
      verifier?.fillRange(0, verifier.length, 0);
      credential?.fillRange(0, credential.length, 0);
    }
  }

  Future<void> _deleteRecoveryMaterial() async {
    await _secureStorage.delete(key: _keyRecoveryWrappedMasterKey);
    await _secureStorage.delete(key: _keyRecoverySalt);
    await _secureStorage.delete(key: _keyRecoveryVerificationHash);
  }

  Future<void> _storeNewPassphraseCredential(
    String passphrase,
    Uint8List masterKey,
  ) async {
    final salt = Kdf.generateSalt();
    Uint8List? kek;
    Uint8List? credential;
    try {
      kek = await Kdf.derivePassphraseKey(passphrase: passphrase, salt: salt);
      credential = await _wrapMasterKeyCredential(
        masterKey: masterKey,
        kek: kek,
        salt: salt,
      );
      await _secureStorage.write(
        key: _keyWrappedMasterCredential,
        value: base64Encode(credential),
      );
      await _deleteLegacyPassphraseMaterial();
    } finally {
      salt.fillRange(0, salt.length, 0);
      kek?.fillRange(0, kek.length, 0);
      credential?.fillRange(0, credential.length, 0);
    }
  }

  Future<void> _deleteLegacyPassphraseMaterial() async {
    await _secureStorage.delete(key: _keyMasterKey);
    await _secureStorage.delete(key: _keyMasterSalt);
    await _secureStorage.delete(key: _keyPassphraseCredential);
  }

  static Future<Uint8List> _wrapMasterKeyCredential({
    required Uint8List masterKey,
    required Uint8List kek,
    required Uint8List salt,
  }) async {
    if (masterKey.length != Kdf.keyLength ||
        kek.length != Kdf.keyLength ||
        salt.length != Kdf.saltLength) {
      throw ArgumentError('Passphrase credential has invalid fields');
    }
    final box = await AesGcm.with256bits().encrypt(
      masterKey,
      secretKey: SecretKey(kek),
      aad: utf8.encode(_passphraseWrappingAad),
    );
    if (box.nonce.length != _passphraseNonceLength ||
        box.mac.bytes.length != _passphraseTagLength) {
      throw StateError('Unexpected AES-GCM output');
    }
    return Uint8List.fromList(<int>[
      ...salt,
      ...box.nonce,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
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
    final validPassphraseCredential = material.hasWrappedPassphraseCredential
        ? material.masterSalt.length == Kdf.saltLength &&
              material.wrappedPassphraseCredential!.length ==
                  Kdf.saltLength +
                      _passphraseNonceLength +
                      Kdf.keyLength +
                      _passphraseTagLength &&
              _constantTimeEquals(
                material.masterSalt,
                Uint8List.sublistView(
                  material.wrappedPassphraseCredential!,
                  0,
                  Kdf.saltLength,
                ),
              )
        : material.masterSalt.length == Kdf.saltLength &&
              material.passphraseVerifier?.length == Kdf.keyLength;
    if (material.masterKey.length != Kdf.keyLength ||
        !validPassphraseCredential ||
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
