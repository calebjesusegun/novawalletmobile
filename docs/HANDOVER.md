# NovaWallet Handover

**Status:** Phase 2 in Progress — T-DB-001 complete and verified; ready for merge and transition to T-DB-002  
**Primary next task:** Merge PR for `feature/T-DB-001-drift-persistence`, then proceed to `T-DB-002` (local wallet, transaction, and goal persistence)  
**Current branch:** `feature/T-DB-001-drift-persistence`  
**Latest commit on main:** `939663d`  
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

Phase 2 (Persistence & Fake Remote) is in progress:
- `T-DB-001` (Configure Drift and pending-operation schema) is COMPLETE on `feature/T-DB-001-drift-persistence`.

---

## 8. Current Execution Task
 
Current Task:
```text
T-DB-001 — Configure Drift and pending-operation schema (feature/T-DB-001-drift-persistence)
```

Next Task:
```text
T-DB-002 — Add local wallet, transaction and goal persistence
```

---

## 9. Scope Control

During Phase 2:
- focus strictly on durable local persistence with Drift/SQLite and fake remote behavior;
- do not build feature UI screens prematurely;
- do not build sync loops or full sync coordinator until Phase 3;
- preserve strict architectural boundaries;
- enforce integer-kobo money representation per `HC-MONEY`.

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
 
`feature/T-DB-001-drift-persistence` is verified and ready to merge into `main`.
 
### Completed Work (T-DB-001):
- Added `drift`, `sqlite3`, `path_provider`, and `path` to dependencies; `drift_dev` and `build_runner` to dev dependencies.
- Implemented `PendingOperations` Drift table schema in `lib/sync/data/pending_operations_table.dart` capturing stable operation ID, unique idempotency key, operation type, JSON payload, exact integer kobo amount (`BigInt`), lifecycle status, attempt count, UTC timestamps, serialized sync error, remote reference, and completion timestamp.
- Implemented `AppDatabase` in `lib/core/persistence/app_database.dart` with support for lazy file storage in production, explicit file connections for restart testing, and in-memory SQLite instances for fast, isolated unit tests.
- Implemented `PendingOperationMapper` in `lib/sync/data/pending_operation_mapper.dart` ensuring strict rehydration through `FinancialOperation.restore` enforcing all domain invariants.
- Implemented `PendingOperationsDao` in `lib/sync/data/pending_operations_dao.dart` providing atomic claiming (`claimOperation`), lifecycle updates (`updateOperation`), crash recovery query (`recoverInterruptedOperations`), and spendable balance active operation watchers (`getActiveOperations`, `watchActiveOperations`).
- Authored 8 unit tests in `test/sync/data/pending_operations_dao_test.dart` verifying exact integer kobo storage, unique idempotency key constraint, atomic claiming, lifecycle progression with recoverable error metadata, and multi-connection database restart simulation across file open/close cycles (bringing test suite total from 193 to 201 tests).
- Ran and verified full baseline checks (201 tests passing, 0 analyzer issues, 0 formatting issues).

### Next Steps:
1. Commit, push `feature/T-DB-001-drift-persistence`, open PR, squash-merge into `main`.
2. Checkout `main`, pull latest.
3. Begin `T-DB-002 — Add local wallet, transaction and goal persistence` on a new feature branch `feature/T-DB-002-wallet-goal-persistence`.
