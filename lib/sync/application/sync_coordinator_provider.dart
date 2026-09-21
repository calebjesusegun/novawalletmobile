import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/connectivity/connectivity.dart';
import 'package:novawallet/core/persistence/persistence_providers.dart';
import 'package:novawallet/fake_backend/fake_backend_providers.dart';
import 'package:novawallet/features/novasave/data/novasave_providers.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/sync/application/sync_coordinator.dart';
import 'package:novawallet/sync/data/sync_providers.dart';
import 'package:novawallet/sync/domain/sync_status.dart';

/// Provider for the single shared [SyncCoordinator].
final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final coordinator = SyncCoordinator(
    operationRepository: ref.watch(operationRepositoryProvider),
    remoteApi: ref.watch(remoteApiProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    walletRepository: ref.watch(walletRepositoryProvider),
    novaSaveRepository: ref.watch(novaSaveRepositoryProvider),
    appDatabase: ref.watch(appDatabaseProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

/// Stream provider for listening to overall [SyncStatus] changes.
final syncStatusStreamProvider = StreamProvider<SyncStatus>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return coordinator.onStatusChanged;
});

/// Provider exposing the current [SyncStatus].
final syncStatusProvider = Provider<SyncStatus>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return coordinator.status;
});
