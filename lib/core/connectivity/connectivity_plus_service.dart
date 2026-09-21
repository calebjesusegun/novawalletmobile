import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:novawallet/core/connectivity/connectivity_service.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';

/// Production implementation of [ConnectivityService] wrapping `connectivity_plus`.
///
/// Maps device network interface states to domain [ConnectivityStatus].
/// Note (per ARCHITECTURE.md §18):
/// A network-interface signal indicates likely connectivity; it does not prove
/// a remote request will succeed. Operation correctness never depends on
/// connectivity status alone.
class ConnectivityPlusService implements ConnectivityService {
  /// Creates a [ConnectivityPlusService] wrapping the provided [Connectivity] client.
  ConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Maps a list of [ConnectivityResult] to [ConnectivityStatus].
  static ConnectivityStatus mapResults(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return ConnectivityStatus.offline;
    }
    final hasActiveConnection = results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn ||
          result == ConnectivityResult.other,
    );
    return hasActiveConnection
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
  }

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return mapResults(results);
  }

  @override
  Stream<ConnectivityStatus> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(mapResults).distinct();
  }

  @override
  void dispose() {
    // connectivity_plus does not require explicit disposal
  }
}
