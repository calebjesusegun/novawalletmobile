# NovaWallet Handover

**Status:** T-WAL-002 (wallet home, lazy transactions and refresh) COMPLETE on `feat/wallet-home-and-refresh` — Ready to merge into `main`  
**Primary next task:** `T-WAL-003 — Implement offline banner and last-updated state`  
**Current branch:** `feat/wallet-home-and-refresh`  
**Latest commit on main:** `162317e`  
**Planning baseline commit:** `2bb6f8b`

This document is the operational handover for Claude Code, Codex, Antigravity, or another coding agent taking over NovaWallet implementation.

---

## 1. Current State

The assessment, approved flows, design exports, architecture, implementation plan, design system, traceability, engineering rules, workflow, and executable task backlog have been reviewed and finalized.

Phase 0 (Toolchain & Project Baseline) is complete:
- Flutter 3.47.5 / Dart 3.13.4 project initialized (`T-BASE-001`).
- Plus Jakarta Sans static fonts bundled and registered.
- Strict linter configuration, analyzer rules, and test architecture scaffolded (`T-BASE-002`).
- GitHub Actions CI pipeline active (`T-BASE-003`).

Phase 1 (Money, Identity & Core Operation Model) is COMPLETE and Remediated:
- `T-MNY-001` (integer-kobo `Money` value object) is complete and merged into `main` (`ad871bb`).
- `T-MNY-002` (exact savings-progress calculation) is complete and merged into `main` (`55af79d`).
- `T-ID-001` (stable operation & idempotency identities) is complete and merged into `main` (`cbdb4a0`).
- `T-OP-001` (financial operation model & state transitions) is complete and merged into `main` (`b5a3d6a`).
- `T-DOM-001` (queued-spendability policy) is complete and merged into `main` (`55b9552`).
- **Phase 1 Adversarial Reviews & Remediation PRs:**
  - Remediation PR 1 (`fix/T-MNY-money-safety`, PR #9, merged `cdc940f`): Fixed `SpendableBalancePolicy` integer wrapping (fail-closed, `Money` accumulation, self-exclusion parameter), savings-progress ceiling (99% until goal reached), compact formatting, strict grammar.
  - Remediation PR 2 (`fix/T-OP-operation-invariants`, PR #10, merged `2d0dc75`): Fixed `FinancialOperation` immutability (private constructor, eliminated public `copyWith`, added strict `.restore`), transition matrix enforcement (processing guards, 64-bit attempt check, UTC timestamp normalization), and RFC 9562 v1-8 UUID support.
  - Remediation PR 3 (`docs/T-DOM-fix-contracts-and-polish`, PR #11, merged `939663d`): Added `PayloadFormatException` and `schemaVersion: 1` to `OperationPayload`, documented atomic balance update contract in `ARCHITECTURE.md` §16, added acceptance criterion to `T-XF-001` in `TASKS.md`, and marked `MNY-006` as `DECISION / INFERRED` in `REQUIREMENTS_TRACEABILITY.md`.

Phase 2 (Persistence & Fake Remote) is COMPLETE:
- `T-DB-001` (Configure Drift and pending-operation schema) is COMPLETE and merged (`128d4ed`).
- `T-DB-002` (Add local wallet, transaction and goal persistence) is COMPLETE and merged (`dd859f5`, PR #13).
- `T-REMOTE-001` (Implement idempotent fake remote) is COMPLETE and merged (`734313a`, PR #14).
- `T-REMOTE-002` (Add deterministic failure simulation) is COMPLETE and merged (`4b3934e`, PR #15).

Phase 3 (Connectivity, Queue & Synchronization) is COMPLETE and Hardened:
- `T-CONN-001` (Implement connectivity abstraction) is COMPLETE and merged (`def0ab9`, PR #16).
- `T-SYNC-001` (Implement durable enqueue API) is COMPLETE and merged (`4d10bcb`, PR #17).
- `T-SYNC-002` (Implement single shared sync coordinator and operation claim) is COMPLETE and merged (`11fb065`, PR #18).
- `T-SYNC-003` (Implement restart recovery) is COMPLETE and merged (`05635ff`, PR #19).
- `T-SYNC-004` (Implement failure classification and retry policy) is COMPLETE and merged (`d4bbf27`, PR #20).
- `T-SYNC-005` (Prove offline → restart → reconnect kernel) is COMPLETE and merged (`50d40a1`, PR #21).
- **Remediation PR #22 (`fix/phase-3-money-safety`):** P0 atomic settlement inside `AppDatabase.transaction(...)` with idempotent projection guard; P1 atomic ledger reservation via `executeAtomicOperation`.
- **Hardening (`fix/sync-concurrency-and-head-of-line`):**
  - In-flight operation tracking (`_inFlightOperationIds`) and live-pass guard in `recoverInterrupted()` (eliminating re-entrancy race and preserving `SYNC-010`).
  - Cold-launch-only crash recovery in `startup()` (`_hasStartedUp` guard).
  - Head-of-line blocking elimination in `_executeSyncPass`: recoverable failures record error and continue to subsequent healthy operations.
  - Accurate `retryOperation` status checking on failed claim and preserved coalesced trigger metadata.

Phase 4 (Design System & App Shell) is COMPLETE and merged into `main` (`3e14dc7`).

Phase 5 (Wallet) is IN PROGRESS:
- `T-WAL-001` (Implement wallet data projection and repositories) is COMPLETE and merged into `main` (`162317e`):
  - `WalletActivityItem` domain model fusing confirmed transactions and in-flight operations with reverse-chronological sorting.
  - `WalletProjection` domain projection enforcing `MNY-004` (headline balance remains confirmed while spendable balance reserves pending debits).
  - Extended `TransactionStatus` with `processing` status.
  - Added `refresh()` to `WalletRepository` and `LocalWalletRepository` with `RemoteApi` synchronization and idempotent caching (`InsertMode.insertOrReplace`).
  - Added `walletSnapshotStreamProvider`, `walletRecentTransactionsStreamProvider`, and `walletProjectionProvider` in `lib/features/wallet/data/wallet_providers.dart`.
- `T-WAL-002` (Implement wallet home, lazy transactions and refresh) is COMPLETE on `feat/wallet-home-and-refresh`:
  - `WalletBalanceCard` (`lib/features/wallet/presentation/widgets/wallet_balance_card.dart`): available balance in Naira from integer kobo (`WAL-001`, `ASM-002`, `HC-MONEY`), navigation shortcuts to Send Money and NovaSave.
  - `WalletActivityTile` (`lib/features/wallet/presentation/widgets/wallet_activity_tile.dart`): directional badges, status badges, counterparty details, and screen reader semantics (`A11Y-001`).
  - `WalletRecentActivitySection` (`lib/features/wallet/presentation/widgets/wallet_recent_activity_section.dart`): lazy list rendering with `ListView.separated` (`WAL-002`, `ASM-017`, `PERF-001`, `HC-PERFORMANCE`), empty state via `AppEmptyState.walletTransactions()` (`WAL-004`, `UI-WAL-09`).
  - `WalletController` (`lib/features/wallet/presentation/controllers/wallet_controller.dart`): pull-to-refresh coordination with error capture and retry.
  - `WalletHomeScreen` (`lib/features/wallet/presentation/screens/wallet_home_screen.dart`): matching `UI-WAL-01` and refreshing state `UI-WAL-07`.
  - Wired into `NovaWalletShell` in `lib/app/app.dart`.
  - Discovered and resolved widget selector conflict in `test/app/app_shell_test.dart` (scoping to `AppBottomNavBar` descendants prevents button label collisions).
  - Full test suite: 378 / 378 passing tests with 0 analyzer issues.

---

## 8. Current Execution Task
 
Current Task:
```text
T-WAL-002 (Implement wallet home, lazy transactions and refresh) COMPLETE on feat/wallet-home-and-refresh
```

Next Task:
```text
T-WAL-003 — Implement offline banner and last-updated state (Phase 5 — Wallet)
```

---

## 9. Scope Control

- Enforce integer-kobo money representation per `HC-MONEY`.
- Enforce exact-once financial effects per `HC-EXACTLY-ONCE-EFFECT` and `HC-IDEMPOTENCY`.
- Enforce `HC-STATE-SEPARATION` (connectivity, sync status, and operation status remain separate dimensions).
- Centralize all design tokens and do not introduce hardcoded values in feature widgets.

---

## 10. Required Verification

Every branch/task must satisfy:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Do not claim success without actually running the relevant commands.

---

### 13. Next Action
 
`T-WAL-002` is fully completed on `feat/wallet-home-and-refresh`. All 378 tests pass, analyzer clean, formatting checked.
 
### Next Steps:
1. Merge `feat/wallet-home-and-refresh` into `main`.
2. Proceed to Phase 5: `T-WAL-003 — Implement offline banner and last-updated state`.



