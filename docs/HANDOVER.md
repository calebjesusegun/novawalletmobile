# NovaWallet Handover

**Status:** T-SND-001 (Implement recipient entry, validation and fake resolution) COMPLETE on `feat/snd-recipient-entry` — Ready to merge into `main`  
**Primary next task:** `T-SND-002 — Implement amount entry and balance validation` (Phase 6 — Send Money)  
**Current branch:** `feat/snd-recipient-entry`  
**Latest commit on main:** `be83371`  
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

Phase 6 (Send Money) In Progress:
- `T-SND-001` (Implement recipient entry, validation and fake resolution) is COMPLETE on `feat/snd-recipient-entry`:
  - `Recipient` domain entity and `RecipientDirectory` contract (`lib/features/send_money/domain/`).
  - `FakeRecipientDirectory` (`lib/features/send_money/data/`) with `0123456789` -> `John Doe` fixture.
  - `RecipientEntryController` & `RecipientEntryState` (`lib/features/send_money/presentation/controllers/`) managing typing, real-time validation, empty field detection, length validation, and auto-resolution.
  - `ResolvedRecipientCard` (`lib/features/send_money/presentation/widgets/`) displaying resolved recipient details with check indicator and clear action.
  - `RecipientEntryScreen` (`lib/features/send_money/presentation/screens/`) hosting `AppTextField` and disabled-by-default `AppButton('Continue')` that enables only when resolved.
  - Connected `RecipientEntryScreen` into `SendMoneyShellTab` in `lib/app/app.dart`.
  - Authored 28 unit and widget tests across `test/features/send_money/`.
  - Full suite passes: 416/416 tests passing, 0 analyzer issues, clean formatting.

---

## 8. Current Execution Task
 
Current Task:
```text
T-SND-001 (Implement recipient entry, validation and fake resolution) COMPLETE on feat/snd-recipient-entry
```

Next Task:
```text
T-SND-002 — Implement amount entry and balance validation (Phase 6 — Send Money)
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
 
`T-WAL-004` is fully completed on `feat/wallet-loading-empty-detail`. All 388 tests pass, analyzer clean, formatting checked.
 
### Next Steps:
1. Merge `feat/wallet-loading-empty-detail` into `main`.
2. Proceed to Phase 6: `T-SND-001 — Implement recipient entry, validation and fake resolution`.



