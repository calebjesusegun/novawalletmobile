import 'dart:math';
import 'dart:typed_data';

/// RFC 4122 compliant UUID utility for NovaWallet identities.
///
/// Implements cryptographically secure version 4 (random) UUID generation
/// and RFC 4122 format validation with zero external dependencies.
class Uuid {
  const Uuid._();

  static final RegExp _rfc4122Regex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  static final RegExp _rfc4122V4Regex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );

  static final RegExp _generalUuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Generates a random RFC 4122 version 4 UUID.
  ///
  /// Uses [Random.secure()] by default for cryptographically secure uniqueness.
  /// An optional [random] instance may be provided for deterministic tests.
  static String v4([Random? random]) {
    final rng = random ?? Random.secure();
    final bytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      bytes[i] = rng.nextInt(256);
    }

    // Set version to 4: bits 12-15 of time_hi_and_version to 0100 (4)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;

    // Set variant to RFC 4122 (variant 1): bits 6-7 of clock_seq_hi_and_reserved to 10
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      if (i == 4 || i == 6 || i == 8 || i == 10) {
        buffer.write('-');
      }
      buffer.write(bytes[i].toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// Checks whether [value] is a valid RFC 4122 UUID (versions 1 through 5).
  static bool isValid(String value) => _rfc4122Regex.hasMatch(value);

  /// Checks whether [value] is a valid RFC 4122 version 4 UUID.
  static bool isValidV4(String value) => _rfc4122V4Regex.hasMatch(value);

  /// Checks whether [value] matches standard 8-4-4-4-12 hex UUID format
  /// (including nil UUID: 00000000-0000-0000-0000-000000000000).
  static bool isGeneralUuid(String value) => _generalUuidRegex.hasMatch(value);
}
