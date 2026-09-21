# AGENTS.md

## NovaWallet Engineering Agent Instructions

This file contains the stable rules every coding agent must follow when working on NovaWallet. It is intentionally short enough to reread at the start of every task and strict enough to prevent unsafe or out-of-scope implementation choices.

Temporary implementation state belongs in `HANDOVER.md`. Executable work items belong in `docs/TASKS.md`. Architecture detail belongs in `docs/ARCHITECTURE.md`.

---

## 1. Project Objective

NovaWallet is a Flutter take-home assessment implementing three product areas:

- Wallet
- Send Money
- NovaSave

The most important product constraint is that a money-moving action started during unreliable connectivity must not be lost and must not create a duplicate financial effect.

The implementation must prioritize:

1. assessment compliance;
2. money correctness;
3. durable offline behavior;
4. duplicate-safe synchronization;
5. accessibility and performance;
6. close adherence to the supplied design states;
7. maintainable, testable Flutter code.

---

## 2. Source of Truth

When sources disagree, use this order:

1. Original assessment / assignment brief
2. Detailed requirements and approved screen flows
3. Approved design exports and screenshots
4. Current repository code and tests
5. Project engineering documentation
6. `docs/TASKS.md` and `HANDOVER.md` for current execution context
7. Previous agent/conversation reasoning
8. General engineering assumptions

Rules:

- Do not preserve an old documented decision when a higher-priority source contradicts it.
- Do not silently reinterpret a requirement.
- If evidence is genuinely missing, record: `Not supported by the supplied evidence — TO VERIFY.`
- Prototype-only interactions must not be mistaken for production requirements. For example, a design tap used to simulate reconnection does not replace real connectivity handling.

---

## 3. Hard Constraints

These are non-negotiable. Treat violations as blocking defects.

### HC-MONEY — Money is integer kobo

- Monetary values in domain and data logic MUST use integer kobo.
- Do not use `double` or floating-point values for balances, transfers, contributions, totals, or progress calculations derived from money.
- Formatting to Naira is a presentation concern.
- Arithmetic must remain exact.

### HC-OFFLINE-DURABILITY — User intent must survive connectivity loss

- If the user confirms Send or Contribution while offline, the operation MUST be durably persisted before the UI reports it as safely saved.
- A queued operation MUST survive app restart.
- Never silently discard a pending operation.

### HC-IDEMPOTENCY — One logical action, one stable key

- Each user-initiated Send or Contribution MUST receive one stable operation identity and one stable idempotency key.
- A retry of the same logical operation MUST reuse the same idempotency key.
- Do not generate a new key merely because a network attempt failed, the app restarted, or the user tapped Retry.
- The fake remote implementation MUST deduplicate by idempotency key so repeated delivery cannot produce a second financial effect.

### HC-EXACTLY-ONCE-EFFECT — Delivery may repeat; financial effect must not

The client may need to deliver an operation more than once after uncertainty, but the system must produce at most one financial effect for the same logical operation.

The implementation must safely handle at least:

- app closes after local save but before send;
- request is accepted but response is lost;
- app closes after remote success but before local completion is persisted;
- reconnect and app-resume triggers happen close together;
- user taps Retry repeatedly.

### HC-SYNC — Synchronization is centralized

- Send Money and NovaSave MUST NOT implement independent ad-hoc replay loops.
- A shared synchronization mechanism owns pending-operation processing.
- Processing of a single operation must be serialized/claimed so concurrent triggers cannot submit it twice at the same time.
- Sync failure must not automatically mean the underlying financial operation is terminally failed.

### HC-RETRY — No silent retry loop

- Do not run an unbounded or hidden retry loop.
- Sync is triggered by deliberate events such as reconnect, supported lifecycle events, app start/resume, or user Retry.
- A failed attempt must remain observable and recoverable according to the design.

### HC-STATE-SEPARATION — Connectivity, sync, and operation state are distinct

Do not model all combinations in one giant enum.

Conceptually keep separate dimensions:

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

A recoverable sync failure may be represented as a pending operation with sync error metadata rather than a terminal operation failure.

### HC-ACCESSIBILITY — Accessibility is required

- Key interactive elements need appropriate Flutter `Semantics`.
- Custom controls must remain understandable to screen readers.
- System font scaling must be respected.
- Do not hard-code layouts that break at larger text scales.

### HC-PERFORMANCE — Large lists must be lazy

- Recent-transactions lists MUST use `ListView.builder` or an equivalent lazy-building approach.
- Do not eagerly build an unbounded transaction list.

### HC-SECURITY — Do not store sensitive mock data in plain preferences

- If the implementation introduces mock auth tokens or similarly sensitive values, do not store them in plain `SharedPreferences`.
- Use secure storage where sensitive local storage is actually required.
- Do not add sensitive mock data merely to satisfy this rule.

### HC-AI-EVIDENCE — AI usage must be documented truthfully

- Maintain `AI_USAGE.md` during implementation.
- Record actual tools used, actual prompts, outcomes, and at least one real case where AI output was wrong or risky and how it was corrected.
- Do not fabricate an AI mistake after the fact.

---

## 4. Product Behavior

### Wallet

Wallet is responsible for presenting:

- available balance;
- recent transactions;
- pull-to-refresh;
- loading/refreshing state;
- empty state;
- offline system messaging;
- pending transactions;
- processing/reconnection state;
- sync-failure presentation;
- transaction details.

Important design rule:

- A pending offline send does not make the headline balance look successfully debited before confirmation.

### Send Money

The required journey is:

```text
Recipient
  ↓
Amount
  ↓
Confirmation
  ↓
Processing / Pending
  ↓
Success / Failure / Retry
```

The supplied design also includes:

- empty recipient validation;
- invalid account validation;
- resolved recipient state;
- zero amount validation;
- insufficient-balance validation;
- offline confirmation;
- pending transfer;
- reconnection processing;
- sync failure with retained operation;
- manual retry.

Recipient resolution is fake/local for this assessment unless implementation evidence later establishes otherwise.

### NovaSave

NovaSave is responsible for:

- goals list;
- empty state;
- goal creation;
- name validation;
- target amount validation;
- future target-date validation;
- date picker;
- goal details;
- contribution entry;
- wallet-balance validation;
- confirmation;
- processing;
- success/failure;
- offline pending contribution;
- reconnect processing;
- sync failure/retry;
- progress bar and percentage.

Important design rule:

- A pending contribution must remain visibly pending and must not make the goal appear successfully progressed before confirmation.

---

## 5. Technology Baseline

Use only dependencies with a clear responsibility.

### Chosen baseline

- Flutter / Dart
- Riverpod for application state and dependency injection
- Drift / SQLite for durable structured local persistence
- Flutter unit/widget testing
- `integration_test` for critical end-to-end flows

### Allowed when justified

- `go_router` for navigation
- `connectivity_plus` or another injectable connectivity implementation
- `flutter_secure_storage` only if sensitive mock data is actually introduced
- code generation where it materially improves the implementation

### Not a default

- Dio / an HTTP stack
- generic REST DTO layers
- `json_serializable`
- background services

The assessment provides no real backend. The project owns the fake remote implementation. A real HTTP client must not be added merely to make the architecture look more production-like.

---

## 6. Architecture Rules

Use the architecture defined in `docs/ARCHITECTURE.md`.

Conceptually:

```text
Presentation
    ↓
Application / State
    ↓
Domain
    ↓
Repositories
    ↓
Data Sources
    ├── Local persistence
    └── Fake remote implementation
```

Rules:

- Widgets render state and dispatch user intent.
- Business rules do not live in widgets.
- Application/state code coordinates use cases.
- Domain code owns money rules, validation, entities, and operation semantics.
- Repositories hide persistence and fake-remote details.
- UI code must not know how queue rows are claimed, persisted, retried, or deduplicated.
- Sync is a shared subsystem, not feature-specific widget logic.

Target high-level structure:

```text
lib/
├── main.dart
├── app/
├── core/
│   ├── connectivity/
│   ├── errors/
│   ├── ids/
│   ├── money/
│   ├── persistence/
│   ├── time/
│   └── utils/
├── design_system/
├── sync/
├── fake_backend/
└── features/
    ├── wallet/
    ├── send_money/
    └── novasave/
```

Exact filenames may evolve. Responsibility boundaries may not be collapsed without an explicit architectural reason.

---

## 7. Fake Remote Rules

The fake backend exists to make the assessment's failure cases testable, not merely to return canned success values.

It should support the behaviors needed to prove correctness, including:

- stable idempotency-key handling;
- duplicate request deduplication;
- deterministic test control;
- simulated success and failure;
- the ability to reproduce uncertain delivery cases such as a lost response after remote acceptance.

Do not couple feature widgets directly to the fake backend.

Do not build a fake production banking platform beyond what is needed to verify the assessment.

---

## 8. Design System Rules

The supplied design system is authoritative for implementation details it defines.

Use centralized tokens/components for:

- colors;
- typography;
- spacing;
- radii;
- elevation;
- icons;
- buttons;
- fields;
- system notifications;
- statuses/results;
- cards/lists;
- progress;
- navigation;
- sheets;
- empty states.

Do not introduce arbitrary visual values where an approved token/component exists.

Do not collapse distinct approved states into one generic screen merely because they share similar layout.

Design fidelity must not override accessibility. Responsive text and Semantics are hard requirements from the assessment.

---

## 9. Validation and Business Rules

Implement only rules supported by the assessment/designs or clearly documented project assumptions.

Known supported examples include:

- amount must be greater than zero;
- transfer/contribution cannot exceed the applicable available wallet amount;
- savings-goal target amount must be greater than zero;
- savings-goal target date must be in the future;
- design examples show account-number validation and recipient resolution using fake data.

Do not invent transfer fees, daily limits, KYC journeys, USSD flows, NIBSS integration, real BVN/NIN handling, or other product scope not required by the assignment.

---

## 10. Testing Rules

The assessment explicitly requires:

- widget tests for Send Money;
- widget tests for the NovaSave contribution flow;
- at least one integration test covering offline queue → restart/reopen → reconnect → sync.

In addition, business-critical logic should have focused unit/data tests.

### Mandatory high-risk coverage

Tests must be capable of catching regressions in:

- integer-kobo arithmetic;
- operation creation;
- stable idempotency-key reuse;
- durable pending persistence;
- app-restart recovery;
- duplicate-trigger protection;
- lost-response recovery;
- retry behavior;
- sync failure retention;
- exactly-once financial effect.

### Widget coverage

Cover important states including:

- validation;
- processing;
- success;
- failure;
- offline;
- pending;
- reconnecting;
- sync failure where applicable.

### Accessibility/performance verification

Where relevant, test:

- meaningful Semantics;
- larger system font scale;
- lazy transaction-list construction.

Do not claim a critical behavior is complete without a test that could fail if that behavior regresses.

---

## 11. Required Verification Commands

Use the repository's actual commands. Until project-specific wrappers are intentionally added, use Flutter directly.

Baseline:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

When integration tests are configured:

```bash
flutter test integration_test
```

Rules:

- Run the narrowest relevant test during iteration.
- Run the complete required verification before a PR is considered ready.
- Do not invent commands such as `make check` unless the repository actually contains and documents them.

---

## 12. Change Discipline

Before implementing a task:

1. Read this file.
2. Read the task entry in `docs/TASKS.md`.
3. Read only the relevant architecture/requirements/design sections.
4. Confirm the branch and working tree.
5. Run the task's baseline verification command.

During implementation:

- implement one coherent task;
- keep the diff focused;
- add/update tests with the behavior;
- avoid unrelated refactors;
- do not alter shared dependencies or routing as a side effect;
- update traceability when the implemented requirement changes status;
- record meaningful AI usage/errors in `AI_USAGE.md`.

At task completion:

- run relevant checks;
- update documentation only where the code changed reality;
- update `HANDOVER.md` with current engineering state;
- commit focused changes.

---

## 13. Documentation Responsibilities

### `README.md`

The README describes the repository as it actually exists.

Do not write planned functionality in present tense.

### `docs/ARCHITECTURE.md`

Explains architecture and important design decisions.

### `docs/IMPLEMENTATION_PLAN.md`

Defines implementation phases and sequencing.

### `docs/REQUIREMENTS_TRACEABILITY.md`

Maps authoritative requirements to design evidence, implementation, tests, and status.

### `docs/DESIGN_SYSTEM.md`

Contains implementation-ready design tokens and component rules derived from the approved exports.

### `docs/DEFINITION_OF_DONE.md`

Defines completion criteria.

### `docs/TASKS.md`

Contains executable implementation tasks. Agents work from task entries, not broad prompts like "build NovaWallet".

### `AI_USAGE.md`

Contains truthful evidence of AI use during the assessment.

### `HANDOVER.md`

Contains current operational state only: branch/task, completed work, verification state, open issues, and next steps.

`HANDOVER.md` is not architectural authority. If it disagrees with code/git history, trust code/git and investigate.

---

## 14. Definition of Done

A feature is not done because its happy-path screen renders.

Before marking applicable work complete, verify:

- authoritative requirement implemented;
- monetary logic uses integer kobo;
- validation is correct;
- required design states are represented;
- offline intent is durable where applicable;
- restart recovery works where applicable;
- synchronization is duplicate-safe;
- retry does not create a second operation;
- accessibility requirements are met;
- performance constraints are met;
- tests cover the behavior;
- format/analyzer/tests pass;
- traceability is current;
- README/docs do not claim unimplemented behavior.

Use `docs/DEFINITION_OF_DONE.md` for the complete checklist.

---

## 15. Out of Scope Unless Explicitly Activated

Do not implement these merely because they would be realistic in production:

- real FirstBank/NIBSS integration;
- real authentication/KYC;
- USSD;
- production BVN/NIN handling;
- background sync service;
- database-at-rest encryption;
- transfer fees or daily limits;
- additional NovaPay modules;
- stretch goals before mandatory requirements are complete.

Optional assessment stretch goals may be considered only after mandatory functionality and verification are complete.

---

## 16. Stop Conditions

Stop and report instead of guessing when:

- a requested change conflicts with a higher-priority source of truth;
- a migration could destroy or corrupt pending operations;
- the proposed solution can produce duplicate financial effects;
- a dependency would materially change the agreed architecture;
- required design/assessment evidence is missing;
- the task expands beyond its stated scope;
- tests reveal an unresolved money or synchronization defect.

For unresolved evidence gaps, use:

> `Not supported by the supplied evidence — TO VERIFY.`
