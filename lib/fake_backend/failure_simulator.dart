import 'package:novawallet/fake_backend/remote_exceptions.dart';
import 'package:novawallet/sync/domain/financial_operation.dart';

/// The failure behavior to simulate.
enum SimulatedFailureType {
  /// Transient network transport error (recoverable).
  /// Fails before remote execution.
  transport,

  /// Transient remote server error (HTTP 500/503, recoverable).
  /// Fails before remote execution.
  serverError,

  /// Terminal business rejection from the bank (non-recoverable).
  /// Fails before remote execution.
  businessRejection,

  /// Operation is settled remotely, but response is lost/timed out in flight (recoverable/uncertain).
  /// Fails AFTER remote balance debit and idempotency recording.
  responseLost,
}

/// A configurable rule for triggering deterministic simulated failures.
class FailureRule {
  /// The failure type to trigger.
  final SimulatedFailureType type;

  /// Custom error message.
  final String? message;

  /// Custom error code.
  final String? code;

  /// Optional predicate to match specific operations.
  final bool Function(FinancialOperation)? predicate;

  /// Maximum times this rule may trigger (e.g. 1 for single-shot, null for unlimited).
  final int? maxTriggers;

  int _currentTriggers = 0;

  FailureRule({
    required this.type,
    this.message,
    this.code,
    this.predicate,
    this.maxTriggers,
  });

  /// Whether this rule is still active and matches [operation].
  bool matches(FinancialOperation operation) {
    if (maxTriggers != null && _currentTriggers >= maxTriggers!) {
      return false;
    }
    if (predicate != null && !predicate!(operation)) {
      return false;
    }
    return true;
  }

  /// Increments trigger counter and builds the corresponding [RemoteApiException].
  RemoteApiException trigger(
    FinancialOperation operation, {
    String? remoteReference,
  }) {
    _currentTriggers++;
    switch (type) {
      case SimulatedFailureType.transport:
        return RemoteTransportException(
          message: message ?? 'Network connection failed during transfer.',
          code: code ?? 'TRANSPORT_ERROR',
        );
      case SimulatedFailureType.serverError:
        return RemoteServerException(
          message: message ?? 'Bank backend service temporarily unavailable.',
          code: code ?? 'SERVER_ERROR',
        );
      case SimulatedFailureType.businessRejection:
        return RemoteBusinessRejectionException(
          message: message ?? 'Transfer rejected: Invalid destination account or account frozen.',
          code: code ?? 'BUSINESS_REJECTION',
        );
      case SimulatedFailureType.responseLost:
        return RemoteResponseLostException(
          remoteReference: remoteReference ?? 'TXN-UNKNOWN',
          message: message ?? 'Transfer accepted by bank, but response was lost due to connection timeout.',
          code: code ?? 'RESPONSE_LOST',
        );
    }
  }

  /// Whether this rule is exhausted.
  bool get isExhausted =>
      maxTriggers != null && _currentTriggers >= maxTriggers!;
}

/// Deterministic failure simulator for the fake remote banking service.
///
/// Implements requirements:
/// - SYNC-011: App interruption after remote success but before local completion does not produce duplicate effect.
/// - SYNC-012: Recoverable sync failure keeps operation durable and retryable.
/// - TST-007: Failure/retry path is tested for lost/uncertain response behavior.
/// - docs/ARCHITECTURE.md §12.4 & §18.
class FailureSimulator {
  final List<FailureRule> _rules = [];

  /// Injects a failure for the next single operation.
  void failNext(SimulatedFailureType type, {String? message, String? code}) {
    _rules.add(
      FailureRule(type: type, message: message, code: code, maxTriggers: 1),
    );
  }

  /// Injects a failure for the next [count] operations.
  void failNextN(
    int count,
    SimulatedFailureType type, {
    String? message,
    String? code,
  }) {
    _rules.add(
      FailureRule(type: type, message: message, code: code, maxTriggers: count),
    );
  }

  /// Injects a failure matching a specific idempotency key.
  void failForIdempotencyKey(
    String idempotencyKey,
    SimulatedFailureType type, {
    String? message,
    String? code,
    int? maxTriggers = 1,
  }) {
    _rules.add(
      FailureRule(
        type: type,
        message: message,
        code: code,
        predicate: (op) => op.idempotencyKey.value == idempotencyKey,
        maxTriggers: maxTriggers,
      ),
    );
  }

  /// Injects a custom rule.
  void addRule(FailureRule rule) {
    _rules.add(rule);
  }

  /// Evaluates pre-execution failure rules (executed BEFORE any ledger state is altered).
  ///
  /// Throws [RemoteApiException] if a matching pre-execution rule exists.
  void checkPreExecution(FinancialOperation operation) {
    for (int i = 0; i < _rules.length; i++) {
      final rule = _rules[i];
      if (rule.type != SimulatedFailureType.responseLost &&
          rule.matches(operation)) {
        final exception = rule.trigger(operation);
        _cleanupExhaustedRules();
        throw exception;
      }
    }
  }

  /// Evaluates post-execution failure rules (executed AFTER ledger state and idempotency entry are recorded).
  ///
  /// Throws [RemoteResponseLostException] if a matching post-execution rule exists.
  void checkPostExecution(
    FinancialOperation operation,
    String remoteReference,
  ) {
    for (int i = 0; i < _rules.length; i++) {
      final rule = _rules[i];
      if (rule.type == SimulatedFailureType.responseLost &&
          rule.matches(operation)) {
        final exception = rule.trigger(
          operation,
          remoteReference: remoteReference,
        );
        _cleanupExhaustedRules();
        throw exception;
      }
    }
  }

  void _cleanupExhaustedRules() {
    _rules.removeWhere((r) => r.isExhausted);
  }

  /// Clears all active failure rules.
  void reset() {
    _rules.clear();
  }

  /// Returns unmodifiable list of active rules for inspection.
  List<FailureRule> get activeRules => List.unmodifiable(_rules);
}
