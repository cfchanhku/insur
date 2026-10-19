/// Manages the master key and purpose-separated session keys.
///
/// The MVP stores the Argon2id-derived master key directly in
/// `FlutterSecureStorage`, relying on Keychain, Keystore, or the platform's
/// equivalent protection. A separate passphrase-derived wrapping key would add
/// complexity for limited benefit here; KEK wrapping may be considered later.
/// The passphrase is verified against the stored master key at unlock, and
/// HKDF derives database, field, and audit keys for use only in memory.
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

import 'backoff_policy.dart';
import 'field_crypto.dart';
import 'kdf.dart';
import 'key_derivation.dart';

/// Current state of master-key setup and session access.
enum KeyManagerState { uninitialized, locked, unlocked }

/// Stores the master key securely and derives in-memory application subkeys.
class KeyManager {
  /// Creates a manager using operating-system secure storage and biometrics.
  KeyManager({
    required FlutterSecureStorage secureStorage,
    required LocalAuthentication localAuth,
  })  : _secureStorage = secureStorage,
        _localAuth = localAuth;

  static const String _keyMasterKey = 'insur.master_key.v1';
  static const String _keyMasterSalt = 'insur.master_salt.v1';
  static const String _keyKdfParams = 'insur.kdf_params.v1';

  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;

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
    final storedMasterKey = await _secureStorage.read(
      key: _keyMasterKey,
    );
    final initialized = storedMasterKey != null && storedMasterKey.isNotEmpty;

    if (_state != KeyManagerState.unlocked) {
      _state =
          initialized ? KeyManagerState.locked : KeyManagerState.uninitialized;
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

    final passphraseBytes = Uint8List.fromList(
      utf8.encode(passphrase),
    );
    final salt = Kdf.generateSalt();
    Uint8List? masterKey;
    try {
      masterKey = await Kdf.deriveMasterKey(
        passphrase: passphrase,
        salt: salt,
      );

      await _secureStorage.write(
        key: _keyMasterSalt,
        value: base64Encode(salt),
      );
      await _secureStorage.write(
        key: _keyKdfParams,
        value: Kdf.paramsDescription(),
      );
      // Write the master key last; its presence marks setup as complete.
      await _secureStorage.write(
        key: _keyMasterKey,
        value: base64Encode(masterKey),
      );

      await _deriveAndHoldSubkeys(masterKey);
      _state = KeyManagerState.unlocked;
      _failedAttempts = 0;
      _currentBackoff = Duration.zero;
    } finally {
      passphraseBytes.fillRange(0, passphraseBytes.length, 0);
      salt.fillRange(0, salt.length, 0);
      masterKey?.fillRange(0, masterKey.length, 0);
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

    if (_currentBackoff > Duration.zero) {
      await Future<void>.delayed(_currentBackoff);
    }
    if (BackoffPolicy.shouldRequireRestart(_failedAttempts)) {
      return false;
    }

    final saltValue = await _secureStorage.read(key: _keyMasterSalt);
    final masterKeyValue = await _secureStorage.read(
      key: _keyMasterKey,
    );
    if (saltValue == null ||
        saltValue.isEmpty ||
        masterKeyValue == null ||
        masterKeyValue.isEmpty) {
      throw StateError('Stored key material is incomplete');
    }

    final passphraseBytes = Uint8List.fromList(
      utf8.encode(passphrase),
    );
    final Uint8List salt;
    try {
      salt = Uint8List.fromList(base64Decode(saltValue));
    } on FormatException {
      passphraseBytes.fillRange(0, passphraseBytes.length, 0);
      throw StateError('Stored key material is invalid');
    }
    late final Uint8List expectedMasterKey;
    try {
      expectedMasterKey = Uint8List.fromList(base64Decode(masterKeyValue));
    } on FormatException {
      passphraseBytes.fillRange(0, passphraseBytes.length, 0);
      salt.fillRange(0, salt.length, 0);
      throw StateError('Stored key material is invalid');
    }

    try {
      if (salt.length != Kdf.saltLength ||
          expectedMasterKey.length != Kdf.keyLength) {
        throw StateError('Stored key material is invalid');
      }
      final isValid = await Kdf.verify(
        passphrase: passphrase,
        salt: salt,
        expectedKey: expectedMasterKey,
      );
      if (!isValid) {
        _failedAttempts++;
        _currentBackoff = BackoffPolicy.forAttempts(_failedAttempts);
        return false;
      }

      await _deriveAndHoldSubkeys(expectedMasterKey);
      _state = KeyManagerState.unlocked;
      _failedAttempts = 0;
      _currentBackoff = Duration.zero;
      return true;
    } finally {
      passphraseBytes.fillRange(0, passphraseBytes.length, 0);
      salt.fillRange(0, salt.length, 0);
      expectedMasterKey.fillRange(0, expectedMasterKey.length, 0);
    }
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
      return true;
    } finally {
      masterKey.fillRange(0, masterKey.length, 0);
    }
  }

  /// Clears all in-memory keys and changes the state to locked.
  ///
  /// The securely stored master key remains available for a later unlock.
  Future<void> lock() async {
    _clearInMemoryKeys();
    _state = KeyManagerState.locked;
  }

  /// Locks the session and optionally removes all managed secure-storage data.
  Future<void> logout({bool wipe = false}) async {
    await lock();
    if (wipe) {
      await _secureStorage.delete(key: _keyMasterKey);
      await _secureStorage.delete(key: _keyMasterSalt);
      await _secureStorage.delete(key: _keyKdfParams);
    }
    _state = KeyManagerState.uninitialized;
    _failedAttempts = 0;
    _currentBackoff = Duration.zero;
  }

  /// Database encryption key; valid only while the manager is unlocked.
  Uint8List get dbKey => _keyForState(_dbKey);

  /// Field encryption key; valid only while the manager is unlocked.
  Uint8List get fieldKey => _keyForState(_fieldKey);

  /// Audit authentication key; valid only while the manager is unlocked.
  Uint8List get auditKey => _keyForState(_auditKey);

  /// Creates a field encryption helper using the in-memory field key.
  FieldCrypto createFieldCrypto() {
    return FieldCrypto(fieldKey: fieldKey);
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
}
