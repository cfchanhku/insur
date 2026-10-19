/// Derives independent cryptographic keys for separate application domains.
///
/// Domain separation prevents a key used for one purpose, such as audit
/// authentication, from also being valid for another purpose, such as database
/// encryption. Versioned domain strings allow future key hierarchies to evolve
/// without reusing keys from this version.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Derives purpose-specific subkeys from the master key.
class SubKeyDeriver {
  const SubKeyDeriver._();

  /// Domain identifier for the database encryption key.
  static const String domainDb = 'insur/db/v1';

  /// Domain identifier for field-level encryption keys.
  static const String domainField = 'insur/field/v1';

  /// Domain identifier for the audit HMAC key.
  static const String domainAudit = 'insur/audit/v1';

  /// Length in bytes of every derived subkey.
  static const int subKeyLength = 32;

  /// Derives the database encryption key from [masterKey].
  static Future<Uint8List> deriveDbKey(Uint8List masterKey) {
    return deriveSubKey(masterKey: masterKey, domain: domainDb);
  }

  /// Derives the field encryption key from [masterKey].
  static Future<Uint8List> deriveFieldKey(Uint8List masterKey) {
    return deriveSubKey(masterKey: masterKey, domain: domainField);
  }

  /// Derives the audit HMAC key from [masterKey].
  static Future<Uint8List> deriveAuditKey(Uint8List masterKey) {
    return deriveSubKey(masterKey: masterKey, domain: domainAudit);
  }

  /// Derives a subkey for [domain] from a 32-byte [masterKey].
  ///
  /// Distinct domain strings produce cryptographically independent keys.
  static Future<Uint8List> deriveSubKey({
    required Uint8List masterKey,
    required String domain,
  }) {
    if (masterKey.length != subKeyLength) {
      throw ArgumentError.value(
        masterKey.length,
        'masterKey.length',
        'Must be exactly $subKeyLength bytes',
      );
    }
    return _hkdf(masterKey: masterKey, info: domain);
  }

  static Future<Uint8List> _hkdf({
    required Uint8List masterKey,
    required String info,
  }) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: subKeyLength);
    final derived = await hkdf.deriveKey(
      secretKey: SecretKey(masterKey),
      // Hkdf defaults nonce to an empty list, the RFC 5869 zero-salt behavior.
      info: utf8.encode(info),
    );
    final bytes = await derived.extractBytes();
    return Uint8List.fromList(bytes);
  }
}
