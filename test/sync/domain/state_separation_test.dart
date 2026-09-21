import 'package:flutter_test/flutter_test.dart';
import 'package:novawallet/sync/domain/connectivity_status.dart';
import 'package:novawallet/sync/domain/operation_status.dart';
import 'package:novawallet/sync/domain/sync_status.dart';

void main() {
  group('HC-STATE-SEPARATION: Independent State Dimensions', () {
    test('ConnectivityStatus provides independent online/offline states', () {
      expect(ConnectivityStatus.online.isOnline, isTrue);
      expect(ConnectivityStatus.online.isOffline, isFalse);

      expect(ConnectivityStatus.offline.isOffline, isTrue);
      expect(ConnectivityStatus.offline.isOnline, isFalse);
    });

    test('SyncStatus provides independent coordinator states', () {
      expect(SyncStatus.idle.isIdle, isTrue);
      expect(SyncStatus.idle.isSyncing, isFalse);
      expect(SyncStatus.idle.isFailed, isFalse);

      expect(SyncStatus.syncing.isSyncing, isTrue);
      expect(SyncStatus.syncing.isIdle, isFalse);
      expect(SyncStatus.syncing.isFailed, isFalse);

      expect(SyncStatus.failed.isFailed, isTrue);
      expect(SyncStatus.failed.isIdle, isFalse);
      expect(SyncStatus.failed.isSyncing, isFalse);
    });

    test('OperationStatus provides independent financial operation lifecycle states', () {
      expect(OperationStatus.pending.isPending, isTrue);
      expect(OperationStatus.pending.isTerminal, isFalse);

      expect(OperationStatus.processing.isProcessing, isTrue);
      expect(OperationStatus.processing.isTerminal, isFalse);

      expect(OperationStatus.completed.isCompleted, isTrue);
      expect(OperationStatus.completed.isTerminal, isTrue);

      expect(OperationStatus.failed.isFailed, isTrue);
      expect(OperationStatus.failed.isTerminal, isTrue);
    });

    test(
      'all distinct dimension combinations can coexist without collision',
      () {
        // Offline, idle coordinator, pending operation
        const state1 = (
          connectivity: ConnectivityStatus.offline,
          sync: SyncStatus.idle,
          operation: OperationStatus.pending,
        );
        expect(state1.connectivity.isOffline, isTrue);
        expect(state1.sync.isIdle, isTrue);
        expect(state1.operation.isPending, isTrue);

        // Online, syncing coordinator, processing operation
        const state2 = (
          connectivity: ConnectivityStatus.online,
          sync: SyncStatus.syncing,
          operation: OperationStatus.processing,
        );
        expect(state2.connectivity.isOnline, isTrue);
        expect(state2.sync.isSyncing, isTrue);
        expect(state2.operation.isProcessing, isTrue);

        // Online, failed coordinator, operation remains durably pending!
        const state3 = (
          connectivity: ConnectivityStatus.online,
          sync: SyncStatus.failed,
          operation: OperationStatus.pending,
        );
        expect(state3.connectivity.isOnline, isTrue);
        expect(state3.sync.isFailed, isTrue);
        expect(state3.operation.isPending, isTrue);

        // Online, idle coordinator, operation successfully completed
        const state4 = (
          connectivity: ConnectivityStatus.online,
          sync: SyncStatus.idle,
          operation: OperationStatus.completed,
        );
        expect(state4.connectivity.isOnline, isTrue);
        expect(state4.sync.isIdle, isTrue);
        expect(state4.operation.isCompleted, isTrue);
      },
    );
  });
}
