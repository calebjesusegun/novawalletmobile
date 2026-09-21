/// Network connectivity states.
///
/// Strictly conforms to HC-STATE-SEPARATION:
/// ConnectivityStatus models ONLY network reachability (online/offline).
/// Sync status (idle, syncing, failed) and operation status
/// (pending, processing, completed, failed) remain completely independent dimensions.
enum ConnectivityStatus {
  online,
  offline;

  /// Whether network connectivity is available.
  bool get isOnline => this == ConnectivityStatus.online;

  /// Whether the client is currently offline.
  bool get isOffline => this == ConnectivityStatus.offline;
}
