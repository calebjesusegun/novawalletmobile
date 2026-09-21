import 'package:flutter/foundation.dart';
import 'package:novawallet/core/money/money.dart';

/// The result returned by [RemoteApi] when an operation is processed remotely.
///
/// Contains the stable [remoteReference] assigned by the remote system,
/// the settlement timestamp, and whether this result was served from an existing
/// idempotency ledger record (indicating a replayed/duplicate delivery).
@immutable
class RemoteOperationResult {
  /// Stable reference assigned by the remote system (e.g. 'TXN-ABC123-167890').
  final String remoteReference;

  /// Timestamp when the remote financial effect was settled (UTC).
  final DateTime settledAt;

  /// The amount debited from the remote balance.
  final Money debitAmount;

  /// True if this result was returned from an existing idempotency record
  /// without producing an additional financial effect.
  final bool isDuplicate;

  /// Optional metadata returned by the remote system.
  final Map<String, dynamic> metadata;

  const RemoteOperationResult({
    required this.remoteReference,
    required this.settledAt,
    required this.debitAmount,
    this.isDuplicate = false,
    this.metadata = const {},
  });

  /// Creates a copy of this result with optional field overrides.
  RemoteOperationResult copyWith({
    String? remoteReference,
    DateTime? settledAt,
    Money? debitAmount,
    bool? isDuplicate,
    Map<String, dynamic>? metadata,
  }) {
    return RemoteOperationResult(
      remoteReference: remoteReference ?? this.remoteReference,
      settledAt: settledAt ?? this.settledAt,
      debitAmount: debitAmount ?? this.debitAmount,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RemoteOperationResult &&
          other.remoteReference == remoteReference &&
          other.settledAt.isAtSameMomentAs(settledAt) &&
          other.debitAmount == debitAmount &&
          other.isDuplicate == isDuplicate &&
          mapEquals(other.metadata, metadata));

  @override
  int get hashCode => Object.hash(
    remoteReference,
    settledAt.toUtc().millisecondsSinceEpoch,
    debitAmount,
    isDuplicate,
  );

  @override
  String toString() =>
      'RemoteOperationResult(ref: $remoteReference, settledAt: $settledAt, '
      'debit: $debitAmount, isDuplicate: $isDuplicate)';
}
