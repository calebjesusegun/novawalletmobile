# NovaWallet Implementation Plan

**Status:** Final pre-implementation baseline  
**Last updated:** 2026-09-20  
**Purpose:** Define the implementation order, phase boundaries, and exit criteria for the NovaWallet take-home assessment.

This document is deliberately a **phase plan**, not a task tracker. Concrete agent-sized work items will be generated in `docs/TASKS.md` after the planning documents are finalized.

The governing rules in `AGENTS.md` and the architecture in `docs/ARCHITECTURE.md` apply to every phase.

---

## 1. Objective

Build a polished Flutter application covering the required NovaPay journeys:

- Wallet
- Send Money
- NovaSave goal creation and contribution
- durable offline queueing and reconnect synchronization

The implementation must satisfy the assessment's highest-risk guarantees before visual polish or stretch work:

```text
Money remains exact
        +
Offline intent survives restart
        +
Repeated delivery cannot create a duplicate financial effect
        +
Required flows remain accessible and usable
```

The project must not become a production-banking simulation. There is no real backend; the repository owns a purpose-built fake remote implementation for the assessment.

---

## 2. Delivery Principles

### 2.1 Build the risky kernel before the full UI

The original plan placed the design system ahead of the money/offline infrastructure. The final plan reverses that priority.

Implement and prove the following first:

```text
Repository baseline
      ↓
Money + operation identity
      ↓
Durable persistence + fake-remote idempotency
      ↓
Sync + restart recovery
      ↓
Design system + app shell
      ↓
Product vertical slices
```

This reduces the chance of discovering a fundamental money or replay flaw after the screens are already built.

### 2.2 Build vertical feature slices after the kernel

After the high-risk foundations are proven, implement product areas as coherent journeys rather than as disconnected screens.

A feature slice should connect:

```text
Design state
    ↓
Presentation
    ↓
Application/state
    ↓
Domain rule
    ↓
Repository/data behavior
    ↓
Tests
```

### 2.3 Mandatory work comes before stretch work

Do not start optional stretch goals until:

- mandatory requirements are implemented;
- mandatory tests pass;
- accessibility/performance constraints are verified;
- required documentation is current;
- the app can demonstrate the offline path reliably.

### 2.4 Documentation must describe reality

During implementation:

- `README.md` describes what is actually implemented;
- `docs/ARCHITECTURE.md` defines the approved architecture;
- `docs/IMPLEMENTATION_PLAN.md` defines phase order;
- `docs/TASKS.md` defines executable work;
- `docs/REQUIREMENTS_TRACEABILITY.md` tracks requirement coverage;
- `AI_USAGE.md` records real AI usage as it happens;
- `HANDOVER.md` records current implementation state once coding begins.

### 2.5 Design references and visual QA

The approved PDF exports remain the authoritative visual source. Individual PNG exports are optional working derivatives and are generated only when they materially improve implementation or comparison.

Repository convention:

```text
docs/design/
├── pdf/                 approved design and flow PDFs
├── SCREEN_INDEX.md      state-to-source map used by tasks and reviewers
└── references/          optional/generated crops or reference PNGs as needed
```

Rules:

- Do not manually export every screen or component before implementation.
- Every UI task must cite one or more entries from `docs/design/SCREEN_INDEX.md`.
- Agents should inspect the referenced PDF first.
- If a PDF is awkward to compare because it contains many frames, generate only the relevant frame/crop into `docs/design/references/`; the PDF remains authoritative.
- Shared components are implemented from `docs/DESIGN_SYSTEM.md` plus the Style Guide and Design Components PDFs; they do not require a separate manual export of every component.
- Visual QA happens during each UI task, not only at the end of the project.
- Phase 10 is a final full-product reconciliation, not the first design comparison.
- Accessibility/font-scale verification is separate from pixel-fidelity verification. The canonical 1.0 text-scale capture is used for design comparison; enlarged text scales are tested for usability and layout resilience.
- If an agent runs in an environment that cannot access the repository design files, provide the exact relevant source PDF or derived reference image for that task rather than the entire design set.

Visual implementation loop:

```text
SCREEN_INDEX entry
      ↓
approved PDF / optional reference crop
      ↓
implement exact state
      ↓
run on canonical visual-QA device
      ↓
capture screenshot
      ↓
compare and correct material differences
      ↓
independent visual review where practical
```

The canonical emulator/device profile for visual QA is selected and recorded in Phase 4 after the Flutter project can run. Do not guess a viewport before the source frames and target runtime are inspected together.

---

## 3. Locked Technical Direction

The following are implementation baselines unless higher-priority source material later contradicts them.

### Required by the assessment

- Flutter / Dart
- integer-kobo monetary representation
- durable local queue for offline Send and Contribution actions
- queued actions survive app restart
- replay after reconnect without duplicate financial effect
- screen-reader semantics on key controls
- system font-scale support
- lazy recent-transactions list
- widget tests for Send Money and NovaSave contribution
- at least one integration test covering offline queue → restart/reconnect → synchronization
- `README.md`
- `AI_USAGE.md`
- declared Flutter/Dart target versions
- single-command app execution on a standard Flutter setup

### Chosen architecture

- Riverpod for application state and dependency injection
- Drift / SQLite for durable structured persistence
- shared top-level sync subsystem
- fake remote behind a narrow interface
- stable operation ID and idempotency key per logical Send/Contribution
- persisted fake-remote idempotency state
- event-triggered foreground synchronization
- confirmed balance/progress changes only after successful remote processing
- local persistence for NovaSave goal definitions/state

### Not baseline dependencies

Do not add these simply because they are common:

- Dio / generic HTTP stack
- generic REST DTO architecture
- `json_serializable`
- background services
- `SharedPreferences` for sensitive data

They may be introduced only when an actual implementation need justifies them.

---

# Phase 0 — Repository and Toolchain Baseline

## Goal

Create a clean, reproducible Flutter repository that all later work can safely build on.

## Work

- [ ] Inspect/bootstrap the Flutter project in the agreed repository structure.
- [ ] Select and record the targeted Flutter and Dart versions.
- [ ] Establish `pubspec.yaml` dependencies required by the approved baseline.
- [ ] Configure static analysis and linting.
- [ ] Establish unit/widget/integration test directories.
- [ ] Bundle and configure Plus Jakarta Sans.
- [ ] Establish CI for formatting, analysis, and tests.
- [ ] Confirm generated-code strategy for Drift.
- [ ] Confirm `.gitignore` rules for local/internal source material.
- [ ] Ensure `AI_USAGE.md` exists before coding-agent implementation begins.
- [ ] Ensure no unsupported network stack or production banking integration is introduced.

## Do not implement yet

- feature screens;
- Send Money logic;
- NovaSave contribution logic;
- sync engine;
- stretch goals.

## Exit criteria

From a clean checkout/environment, the baseline can run:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

and all applicable checks pass.

The targeted Flutter/Dart versions are documented.

---

# Phase 1 — Money, Identity, and Core Domain Primitives

## Goal

Establish the domain invariants that every money-moving feature depends on.

## Work

### Money

- [ ] Implement a `Money` value type backed by integer kobo.
- [ ] Implement exact addition/subtraction/comparison.
- [ ] Implement Naira display formatting at the presentation boundary.
- [ ] Ensure no authoritative monetary calculation uses floating point.
- [ ] Define exact progress calculation behavior for NovaSave.

Example invariant:

```text
12545000 kobo -> ₦125,450.00
```

### Identity

- [ ] Define stable local operation IDs.
- [ ] Define stable idempotency keys.
- [ ] Ensure idempotency identity is created once per logical operation.
- [ ] Ensure retry/restart cannot regenerate the key for the same operation.

### Core operation model

- [ ] Define operation type(s) for Send and Contribution.
- [ ] Define operation status.
- [ ] Define connectivity status separately.
- [ ] Define sync status separately.
- [ ] Define error/failure categories needed by the architecture.

### Test support

- [ ] Add deterministic ID/key generation seams where useful for tests.
- [ ] Add deterministic clock/time seams where useful for tests.

## Required tests

At minimum:

- [ ] exact kobo arithmetic;
- [ ] Naira formatting;
- [ ] comparison/validation boundaries;
- [ ] progress calculation;
- [ ] stable operation identity;
- [ ] stable idempotency identity across retries.

## Exit criteria

The project has a tested money/operation foundation with no feature UI dependency.

No `double` represents an authoritative wallet amount, transfer amount, contribution amount, goal target, or saved amount.

---

# Phase 2 — Durable Persistence and Fake Remote

## Goal

Create the persistence boundaries required to prove restart safety and idempotent remote behavior before building synchronization or UI.

## Local persistence

- [ ] Configure Drift/SQLite.
- [ ] Implement the operations table.
- [ ] Persist operation payload, type, stable ID, idempotency key, timestamps, status, and failure metadata required by the architecture.
- [ ] Implement deterministic pending-operation queries.
- [ ] Implement atomic/conditional operation claiming support.
- [ ] Implement operation completion/failure updates.
- [ ] Add goal persistence required by NovaSave.
- [ ] Add only the wallet/transaction cache persistence needed by the required offline experience.

## Fake remote

Implement a narrow fake remote interface such as:

```text
RemoteApi
- sendMoney(...)
- contribute(...)
- fetchWalletSnapshot(...)
```

The exact Dart API is an implementation detail.

The fake remote must:

- [ ] apply one financial effect for a new idempotency key;
- [ ] return the prior result for legitimate repeated delivery;
- [ ] reject conflicting reuse of an idempotency key with a different payload;
- [ ] persist enough idempotency/result state to survive the client restart scenarios being tested;
- [ ] support deterministic success/failure/latency injection for tests;
- [ ] support an uncertain-response scenario where the operation succeeds remotely but the client does not receive the success result.

## Required tests

- [ ] persisted operation survives database reopen/repository recreation;
- [ ] same idempotency key + same operation produces one remote financial effect;
- [ ] same key + conflicting payload is rejected;
- [ ] accepted operation + lost response can be safely replayed;
- [ ] conditional claim prevents two claimers from owning the same operation simultaneously.

## Exit criteria

The data layer can demonstrate:

```text
one logical operation
→ repeated remote delivery
→ one financial effect
```

without any screen code.

---

# Phase 3 — Synchronization, Connectivity, and Restart Recovery

## Goal

Implement and prove the shared offline/reconnect lifecycle used by both Send Money and NovaSave.

## Connectivity

- [ ] Define an injectable connectivity abstraction.
- [ ] Add the concrete connectivity implementation selected for the app.
- [ ] Support deterministic online/offline overrides in tests.
- [ ] Keep connectivity status separate from sync status.

## Sync engine

- [ ] Implement one shared `SyncEngine` / coordinator.
- [ ] Load eligible pending operations in deterministic order.
- [ ] Atomically claim each operation before delivery.
- [ ] Route the operation to the fake remote.
- [ ] Persist successful result before exposing completed state.
- [ ] Retain recoverable failures safely.
- [ ] Represent definitive/business rejection separately from recoverable sync failure.
- [ ] Recover operations that were interrupted while processing.
- [ ] Ensure two concurrent triggers cannot produce simultaneous delivery of the same operation.

## Allowed triggers

At minimum:

- [ ] offline → online reconnect;
- [ ] application startup when pending work exists and connectivity is available;
- [ ] supported app resume/lifecycle recovery;
- [ ] explicit user Retry.

## Retry policy

- [ ] No background timer.
- [ ] No unbounded hidden retry loop.
- [ ] Each trigger creates a bounded sync run over currently eligible work.
- [ ] A later trigger may retry retained pending work.

## Required high-risk tests

Prove at least:

```text
Offline submit
→ durable pending record
→ repository/app recreation
→ online trigger
→ processing
→ completed
```

and:

- [ ] app dies after local save but before delivery;
- [ ] fake remote accepts request but response is lost;
- [ ] app dies after remote acceptance but before local completion is saved;
- [ ] reconnect and resume triggers race;
- [ ] user Retry is tapped repeatedly;
- [ ] recoverable failure leaves user intent safe;
- [ ] definitive rejection does not masquerade as a transient sync problem.

## Exit criteria

Before product UI work proceeds, the shared kernel must already prove the core assessment guarantee:

> a durable offline operation can survive restart and later create one financial effect when connectivity returns.

---

# Phase 4 — Design System Foundation and App Shell

## Goal

Translate the approved design exports into reusable Flutter primitives, then establish the navigable application shell.

## Design tokens

Implement the finalized tokens from `docs/DESIGN_SYSTEM.md`:

- [ ] complete color scales;
- [ ] Plus Jakarta Sans typography styles;
- [ ] spacing scale;
- [ ] radii;
- [ ] elevation/shadow;
- [ ] icon mapping.

## Shared components

Implement the shared components required by the upcoming product screens:

- [ ] primary/secondary buttons and disabled states;
- [ ] text fields and error/helper states;
- [ ] amount field presentation;
- [ ] status indicators;
- [ ] system notification/banner patterns;
- [ ] cards/list items;
- [ ] progress indicator;
- [ ] bottom navigation;
- [ ] sheet/empty-state patterns.

Do not create speculative abstractions for components that are not used by the approved designs.

## App shell

- [ ] app entry point;
- [ ] root theme;
- [ ] Riverpod scope/providers;
- [ ] navigation strategy;
- [ ] Wallet, Send, and NovaSave destinations;
- [ ] basic lifecycle hooks required by the sync subsystem.

`go_router` may be used if it remains justified; it is not an assessment requirement.

## Accessibility baseline

Shared components must support:

- [ ] appropriate Semantics;
- [ ] system font scaling;
- [ ] usable tap targets;
- [ ] no fixed layouts that obviously break with larger text.

## Exit criteria

The application launches into the correct shell, the three product areas are navigable, and shared UI primitives use centralized approved tokens.

---

# Phase 5 — Wallet Vertical Slice

## Goal

Implement Wallet as the visible projection of confirmed wallet state plus pending/sync state.

## Wallet home

- [ ] confirmed available balance;
- [ ] updated/last-updated state;
- [ ] Send Money entry point;
- [ ] NovaSave entry point;
- [ ] recent transactions;
- [ ] pull-to-refresh;
- [ ] loading/refreshing presentation;
- [ ] empty transaction state;
- [ ] offline system notification;
- [ ] reconnect/sync notification;
- [ ] sync-failure notification.

## Transaction list

- [ ] use `ListView.builder` or equivalent lazy rendering;
- [ ] completed transaction rows;
- [ ] pending transaction rows;
- [ ] processing transaction rows;
- [ ] retryable sync-failure presentation;
- [ ] correct money/status formatting.

## Transaction details

- [ ] completed detail state;
- [ ] pending offline detail state;
- [ ] required amount/recipient/reference/date/status information where available from the design/state.

## Important invariant

A pending offline transfer remains visible but must not make the headline balance look successfully debited before remote confirmation.

## Tests

- [ ] wallet loaded state;
- [ ] empty state;
- [ ] refresh state;
- [ ] offline banner/state;
- [ ] pending transaction rendering;
- [ ] processing/reconnect rendering;
- [ ] sync-failure rendering;
- [ ] lazy-list behavior is preserved.

## Exit criteria

Wallet accurately renders confirmed, cached, pending, and synchronization states from application/data state and closely matches the supplied design.

---

# Phase 6 — Send Money Vertical Slice

## Goal

Implement the complete Send Money journey on top of the already-proven operation/sync kernel.

## Recipient

- [ ] recipient input;
- [ ] required-field validation;
- [ ] invalid account validation;
- [ ] deterministic fake/local recipient resolution;
- [ ] resolved recipient presentation.

The approved design uses a ten-digit account example. Treat any exact fake-directory/account rule as a documented assessment assumption rather than a real banking integration.

## Amount

- [ ] amount entry;
- [ ] integer-kobo conversion;
- [ ] amount greater-than-zero validation;
- [ ] available/spendable balance validation according to the chosen documented pending-debit policy;
- [ ] offline last-updated balance presentation;
- [ ] exact balance-after preview.

## Confirmation

- [ ] recipient;
- [ ] amount;
- [ ] wallet source;
- [ ] balance-after preview;
- [ ] online confirmation state;
- [ ] offline confirmation copy/state;
- [ ] Edit details.

## Submit

One confirmed user intent must create one operation identity and one idempotency key.

- [ ] prevent accidental double creation from rapid taps;
- [ ] online path enters processing;
- [ ] offline path durably enqueues before showing Pending;
- [ ] retry reuses the same operation/idempotency identity.

## Result states

- [ ] processing;
- [ ] success;
- [ ] immediate failure;
- [ ] retry;
- [ ] offline Pending result;
- [ ] reconnect processing;
- [ ] post-reconnect success;
- [ ] recoverable sync failure with operation retained.

## State integration

- [ ] successful transfer updates wallet balance once;
- [ ] successful transfer appears in transaction history once;
- [ ] pending transfer remains visible while unsent;
- [ ] failed sync does not erase pending intent.

## Mandatory widget coverage

The assessment explicitly requires widget tests for Send Money.

Cover at minimum:

- [ ] recipient validation;
- [ ] amount validation;
- [ ] confirmation;
- [ ] online processing/success;
- [ ] offline Pending state;
- [ ] failure/retry state.

## Exit criteria

The approved online and offline Send Money journeys work end-to-end against the fake remote and the shared sync engine.

---

# Phase 7 — NovaSave Goal Creation

## Goal

Implement the non-money-moving NovaSave goal-management flow cleanly before adding the contribution lifecycle.

## Goals list

- [ ] goal cards;
- [ ] progress bar/percentage;
- [ ] saved amount and target amount;
- [ ] target date;
- [ ] empty goals state;
- [ ] Create Goal action.

## Create goal

- [ ] goal name;
- [ ] target amount using integer-kobo money;
- [ ] target date;
- [ ] missing-name validation;
- [ ] target amount > 0 validation;
- [ ] future-date validation;
- [ ] approved date-picker interaction;
- [ ] persist goal locally.

## Goal details

- [ ] saved-so-far amount;
- [ ] target amount;
- [ ] remaining amount;
- [ ] progress percentage/bar;
- [ ] target date;
- [ ] Contribute action.

## Tests

- [ ] empty goals state;
- [ ] creation validation;
- [ ] date validation;
- [ ] successful creation/persistence;
- [ ] exact progress calculation/rendering.

## Exit criteria

Goals can be created, persisted, listed, reopened, and rendered according to the approved NovaSave designs.

---

# Phase 8 — NovaSave Contribution Vertical Slice

## Goal

Implement contribution as the second consumer of the shared money-operation/sync architecture.

## Contribution amount

- [ ] contribution entry;
- [ ] integer-kobo conversion;
- [ ] amount > 0 validation;
- [ ] wallet balance validation;
- [ ] after-contribution goal preview;
- [ ] exact progress preview.

## Confirmation

- [ ] goal name;
- [ ] contribution amount;
- [ ] current goal saved amount;
- [ ] projected saved amount/progress;
- [ ] online confirmation state;
- [ ] offline confirmation state;
- [ ] Edit details.

## Submit/results

- [ ] processing;
- [ ] success;
- [ ] immediate failure;
- [ ] retry;
- [ ] offline durable Pending state;
- [ ] pending contribution visible on goal;
- [ ] reconnect processing;
- [ ] post-reconnect success;
- [ ] recoverable sync failure with contribution retained.

## Important invariant

A pending contribution must not make the goal appear successfully progressed before confirmation.

The approved design shows the goal remaining at 30% while a ₦50,000 contribution is pending, then moving to 40% only after successful processing.

## State integration

- [ ] successful contribution updates the goal exactly once;
- [ ] successful contribution affects wallet state consistently with the chosen runtime model;
- [ ] contribution history/transaction presentation is consistent where required;
- [ ] pending contribution survives restart.

## Mandatory widget coverage

The assessment explicitly requires widget tests for the NovaSave contribution flow.

Cover at minimum:

- [ ] amount validation;
- [ ] confirmation;
- [ ] online processing/success;
- [ ] failure/retry;
- [ ] offline Pending state;
- [ ] pending contribution on goal;
- [ ] reconnect success state.

## Exit criteria

The complete contribution journey works online and offline while reusing the same durable operation/sync machinery as Send Money.

---

# Phase 9 — Cross-Feature Consistency and Resilience

## Goal

Verify that Wallet, Send Money, NovaSave, persistence, and synchronization behave as one coherent product rather than isolated features.

## Consistency checks

- [ ] completed Send changes wallet balance exactly once;
- [ ] completed Send creates one transaction-history effect;
- [ ] completed Contribution changes goal progress exactly once;
- [ ] wallet state after Contribution is internally consistent;
- [ ] pending operations remain pending across navigation;
- [ ] pending operations remain pending across restart;
- [ ] reconnect state is reflected consistently across features;
- [ ] recoverable sync failure is presented consistently;
- [ ] manual Retry behaves consistently;
- [ ] references/timestamps/status values remain stable after replay.

## Multiple queued outgoing operations

The assessment/designs do not explicitly define whether pending offline outgoing operations reserve spendable balance against later offline operations.

Before completing this phase:

- [ ] choose the project policy;
- [ ] document it in README/traceability;
- [ ] implement it consistently for Send and Contribution;
- [ ] test it.

Do not silently invent production banking semantics.

## Concurrency/resilience checks

- [ ] two sync triggers cannot process the same row simultaneously;
- [ ] repeated user Retry cannot create a duplicate financial effect;
- [ ] operation recovery after interrupted processing is deterministic;
- [ ] idempotency conflict is surfaced as an implementation/data-integrity error rather than retried as a normal transport failure.

## Exit criteria

Cross-feature state remains internally consistent under normal, offline, restart, retry, and concurrency scenarios.

---

# Phase 10 — Accessibility, Performance, and Visual Fidelity

## Goal

Treat the assessor's accessibility/performance constraints and the approved design as completion requirements, not optional polish.

## Accessibility

- [ ] key interactive controls expose meaningful Semantics;
- [ ] custom controls are understandable to a screen reader;
- [ ] important status changes have an accessible representation;
- [ ] layouts respect system text scaling;
- [ ] verify the primary journeys at a materially enlarged text scale (target 2.0 unless implementation constraints justify another documented test value);
- [ ] no critical action or value is available only by color.

## Performance

- [ ] recent transactions remain lazily built;
- [ ] no avoidable eager construction of large lists;
- [ ] loading/refreshing does not block basic navigation unnecessarily;
- [ ] persistence/sync work avoids obvious UI-thread abuse.

A large transaction fixture may be used as a sanity check, but do not invent an arbitrary performance benchmark as an assessor requirement.

## Visual verification

Per-screen visual QA should already have occurred during Phases 4–8 using `docs/design/SCREEN_INDEX.md`. This phase performs the final cross-product sweep.

For every required state:

1. resolve its `SCREEN_INDEX.md` entry;
2. inspect the authoritative PDF (and optional derived reference crop if one exists);
3. capture the implemented state on the canonical visual-QA device;
4. compare copy, hierarchy, geometry and styling;
5. correct material mismatches;
6. record the verification result in the task/PR or final QA notes.

Compare every required screen/state for:

- [ ] typography;
- [ ] font weights;
- [ ] colors;
- [ ] spacing;
- [ ] alignment;
- [ ] dimensions;
- [ ] radii;
- [ ] shadows/elevation;
- [ ] icons;
- [ ] navigation;
- [ ] buttons;
- [ ] text fields;
- [ ] cards/lists;
- [ ] progress indicators;
- [ ] empty states;
- [ ] validation states;
- [ ] offline notifications;
- [ ] pending states;
- [ ] processing states;
- [ ] success/failure/sync-failure states.

## Exit criteria

The mandatory flows remain usable with accessibility services/font scaling and closely match the approved visual states.

---

# Phase 11 — Final Test Rigor and Failure Matrix

## Goal

Prove the assessment's correctness claims with tests that would actually fail if the offline/idempotency architecture regressed.

## Unit/domain

- [ ] `Money` arithmetic/formatting;
- [ ] validation rules;
- [ ] goal progress;
- [ ] operation state transitions;
- [ ] failure classification;
- [ ] idempotency identity.

## Data/repository

- [ ] operation persistence;
- [ ] atomic claiming;
- [ ] restart restoration;
- [ ] fake-remote idempotency;
- [ ] uncertain/lost response;
- [ ] goal persistence;
- [ ] wallet/transaction reconciliation.

## Widget

Mandatory:

- [ ] Send Money flow;
- [ ] NovaSave contribution flow.

Also retain useful coverage for Wallet and goal creation states.

## Integration

Mandatory integration scenario:

```text
Launch
→ go offline
→ confirm money-moving action
→ operation becomes Pending
→ recreate/restart application state
→ operation is still Pending
→ restore connectivity
→ sync runs
→ operation completes
→ exactly one financial effect is visible
```

Prefer Send Money for the mandatory end-to-end restart/reconnect test because the resulting wallet debit makes duplicate processing especially easy to detect.

If schedule permits after mandatory coverage is stable, add the corresponding NovaSave offline contribution integration path; otherwise the shared sync engine and contribution-specific lower-level tests must still prove its behavior.

## Failure matrix

Cover at the appropriate test layer:

- [ ] offline at confirmation;
- [ ] reconnect;
- [ ] transport failure;
- [ ] timeout/uncertain response;
- [ ] remote success + lost response;
- [ ] app interruption before local completion;
- [ ] concurrent sync triggers;
- [ ] repeated manual retry;
- [ ] definitive rejection;
- [ ] idempotency-key conflict;
- [ ] persistence failure where practical to simulate.

## Full verification

Before leaving this phase:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test
```

Use the repository's actual final integration-test command if the configured Flutter version requires a more specific invocation.

## Exit criteria

All mandatory tests pass and the suite demonstrates the guarantees the README will claim.

---

# Phase 12 — Documentation, Traceability, and Submission Readiness

## Goal

Make the repository truthful, reviewable, reproducible, and ready for assessment/interview demonstration.

## README

Finalize only claims that are backed by the implementation.

It must cover:

- [ ] what the app implements;
- [ ] targeted Flutter/Dart versions;
- [ ] how to run with a single standard command;
- [ ] how to run tests;
- [ ] architecture and state-management choices;
- [ ] offline/sync design;
- [ ] idempotency/exactly-once-effect strategy;
- [ ] fake-remote approach;
- [ ] trade-offs;
- [ ] documented assumptions;
- [ ] known limitations;
- [ ] stretch-goal status.

## AI usage

Finalize `AI_USAGE.md` from the living log:

- [ ] tools actually used;
- [ ] what each tool was used for;
- [ ] 2–3 real concrete prompts and results;
- [ ] at least one real wrong/risky AI output;
- [ ] how it was identified and corrected;
- [ ] relevant tests/commits where useful.

Do not fabricate retrospective evidence.

## Traceability

- [ ] every authoritative assessment requirement mapped;
- [ ] design-derived states mapped where applicable;
- [ ] implementation paths linked;
- [ ] tests linked;
- [ ] final status updated;
- [ ] no stale `TO VERIFY` entries remain except genuinely unsupported items.

## Final design/system docs

- [ ] `docs/ARCHITECTURE.md` reflects the implementation;
- [ ] `docs/DESIGN_SYSTEM.md` reflects the actual tokens/components;
- [ ] `docs/DEFINITION_OF_DONE.md` is satisfied;
- [ ] `docs/GIT_WORKFLOW.md` matches real practice;
- [ ] `docs/TASKS.md` reflects completed work;
- [ ] `HANDOVER.md` reflects final implementation state or is reset according to the workflow.

## Clean-environment check

Verify from a clean checkout/clone as closely as practical:

```text
clone/checkout
→ flutter pub get
→ flutter run
```

and independently run the full test suite.

## Submission/interview readiness

- [ ] repository link is ready;
- [ ] private repository access is granted if required;
- [ ] no secrets/internal material are committed;
- [ ] app can be demonstrated on emulator/simulator/device;
- [ ] airplane-mode/offline path can be demonstrated reliably;
- [ ] candidate can explain money representation, queue durability, idempotency, sync triggers, failure handling, and major trade-offs.

## Exit criteria

The repository is assessment-compliant, truthful, reproducible, and ready for submission/demo.

---

# Stretch Goals — Explicit Gate

Stretch goals are optional differentiators from the assessment, not baseline scope.

Potential items:

- local notification after queued Send successfully syncs;
- English + one Nigerian-language localization scaffold for at least Send Money;
- Wallet Home golden test;
- biometric-confirmation stub above a threshold amount.

Do not begin any stretch goal until all mandatory phases through Phase 12 are effectively green or the project owner deliberately accepts the trade-off.

Any selected stretch goal must receive its own task, tests, and documentation rather than being slipped into an unrelated feature branch.

---

# Phase Dependency Map

```text
P0  Repository baseline
 |
 v
P1  Money + identity
 |
 v
P2  Persistence + fake remote
 |
 v
P3  Sync + restart recovery
 |
 v
P4  Design system + app shell
 |
 v
P5  Wallet
 |
 v
P6  Send Money
 |
 +-------------------+
 |                   |
 v                   v
P7  Goal creation    P9 cross-feature work begins as evidence accumulates
 |
 v
P8  Contribution
 |
 v
P9  Cross-feature consistency/resilience
 |
 v
P10 Accessibility/performance/visual verification
 |
 v
P11 Final test rigor/failure matrix
 |
 v
P12 Documentation/submission readiness
```

`docs/TASKS.md` may split or parallelize work inside a phase where dependencies are clear, but it must not violate this architectural dependency order.

---

# Verification Rhythm

For each executable task:

1. run the task's narrow verification command before changes;
2. implement the smallest coherent change;
3. run targeted tests;
4. run targeted analysis/formatting where useful;
5. commit;
6. review according to `docs/AGENT_WORKFLOW.md`;
7. fix findings;
8. run the phase/full checks at the appropriate boundary;
9. update traceability and AI usage when applicable;
10. update `HANDOVER.md` once implementation has begun.

Do not run expensive full integration suites after every tiny edit. Do run them at the phase/PR boundaries where their guarantees matter.

---

# Remaining `TO VERIFY`

The planning review has intentionally reduced uncertainty to implementation/tooling choices rather than missing product requirements.

## Repository/toolchain

Resolve during Phase 0:

- exact Flutter version;
- exact Dart version;
- package versions;
- generated-code strategy;
- CI runner/environment.

## Multiple pending outgoing debits

Resolve by Phase 9, preferably earlier if Send/Contribution validation requires it:

> Does a pending offline outgoing operation reduce the amount available to validate a later offline outgoing operation?

The supplied assessment/designs do not define this behavior. The chosen policy must be documented, implemented consistently, and tested.

Do not reintroduce `TO VERIFY` items for production API/auth/KYC/NIBSS behavior. Those are outside the supplied implementation scope.

---

# Planning-to-Implementation Transition

This plan is considered final enough for implementation when the remaining project-document pass is complete.

Before the first coding branch:

1. finalize `docs/REQUIREMENTS_TRACEABILITY.md`;
2. finalize `docs/DESIGN_SYSTEM.md`;
3. update `docs/DEFINITION_OF_DONE.md`;
4. review `docs/GIT_WORKFLOW.md`;
5. rewrite the pre-implementation `README.md` so it does not claim unimplemented behavior;
6. create the `AI_USAGE.md` template;
7. generate `docs/TASKS.md` from this plan using the task contract in `docs/AGENT_WORKFLOW.md`;
8. generate the initial `HANDOVER.md`;
9. start Phase 0 implementation.

After `HANDOVER.md` is generated, planning stops unless implementation evidence requires a targeted change.
