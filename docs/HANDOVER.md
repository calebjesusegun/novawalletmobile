# NovaWallet Handover

**Status:** Phase 1 Remediations in Progress — PRs 1 and 2 merged into `main`; PR 3 ready for review and merge  
**Primary next task:** Merge PR 3 (`docs/T-DOM-fix-contracts-and-polish`), then proceed to Phase 2 (`T-DB-001`)  
**Current branch:** `docs/T-DOM-fix-contracts-and-polish`  
**Latest commit on main:** `2d0dc75`  
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
  - Remediation PR 3 (`docs/T-DOM-fix-contracts-and-polish`, in progress): Added `PayloadFormatException` and `schemaVersion: 1` to `OperationPayload`, documented atomic balance update contract in `ARCHITECTURE.md` §16, added acceptance criterion to `T-XF-001` in `TASKS.md`, and marked `MNY-006` as `DECISION / INFERRED` in `REQUIREMENTS_TRACEABILITY.md`.

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

## 7. Open Decisions (RESOLVED)

The previously open product-policy item regarding queued spendability has been resolved and implemented in `SpendableBalancePolicy` (`lib/sync/domain/spendable_balance_policy.dart`):

- Headline balance continues to reflect confirmed cached balance per design AD-09.
- Spendable balance = `max(0, confirmedBalance - sum(activePendingKobo))`.
- Outgoing entry flows validate against spendable balance.
- All Phase 1 open decisions are now resolved.

---

## 8. Current Execution Task
 
Current Task:
```text
Phase 1 Peer Review by Codex (all Phase 1 tasks T-MNY-001, T-MNY-002, T-ID-001, T-OP-001, T-DOM-001 complete)
```

Next Task:
```text
T-DB-001 — Configure Drift and pending-operation schema (start of Phase 2)
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

### 13. Next Action
 
`docs/T-DOM-fix-contracts-and-polish` is verified and ready to merge into `main`.
 
### Completed Work (Remediation PR 3):
- Implemented `PayloadFormatException` implementing `FormatException` and added `OperationPayload.currentSchemaVersion = 1` serialized in `toMap()` for migration safety.
- Made `fromMap()` strictly validate required keys and value types, throwing typed `PayloadFormatException` on invalid or missing data.
- Added comprehensive unit tests in `test/sync/domain/operation_payload_test.dart` verifying serialization with `schemaVersion` and rejection of malformed maps with `PayloadFormatException`.
- Documented the Atomic Balance Update Contract in `docs/ARCHITECTURE.md` §16 (atomic transaction when applying financial effect and completing operation to prevent spendable balance overspend spikes; fail-closed behavior on lost-response balance refreshes).
- Added explicit acceptance criterion to `T-XF-001` in `docs/TASKS.md` requiring this atomic transaction.
- Removed dangling self-referential sentence in `docs/ARCHITECTURE.md` §26.
- Updated `MNY-006` status in `docs/REQUIREMENTS_TRACEABILITY.md` to `DECISION / INFERRED` reflecting that the offline balance reservation policy was an engineering architectural decision rather than an explicit assessment specification.
- Ran and verified full test suite (191 tests passing, 0 analyzer issues, 0 formatting issues).

### Next Steps:
1. Commit, push `docs/T-DOM-fix-contracts-and-polish`, create PR, and squash-merge to `main`.
2. Checkout `main`, pull latest.
3. All Phase 1 tasks and all adversarial review remediations are complete and signed off.
4. Begin Phase 2 (`T-DB-001 — Configure Drift and pending-operation schema`) on a new feature branch `feature/T-DB-001-drift-persistence`.
