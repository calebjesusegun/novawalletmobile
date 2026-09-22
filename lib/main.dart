import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/app/app.dart';
import 'package:novawallet/core/persistence/persistence.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer();
  // Ensure canonical demonstration data (₦125,450.00 balance, Emergency Fund goal, sample activity)
  // is present on fresh cold start so features are immediately interactive and testable.
  try {
    await container.read(appDatabaseProvider).seedInitialDataIfEmpty();
  } catch (e, stackTrace) {
    debugPrint(
      'Database initial seeding non-blocking warning: $e\n$stackTrace',
    );
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NovaWalletApp(),
    ),
  );
}
