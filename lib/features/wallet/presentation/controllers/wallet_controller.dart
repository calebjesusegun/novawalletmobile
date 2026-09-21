import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/features/wallet/data/wallet_providers.dart';
import 'package:novawallet/features/wallet/domain/wallet_repository.dart';

/// State controller managing Wallet user actions (such as pull-to-refresh).
///
/// Under docs/ARCHITECTURE.md §17:
/// Exposes presentation actions without embedding business rules in widgets.
class WalletController extends StateNotifier<AsyncValue<void>> {
  final WalletRepository _repository;

  WalletController(this._repository) : super(const AsyncValue.data(null));

  /// Triggers a wallet sync refresh with the remote banking service.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      await _repository.refresh();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Provider for [WalletController].
final walletControllerProvider =
    StateNotifierProvider<WalletController, AsyncValue<void>>((ref) {
      final repository = ref.watch(walletRepositoryProvider);
      return WalletController(repository);
    });
