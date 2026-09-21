/// Represents the device connectivity state.
///
/// Per HC-STATE-SEPARATION, connectivity status is an independent dimension
/// and MUST NOT be coupled with operation state or sync coordinator state.
enum ConnectivityStatus {
  online,
  offline;

  /// Returns `true` if network connectivity is available.
  bool get isOnline => this == ConnectivityStatus.online;

  /// Returns `true` if the device is currently offline.
  bool get isOffline => this == ConnectivityStatus.offline;
}
