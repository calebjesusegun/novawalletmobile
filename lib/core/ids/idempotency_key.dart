import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/ids/uuid.dart';

/// Represents a stable, unique remote deduplication identity for a logical financial operation.
///
/// Under HC-IDEMPOTENCY and HC-EXACTLY-ONCE-EFFECT:
/// - One logical financial action has exactly ONE stable idempotency key.
/// - Retries of the same logical operation MUST reuse the same idempotency key.
/// - A retry never generates a new key merely because delivery failed, the app restarted,
///   or the user tapped retry.
/// - The fake remote implementation deduplicates incoming requests by [IdempotencyKey]
///   to ensure at most one financial effect occurs.
@immutable
class IdempotencyKey implements Comparable<IdempotencyKey> {
  /// The underlying string key.
  final String value;

  static final RegExp _formatRegex = RegExp(r'^[a-zA-Z0-9_\-\.:]+$');

  const IdempotencyKey._(this.value);

  /// Creates an [IdempotencyKey] from a validated string.
  ///
  /// Enforces:
  /// - Non-empty string.
  /// - No leading, trailing, or internal whitespace.
  /// - Valid identifier characters (alphanumeric, hyphens, underscores, dots, colons).
  /// - Maximum length of 255 characters.
  /// - RFC 4122 / RFC 9562 UUIDs are normalized to canonical lowercase.
  factory IdempotencyKey(String value) {
    _validate(value);
    final normalized = Uuid.isGeneralUuid(value) ? value.toLowerCase() : value;
    return IdempotencyKey._(normalized);
  }

  /// Generates a new random UUID v4 backed [IdempotencyKey].
  ///
  /// Uses [Random.secure()] by default for cryptographically secure randomness.
  /// An optional [random] generator can be passed for deterministic test scenarios.
  factory IdempotencyKey.generate([Random? random]) {
    return IdempotencyKey._(Uuid.v4(random));
  }

  /// Creates an [IdempotencyKey] from a string that must strictly conform to
  /// the RFC 4122 / RFC 9562 UUID format (versions 1 through 8).
  factory IdempotencyKey.fromUuid(String uuid) {
    if (!Uuid.isValid(uuid)) {
      throw ArgumentError.value(
        uuid,
        'uuid',
        'Idempotency key must be a valid RFC 4122 / RFC 9562 UUID.',
      );
    }
    return IdempotencyKey(uuid);
  }

  /// Creates an [IdempotencyKey] deterministically bound to an [OperationId].
  ///
  /// Requires a non-empty [prefix] (e.g. `idem_`) to ensure clear wire distinction
  /// between the local operation ID and the remote idempotency key.
  factory IdempotencyKey.fromOperationId(
    OperationId operationId, {
    required String prefix,
  }) {
    if (prefix.trim().isEmpty) {
      throw ArgumentError.value(
        prefix,
        'prefix',
        'Prefix must be non-empty to ensure wire distinction between OperationId and IdempotencyKey.',
      );
    }
    return IdempotencyKey('$prefix${operationId.value}');
  }

  /// Returns `true` if [value] meets the validation invariants for an [IdempotencyKey].
  static bool isValid(String value) {
    if (value.isEmpty ||
        value.length > 255 ||
        value.trim() != value ||
        value.contains(RegExp(r'\s'))) {
      return false;
    }
    return _formatRegex.hasMatch(value);
  }

  /// Returns `true` if [value] is a valid RFC 4122 UUID.
  static bool isValidUuid(String value) => Uuid.isValid(value);

  /// Whether this key is an RFC 4122 UUID (versions 1-5).
  bool get isUuid => Uuid.isValid(value);

  /// Whether this key is an RFC 4122 version 4 (random) UUID.
  bool get isUuidV4 => Uuid.isValidV4(value);

  static void _validate(String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Idempotency key cannot be empty.',
      );
    }
    if (value.trim() != value || value.contains(RegExp(r'\s'))) {
      throw ArgumentError.value(
        value,
        'value',
        'Idempotency key cannot contain whitespace.',
      );
    }
    if (value.length > 255) {
      throw ArgumentError.value(
        value,
        'value',
        'Idempotency key cannot exceed 255 characters.',
      );
    }
    if (!_formatRegex.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'Idempotency key contains invalid characters. Only alphanumeric characters, '
            'hyphens, underscores, dots, and colons are permitted.',
      );
    }
  }

  @override
  int compareTo(IdempotencyKey other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdempotencyKey && other.value == value);

  @override
  int get hashCode => Object.hash(IdempotencyKey, value);

  @override
  String toString() => value;
}
