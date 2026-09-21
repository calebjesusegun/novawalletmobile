import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:novawallet/core/persistence/local_tables.dart';
import 'package:novawallet/sync/data/pending_operations_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// The central Drift SQLite database for NovaWallet.
///
/// Implements durable local persistence for operations, wallet balance, transactions, and savings goals.
///
/// Designed to support:
/// - Real file-backed databases in production via [AppDatabase.forFile] or [AppDatabase.forDefaultDirectory].
/// - In-memory SQLite instances for fast, isolated, deterministic unit testing via [AppDatabase.inMemory].
@DriftDatabase(
  tables: [
    PendingOperations,
    WalletCache,
    TransactionsTable,
    SavingsGoalsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? _openDefaultConnection());

  /// Creates an in-memory database instance for testing.
  AppDatabase.inMemory() : super(NativeDatabase.memory());

  /// Creates a database instance backed by a specific file path.
  /// Useful for restart simulation tests.
  AppDatabase.forFile(File file) : super(NativeDatabase(file));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Future schema migrations will be handled here incrementally.
    },
    beforeOpen: (details) async {
      // Enable foreign key constraints in SQLite
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  static QueryExecutor _openDefaultConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'novawallet.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
