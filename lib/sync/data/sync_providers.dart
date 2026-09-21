import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/persistence/persistence.dart';
import 'package:novawallet/sync/data/local_operation_repository.dart';
import 'package:novawallet/sync/data/pending_operations_dao.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';
import 'package:novawallet/sync/domain/operation_repository.dart';

/// Provider for the low-level [PendingOperationsDao].
final pendingOperationsDaoProvider = Provider<PendingOperationsDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PendingOperationsDao(db);
});

/// Provider for the centralized [OperationRepository].
final operationRepositoryProvider = Provider<OperationRepository>((ref) {
  final dao = ref.watch(pendingOperationsDaoProvider);
  return LocalOperationRepository(dao);
});

/// Stream provider for reactive list of all pending operations.
final pendingOperationsStreamProvider =
    StreamProvider<List<FinancialOperation>>((ref) {
      final repo = ref.watch(operationRepositoryProvider);
      return repo.watchPendingOperations();
    });

/// Stream provider for reactive list of all active operations (pending + processing).
final activeOperationsStreamProvider = StreamProvider<List<FinancialOperation>>(
  (ref) {
    final repo = ref.watch(operationRepositoryProvider);
    return repo.watchActiveOperations();
  },
);
