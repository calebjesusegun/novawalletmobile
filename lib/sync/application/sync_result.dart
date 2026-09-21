import 'package:flutter/foundation.dart';
import 'package:novawallet/sync/domain/sync_error.dart';

/// The trigger that initiated a synchronization run.
enum SyncTrigger {
  /// Automatic synchronization triggered when connectivity transitions from offline to online.
  reconnect,

  /// Synchronization triggered on app startup or foreground resume.
  startup,

  /// Explicit user-initiated retry on an operation or the sync queue.
  userRetry,

  /// General manual synchronization trigger.
  manual,
}

/// The result summary of a synchronization run.
@immutable
class SyncRunResult {
  /// The trigger that initiated this run.
  final SyncTrigger trigger;

  /// Total count of operations considered during this run.
  final int totalDiscovered;

  /// Count of operations claimed and actively attempted.
  final int totalClaimed;

  /// Count of operations that completed successfully on remote and persisted locally.
  final int succeeded;

  /// Count of operations that encountered a recoverable error.
  final int recoverableFailures;

  /// Count of operations that encountered a terminal failure.
  final int terminalFailures;

  /// Count of operations skipped because they were already claimed or completed.
  final int skipped;

  /// List of sync errors encountered during the run.
  final List<SyncError> errors;

  const SyncRunResult({
    required this.trigger,
    required this.totalDiscovered,
    required this.totalClaimed,
    required this.succeeded,
    required this.recoverableFailures,
    required this.terminalFailures,
    required this.skipped,
    this.errors = const [],
  });

  /// Factory for an empty sync run (no operations eligible).
  factory SyncRunResult.empty(SyncTrigger trigger) {
    return SyncRunResult(
      trigger: trigger,
      totalDiscovered: 0,
      totalClaimed: 0,
      succeeded: 0,
      recoverableFailures: 0,
      terminalFailures: 0,
      skipped: 0,
    );
  }

  /// Whether any errors occurred during the sync pass.
  bool get hasErrors =>
      errors.isNotEmpty || recoverableFailures > 0 || terminalFailures > 0;

  @override
  String toString() =>
      'SyncRunResult(trigger: $trigger, discovered: $totalDiscovered, claimed: $totalClaimed, '
      'succeeded: $succeeded, recoverableFailures: $recoverableFailures, '
      'terminalFailures: $terminalFailures, skipped: $skipped)';
}
