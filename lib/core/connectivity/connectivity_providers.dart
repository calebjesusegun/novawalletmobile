import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:novawallet/core/connectivity/connectivity_plus_service.dart';
import 'package:novawallet/core/connectivity/connectivity_service.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';

/// Provider for the injectable [ConnectivityService].
///
/// In production, uses [ConnectivityPlusService].
/// In unit, widget, or integration tests, override this provider with
/// [InMemoryConnectivityService] via `ProviderScope.overrides`.
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityPlusService();
  ref.onDispose(service.dispose);
  return service;
});

/// Stream provider for observing [ConnectivityStatus] changes.
///
/// Emits the current connectivity status immediately upon subscription,
/// followed by any updates whenever network availability transitions.
final connectivityStatusStreamProvider = StreamProvider<ConnectivityStatus>((
  ref,
) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.checkConnectivity();
  yield* service.onConnectivityChanged;
});

/// Convenience provider exposing the latest known [ConnectivityStatus].
/// Defaults to [ConnectivityStatus.online] while loading or before resolution.
final connectivityStatusProvider = Provider<ConnectivityStatus>((ref) {
  final asyncStatus = ref.watch(connectivityStatusStreamProvider);
  return asyncStatus.valueOrNull ?? ConnectivityStatus.online;
});
