# NovaWallet Architecture

**Status:** Final pre-implementation baseline  
**Last updated:** 2026-09-19  
**Scope:** NovaWallet Mobile - Send & Save take-home assessment

This document defines the implementation architecture for NovaWallet after reconciliation against the original assessment brief, the supplied screen flows, the approved design exports, and the project engineering rules in `AGENTS.md`.

It is an implementation specification, not a description of code that already exists. Where the source material does not define behavior, the document either records an explicit engineering decision or marks the point `TO VERIFY` rather than presenting an assumption as an assessment requirement.

---

## 1. Architectural Goal

NovaWallet must be a maintainable Flutter application whose architecture protects the two things that matter most in this assessment:

1. **money must remain exact;**
2. **user intent must survive unreliable connectivity without producing a duplicate financial effect.**

The central principle is:

> **User intent must survive connectivity loss.**

The UI is therefore a projection of durable application state. Widgets do not own persistence, replay, retry, or idempotency.

---

## 2. Source of Truth

Architecture decisions follow the project source hierarchy defined in `AGENTS.md`:

1. original assessment / assignment brief;
2. detailed requirements and approved screen flows;
3. approved design exports and screenshots;
4. current repository code and tests once implementation exists;
5. project engineering documentation;
6. current task/handover execution context;
7. previous agent reasoning;
8. general engineering assumptions.

If implementation evidence later conflicts with this document because a higher-priority source required a change, update this document rather than preserving an outdated architectural statement.

---

## 3. Assessment-Driven Constraints

The following constraints shape the architecture and are not optional.

### 3.1 Money

- Money enters the application as an integer number of kobo.
- Domain and data arithmetic must not use floating-point money values.
- Balance, transfer, contribution, and money-derived calculations must remain exact.
- Naira formatting belongs at the presentation boundary.

### 3.2 Offline durability

- If the device is offline when the user confirms **Send** or **Contribution**, the intent is persisted locally.
- The operation must survive application restart.
- The UI may only report that an action is safely saved after durable persistence succeeds.

### 3.3 Duplicate prevention

- Each logical Send or Contribution receives one stable operation ID and one stable idempotency key.
- Retries reuse that key.
- Reconnect, app restart, app resume, timeout, lost response, or repeated Retry taps must not create a second financial effect for the same logical action.

### 3.4 Retry behavior

- There is no unbounded background retry loop.
- Sync runs are triggered deliberately.
- Recoverable sync failures retain the operation and expose the required pending/retry presentation.

### 3.5 Accessibility and performance

- Key interactive elements require appropriate Flutter `Semantics`.
- Layouts must respect system font scaling.
- Large transaction lists are lazy (`ListView.builder` or equivalent).

### 3.6 Security

- Sensitive mock values, if introduced, must not be stored in plain `SharedPreferences`.
- Do not introduce mock secrets merely to demonstrate secure storage.

---

## 4. Product and System Boundaries

The application has three user-facing product areas and two supporting subsystems.

```text
User-facing features
├── Wallet
├── Send Money
└── NovaSave

Supporting subsystems
├── Sync / offline operations
└── Fake remote
```

### Wallet

Responsible for presenting:

- available balance;
- recent transactions;
- pull-to-refresh;
- loading/refreshing state;
- empty state;
- offline/reconnection system messaging;
- pending and processing transactions;
- sync-failure presentation;
- transaction details.

### Send Money

Responsible for:

- recipient entry and validation;
- fake recipient resolution;
- amount entry and balance validation;
- confirmation;
- online processing;
- success/failure;
- offline persistence;
- pending presentation;
- retry entry points.

### NovaSave

Responsible for:

- goal list and empty state;
- goal creation;
- name/amount/date validation;
- goal details;
- contribution entry and wallet-balance validation;
- confirmation;
- online processing;
- success/failure;
- offline persistence;
- pending contribution presentation;
- retry entry points;
- progress bar and percentage.

### Sync

Responsible for the shared lifecycle of durable money-moving operations. Send Money and NovaSave do not own separate replay loops.

### Fake remote

Represents the unavailable backend boundary. It exists to make success, failure, idempotency, and uncertain-delivery cases testable. It is not intended to model a complete banking platform.

---

## 5. High-Level Architecture

Use a layered, feature-oriented architecture.

```text
Presentation
    |
    v
Application / State
    |
    v
Domain
    |
    v
Repository interfaces
    |
    v
Data implementations
    |---------------------------|
    v                           v
Local persistence          Fake remote
    ^                           ^
    |                           |
    +---------- Sync -----------+
```

### Responsibilities

#### Presentation

- Flutter screens and reusable widgets;
- rendering state;
- gathering user input;
- dispatching user intent;
- accessibility semantics;
- navigation actions.

Presentation must not contain persistence, replay, idempotency, or money-business logic.

#### Application / State

- Riverpod controllers/notifiers/providers;
- orchestration of use cases;
- screen/application state;
- translating domain outcomes into presentation states;
- coordination with shared sync state.

#### Domain

- `Money` and money-safe calculations;
- entities/value objects;
- validation rules;
- operation semantics;
- repository contracts where appropriate;
- progress calculations;
- failure categories used by the application.

Domain code must not depend on Flutter widgets, Drift, or the fake remote implementation.

#### Data

- repository implementations;
- Drift persistence adapters;
- mapping between database records and domain models;
- fake-remote adapters;
- transaction/cache updates.

#### Infrastructure

- Drift/SQLite;
- connectivity implementation;
- ID/key generation;
- clock/time implementation;
- secure storage only if required;
- router implementation.

---

## 6. Target Repository Structure

```text
lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── providers.dart
│
├── core/
│   ├── connectivity/
│   ├── errors/
│   ├── ids/
│   ├── money/
│   ├── persistence/
│   ├── time/
│   └── utils/
│
├── design_system/
│   ├── tokens/
│   ├── theme/
│   ├── icons/
│   └── components/
│
├── sync/
│   ├── domain/
│   ├── application/
│   └── data/
│
├── fake_backend/
│   ├── remote_api.dart
│   ├── fake_novapay_server.dart
│   └── failure_simulator.dart
│
└── features/
    ├── wallet/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    ├── send_money/
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    └── novasave/
        ├── domain/
        ├── data/
        └── presentation/
```

Tests mirror responsibility rather than screen names only:

```text
test/
├── core/
├── sync/
├── fake_backend/
└── features/

integration_test/
```

`sync/` is a top-level subsystem rather than a feature because Wallet, Send Money, and NovaSave consume it.

`fake_backend/` is also explicit because the assessment provides no real backend and the fake remote is part of how correctness is demonstrated.

---

## 7. Money Architecture

### 7.1 Representation

Use a `Money` value object backed by integer kobo.

Conceptually:

```text
Money
- kobo: int

operations
- add
- subtract
- compare
- isPositive
- format/display conversion
```

Do not use `double` as the authoritative representation of:

- wallet balance;
- transfer amount;
- contribution amount;
- target amount;
- saved amount;
- remaining amount.

### 7.2 Naira display

Formatting is derived from kobo at the presentation boundary.

Example:

```text
12545000 kobo -> ₦125,450.00
```

### 7.3 Goal progress

Progress must be derived from exact integer money values rather than independently persisted.

The domain should expose an integer-safe representation such as percentage/basis points or an equivalent rational calculation with an explicit rounding rule.

If a Flutter progress widget requires a `double` in the range 0..1, convert only the already-derived display progress at the UI boundary. A UI rendering fraction is not an authoritative money calculation.

---

## 8. Core Domain Models

The initial domain model should include at least:

```text
Money
WalletSnapshot
Transaction
Recipient
SavingsGoal
Contribution
PendingOperation
ConnectivityStatus
SyncStatus
OperationStatus
```

Exact filenames are implementation details.

### 8.1 Transaction

Conceptually:

```text
Transaction
- id
- type
- amount: Money
- counterparty / goal label
- createdAt
- status
- reference (when completed)
```

The transaction model should represent product state without embedding widget state.

### 8.2 SavingsGoal

Conceptually:

```text
SavingsGoal
- id
- name
- targetAmount: Money
- savedAmount: Money
- targetDate

Derived:
- remainingAmount
- progress
```

Progress and remaining amount are derived from the persisted monetary values.

### 8.3 PendingOperation

A pending operation is the durable representation of user intent.

Conceptually:

```text
PendingOperation
- operationId
- operationType
- idempotencyKey
- payload snapshot
- createdAt
- status
- attemptCount
- lastAttemptAt
- lastError
- remoteReference/result metadata when available
```

The payload must contain enough immutable information to replay the original user intent without reconstructing it from mutable screen state.

---

## 9. State Model

Connectivity, synchronization, and operation state are independent dimensions.

```text
ConnectivityStatus
- online
- offline
```

```text
SyncStatus
- idle
- syncing
- failed
```

```text
OperationStatus
- pending
- processing
- completed
- failed
```

Examples:

```text
offline + idle + pending
online  + syncing + processing
online  + failed  + pending
online  + idle    + completed
```

A synchronization attempt can fail while the underlying operation remains durably pending. This is required by the supplied sync-failure designs where the action is still saved and can be retried.

Do not model all combinations as one giant state enum.

---

## 10. Operation Lifecycle

### 10.1 Online operation

```text
User confirms
    |
    v
Create logical operation + stable idempotency key
    |
    v
Processing
    |
    +---- success ----> Completed
    |
    +---- failure ----> Failed / recoverable result according to failure type
```

The implementation may persist the operation before the remote call even while online. Doing so creates one consistent operation pipeline for both online and offline actions and simplifies crash recovery.

### 10.2 Offline operation

```text
User confirms while offline
    |
    v
Create logical operation + stable idempotency key
    |
    v
Durably persist operation
    |
    v
Pending
    |
    v
Reconnect / app-start trigger
    |
    v
Atomic claim
    |
    v
Processing
    |
    +---- success ----------> Completed
    |
    +---- recoverable error -> Pending + last error
    |
    +---- terminal rejection -> Failed
```

The UI must not claim the operation is saved until persistence succeeds.

### 10.3 Interrupted processing

If the app terminates while an operation is `processing`, the next startup must treat that state as uncertain rather than assuming failure or success.

The operation becomes eligible for safe redelivery using the **same idempotency key**. The fake remote's idempotency record resolves whether the effect already happened.

---

## 11. Exactly-Once Financial Effect

The architecture does not assume that a client can guarantee literal exactly-once network delivery.

Instead:

> **The client may deliver at least once; the remote processes idempotently; together they produce one financial effect per logical operation.**

### 11.1 Stable identity

One user intent creates:

```text
operationId      -> local durable identity
idempotencyKey   -> remote deduplication identity
```

Both remain stable across:

- retry;
- reconnect;
- app restart;
- timeout;
- lost response;
- duplicate sync triggers.

### 11.2 Atomic claim

The local queue must prevent two sync triggers from processing the same pending row simultaneously.

Conceptually:

```text
UPDATE operation
SET status = processing
WHERE id = ? AND status = pending
```

Only the caller that successfully claims the row may process it.

The exact Drift implementation is an implementation detail, but the claim must be atomic.

### 11.3 Remote deduplication

The fake remote must persist enough idempotency state to distinguish:

- first delivery of a key;
- repeated delivery of the same key and same logical payload;
- conflicting reuse of the same key for a different payload.

For a legitimate repeat, it returns the already-recorded result rather than applying the financial effect again.

### 11.4 Fake-remote persistence boundary

Because the fake remote runs inside the assessment app rather than on a real server, its idempotency ledger must still survive the client restart scenarios being tested.

The physical implementation may reuse Drift infrastructure, but fake-remote persisted state must be accessed only through the fake-remote boundary. Client repositories must not inspect or mutate the fake server's idempotency records directly.

---

## 12. Synchronization Architecture

Use one shared `SyncEngine` / coordinator for Send and Contribution operations.

Conceptually:

```text
Trigger
  |
  v
SyncEngine
  |
  v
Load eligible pending operations
  |
  v
Process deterministically
  |
  v
Atomic claim per operation
  |
  v
Fake remote
  |
  +---- success ----------> persist result + complete
  |
  +---- recoverable error -> retain pending + record error
  |
  +---- rejection --------> failed
  |
  v
Publish sync/application state
```

### 12.1 Allowed sync triggers

At minimum:

- connectivity changes from offline to online;
- application startup when pending work exists and connectivity is available;
- supported application resume/lifecycle recovery;
- explicit user Retry.

### 12.2 No background loop

Do not use an unbounded timer or hidden perpetual retry loop.

Each trigger creates a bounded sync run over currently eligible work. A later trigger may make another attempt.

### 12.3 Ordering

Process pending operations in a deterministic order, normally oldest first, unless implementation evidence establishes a safer requirement.

The purpose is predictable state progression, not a claim that the assessment defines production settlement ordering.

### 12.4 Failure semantics

Distinguish:

```text
Transport/connectivity failure
Timeout / uncertain response
Recoverable fake-server failure
Definitive/business rejection
Persistence failure
Unexpected application failure
```

A sync failure does not automatically convert the underlying operation into a terminal failed financial action.

---

## 13. Local Persistence

Drift/SQLite is the chosen structured persistence mechanism.

The client-side store should contain only data needed to preserve the required experience and application state.

Conceptually:

```text
operations
wallet cache / balance snapshot
transaction cache
savings goals
local metadata required for sync/recovery
```

### 13.1 Operations table

The operations table is the critical durable store.

It must support:

- stable operation identity;
- stable idempotency key;
- operation type;
- replayable payload;
- durable status;
- attempt/error metadata;
- atomic claiming;
- startup recovery.

### 13.2 Goals

Because no real backend is provided, savings goals may use local persistence as the product source for goal definition/state, while contribution completion remains gated by the fake remote operation result.

This is an explicit engineering decision for the assessment, not a claim about a real NovaPay backend.

### 13.3 Wallet and transaction cache

Wallet balance and transaction history may be cached locally so the required offline screens can render the last known state.

The design explicitly shows a last-updated balance while offline.

---

## 14. Fake Remote Architecture

There is no real backend. Do not add HTTP/Dio merely to imitate one.

Define a narrow interface such as:

```text
RemoteApi
- sendMoney(operation)
- contribute(operation)
- fetchWalletSnapshot()
```

Recipient resolution may remain a deterministic fake/local service unless implementation needs justify placing it behind the remote interface.

### Fake remote responsibilities

- apply one financial effect for a new idempotency key;
- return the prior result for a legitimate duplicate delivery;
- detect conflicting key reuse;
- provide deterministic latency/failure control for tests;
- simulate uncertain-delivery cases such as "accepted remotely, response lost";
- expose only the behavior needed by the assessment.

### Fake remote non-goals

Do not build:

- real authentication;
- KYC/BVN/NIN flows;
- NIBSS integration;
- bill payments;
- production banking APIs;
- a generic REST layer solely for architectural appearance.

Those are operating-context references, not required features in this assignment.

---

## 15. Repository Responsibilities

Repositories expose domain-level operations and hide persistence/fake-remote details.

Conceptually:

```text
WalletRepository
- getBalance / watchBalance
- getTransactions / watchTransactions
- refresh
- getTransaction

SendMoneyRepository
- resolveRecipient
- submitTransferIntent
- observeTransfer

NovaSaveRepository
- getGoals / watchGoals
- createGoal
- getGoal
- submitContributionIntent

OperationRepository
- enqueue
- getEligiblePending
- claim
- markPendingWithError
- markCompleted
- markFailed
- recoverInterrupted
```

Exact method names are not part of the architecture contract.

The important rules are:

- widgets never call Drift directly;
- widgets never call the fake remote directly;
- feature repositories do not each implement their own replay loop;
- operation persistence and sync ownership remain centralized.

---

## 16. Source-of-Truth Ownership at Runtime

Different state has different authority.

### Local operation intent

The local operations store is authoritative for whether a user intent has been safely queued and still needs processing.

### Remote financial result

The fake remote is authoritative for whether a submitted operation has produced its simulated financial effect and for idempotency deduplication.

### UI state

The UI is derived from persisted domain/application state. It is never the source of truth for operation completion.

### Cached wallet data

While offline, the wallet may show the last confirmed cached balance and timestamp, as shown by the design.

A pending offline action must not make the headline balance appear successfully settled before remote confirmation.

### Multiple pending outgoing operations

The project explicitly adopts the **Spendable Balance Reservation Policy** (`SpendableBalancePolicy` in `lib/sync/domain/spendable_balance_policy.dart`) to resolve MNY-006:

1. **Headline balance remains confirmed balance:** Per AD-09, the headline wallet balance continues to show the last confirmed cached balance and timestamp; it is never debited in the UI before remote confirmation.
2. **Spendable balance deducts active outgoing operations:** When the user initiates a new Send Money or Contribution while offline, amount validation evaluates against `spendableBalance = max(0, confirmedBalance - sum(activePendingKobo))` where active operations are those in `pending` or `processing` states.
3. **Over-reservation prevention:** An offline operation that would exceed `spendableBalance` is blocked in the UI with an insufficient spendable balance message, preventing the queuing of operations that are guaranteed to bounce or overdraft upon reconnection.
4. **Lifecycle release:** Completed operations are reconciled with remote confirmed balance updates and do not double-deduct; terminally failed operations release their reservation immediately.

---

## 17. State Management

Riverpod is the chosen application-state/dependency-injection mechanism.

Use it for:

- dependency wiring;
- controller/notifier lifecycle;
- async application state;
- repository/interface injection;
- test overrides for connectivity, clock, IDs, and fake remote behavior.

Prefer feature-scoped controllers such as:

```text
WalletController
SendMoneyController
NovaSaveController
SyncController / SyncStatusProvider
```

Avoid one global state object containing every feature and every network/operation combination.

Do not put domain rules inside Riverpod providers merely because providers can hold logic.

---

## 18. Connectivity

Connectivity must be abstracted behind an injectable interface.

The production implementation may use `connectivity_plus` or another suitable Flutter connectivity source.

Important distinction:

> A network-interface signal indicates likely connectivity; it does not prove a remote request will succeed.

Remote calls can still time out or fail after an `online` signal. Therefore operation correctness must never depend on connectivity state alone.

The fake remote/failure simulator should allow tests to reproduce both:

- explicit offline state;
- online-but-request-fails / response-is-lost uncertainty.

---

## 19. Navigation

Navigation should reflect product journeys rather than widget implementation details.

Primary areas:

```text
Wallet
Send
NovaSave
```

Nested destinations include:

```text
Transaction details
Send recipient
Send amount
Send confirmation
Send result / pending state
Goal creation
Goal details
Contribution amount
Contribution confirmation
Contribution result / pending state
```

Routing belongs under `app/` and should not own business state.

`go_router` is acceptable if adopted during bootstrap, but the architecture does not depend on it specifically.

---

## 20. Design System Architecture

The approved exports define:

- color scales;
- Plus Jakarta Sans typography;
- spacing;
- radii;
- elevation;
- iconography;
- buttons;
- text fields;
- system notifications;
- status/result components;
- cards/lists;
- progress;
- navigation;
- sheets;
- empty states.

Implement these centrally under `design_system/`.

Feature widgets should consume shared tokens/components rather than copy values locally.

The design system contains presentation primitives only. It must not fetch data or own feature business logic.

---

## 21. Error Model

Technical failures must be mapped into meaningful domain/application outcomes.

Distinguish at least:

```text
ValidationFailure
ConnectivityFailure
Timeout / UncertainDelivery
RemoteFailure
BusinessRejection
PersistenceFailure
SyncFailure
UnexpectedFailure
```

Rules:

- do not display raw exception strings to users;
- preserve approved user-facing copy from the design;
- record enough internal failure context to test/recover safely;
- do not interpret an uncertain response as proof that nothing happened remotely;
- retry uncertain delivery with the same idempotency key.

---

## 22. Accessibility and Performance Architecture

Accessibility and performance are architectural constraints, not final-polish tasks.

### Accessibility

- interactive controls expose useful semantics;
- custom status/progress elements remain understandable to screen readers;
- layouts adapt to larger system font scales;
- avoid fixed-height text containers that clip scaled copy;
- status transitions should be presented in a way assistive technology can understand.

### Performance

- recent transactions use a lazy list;
- avoid eagerly instantiating an unbounded transaction history;
- controllers should expose data in a form that does not require rebuilding the entire application for a local state change;
- keep expensive persistence/network simulation work outside widget build methods.

---

## 23. Testing Architecture

Testing exists at several levels because the assessment specifically evaluates regression resistance in the offline/sync path.

### 23.1 Unit / domain tests

Cover:

- `Money` arithmetic and formatting inputs;
- amount validation;
- goal progress calculations;
- operation state transitions;
- stable ID/idempotency behavior;
- retry classification;
- fake-remote idempotency.

### 23.2 Data/repository tests

Cover:

- operations survive database reopen;
- atomic claim behavior;
- interrupted-processing recovery;
- repository mapping;
- fake-remote duplicate handling;
- lost-response scenario;
- transaction/cache updates.

### 23.3 Widget tests

The assessment explicitly requires widget tests for:

- Send Money;
- NovaSave contribution.

Also test important validation/offline/pending states where practical.

### 23.4 Integration tests

At least one integration test must prove the required offline lifecycle.

The critical test should demonstrate:

```text
offline
  -> confirm action
  -> persist pending operation
  -> restart/reopen application state
  -> restore pending operation
  -> reconnect
  -> sync
  -> complete exactly once
```

The strongest version also proves that duplicate/repeated triggers do not apply a second effect.

### 23.5 Failure matrix

High-risk sync work should include regression coverage for applicable cases such as:

- offline at confirmation;
- reconnect processing;
- timeout;
- accepted request with lost response;
- app terminates while processing;
- repeated Retry taps;
- overlapping reconnect/resume triggers;
- key reuse with conflicting payload;
- persistence failure.

Not every case must be a separate end-to-end test if lower-level tests prove the invariant more efficiently.

---

## 24. Architecture Decisions

The following decisions are now considered part of the baseline unless higher-priority evidence requires a change.

### AD-01 - Flutter/Dart

Required by the assessment.

### AD-02 - Riverpod

Chosen for state management and dependency injection because it supports explicit dependencies and test overrides without coupling domain logic to widgets.

### AD-03 - Drift/SQLite

Chosen for durable structured persistence because queued operations must survive process/app restart and require atomic state transitions.

### AD-04 - No default HTTP/Dio layer

The assessment supplies no backend. The fake remote sits behind an interface. HTTP may be introduced only if a later explicit requirement justifies it.

### AD-05 - Shared sync subsystem

Replay, claiming, retry, and synchronization are centralized rather than implemented independently inside Send Money and NovaSave.

### AD-06 - Stable idempotency key per logical operation

A retry never becomes a new logical transaction merely because delivery is repeated.

### AD-07 - Fake remote persists idempotency state

The in-process fake remote preserves enough state across client restart scenarios to make duplicate-safe replay demonstrable.

### AD-08 - Foreground/event-triggered synchronization

No background service or periodic retry timer is required for the assessment. Sync runs from reconnect/start/resume/manual-retry triggers.

### AD-09 - Confirmed balance/progress only

Pending operations remain visibly pending. Headline wallet balance and goal progress do not imply successful settlement before confirmation.

### AD-10 - Local savings-goal persistence

With no real backend supplied, goal definitions/state are persisted locally for the assessment. Contributions still pass through the shared money-operation pipeline before confirmed progress is applied.

---

## 25. What This Architecture Deliberately Does Not Add

Do not expand the assessment into unsupported production scope.

Out of scope unless later evidence explicitly requires them:

- authentication/KYC implementation;
- real bank-account lookup;
- real NIBSS/NIP integration;
- background services;
- production API clients;
- push infrastructure;
- encryption-at-rest framework beyond assessment needs;
- production analytics/observability platform;
- complex multi-account reservation/ledger rules not defined by the supplied material;
- stretch goals before mandatory requirements are complete.

---

## 26. Remaining `TO VERIFY` Items

After assessment/design reconciliation, the unresolved architecture questions are intentionally narrow.

### Repository/toolchain state

Until the Flutter repository is bootstrapped/inspected:

- exact Flutter version;
- exact Dart version;
- actual package versions;
- generated-code strategy;
- actual CI environment.

These are implementation/toolchain decisions, not missing assessment requirements.

### Multiple queued outgoing debits (RESOLVED)

The policy for multiple queued outgoing operations against one cached confirmed balance is resolved and implemented in `SpendableBalancePolicy` (`lib/sync/domain/spendable_balance_policy.dart`):

- **Confirmed Balance Display:** The headline wallet balance continues to display the confirmed cached balance from the local store/remote until an operation completes successfully (per AD-09 / UI design flows).
- **Available Spendable Balance:** Outgoing transfer and contribution entry screens validate against `spendableBalance = max(0, confirmedBalance - sum(activePendingKobo))`.
- **Reservation Lifecycle:** Outgoing operations in `pending` and `processing` statuses reserve funds. Completed operations are reflected in confirmed balance updates without double deduction. Terminally failed operations release their reservations immediately.
- See Section 16 for the complete reservation ledger specification.

Everything previously marked `TO VERIFY` regarding a production backend/API/authentication contract is removed: the assessment explicitly provides no real backend and gives the project ownership of the fake implementation.

---

## 27. Architecture Invariants for Review

A change is architecturally invalid if it causes any of the following:

- monetary business logic uses floating-point values;
- an offline operation can be reported saved before durable persistence;
- a retry generates a new idempotency key for the same logical action;
- two sync triggers can concurrently process one operation without a claim/serialization guard;
- app restart can lose a pending operation;
- an uncertain response is treated as proof of failure and resent under a new key;
- a recoverable sync failure discards the user's intent;
- widgets call Drift or the fake remote directly;
- Send Money and NovaSave implement independent replay engines;
- an unbounded silent retry loop is introduced;
- pending state makes wallet balance or goal progress look successfully settled;
- required accessibility or lazy-list constraints are designed out of the implementation.

These invariants should drive Risk A reviews and the highest-value regression tests.

---

## 28. Final Principle

NovaWallet is not an online-first UI with an offline banner added afterward.

Its architecture treats a Send or Contribution as a durable operation with explicit identity, persistence, lifecycle, and replay semantics.

> **Create the intent once. Persist it safely. Deliver it as many times as uncertainty requires. Apply its financial effect once.**
