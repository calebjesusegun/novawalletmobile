# NovaWallet Handover

**Status:** Task `T-TST-003` (App-Level Offline Queue → Restart → Reconnect Integration Test) COMPLETE  
**Primary next task:** Task `T-TST-004` — Add high-value sync failure regression matrix  
**Current branch:** `test/T-TST-003-offline-restart-sync`  
**Latest commit on main:** `83f4a6c` (PR #29 — `T-TST-002` NovaSave Contribution Widgets & Seeder)  
**Planning baseline commit:** `2bb6f8b`

This document is the operational handover for Claude Code, Codex, Antigravity, or another coding agent taking over NovaWallet implementation.

---

## 1. Current State

The assessment, approved flows, design exports, architecture, implementation plan, design system, traceability, engineering rules, workflow, and executable task backlog have been reviewed and finalized.

Phase 0 through Phase 10 are COMPLETE and merged into `main`.

Phase 11 (Mandatory Assessment Testing & Failure Matrix):
- `T-TST-001` (Send Money widget journey coverage):
  - Covered 5 complete journeys in `send_money_flow_test.dart` (PR #28 merged).
- `T-TST-002` (NovaSave contribution widget journey coverage):
  - Covered 5 complete journeys in `test/features/novasave/presentation/novasave_contribution_flow_test.dart` (PR #29 merged).
  - Database cold start demo seeding implemented via idempotent `DatabaseSeeder`.
- `T-TST-003` (App-level offline queue → restart → reconnect integration test):
  - Authored `test/app/app_offline_restart_sync_test.dart` and `integration_test/offline_queue_restart_sync_test.dart`.
  - Exercises full 11-step journey:
    1. Cold App Launch on persistent SQLite file while OFFLINE (seeded with `₦125,450.00`).
    2. Recipient Entry & resolution (`0123456789` → `John Doe`, NovaBank).
    3. Amount Entry (`₦10,000.00`).
    4. Offline Transfer Confirmation with secure queuing notification.
    5. Pending Result Screen (`UI-SND-09` / `NSV-017`).
    6. Return to Wallet: Headline balance remains `₦125,450.00` (`HC-MONEY`), pending activity displayed.
    7. Process kill simulation: Database closed, Riverpod container disposed.
    8. Process restart on same SQLite file: Pending operation restored from disk (`HC-OFFLINE-DURABILITY`), remote untouched.
    9. Network reconnection: Centralized `SyncCoordinator` claims and executes pending transfer.
    10. Settlement: Pending queue cleared, remote balance debited to `₦115,450.00` exactly once (`HC-EXACTLY-ONCE-EFFECT`), local wallet balance updated.
    11. Replay deduplication: Subsequent sync runs trigger 0 remote operations, remote balance preserved (`HC-IDEMPOTENCY`).
  - Verified on Android emulator (`emulator-5554`) and Flutter test engine.

---

## 2. Current Execution Task
 
Current Task:
```text
T-TST-003 (App-Level Offline Queue → Restart → Reconnect Integration Test) COMPLETE on test/T-TST-003-offline-restart-sync
```

Next Task:
```text
T-TST-004 — Add high-value sync failure regression matrix on test/T-TST-004-sync-failure-matrix
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

Current test suite status: **564 / 564 tests passing**, analyzer clean, 0 formatting errors.

---

## 5. Next Steps

1. Commit and push `test/T-TST-003-offline-restart-sync`.
2. Open Pull Request to merge `test/T-TST-003-offline-restart-sync` into `main`.
3. Merge PR into `main` via `gh pr merge --squash --delete-branch`.
4. Switch to `main`, pull latest, and branch `test/T-TST-004-sync-failure-matrix` for `T-TST-004`.
