# NovaWallet Handover

**Status:** Phase 2 in Progress — T-DB-001, T-DB-002, and T-REMOTE-001 complete and verified; ready for PR and merge of T-REMOTE-001  
**Primary next task:** Merge PR for `feature/T-REMOTE-001-fake-remote`, then proceed to `T-REMOTE-002` (Add deterministic failure simulation)  
**Current branch:** `feature/T-REMOTE-001-fake-remote`  
**Latest commit on main:** `dd859f5`  
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
- `T-DB-001` (Configure Drift and pending-operation schema) is COMPLETE and merged (`128d4ed`).
- `T-DB-002` (Add local wallet, transaction and goal persistence) is COMPLETE and merged (`dd859f5`, PR #13).
- `T-REMOTE-001` (Implement idempotent fake remote) is COMPLETE on `feature/T-REMOTE-001-fake-remote`.

---

## 8. Current Execution Task
 
Current Task:
```text
T-REMOTE-001 — Implement idempotent fake remote (feature/T-REMOTE-001-fake-remote)
```

Next Task:
```text
T-REMOTE-002 — Add deterministic failure simulation
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
 
`feature/T-REMOTE-001-fake-remote` is verified and ready to merge into `main`.
 
### Completed Work (T-REMOTE-001):
- Implemented `RemoteApi` interface (`lib/fake_backend/remote_api.dart`) with `sendMoney`, `contribute`, `submitOperation`, `fetchWalletSnapshot`, and `fetchTransactions`.
- Implemented `RemoteOperationResult` and custom remote exceptions (`ConflictingIdempotencyKeyException`, `InsufficientRemoteFundsException`, `InvalidRemoteOperationException`).
- Implemented `RemoteIdempotencyRecord` with payload conflict verification (`matchesPayload`) per requirement SYNC-009.
- Implemented `RemoteIdempotencyLedger` interface with `InMemoryRemoteLedger` and `DriftRemoteLedger` backed by Drift tables (`RemoteIdempotencyTable`, `RemoteWalletStateTable`, `RemoteTransactionsTable`) respecting the persistence boundary in `docs/ARCHITECTURE.md` §11.4.
- Implemented `FakeRemoteApi` supporting deterministic injected clocks and reference generators, balance checking, and exact-once financial effects per HC-IDEMPOTENCY and HC-EXACTLY-ONCE-EFFECT.
- Authored 18 tests across `test/fake_backend/fake_remote_api_test.dart` and `test/fake_backend/drift_remote_ledger_test.dart`, verifying idempotency, duplicate request deduplication without double debit, payload conflict rejection across all payload fields, and restart survival with SQLite file reopen.
- Ran and verified full baseline checks (all 228 tests passing, 0 analyzer issues, 0 formatting issues).

### Next Steps:
1. Commit, push `feature/T-REMOTE-001-fake-remote`, open PR, squash-merge into `main`.
2. Checkout `main`, pull latest.
3. Begin `T-REMOTE-002 — Add deterministic failure simulation` on a new feature branch `feature/T-REMOTE-002-failure-simulation`.

