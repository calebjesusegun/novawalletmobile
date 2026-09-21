import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/persistence/persistence.dart';
import 'package:novawallet/fake_backend/data/drift_remote_ledger.dart';
import 'package:novawallet/fake_backend/failure_simulator.dart';
import 'package:novawallet/fake_backend/fake_remote_api.dart';
import 'package:novawallet/fake_backend/remote_api.dart';
import 'package:novawallet/fake_backend/remote_idempotency_ledger.dart';

/// Provider for the remote idempotency ledger backed by Drift tables.
final remoteIdempotencyLedgerProvider = Provider<RemoteIdempotencyLedger>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return DriftRemoteLedger(db);
});

/// Provider for the failure simulator.
final failureSimulatorProvider = Provider<FailureSimulator>((ref) {
  return FailureSimulator();
});

/// Provider for the [RemoteApi] backed by [FakeRemoteApi].
final remoteApiProvider = Provider<RemoteApi>((ref) {
  return FakeRemoteApi(
    ledger: ref.watch(remoteIdempotencyLedgerProvider),
    failureSimulator: ref.watch(failureSimulatorProvider),
  );
});
