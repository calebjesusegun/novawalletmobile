# NovaWallet Handover

**Status:** Phase 1 in progress — T-ID-001 implemented on feature branch  
**Primary next task:** `T-OP-001 — Define financial operation model and state transitions`  
**Current branch:** `feature/T-ID-001-identities`  
**Latest commit on main:** `55af79d`  
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
T-ID-001 — Implement stable operation and idempotency identities (complete on branch, ready for review/merge)
```

Next Task:
```text
T-OP-001 — Define financial operation model and state transitions
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
 
`T-ID-001 — Implement stable operation and idempotency identities` is complete and verified on branch `feature/T-ID-001-identities`.
 
### Completed Work (T-ID-001):
- Implemented `Uuid` utility in `lib/core/ids/uuid.dart` providing zero-dependency RFC 4122 version 4 cryptographically secure UUID generation (`Uuid.v4([Random? random])`) and validation (`isValid`, `isValidV4`, `isGeneralUuid`).
- Implemented `OperationId` domain value object in `lib/core/ids/operation_id.dart` representing a stable local durable identity for logical financial actions per HC-IDEMPOTENCY.
- Implemented `IdempotencyKey` domain value object in `lib/core/ids/idempotency_key.dart` representing a stable remote deduplication identity for delivery attempts per HC-IDEMPOTENCY and HC-EXACTLY-ONCE-EFFECT.
- Differentiated `OperationId` and `IdempotencyKey` by type, preventing accidental cross-assignment and ensuring distinct hash codes and non-equality even with identical underlying strings.
- Implemented deterministic key derivation via `IdempotencyKey.fromOperationId(operationId, {String? prefix})`.
- Enforced domain invariants across both identities: non-empty string, no leading/trailing/internal whitespace, allowed character set (`[a-zA-Z0-9_\-\.:]`), and maximum length of 255 characters with descriptive `ArgumentError` exceptions.
- Canonicalized RFC 4122 UUID representations to lowercase across both identity objects to guarantee casing consistency in hash sets, comparisons, and persistence.
- Created barrel export in `lib/core/ids/ids.dart`.
- Preserved strict architectural boundaries: untouched sync queues, UI screens, or fake backend.
- Authored 52 unit tests across `test/core/ids/uuid_test.dart`, `test/core/ids/operation_id_test.dart`, and `test/core/ids/idempotency_key_test.dart` verifying all invariants, retry stability, reload recovery, type differentiation, and RFC 4122 compliance (total project tests increased from 81 to 133).
- Updated `docs/REQUIREMENTS_TRACEABILITY.md` (`SYNC-006` marked DONE; `ASM-006`, `ASM-013`, `SND-010`, `NSV-012`, `SYNC-007` updated to IN_PROGRESS), `docs/TASKS.md` (T-ID-001 checked off), and `AI_USAGE.md` (recorded Prompt 8).
- Ran and verified local checks:
  - `flutter test test/core/ids/` (52/52 tests passed)
  - `dart format --output=none --set-exit-if-changed .` (21 files formatted, 0 changed)
  - `flutter analyze` (0 issues found)
  - `flutter test` (133 tests passed, 0 failures)

### Next Task:
`T-OP-001 — Define financial operation model and state transitions` as defined in `docs/TASKS.md`.
