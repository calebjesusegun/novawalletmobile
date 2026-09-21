# NovaWallet Handover

**Status:** Phase 3 COMPLETE — All Phase 3 tasks merged into main; ready for Phase 4 (Design System & App Shell)  
**Primary next task:** `T-DS-001 — Implement design tokens, theme, font and icons`  
**Current branch:** `main`  
**Latest commit on main:** `50d40a1` (PR #21)  
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

Phase 3 (Connectivity, Queue & Synchronization) is COMPLETE:
- `T-CONN-001` (Implement connectivity abstraction) is COMPLETE and merged (`def0ab9`, PR #16).
- `T-SYNC-001` (Implement durable enqueue API) is COMPLETE and merged (`4d10bcb`, PR #17).
- `T-SYNC-002` (Implement single shared sync coordinator and operation claim) is COMPLETE and merged (`11fb065`, PR #18).
- `T-SYNC-003` (Implement restart recovery) is COMPLETE and merged (`05635ff`, PR #19).
- `T-SYNC-004` (Implement failure classification and retry policy) is COMPLETE and merged (`d4bbf27`, PR #20).
- `T-SYNC-005` (Prove offline → restart → reconnect kernel) is COMPLETE on `feature/T-SYNC-005-kernel-verification`.

---

## 8. Current Execution Task
 
Current Task:
```text
T-SYNC-005 — Prove offline → restart → reconnect kernel (feature/T-SYNC-005-kernel-verification)
```

Next Task:
```text
T-DS-001 — Implement design tokens, theme, font and icons (Phase 4 — Design System & App Shell)
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
 
`feature/T-SYNC-005-kernel-verification` is verified and ready to merge into `main`.
 
### Completed Work (T-SYNC-005):
- Implemented `SyncKernelTestHarness` (`test/sync/kernel/sync_kernel_test_harness.dart`) providing end-to-end integration lifecycle orchestration across real SQLite storage files (`AppDatabase.forFile`), independent Riverpod `ProviderContainer` instances, and fake remote banking infrastructure.
- Implemented `test/sync/kernel/sync_kernel_test.dart` with 5 integration tests:
  1. Full Offline → Process Crash/Restart → Reconnect Auto-Sync → Exactly-Once Effect (`ASM-011`, `ASM-012`, `TST-006`): verified that Send Money and NovaSave operations enqueued offline survive sudden app termination, resume upon reconnect, update local and remote balances by exact integer kobo amounts without duplication, append ledger transactions, and advance goal progress.
  2. Replay Deduplication Guard (`ASM-013`, `HC-IDEMPOTENCY`): verified that replaying completed operations reuses the same idempotency key, resulting in cached receipt retrieval from the remote ledger with zero second financial debit.
  3. Crash Recovery After Remote Settlement (`SYNC-011`, `HC-EXACTLY-ONCE-EFFECT`): verified that an in-flight operation interrupted after remote execution recovers to pending and resynchronizes with the same key, returning the deduplicated result and committing local state without double-debiting.
  4. Negative Invariant Guard (Key Stability): proved that altering the idempotency key causes duplicate remote debits, demonstrating that `HC-IDEMPOTENCY` is strictly required.
  5. Negative Invariant Guard (Restart Recovery): proved that without startup recovery, in-flight operations would remain permanently blocked in `processing`.
- All checks verified (0 format issues, 0 analyze issues, 301/301 tests passing).
- Phase 3 is now COMPLETE!

### Next Steps:
1. Commit, push `feature/T-SYNC-005-kernel-verification`, open PR, squash-merge into `main`.
2. Checkout `main`, pull latest.
3. Begin Phase 4 (Design System & App Shell) with `T-DS-001 — Implement design tokens, theme, font and icons`.

