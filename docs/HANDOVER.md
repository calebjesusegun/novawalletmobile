# NovaWallet Handover

**Status:** Phase 0 in progress — T-BASE-002 completed on branch chore/T-BASE-002-linting-tests  
**Primary next task:** `T-BASE-003 — Add CI verification`  
**Current branch:** `chore/T-BASE-002-linting-tests`  
**Latest commit:** `a5300c2`  
**Planning baseline commit:** `2bb6f8b`

This document is the operational handover for Claude Code, Codex, Antigravity, or another coding agent taking over NovaWallet implementation.

---

## 1. Current State

The assessment, approved flows, design exports, architecture, implementation plan, design system, traceability, engineering rules, workflow, and executable task backlog have been reviewed and finalized.

Flutter implementation has **not** started yet.

Repository assembly is complete:
- Git initialized on branch `main`.
- Planning baseline committed (`2bb6f8b`).
- Core engineering documentation organized under `docs/`.
- Screen index organized under `docs/design/SCREEN_INDEX.md`.
- Approved design PDFs organized under `docs/design/pdf/`.
- Assessment brief safely isolated under `docs_internal/assessment/` and ignored by `.gitignore`.
- Files moved/renamed:
  - `ARCHITECTURE.md` -> `docs/ARCHITECTURE.md`
  - `IMPLEMENTATION_PLAN.md` -> `docs/IMPLEMENTATION_PLAN.md`
  - `REQUIREMENTS_TRACEABILITY.md` -> `docs/REQUIREMENTS_TRACEABILITY.md`
  - `DESIGN_SYSTEM.md` -> `docs/DESIGN_SYSTEM.md`
  - `DEFINITION_OF_DONE.md` -> `docs/DEFINITION_OF_DONE.md`
  - `GIT_WORKFLOW.md` -> `docs/GIT_WORKFLOW.md`
  - `AGENT_WORKFLOW.md` -> `docs/AGENT_WORKFLOW.md`
  - `TASKS.md` -> `docs/TASKS.md`
  - `HANDOVER.md` -> `docs/HANDOVER.md`
  - `SCREEN_INDEX.md` -> `docs/design/SCREEN_INDEX.md`
  - `Doc1_TakeHome_Frontend_Flutter.pdf` -> `docs_internal/assessment/Doc1_TakeHome_Frontend_Flutter.pdf`
  - Design PDFs (`Wallet.pdf`, `Send Money.pdf`, `NovaSave.pdf`, `Flow 1-6.pdf`, `NovaWallet Design Components.pdf`, `NovaWallet Style Guide.pdf`) -> `docs/design/pdf/`
- Unresolved repository setup issues: None.
- Next task: `T-BASE-001 — Bootstrap Flutter project`.

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
2. `docs/TASKS.md` — `T-BASE-001`
3. `docs/ARCHITECTURE.md`
4. `docs/IMPLEMENTATION_PLAN.md` — Phase 0
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

## 8. First Implementation Task

Start with:

```text
T-BASE-001 — Bootstrap Flutter project
```

Goal:

- create the Flutter project in the existing repository root;
- record actual Flutter/Dart versions;
- add only the approved baseline dependencies needed for Phase 0;
- configure Plus Jakarta Sans assets;
- keep current project documentation intact;
- do not implement product features yet.

Before editing:

```bash
git status
git branch --show-current
git log -5 --oneline
```

Then create/use the task branch according to `docs/GIT_WORKFLOW.md`.

---

## 9. Do Not Do Yet

During `T-BASE-001`:

- do not build Wallet screens;
- do not build Send Money;
- do not build NovaSave;
- do not implement sync;
- do not create Drift schemas yet unless the task is explicitly expanded;
- do not add Dio;
- do not implement stretch goals;
- do not redesign the approved architecture;
- do not change the design-source hierarchy.

---

## 10. Verification for the First Task

The task must leave the repository able to run:

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

## 13. Next Action

`T-BASE-002 — Configure linting and project test layout` is complete on branch `chore/T-BASE-002-linting-tests`.

### Completed Work:
- Enabled strict analyzer language checks (`strict-casts: true`, `strict-inference: true`, `strict-raw-types: true`) in `analysis_options.yaml`.
- Configured comprehensive recommended linter rules in `analysis_options.yaml` (including `unawaited_futures`, `prefer_const_*`, `avoid_print`, `avoid_relative_lib_imports`, `always_use_package_imports`, `cancel_subscriptions`, `close_sinks`, `directives_ordering`, `prefer_final_locals`, `prefer_single_quotes`, etc.).
- Added `integration_test: sdk: flutter` to `dev_dependencies` in `pubspec.yaml`.
- Scaffolded project test layout mirroring the approved architecture:
  - `test/core/core_layout_test.dart`
  - `test/features/features_layout_test.dart`
  - `test/sync/sync_layout_test.dart`
  - `test/fake_backend/fake_backend_layout_test.dart`
  - `integration_test/app_test.dart` (baseline smoke integration test)
  - `test_driver/integration_test.dart` (integration test driver)
- Ran and verified:
  - `dart format --output=none --set-exit-if-changed .` (8 files formatted, 0 changed)
  - `flutter analyze` (0 issues found)
  - `flutter test` (5 tests passed, 0 failures)

### Next Task:
`T-BASE-003 — Add CI verification` as defined in `docs/TASKS.md`.
