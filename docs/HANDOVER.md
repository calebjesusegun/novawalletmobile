# NovaWallet Handover

**Status:** Phase 3 Money-Safety Hardening MERGED into main — Ready for Phase 4 (Design System & App Shell)  
**Primary next task:** `T-DS-001 — Implement design tokens, theme, font and icons`  
**Current branch:** `main`  
**Latest commit on main:** `fa24962` (PR #22)  
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

Phase 3 (Connectivity, Queue & Synchronization) is COMPLETE and Remediated:
- `T-CONN-001` (Implement connectivity abstraction) is COMPLETE and merged (`def0ab9`, PR #16).
- `T-SYNC-001` (Implement durable enqueue API) is COMPLETE and merged (`4d10bcb`, PR #17).
- `T-SYNC-002` (Implement single shared sync coordinator and operation claim) is COMPLETE and merged (`11fb065`, PR #18).
- `T-SYNC-003` (Implement restart recovery) is COMPLETE and merged (`05635ff`, PR #19).
- `T-SYNC-004` (Implement failure classification and retry policy) is COMPLETE and merged (`d4bbf27`, PR #20).
- `T-SYNC-005` (Prove offline → restart → reconnect kernel) is COMPLETE and merged (`50d40a1`, PR #21).
- **Phase 3 Adversarial Review & Money-Safety Hardening (`fix/phase-3-money-safety`):**
  - **P0 — Atomic Local Settlement & Idempotent Projection Guard:** In `SyncCoordinator._applySuccessfulOperationEffects`, wrapped local wallet balance update, transaction ledger insertion, NovaSave goal progress increment, and `markCompleted` operation transition inside an atomic `AppDatabase` transaction (`appDatabase.transaction(...)`). Injected `AppDatabase` via `SyncCoordinator` and `syncCoordinatorProvider`. Added an idempotent projection guard checking `walletRepository.getTransactionById(operation.id.value)` so that if a crash or restart occurs right before `markCompleted`, subsequent sync passes mark the operation completed without double-debiting wallet balance or double-incrementing goal progress.
  - **P1 — Atomic Remote Idempotency Key Reservation:** In `FakeRemoteApi` and `RemoteIdempotencyLedger`, replaced the race-prone check-then-debit pattern with `executeAtomicOperation`. In `InMemoryRemoteLedger`, atomic reservation runs synchronously without async interleaving. In `DriftRemoteLedger`, remote balance debit, transaction ledger insert, and idempotency-record storage are executed in a single SQLite transaction with unique-key collision fallback to return the already committed result without an additional debit.

---

## 8. Current Execution Task
 
Current Task:
```text
Phase 3 Money-Safety Remediation COMPLETE & MERGED into main (PR #22)
```

Next Task:
```text
T-DS-001 — Implement design tokens, theme, font and icons (Phase 4 — Design System & App Shell)
```

---

## 9. Scope Control

- Enforce integer-kobo money representation per `HC-MONEY`.
- Enforce exact-once financial effects per `HC-EXACTLY-ONCE-EFFECT` and `HC-IDEMPOTENCY`.
- Enforce `HC-STATE-SEPARATION` (connectivity, sync status, and operation status remain separate dimensions).
- In Phase 4, establish shared design tokens and typography without prematurely building full feature flows.

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
 
`fix/phase-3-money-safety` (PR #22) is squashed and merged into `main`. Working branch is clean `main`.
 
### Completed Work (fix/phase-3-money-safety, PR #22):
1. **P0 (SyncCoordinator Atomic Settlement):**
   - Added `AppDatabase? appDatabase` to `SyncCoordinator` and injected it in `syncCoordinatorProvider`.
   - Wrapped projections in `_applySuccessfulOperationEffects()` inside `appDatabase.transaction(...)`.
   - Added idempotent projection guard checking `walletRepository.getTransactionById(...)` to prevent duplicate debit/contribution on replay after an interrupted run.
   - Authored regression tests in `test/sync/application/sync_coordinator_test.dart`.
2. **P1 (FakeRemoteApi Atomic Ledger Reservation):**
   - Added `executeAtomicOperation` method to `RemoteIdempotencyLedger`.
   - Implemented synchronous non-interleaved atomic reservation in `InMemoryRemoteLedger`.
   - Implemented SQLite transaction with unique-key constraint handling in `DriftRemoteLedger`.
   - Updated `FakeRemoteApi.sendMoney` and `contribute` to use `executeAtomicOperation`.
   - Authored regression tests in `test/fake_backend/fake_remote_api_test.dart` and `test/fake_backend/drift_remote_ledger_test.dart`.
3. **Verification Trinity:**
   - `dart format --output=none --set-exit-if-changed .` -> 0 issues.
   - `flutter analyze` -> 0 issues.
   - `flutter test` -> 306/306 passing tests across entire suite.
4. **Documentation:**
   - Updated `AI_USAGE.md` (Prompt 21 & `AI-RISK-005`).
   - Updated `docs/HANDOVER.md`.

### Next Steps:
1. Create task branch `feature/T-DS-001-design-tokens` from clean `main`.
2. Begin Phase 4 (Design System & App Shell) with `T-DS-001 — Implement design tokens, theme, font and icons`.

