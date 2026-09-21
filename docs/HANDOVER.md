# NovaWallet Handover

**Status:** Phase 3 in Progress — T-CONN-001 merged; T-SYNC-001 complete and verified; ready for PR and merge  
**Primary next task:** Merge PR for `feature/T-SYNC-001-durable-enqueue`, then proceed to `T-SYNC-002` (Implement single shared sync coordinator and operation claim)  
**Current branch:** `feature/T-SYNC-001-durable-enqueue`  
**Latest commit on main:** `def0ab9`  
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

Phase 3 (Connectivity, Queue & Synchronization) is in progress:
- `T-CONN-001` (Implement connectivity abstraction) is COMPLETE and merged (`def0ab9`, PR #16).
- `T-SYNC-001` (Implement durable enqueue API) is COMPLETE on `feature/T-SYNC-001-durable-enqueue`.

---

## 8. Current Execution Task
 
Current Task:
```text
T-SYNC-001 — Implement durable enqueue API (feature/T-SYNC-001-durable-enqueue)
```

Next Task:
```text
T-SYNC-002 — Implement single shared sync coordinator and operation claim
```

---

## 9. Scope Control

During Phase 3:
- focus strictly on connectivity, queue, and single centralized sync coordinator;
- do not build feature UI screens prematurely;
- preserve strict architectural boundaries;
- enforce integer-kobo money representation per `HC-MONEY`;
- enforce exact-once financial effects per `HC-EXACTLY-ONCE-EFFECT` and `HC-IDEMPOTENCY`;
- enforce HC-STATE-SEPARATION (connectivity, sync status, and operation status remain separate dimensions).

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
 
`feature/T-SYNC-001-durable-enqueue` is verified and ready to merge into `main`.
 
### Completed Work (T-SYNC-001):
- Implemented `OperationRepository` abstract interface (`lib/sync/domain/operation_repository.dart`) with durable enqueue (`enqueue`, `enqueueSendMoney`, `enqueueContribution`), query, atomic claim, state transition (`markPendingWithError`, `markCompleted`, `markFailed`), crash recovery (`recoverInterrupted`), and reactive stream watchers (`watchPendingOperations`, `watchActiveOperations`).
- Implemented `LocalOperationRepository` (`lib/sync/data/local_operation_repository.dart`) backed by Drift SQLite `PendingOperationsDao`, verifying writes on persistence and throwing on failure so callers never get a false saved acknowledgment (`HC-OFFLINE-DURABILITY`, `SYNC-002`, `SND-015`, `NSV-017`).
- Implemented `appDatabaseProvider` in `lib/core/persistence/persistence_providers.dart` and sync providers (`operationRepositoryProvider`, `pendingOperationsStreamProvider`, `activeOperationsStreamProvider`) in `lib/sync/data/sync_providers.dart`.
- Unified `ConnectivityStatus` enum source of truth between `core/connectivity` and `sync/domain`.
- Authored 10 exhaustive unit, lifecycle transition, and SQLite restart simulation tests in `test/sync/data/local_operation_repository_test.dart` (bringing test suite total to 268 passing tests).
- All checks verified (0 format issues, 0 analyze issues, 268/268 tests passing).

### Next Steps:
1. Commit, push `feature/T-SYNC-001-durable-enqueue`, open PR #17, squash-merge into `main`.
2. Checkout `main`, pull latest.
3. Begin `T-SYNC-002 — Implement single shared sync coordinator and operation claim` on a new feature branch `feature/T-SYNC-002-sync-coordinator`.

