import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:novawallet/core/ids/uuid.dart';

/// Represents a stable, unique local identity for a logical financial operation
/// (e.g. Send Money transfer, NovaSave contribution, or Goal creation).
///
/// An [OperationId] identifies the logical user intent in local durable storage.
/// Per HC-IDEMPOTENCY, an operation maintains its stable identity across retries,
/// app restarts, and network reconnects.
@immutable
class OperationId implements Comparable<OperationId> {
  /// The underlying string identifier.
  final String value;

  static final RegExp _formatRegex = RegExp(r'^[a-zA-Z0-9_\-\.:]+$');

  const OperationId._(this.value);

  /// Creates an [OperationId] from a validated string identifier.
  ///
  /// Enforces:
  /// - Non-empty string.
  /// - No leading, trailing, or internal whitespace.
  /// - Valid identifier characters (alphanumeric, hyphens, underscores, dots, colons).
  /// - Maximum length of 255 characters.
  /// - RFC 4122 UUIDs are normalized to canonical lowercase.
  factory OperationId(String value) {
    _validate(value);
    final normalized = Uuid.isGeneralUuid(value) ? value.toLowerCase() : value;
    return OperationId._(normalized);
  }

  /// Generates a new random UUID v4 backed [OperationId].
  ///
  /// Uses [Random.secure()] by default. An optional [random] generator can be
  /// provided for deterministic test scenarios.
  factory OperationId.generate([Random? random]) {
    return OperationId._(Uuid.v4(random));
  }

  /// Creates an [OperationId] from a string that must strictly conform to
  /// the RFC 4122 UUID format (versions 1 through 5).
  factory OperationId.fromUuid(String uuid) {
    if (!Uuid.isValid(uuid)) {
      throw ArgumentError.value(
        uuid,
        'uuid',
        'Operation ID must be a valid RFC 4122 UUID.',
      );
    }
    return OperationId(uuid);
  }

  /// Returns `true` if [value] meets the validation invariants for an [OperationId].
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

  /// Whether this operation identity is an RFC 4122 UUID (versions 1-5).
  bool get isUuid => Uuid.isValid(value);

  /// Whether this operation identity is an RFC 4122 version 4 (random) UUID.
  bool get isUuidV4 => Uuid.isValidV4(value);

  static void _validate(String value) {
    if (value.isEmpty) {
      throw ArgumentError.value(
        value,
        'value',
        'Operation ID cannot be empty.',
      );
    }
    if (value.trim() != value || value.contains(RegExp(r'\s'))) {
      throw ArgumentError.value(
        value,
        'value',
        'Operation ID cannot contain whitespace.',
      );
    }
    if (value.length > 255) {
      throw ArgumentError.value(
        value,
        'value',
        'Operation ID cannot exceed 255 characters.',
      );
    }
    if (!_formatRegex.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'Operation ID contains invalid characters. Only alphanumeric characters, '
            'hyphens, underscores, dots, and colons are permitted.',
      );
    }
  }

  @override
  int compareTo(OperationId other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is OperationId && other.value == value);

  @override
  int get hashCode => Object.hash(OperationId, value);

  @override
  String toString() => value;
}
