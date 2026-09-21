# NovaWallet Handover

**Status:** Phase 1 in progress — T-MNY-002 merged into main  
**Primary next task:** `T-ID-001 — Implement stable operation and idempotency identities`  
**Current branch:** `main`  
**Latest commit:** `012db7f`  
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

Phase 1 (Money, Identity & Core Operation Model) is in progress:
- `T-MNY-001` (integer-kobo `Money` value object) is complete and merged into `main` (`ad871bb`).
- `T-MNY-002` (exact savings-progress calculation) is implemented and verified on branch `feature/T-MNY-002-savings-progress`.
- Next task: `T-ID-001 — Implement stable operation and idempotency identities`.

---

## 2. Source of Truth

Use this order when resolving conflicts:

1. Original assessment brief
2. Detailed approved screen-flow documents
3. Approved design exports / screenshots
4. Current repository code
5. Project engineering documentation
6. This handover / current task context
7. Previous agent reasoning
8. General engineering assumptions

Do not invent behavior when authoritative material is silent.

---

## 3. Read First

Before changing code, read:

1. `AGENTS.md`
2. `docs/TASKS.md` — target task
3. `docs/ARCHITECTURE.md`
4. `docs/IMPLEMENTATION_PLAN.md`
5. `docs/REQUIREMENTS_TRACEABILITY.md`
6. `docs/AGENT_WORKFLOW.md`
7. `docs/GIT_WORKFLOW.md`
8. this `docs/HANDOVER.md`

For UI tasks later, also read:

- `docs/DESIGN_SYSTEM.md`
- `docs/design/SCREEN_INDEX.md`
- the exact referenced PDF(s)

---

## 4. Locked Decisions

The following decisions have already been reviewed against the assessment and should not be reopened casually.

### Money

- Financial values use integer kobo in domain/data logic.
- Do not use `double` for money.
- Naira formatting happens from integer kobo.

### Offline durability

- Send and Contribution intents must be durably persisted before the UI reports them as safely saved.
- Pending operations must survive an app restart.

### Idempotency / duplicate safety

- Each logical Send or Contribution has one stable operation ID.
- Each logical operation has one stable idempotency key.
- Retries reuse the same idempotency key.
- The fake remote must deduplicate repeated delivery.
- The target guarantee is one financial effect even when delivery is retried.

### State separation

Keep these concerns separate:

```text
ConnectivityStatus
- online
- offline

SyncStatus
- idle
- syncing
- failed

OperationStatus
- pending
- processing
- completed
- failed
```

### Retry

- No uncontrolled background retry loop.
- Retry is event-triggered (for example reconnect, app lifecycle trigger, or explicit user retry).
- Recoverable sync failure must retain saved user intent.

### Backend

- No real backend is provided.
- Use an in-process fake remote behind an interface.
- Dio/HTTP is not part of the baseline and should not be added unless a concrete need emerges.

### State management / persistence

- Riverpod is the approved state-management / dependency-injection direction.
- Drift / SQLite is the approved durable persistence direction.

### Sync ownership

- Synchronization is shared infrastructure.
- Do not build independent sync loops inside Send Money and NovaSave.

### Design

- Approved PDFs are authoritative.
- `docs/design/SCREEN_INDEX.md` maps implementation states to those PDFs.
- PNG crops are optional implementation aids only.
- Visual verification happens during UI tasks, not only at the end.

---

## 5. Repository Target

The intended repository layout is:

```text
novawalletmobile/
├── README.md
├── AGENTS.md
├── AI_USAGE.md
├── pubspec.yaml
├── analysis_options.yaml
│
├── assets/
│   └── fonts/
│
├── lib/
│   ├── app/
│   ├── core/
│   ├── design_system/
│   ├── fake_backend/
│   ├── sync/
│   ├── features/
│   │   ├── wallet/
│   │   ├── send_money/
│   │   └── novasave/
│   └── main.dart
│
├── test/
├── integration_test/
│
└── docs/
    ├── ARCHITECTURE.md
    ├── IMPLEMENTATION_PLAN.md
    ├── REQUIREMENTS_TRACEABILITY.md
    ├── DESIGN_SYSTEM.md
    ├── DEFINITION_OF_DONE.md
    ├── GIT_WORKFLOW.md
    ├── AGENT_WORKFLOW.md
    ├── TASKS.md
    ├── HANDOVER.md
    └── design/
        ├── SCREEN_INDEX.md
        ├── pdf/
        └── references/
```

Do **not** manually pre-create every `lib/` subdirectory before Flutter bootstrap. Create them as implementation tasks require.

---

## 6. Design Files

Expected clean repository filenames under `docs/design/pdf/`:

```text
Wallet.pdf
Send Money.pdf
NovaSave.pdf
Flow 1 Successful Send.pdf
Flow 2 Offline Send.pdf
Flow 3 Offline Send and Reconnect.pdf
Flow 4 Create Savings Goal.pdf
Flow 5 Successful Contribution.pdf
Flow 6 Offline Contribution and Reconnect.pdf
NovaWallet Design Components.pdf
NovaWallet Style Guide.pdf
```

The original assessment brief should remain local/private if its distribution marking requires it. Do not publish restricted hiring material accidentally.

---

## 7. Current Open Decision

One product-policy item remains intentionally unresolved:

> How should amount validation behave when multiple outgoing operations are queued against one stale cached confirmed balance?

This is tracked in `docs/TASKS.md` as `T-DOM-001`.

Do not invent a hidden policy before that task is completed.

---

## 8. Current Execution Task

Current Task:
```text
T-MNY-002 — Implement exact savings-progress calculation (complete on branch, ready for review/merge)
```

Next Task:
```text
T-ID-001 — Implement stable operation and idempotency identities
```

---

## 9. Scope Control

During Phase 1:
- focus strictly on core domain models, exact money math, and stable identities;
- do not build feature UI screens prematurely;
- do not implement sync loops or Drift persistence schemas until their respective tasks;
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

## 11. AI Usage

`AI_USAGE.md` is a live assessment artifact.

Update it only with real examples from the project:

- meaningful prompts;
- useful results;
- actual risky/incorrect AI output;
- how it was caught and corrected.

Do not fabricate examples.

---

## 12. Handover Discipline

At the end of a work session or when another tool takes over:

1. leave the branch in a clear state;
2. commit/push where appropriate;
3. update this file with:
   - current branch;
   - current task;
   - completed work;
   - files changed;
   - commands run;
   - current failures/blockers;
   - decisions made;
   - exact next steps.

If this handover and Git disagree, trust Git.

---

### 13. Next Action
 
`T-MNY-002 — Implement exact savings-progress calculation` is complete and merged into `main` via PR #5 (`012db7f`).
 
### Completed Work (T-MNY-002):
- Implemented `SavingsProgress` domain calculation model in `lib/features/novasave/domain/savings_progress.dart` backed strictly by integer kobo via `Money` per HC-MONEY.
- Implemented `SavingsGoal` domain entity in `lib/features/novasave/domain/savings_goal.dart` per `docs/ARCHITECTURE.md` §8.2 with derived progress and remaining amount.
- Enforced exact integer basis points calculations (`10000 bps = 100%`) using intermediate `BigInt` arithmetic (`savedKobo * 10000 ~/ targetKobo`), eliminating floating-point rounding errors and guarding against 64-bit integer multiplication overflow on large balances.
- Implemented exact remaining amount calculation (`targetAmount - savedAmount`), guaranteeing that over-saving returns `Money.zero()` (never negative balance), and providing `excessAmount` to represent savings beyond target.
- Supported capped progress (0–100% percentage, 0–10,000 basis points) and arbitrary-precision uncapped metric (`uncappedBasisPoints` as `BigInt`), with flags `isGoalReached` and `isOverTarget`.
- Implemented pure integer string formatting for progress percentages (`formatPercentage()`).
- Provided an explicit UI presentation boundary converter (`toProgressFraction()`) strictly returning values within `[0.0, 1.0]` for Flutter progress indicators, keeping domain arithmetic exact and integer-based.
- Handled all domain invariants and edge cases:
  - Non-positive target amounts rejected with `ArgumentError`.
  - Negative saved amounts rejected with `ArgumentError`.
  - Negative contribution attempts rejected with `ArgumentError`.
  - Zero contribution returns unchanged progress state.
  - Exceeding target caps progress to 100% and flags over-achievement without negative remaining balance.
- Authored 29 unit tests across `test/features/novasave/savings_progress_test.dart` and `test/features/novasave/savings_goal_test.dart` verifying all acceptance criteria, edge cases, basis points precision, 64-bit bounds, and extreme ratio (`maxKobo / 1 kobo`) exactness (total project tests increased from 52 to 81).
- Maintained strict architectural boundaries: untouched UI screens, sync engine, and database persistence schemas.
- Updated `docs/REQUIREMENTS_TRACEABILITY.md` (MNY-003 marked DONE; ASM-008, ASM-014, NSV-008, NSV-009, NSV-014 updated to IN_PROGRESS), `docs/TASKS.md` (T-MNY-002 checked off), and `AI_USAGE.md` (recorded Prompt 7 and AI-RISK-003).
- Ran and verified local checks:
  - `flutter test test/features/novasave/` (29/29 tests passed)
  - `dart format --output=none --set-exit-if-changed .` (14 files formatted, 0 changed)
  - `flutter analyze` (0 issues found)
  - `flutter test` (81 tests passed, 0 failures)

### Next Task:
`T-ID-001 — Implement stable operation and idempotency identities` as defined in `docs/TASKS.md`.
