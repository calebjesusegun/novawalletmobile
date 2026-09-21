import 'dart:async';

import 'package:novawallet/core/connectivity/connectivity_service.dart';
import 'package:novawallet/core/connectivity/connectivity_status.dart';

/// Deterministic, in-memory implementation of [ConnectivityService].
///
/// Intended for unit tests, widget tests, integration tests, and local simulation.
/// Allows tests to explicitly dictate or toggle online/offline state and observe
/// subscriber reactions deterministically.
class InMemoryConnectivityService implements ConnectivityService {
  /// Creates an in-memory connectivity service with an optional [initialStatus].
  /// Defaults to [ConnectivityStatus.online].
  InMemoryConnectivityService({
    ConnectivityStatus initialStatus = ConnectivityStatus.online,
  }) : _currentStatus = initialStatus;

  ConnectivityStatus _currentStatus;
  final StreamController<ConnectivityStatus> _controller =
      StreamController<ConnectivityStatus>.broadcast();

  bool _isDisposed = false;

  /// The current connectivity status.
  ConnectivityStatus get currentStatus => _currentStatus;

  /// Whether this service has been disposed.
  bool get isDisposed => _isDisposed;

  /// Updates the connectivity status and broadcasts the new state to subscribers.
  ///
  /// By default, if [newStatus] is identical to [_currentStatus], no redundant
  /// event is emitted unless [notifyIfUnchanged] is set to `true`.
  void setStatus(
    ConnectivityStatus newStatus, {
    bool notifyIfUnchanged = false,
  }) {
    if (_isDisposed) {
      throw StateError(
        'Cannot set status on a disposed InMemoryConnectivityService',
      );
    }
    final previousStatus = _currentStatus;
    _currentStatus = newStatus;
    if (notifyIfUnchanged || previousStatus != newStatus) {
      _controller.add(newStatus);
    }
  }

  /// Toggles between [ConnectivityStatus.online] and [ConnectivityStatus.offline].
  void toggle() {
    setStatus(
      _currentStatus == ConnectivityStatus.online
          ? ConnectivityStatus.offline
          : ConnectivityStatus.online,
    );
  }

  @override
  Future<ConnectivityStatus> checkConnectivity() async {
    return _currentStatus;
  }

  @override
  Stream<ConnectivityStatus> get onConnectivityChanged => _controller.stream;

  @override
  void dispose() {
    if (!_isDisposed) {
      _isDisposed = true;
      _controller.close();
    }
  }
}
