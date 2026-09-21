/// Represents the overall status of the shared synchronization subsystem.
///
/// Per HC-STATE-SEPARATION and HC-SYNC, synchronization is centralized and its
/// state is independent from individual operation lifecycle states.
enum SyncStatus {
  /// The synchronization engine is idle (no sync pass in progress).
  idle,

  /// A synchronization pass is actively claiming and processing queued operations.
  syncing,

  /// The most recent synchronization attempt encountered an error (e.g. network failure).
  /// Note that a sync failure does NOT automatically mean queued operations are terminally failed;
  /// they remain durably pending and retryable.
  failed;

  /// Returns `true` if sync is idle.
  bool get isIdle => this == SyncStatus.idle;

  /// Returns `true` if sync is actively processing operations.
  bool get isSyncing => this == SyncStatus.syncing;

  /// Returns `true` if the last sync run encountered an error.
  bool get isFailed => this == SyncStatus.failed;
}
