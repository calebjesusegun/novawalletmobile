# NovaWallet Handover

**Status:** Task `T-TST-001` (Send Money Widget Coverage) COMPLETE  
**Primary next task:** Task `T-TST-002` — Complete required NovaSave contribution widget coverage  
**Current branch:** `test/T-TST-001-send-money-widgets`  
**Latest commit on main:** `e92e96f` (PR #27 — `CurrencyAmountInputFormatter`)  
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

Phase 4 (Design System & App Shell) is COMPLETE and merged into `main` (`3e14dc7`).

Phase 5 (Wallet) is COMPLETE and merged into `main` (`be83371`).

Phase 6 (Send Money) is COMPLETE:
- `T-SND-001` through `T-SND-005` complete and verified on `main`.

Phase 7 (NovaSave Goal Creation) is COMPLETE:
- `T-NSV-001` (Implement goal list and empty state) is COMPLETE (`UI-NSV-01`, `UI-NSV-02`, `UI-NSV-03`).
- `T-NSV-002` (Implement create-goal form, validation and date picker) is COMPLETE (`UI-NSV-04`, `UI-NSV-05`, `UI-NSV-06`, `UI-NSV-07`).
- `T-NSV-003` (Implement goal details and progress) is COMPLETE (`UI-NSV-08`, `UI-NSV-18`).

Phase 8 (NovaSave Contribution) is COMPLETE:
- `T-NSC-001` through `T-NSC-004` complete and merged into `main`.

Phase 9 (Cross-Feature Consistency & Resilience) is COMPLETE and merged into `main` (`40860eb`, PR #25).

Phase 10 (Accessibility, Performance & Visual Reconciliation) is COMPLETE and merged into `main` (`d671f4e`, PR #26).

Amount Currency Formatter:
- Added `CurrencyAmountInputFormatter` and wired to `AppAmountField` (`e92e96f`, PR #27).

Phase 11 (Mandatory Assessment Testing & Failure Matrix):
- `T-TST-001` (Send Money widget journey coverage):
  - Covered 5 complete journeys in `send_money_flow_test.dart`:
    1. Navigation and back-navigation between Recipient and Amount screens.
    2. Flow-level validation blocking for invalid recipient, zero amount, and balance exceeding available funds.
    3. Full online journey to Success view, verifying tap on "Done" resets to `AppDestination.wallet`.
    4. Full offline journey with offline notification banner, enqueue in pending status, Pending view, and tap on "Back to wallet" resets to `AppDestination.wallet`.
    5. Online failure journey with Failed view, verifying tap on "Try Again" resets to retry.
  - Implemented synchronous listen-forward `StreamController` in `MockFlowOperationRepository` to prevent stream delivery races during Riverpod `StreamProvider` binding.
  - All 74 tests in `test/features/send_money/` pass.

---

## 2. Current Execution Task
 
Current Task:
```text
T-TST-001 (Send Money Widget Coverage) COMPLETE on test/T-TST-001-send-money-widgets
```

Next Task:
```text
T-TST-002 — Complete required NovaSave contribution widget coverage on test/T-TST-002-novasave-contribution-widgets
```

---

## 3. Scope Control

- Enforce integer-kobo money representation per `HC-MONEY`.
- Enforce exact-once financial effects per `HC-EXACTLY-ONCE-EFFECT` and `HC-IDEMPOTENCY`.
- Enforce `HC-STATE-SEPARATION` (connectivity, sync status, and operation status remain separate dimensions).
- Centralize all design tokens and do not introduce hardcoded values in feature widgets.
- Respect accessibility (`Semantics`, 2.0x font scaling) and performance (lazy list virtualization).

---

## 4. Required Verification

Every branch/task must satisfy:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Current test suite status: **554 / 554 tests passing**, analyzer clean, 0 formatting errors.

---

## 5. Next Steps

1. Commit and push `test/T-TST-001-send-money-widgets`.
2. Open Pull Request to merge `test/T-TST-001-send-money-widgets` into `main`.
3. Merge PR into `main` via `gh pr merge --squash --delete-branch`.
4. Switch to `main`, pull latest, and branch `test/T-TST-002-novasave-contribution-widgets` for `T-TST-002`.
