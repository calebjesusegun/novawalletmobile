# NovaWallet Definition of Done

**Status:** Final pre-implementation baseline  
**Purpose:** A task, feature, or phase is not complete merely because it renders or passes the happy path. It is complete only when the applicable functional, financial-integrity, offline/sync, visual, accessibility, performance, testing, and documentation criteria below are satisfied.

## 1. General Completion Rule

A task may be marked `DONE` only when:

- its acceptance criteria in `docs/TASKS.md` are satisfied;
- the mapped requirement(s) in `docs/REQUIREMENTS_TRACEABILITY.md` are implemented;
- relevant approved design state(s) in `docs/design/SCREEN_INDEX.md` are represented;
- applicable tests pass;
- required visual verification has been completed;
- no unresolved blocker or applicable `TO VERIFY` remains hidden;
- any assumptions introduced by the implementation are documented.

If a requirement is intentionally deferred, the task is not `DONE`; mark it `BLOCKED`, `DEFERRED`, or `TO VERIFY` with a reason.

## 2. Functional Behaviour

For an applicable feature:

- [ ] The required journey works from entry to completion.
- [ ] Required fields, actions, navigation, and states exist.
- [ ] Required validation messages and disabled/enabled states work.
- [ ] Confirmation behaviour matches the approved flow.
- [ ] Processing/loading states are represented where required.
- [ ] Success states are correct.
- [ ] Failure states are correct.
- [ ] Retry is available where the approved flow requires it.
- [ ] Back/cancel/edit actions preserve or discard state intentionally.
- [ ] User-visible copy follows the approved design/flow unless a documented implementation constraint requires otherwise.
- [ ] No unsupported product behaviour was invented.

## 3. Money and Financial Integrity

For any code that reads, stores, calculates, validates, formats, or displays money:

- [ ] Monetary values are represented as integer kobo in domain/data logic.
- [ ] `double` / floating-point arithmetic is not used for financial amounts.
- [ ] Naira formatting is derived from integer kobo correctly.
- [ ] Addition, subtraction, balance checks, and savings progress calculations are covered by tests.
- [ ] A financial operation is never shown as completed before the authoritative fake remote confirms completion.
- [ ] A retry of the same logical operation reuses the same stable operation identity/idempotency key.
- [ ] Repeated delivery of the same idempotency key cannot produce a duplicate financial effect.
- [ ] A repeated idempotency key with a conflicting payload is rejected or otherwise handled safely.
- [ ] Concurrent triggers cannot process the same pending operation simultaneously.
- [ ] Interrupted processing can recover safely after app restart.

These checks are mandatory for Send Money and NovaSave contribution work.

## 4. Offline, Persistence, and Synchronization

For Send Money and NovaSave contributions:

- [ ] Offline state is detected through the shared connectivity abstraction.
- [ ] User intent is durably persisted before the UI claims that it is safely saved.
- [ ] The queued operation survives a full app restart while offline.
- [ ] The operation is visibly represented as pending.
- [ ] Pending state does not prematurely alter confirmed wallet balance or confirmed savings progress.
- [ ] Connectivity restoration triggers eligible synchronization.
- [ ] Sync processing is serialized/claimed safely so the same operation is not sent by two concurrent runs.
- [ ] Successful sync updates the relevant local/application state exactly once.
- [ ] A transient/uncertain sync failure retains the user's saved intent.
- [ ] A terminal/definitive failure is distinguishable from a recoverable sync failure.
- [ ] Manual retry is duplicate-safe.
- [ ] There is no uncontrolled background retry loop.
- [ ] Restart/reconnect behaviour is covered by automated tests.

For changes to sync, persistence, queue schemas, operation claiming, or idempotency, completion requires a high-risk review under `docs/AGENT_WORKFLOW.md`.

## 5. State Model

Where applicable:

- [ ] Connectivity state is modeled independently from synchronization state.
- [ ] Synchronization state is modeled independently from operation/transaction state.
- [ ] UI state does not collapse materially different conditions into one generic state.
- [ ] Recoverable sync failure does not silently become a terminal financial failure.
- [ ] State transitions are deterministic and tested.

Conceptually:

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

Equivalent implementations are acceptable if they preserve the same separation of concerns.

## 6. Visual Fidelity

For every UI task:

- [ ] The exact relevant design state(s) are identified in `docs/design/SCREEN_INDEX.md`.
- [ ] The approved PDFs remain the source of truth.
- [ ] `docs/DESIGN_SYSTEM.md` tokens/components are used instead of arbitrary replacements where a supplied token/component exists.
- [ ] Plus Jakarta Sans and the approved typography styles are used.
- [ ] Colors match approved tokens.
- [ ] Spacing, alignment, radii, elevation, borders, and component proportions match the source design materially.
- [ ] Icons match the approved iconography or the closest documented implementation mapping.
- [ ] Empty, validation, offline, pending, processing, success, failure, and sync states match the relevant approved screens.
- [ ] A canonical emulator/device screenshot was captured for implemented UI states where practical.
- [ ] Material discrepancies against the reference were corrected or documented.

Individual PNG crops/references are optional implementation aids; the PDFs are authoritative.

## 7. Accessibility

For every interactive screen:

- [ ] Key interactive controls expose meaningful Flutter `Semantics`.
- [ ] Custom controls have appropriate labels/roles/state information.
- [ ] Important status changes are understandable to screen-reader users.
- [ ] Text respects the system font-scale setting.
- [ ] Layout remains usable at increased font scale; text is not clipped or made inaccessible by fixed-height assumptions.
- [ ] Interactive targets are usable and not visually/semantically ambiguous.
- [ ] Validation and error meaning is not conveyed by color alone.

At minimum, critical flows should be manually or automatically exercised at an increased text scale before final sign-off.

## 8. Performance

- [ ] Recent transactions use `ListView.builder` or an equivalent lazy-list implementation.
- [ ] Large lists are not fully built eagerly.
- [ ] Expensive work is not performed unnecessarily inside widget `build` methods.
- [ ] Business logic, persistence calls, and sync orchestration are not embedded in presentation widgets.
- [ ] No obvious avoidable jank is introduced in the critical assessment journeys.

## 9. Security and Sensitive Data

- [ ] No secrets or real credentials are committed.
- [ ] No sensitive mocked authentication/session data is stored in plain `SharedPreferences`.
- [ ] If sensitive mock data is introduced, it uses an appropriate secure-storage mechanism.
- [ ] Logs do not expose sensitive values unnecessarily.
- [ ] The implementation does not pretend to provide production banking/KYC/security guarantees beyond the assessment scope.

## 10. Testing

### Unit / domain

Where applicable:

- [ ] Money arithmetic and formatting are tested.
- [ ] Validation rules are tested.
- [ ] Savings progress calculations are tested.
- [ ] Operation state transitions are tested.
- [ ] Idempotency/deduplication behaviour is tested.
- [ ] Retry/recovery logic is tested.

### Repository / persistence

Where applicable:

- [ ] Enqueue and restore behaviour is tested.
- [ ] App-restart restoration is tested.
- [ ] Operation claiming/concurrency behaviour is tested.
- [ ] Failure retention is tested.
- [ ] Fake-remote idempotency behaviour is tested.

### Widget

- [ ] Relevant screen states are covered.
- [ ] Required validation states are covered.
- [ ] Send Money has the assessment-required widget coverage.
- [ ] NovaSave contribution has the assessment-required widget coverage.

### Integration

Before submission:

- [ ] At least one integration test covers: offline action -> durable queue -> restart/reload -> reconnect -> successful sync.
- [ ] The integration test verifies one financial effect rather than only a screen transition.
- [ ] Critical failure/retry behaviour has coverage sufficient to catch a regression in the offline-sync guarantee.

A test is only valuable if it fails when the guarantee it protects is broken.

## 11. Code Quality and Architecture

- [ ] Business rules are outside widgets.
- [ ] Presentation code dispatches intent and renders state.
- [ ] Repository boundaries hide concrete persistence/fake-remote details.
- [ ] Sync orchestration is shared and is not independently reimplemented inside Send Money and NovaSave.
- [ ] Shared design tokens/components are not duplicated in features.
- [ ] New dependencies have a documented responsibility and are not added speculatively.
- [ ] No Dio/HTTP dependency is introduced unless a concrete implementation need justifies it.
- [ ] No unrelated refactor is mixed into the task.
- [ ] Public names and folder placement follow the current architecture.

## 12. Verification Commands

Before a feature/PR is considered complete, run the narrowest relevant tests first.

Before merge/final sign-off, the applicable full checks must pass:

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

If the repository later introduces authoritative scripts, use those documented commands instead.

## 13. Documentation and Traceability

For every meaningful implementation change:

- [ ] `docs/REQUIREMENTS_TRACEABILITY.md` is updated when implementation/test/status mapping changes.
- [ ] `docs/TASKS.md` reflects the task's final state.
- [ ] `docs/HANDOVER.md` is updated at the required workflow checkpoint after implementation has started.
- [ ] Architecture documentation is updated if an architectural decision changed.
- [ ] Design documentation/index is updated if a design-reference mapping changed.
- [ ] README claims remain truthful about what is actually implemented.
- [ ] New assumptions or unresolved ambiguities are documented explicitly.
- [ ] `AI_USAGE.md` is updated when the work produced a concrete AI-use example worth recording, especially a risky/incorrect suggestion that was caught and corrected.

Do not manufacture AI mistakes merely to satisfy `AI_USAGE.md`; record real usage and real judgment.

## 14. Git / Review Completion

- [ ] Work is on the intended task branch.
- [ ] Commits are focused and understandable.
- [ ] The diff contains no accidental unrelated changes.
- [ ] High-risk money/offline/sync changes receive the review level required by `docs/AGENT_WORKFLOW.md`.
- [ ] Reviewer findings are resolved or explicitly documented.
- [ ] Final checks pass after the last material change.

## 15. Feature-Level Done

A feature such as Wallet, Send Money, or NovaSave can be marked complete only when all applicable requirements above are satisfied and:

- [ ] every mapped mandatory requirement is implemented;
- [ ] every mapped required design state is represented;
- [ ] required tests pass;
- [ ] visual verification is complete;
- [ ] accessibility/performance constraints are met;
- [ ] no applicable critical `TO VERIFY` remains.

## 16. Submission-Level Done

The project is ready for assessment submission only when:

- [ ] Mandatory Wallet, Send Money, NovaSave, offline queue, and reconnect behaviour are complete.
- [ ] Integer-kobo money correctness is demonstrated by tests.
- [ ] Offline queued actions survive app restart.
- [ ] Duplicate processing is prevented across retry/restart/reconnect scenarios.
- [ ] Required widget tests exist for Send Money and NovaSave contribution.
- [ ] Required offline-queue-then-sync integration coverage exists.
- [ ] Accessibility and lazy-list requirements are satisfied.
- [ ] The app runs with the documented single-command Flutter setup.
- [ ] Target Flutter and Dart versions are stated.
- [ ] `README.md` accurately documents architecture, key decisions, trade-offs, how to run, and how to test.
- [ ] `AI_USAGE.md` satisfies the assessment requirement with real usage evidence.
- [ ] `docs/REQUIREMENTS_TRACEABILITY.md` is current.
- [ ] Final visual reconciliation against approved design references is complete.
- [ ] The repository contains no confidential assessment material that should not be distributed.
- [ ] Stretch goals, if any, are clearly labeled as optional and do not mask incomplete mandatory work.
- [ ] Final format/analyze/unit/widget/integration checks pass.

## 17. Sign-Off Rule

Do not mark work `DONE` because it "looks finished."

For NovaWallet, completion means the required behaviour is **correct, durable, duplicate-safe, tested, visually verified, accessible, traceable, and honestly documented**.
