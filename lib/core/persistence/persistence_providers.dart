import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:novawallet/core/persistence/app_database.dart';

/// Central database provider for NovaWallet.
///
/// In production, uses the default SQLite persistent file database.
/// In unit and widget tests, override with [AppDatabase.inMemory] via `ProviderScope.overrides`.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
