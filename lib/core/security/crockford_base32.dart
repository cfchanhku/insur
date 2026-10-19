/// Encodes bytes with Crockford Base32, whose alphabet avoids easily confused
/// letters such as I, L, O, and U.
library;

import 'dart:typed_data';

/// Encodes and decodes the Crockford Base32 representation.
class CrockfordBase32 {
  const CrockfordBase32._();

  /// Crockford alphabet used for canonical output.
  static const String alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// Encodes [bytes] as ungrouped uppercase Crockford Base32.
  static String encode(Uint8List bytes) {
    if (bytes.isEmpty) {
      return '';
    }

    final output = StringBuffer();
    var accumulator = 0;
    var bitCount = 0;
    for (final byte in bytes) {
      accumulator = (accumulator << 8) | byte;
      bitCount += 8;
      while (bitCount >= 5) {
        bitCount -= 5;
        output.write(alphabet[(accumulator >> bitCount) & 0x1f]);
      }
      accumulator &= (1 << bitCount) - 1;
    }
    if (bitCount > 0) {
      output.write(alphabet[(accumulator << (5 - bitCount)) & 0x1f]);
    }
    return output.toString();
  }

  /// Decodes Crockford Base32 [input], accepting common ambiguous aliases.
  ///
  /// Input is case-insensitive; `O` maps to `0`, `I` and `L` map to `1`, and
  /// `U` maps to `V`. Non-zero trailing padding bits are rejected.
  static Uint8List decode(String input) {
    final normalized = stripHyphens(input);
    final bytes = <int>[];
    var accumulator = 0;
    var bitCount = 0;

    for (final codeUnit in normalized.codeUnits) {
      var character = String.fromCharCode(codeUnit);
      if (character == 'O') {
        character = '0';
      } else if (character == 'I' || character == 'L') {
        character = '1';
      } else if (character == 'U') {
        character = 'V';
      }

      final value = alphabet.indexOf(character);
      if (value < 0) {
        throw const FormatException('Invalid Crockford Base32 character');
      }
      accumulator = (accumulator << 5) | value;
      bitCount += 5;
      if (bitCount >= 8) {
        bitCount -= 8;
        bytes.add((accumulator >> bitCount) & 0xff);
      }
      accumulator &= (1 << bitCount) - 1;
    }

    if (bitCount > 0 && accumulator != 0) {
      throw const FormatException('Invalid Crockford Base32 padding');
    }
    return Uint8List.fromList(bytes);
  }

  /// Inserts a hyphen after each [groupSize] characters.
  static String groupWithHyphens(
    String ungrouped, {
    int groupSize = 4,
  }) {
    if (groupSize <= 0) {
      throw ArgumentError.value(groupSize, 'groupSize', 'Must be positive');
    }
    final output = StringBuffer();
    for (var index = 0; index < ungrouped.length; index += groupSize) {
      if (index > 0) {
        output.write('-');
      }
      final end = index + groupSize < ungrouped.length
          ? index + groupSize
          : ungrouped.length;
      output.write(ungrouped.substring(index, end));
    }
    return output.toString();
  }

  /// Removes hyphens and spaces and converts [grouped] to uppercase.
  static String stripHyphens(String grouped) {
    return grouped.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
  }

  /// Returns whether [input] contains only accepted Crockford characters.
  static bool isValid(String input) {
    try {
      decode(input);
      return true;
    } on FormatException {
      return false;
    }
  }
}
