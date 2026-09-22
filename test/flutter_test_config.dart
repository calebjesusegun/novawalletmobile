import 'dart:async';

import 'package:drift/drift.dart';

/// Global test configuration for NovaWallet test suite.
///
/// Automatically invoked by Flutter Test before executing test suites.
/// Suppresses Drift's multi-database debug warning across all widget tests where
/// in-memory databases and ProviderScopes are intentionally created per test.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
