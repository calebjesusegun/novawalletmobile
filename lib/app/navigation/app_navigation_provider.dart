import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/app/navigation/app_destination.dart';

/// State notifier managing primary destination in the app shell.
class AppNavigationNotifier extends StateNotifier<AppDestination> {
  AppNavigationNotifier([super.initial = AppDestination.wallet]);

  void selectDestination(AppDestination destination) {
    state = destination;
  }
}

/// App-level provider for primary navigation state.
///
/// Can be overridden in tests via `ProviderScope(overrides: [...])`.
final appNavigationProvider =
    StateNotifierProvider<AppNavigationNotifier, AppDestination>((ref) {
      return AppNavigationNotifier();
    });
