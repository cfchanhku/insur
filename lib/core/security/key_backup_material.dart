import 'dart:typed_data';

/// Secure-storage state required to reopen a backed-up vault on another device.
///
/// Instances contain the master key and must be cleared promptly after the
/// encrypted backup operation. Recovery-key bytes are the already wrapped
/// master-key material, never the user's offline recovery key.
class KeyBackupMaterial {
  /// Creates a disposable copy of the key-manager backup state.
  KeyBackupMaterial({
    required Uint8List masterKey,
    required Uint8List masterSalt,
    Uint8List? passphraseVerifier,
    required this.kdfParameters,
    Uint8List? recoverySalt,
    Uint8List? recoveryWrappedMasterKey,
    Uint8List? recoveryVerificationHash,
  }) : masterKey = Uint8List.fromList(masterKey),
       masterSalt = Uint8List.fromList(masterSalt),
       passphraseVerifier = Uint8List.fromList(passphraseVerifier ?? masterKey),
       recoverySalt = recoverySalt == null
           ? null
           : Uint8List.fromList(recoverySalt),
       recoveryWrappedMasterKey = recoveryWrappedMasterKey == null
           ? null
           : Uint8List.fromList(recoveryWrappedMasterKey),
       recoveryVerificationHash = recoveryVerificationHash == null
           ? null
           : Uint8List.fromList(recoveryVerificationHash);

  /// Current 32-byte master key.
  final Uint8List masterKey;

  /// Argon2id salt used to verify the current login passphrase.
  final Uint8List masterSalt;

  /// Argon2id verifier for the current login passphrase.
  ///
  /// Older backups do not contain a separate verifier; their master key is
  /// used as the legacy verifier when parsed.
  final Uint8List passphraseVerifier;

  /// Fixed Argon2id parameter description stored by KeyManager.
  final String kdfParameters;

  /// Salt for the offline recovery-key wrapping key, if configured.
  final Uint8List? recoverySalt;

  /// AES-GCM-wrapped master key for the existing offline recovery key.
  final Uint8List? recoveryWrappedMasterKey;

  /// Fast-check hash used to validate entry of the existing recovery key.
  final Uint8List? recoveryVerificationHash;

  /// Whether a complete recovery-key state is present.
  bool get hasRecoveryKey =>
      recoverySalt != null &&
      recoveryWrappedMasterKey != null &&
      recoveryVerificationHash != null;

  /// Overwrites all mutable key and recovery buffers in this object.
  void clear() {
    masterKey.fillRange(0, masterKey.length, 0);
    masterSalt.fillRange(0, masterSalt.length, 0);
    passphraseVerifier.fillRange(0, passphraseVerifier.length, 0);
    recoverySalt?.fillRange(0, recoverySalt!.length, 0);
    recoveryWrappedMasterKey?.fillRange(0, recoveryWrappedMasterKey!.length, 0);
    recoveryVerificationHash?.fillRange(0, recoveryVerificationHash!.length, 0);
  }

  @override
  String toString() => 'KeyBackupMaterial(recoveryKey: $hasRecoveryKey)';
}
