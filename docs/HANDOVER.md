# NovaWallet Handover

**Status:** Phase 7 (NovaSave Goal Creation) IN PROGRESS — `T-NSV-001` (Implement goal list and empty state) COMPLETE and verified  
**Primary next task:** `T-NSV-002 — Implement create-goal form, validation and date picker` (Phase 7 — NovaSave Goal Creation)  
**Current branch:** `feat/nsv-goal-list-empty-state`  
**Latest commit on main:** `dab85c1`  
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
- `T-SND-001` (Implement recipient entry, validation and fake resolution) is COMPLETE and merged into `main` (`1bf0f7a`).
- `T-SND-002` (Implement amount entry and balance validation) is COMPLETE and merged into `main` (`ab1e769`).
- `T-SND-003` (Implement confirmation and operation creation) is COMPLETE and merged into `main` (`051cffe`).
- `T-SND-004` (Implement online processing, success and immediate failure) is COMPLETE and merged into `main` (`302a316`).
- `T-SND-005` (Implement pending, reconnect and sync-failure Send states) is COMPLETE on `feat/snd-offline-pending-reconnect`:
  - `AppStepProgress` component added to design system (`lib/design_system/components/progress/app_step_progress.dart`).
  - `TransferResultScreen` extended to support:
    - Offline Transfer Pending (`UI-SND-15` / `SND-015`, `SND-016`).
    - Reconnect Processing (`UI-SND-16` / `SND-017`).
    - Reconnect Success (`UI-SND-17` / `SND-018`).
    - Recoverable Sync Failure with idempotent retry (`UI-SND-18` / `SND-019`, `SND-020`).
  - `SendMoneyFlowScreen` updated to track offline submission.
  - 11 widget tests in `transfer_result_screen_test.dart` (70 Send Money tests, 459 repo tests passing).

Phase 7 (NovaSave Goal Creation) in progress:
- `T-NSV-001` (Implement goal list and empty state) is COMPLETE on `feat/nsv-goal-list-empty-state`:
  - `savingsGoalsStreamProvider` exposed in `lib/features/novasave/data/novasave_providers.dart`.
  - `GoalCard` implemented in `lib/features/novasave/presentation/widgets/goal_card.dart` (`UI-NSV-01`, `UI-NSV-02`).
  - `GoalsListScreen` implemented in `lib/features/novasave/presentation/screens/goals_list_screen.dart` (`UI-NSV-01`, `UI-NSV-02`, `UI-NSV-03`).
  - `NovaSaveShellTab` in `lib/app/app.dart` wired directly to `GoalsListScreen`.
  - 5 widget tests in `test/features/novasave/presentation/goals_list_screen_test.dart` (464 total repo tests passing).

---

## 8. Current Execution Task
 
Current Task:
```text
T-NSV-001 (Implement goal list and empty state) COMPLETE on feat/nsv-goal-list-empty-state
```

Next Task:
```text
T-NSV-002 — Implement create-goal form, validation and date picker (Phase 7 — NovaSave Goal Creation)
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
 
`T-SND-004` is fully completed on `feat/snd-online-processing-results`. All 454 tests pass, analyzer clean, formatting checked.
 
### Next Steps:
1. Merge `feat/snd-online-processing-results` into `main`.
2. Proceed to `T-SND-005 — Implement pending, reconnect and sync-failure Send states`.



