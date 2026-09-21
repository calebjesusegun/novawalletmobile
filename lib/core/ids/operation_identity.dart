import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';

/// Pairs a local [OperationId] and a remote [IdempotencyKey] for a single logical operation.
///
/// Under HC-IDEMPOTENCY and HC-EXACTLY-ONCE-EFFECT:
/// - One user intent mints exactly one operation identity and one idempotency key atomically.
/// - The idempotency key is retained across retries of the same logical operation.
@immutable
class OperationIdentity {
  const OperationIdentity({required this.id, required this.key});

  /// The stable local operation identity.
  final OperationId id;

  /// The stable remote idempotency key for deduplication.
  final IdempotencyKey key;

  /// Generates a new unique [OperationIdentity] pair.
  ///
  /// Uses [Random.secure()] by default for cryptographically secure UUIDs.
  /// An optional [random] generator may be passed for deterministic testing.
  factory OperationIdentity.generate([Random? random]) {
    final id = OperationId.generate(random);
    final key = IdempotencyKey.generate(random);
    return OperationIdentity(id: id, key: key);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OperationIdentity && other.id == id && other.key == key);

  @override
  int get hashCode => Object.hash(id, key);

  @override
  String toString() => 'OperationIdentity(id: $id, key: $key)';
}
