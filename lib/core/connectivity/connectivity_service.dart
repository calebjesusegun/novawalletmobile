import 'package:novawallet/core/connectivity/connectivity_status.dart';

/// Abstract contract for observing and querying network connectivity.
///
/// Designed to be fully injectable and overridable in tests.
abstract interface class ConnectivityService {
  /// Queries the current network connectivity status.
  Future<ConnectivityStatus> checkConnectivity();

  /// Emits updates whenever the network reachability status transitions.
  Stream<ConnectivityStatus> get onConnectivityChanged;

  /// Releases any active stream subscriptions or underlying resources.
  void dispose();
}
