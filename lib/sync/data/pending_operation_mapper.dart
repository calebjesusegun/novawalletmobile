import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:novawallet/core/ids/idempotency_key.dart';
import 'package:novawallet/core/ids/operation_id.dart';
import 'package:novawallet/core/persistence/app_database.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_payload.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/operation_type.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

/// Clean bidirectional mapping between Drift database entities and domain entities.
///
/// Under HC-MONEY, HC-OFFLINE-DURABILITY, and HC-IDEMPOTENCY:
/// - Maps integer-kobo amount to/from 64-bit int / BigInt without loss of precision.
/// - Serializes/deserializes [OperationPayload] as JSON with schema version tracking.
/// - Serializes/deserializes [SyncError] metadata for transient/terminal sync error retention.
/// - Restores operations exclusively via [FinancialOperation.restore] to enforce domain invariants.
/// - Converts all moments strictly to UTC epoch milliseconds.
class PendingOperationMapper {
  const PendingOperationMapper._();

  /// Converts a domain [FinancialOperation] into a Drift [PendingOperationsCompanion] for insert or update.
  static PendingOperationsCompanion toCompanion(FinancialOperation operation) {
    return PendingOperationsCompanion(
      id: Value(operation.id.value),
      idempotencyKey: Value(operation.idempotencyKey.value),
      operationType: Value(operation.type.name),
      payloadJson: Value(jsonEncode(operation.payload.toMap())),
      amountKobo: Value(BigInt.from(operation.payload.amount.kobo)),
      status: Value(operation.status.name),
      attemptCount: Value(operation.attemptCount),
      createdAt: Value(BigInt.from(operation.createdAt.millisecondsSinceEpoch)),
      lastAttemptAt: Value(
        operation.lastAttemptAt != null
            ? BigInt.from(operation.lastAttemptAt!.millisecondsSinceEpoch)
            : null,
      ),
      lastErrorJson: Value(
        operation.lastError != null
            ? jsonEncode(operation.lastError!.toMap())
            : null,
      ),
      remoteReference: Value(operation.remoteReference),
      completedAt: Value(
        operation.completedAt != null
            ? BigInt.from(operation.completedAt!.millisecondsSinceEpoch)
            : null,
      ),
    );
  }

  /// Rehydrates a domain [FinancialOperation] from a Drift [PendingOperationEntry].
  ///
  /// Strictly calls [FinancialOperation.restore] to enforce lifecycle and identity invariants.
  static FinancialOperation toDomain(PendingOperationEntry row) {
    final type = OperationType.values.byName(row.operationType);
    final status = OperationStatus.values.byName(row.status);

    final payloadMap = jsonDecode(row.payloadJson) as Map<String, dynamic>;
    final payload = OperationPayload.fromMap(type, payloadMap);

    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      row.createdAt.toInt(),
      isUtc: true,
    );

    final lastAttemptAt = row.lastAttemptAt != null
        ? DateTime.fromMillisecondsSinceEpoch(
            row.lastAttemptAt!.toInt(),
            isUtc: true,
          )
        : null;

    final completedAt = row.completedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(
            row.completedAt!.toInt(),
            isUtc: true,
          )
        : null;

    final lastError = row.lastErrorJson != null
        ? SyncError.fromMap(
            jsonDecode(row.lastErrorJson!) as Map<String, dynamic>,
          )
        : null;

    return FinancialOperation.restore(
      id: OperationId(row.id),
      type: type,
      idempotencyKey: IdempotencyKey(row.idempotencyKey),
      payload: payload,
      createdAt: createdAt,
      status: status,
      attemptCount: row.attemptCount,
      lastAttemptAt: lastAttemptAt,
      lastError: lastError,
      remoteReference: row.remoteReference,
      completedAt: completedAt,
    );
  }
}
