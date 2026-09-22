# NovaWallet Tasks

**Status:** Pre-implementation executable backlog  
**Purpose:** Convert `docs/IMPLEMENTATION_PLAN.md` into small, reviewable tasks for Claude Code, Codex, Antigravity, or another coding agent.

This file is the execution layer of the project. It does not replace the assessment, approved designs, `AGENTS.md`, architecture, or requirements traceability.

---

## How to Use This File

Before starting any task:

1. Read `AGENTS.md`.
2. Read the task entry below.
3. Read only the referenced architecture, requirements, and design sections.
4. Read `docs/HANDOVER.md` once implementation has begun.
5. Confirm the branch and working tree.
6. Run the task's baseline verification command before editing.
7. Work on the assigned task only.

Task statuses:

```text
[ ] TODO
[-] IN PROGRESS
[x] DONE
[!] BLOCKED
[?] TO VERIFY
```

Risk levels:

- **A** — money, persistence, idempotency, sync, migrations, or data-integrity work.
- **B** — normal feature/application/UI work.
- **C** — low-risk setup, documentation, or mechanical work.

Sizes:

- **S** — focused change, usually a few hours.
- **M** — substantial but coherent change, roughly a working day.
- **L** — likely too large; split before implementation where practical.

---

# Phase 0 — Repository & Toolchain Baseline

## [x] T-BASE-001 — Bootstrap Flutter project

**Risk:** C  
**Size:** S

**Requirements**
- ASM-001
- ASM-025
- ASM-026
- DOC-003
- DOC-004

**Dependencies**
- None

**Read first**
- `AGENTS.md`
- `docs/ARCHITECTURE.md` — repository structure and technology baseline
- `docs/IMPLEMENTATION_PLAN.md` — Phase 0
- `README.md`

**Touch**
- Flutter-generated project files
- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`
- `assets/fonts/`
- `README.md` only for verified Flutter/Dart version/run instructions

**Do not touch**
- feature implementation
- sync implementation
- fake backend implementation
- stretch goals

**Acceptance**
- Given a clean repository, when the project is bootstrapped, then it is a valid Flutter application using the agreed package name.
- Given the selected toolchain, when versions are inspected, then targeted Flutter and Dart versions are recorded in README/repository configuration.
- Given the baseline dependencies, when `flutter pub get` runs, then dependency resolution succeeds.
- Plus Jakarta Sans is available to the project without feature UI being implemented.
- No Dio/HTTP stack is added without a concrete need.

**Verify**
```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

**Update**
- `README.md`
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md` if this produces a meaningful AI example
- `docs/HANDOVER.md`

---

## [x] T-BASE-002 — Configure linting and project test layout

**Risk:** C  
**Size:** S

**Requirements**
- ASM-001
- ASM-022
- ASM-023
- ASM-024

**Dependencies**
- T-BASE-001

**Read first**
- `AGENTS.md`
- `docs/DEFINITION_OF_DONE.md`
- `docs/AGENT_WORKFLOW.md`

**Touch**
- `analysis_options.yaml`
- `test/`
- `integration_test/`
- minimal placeholder/smoke tests if needed

**Do not touch**
- product feature logic
- persistence schema
- routing beyond what bootstrap requires

**Acceptance**
- Analyzer rules are strict enough to catch avoidable type/code-quality issues.
- `test/` mirrors the intended application areas.
- `integration_test/` exists and is ready for later offline-sync coverage.
- A clean baseline test suite passes.

**Verify**
```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

**Update**
- `docs/HANDOVER.md`

---

## [x] T-BASE-003 — Add CI verification

**Risk:** C  
**Size:** S

**Requirements**
- ASM-025
- DOC-004

**Dependencies**
- T-BASE-001
- T-BASE-002

**Read first**
- `docs/GIT_WORKFLOW.md`
- `docs/DEFINITION_OF_DONE.md`

**Touch**
- `.github/workflows/`

**Do not touch**
- application code
- dependencies unless CI requires a documented setup fix

**Acceptance**
- Pull requests can run format, analyze, and test checks.
- CI uses the same repository-supported commands documented for local verification.
- CI does not introduce a second build workflow that conflicts with local development.

**Verify**
```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

**Update**
- `README.md` only if CI usage is worth documenting
- `docs/HANDOVER.md`

---

# Phase 1 — Money, Identity & Core Operation Model

## [x] T-MNY-001 — Implement integer-kobo Money value object

**Risk:** A  
**Size:** S

**Requirements**
- ASM-002
- ASM-014
- MNY-001
- MNY-002
- TST-001

**Dependencies**
- T-BASE-001

**Read first**
- `AGENTS.md` — HC-MONEY
- `docs/ARCHITECTURE.md` — Money
- `docs/REQUIREMENTS_TRACEABILITY.md` — Money requirements

**Touch**
- `lib/core/money/`
- `test/core/money/`

**Do not touch**
- persistence
- routing
- feature UI

**Acceptance**
- Given `12545000` kobo, when formatted, then the result is `₦125,450.00`.
- Given `1000000` kobo, when formatted, then the result is `₦10,000.00`.
- Addition, subtraction, comparison, zero and negative validation are integer-based.
- No financial calculation in this scope uses `double`.

**Verify**
```bash
flutter test test/core/money/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md` if applicable
- `docs/HANDOVER.md`

---

## [x] T-MNY-002 — Implement exact savings-progress calculation

**Risk:** A  
**Size:** S

**Requirements**
- MNY-003
- ASM-008
- NSV-008
- NSV-009
- NSV-014

**Dependencies**
- T-MNY-001

**Read first**
- `AGENTS.md` — HC-MONEY
- `docs/ARCHITECTURE.md` — savings model
- `docs/REQUIREMENTS_TRACEABILITY.md` — MNY/NSV rows

**Touch**
- NovaSave domain calculation code
- corresponding unit tests

**Do not touch**
- NovaSave screens
- sync
- database schema unless genuinely required

**Acceptance**
- Given ₦150,000 saved toward ₦500,000, progress resolves to 30%.
- Given a successful ₦50,000 contribution, projected/confirmed progress resolves to 40%.
- Progress calculation does not use floating-point money arithmetic.
- Edge cases such as zero/invalid target values are handled deliberately.

**Verify**
```bash
flutter test test/features/novasave/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-ID-001 — Implement stable operation and idempotency identities

**Risk:** A  
**Size:** S

**Requirements**
- ASM-006
- ASM-013
- SYNC-006
- SYNC-007
- SND-010
- NSV-012

**Dependencies**
- T-BASE-001

**Read first**
- `AGENTS.md` — HC-IDEMPOTENCY, HC-EXACTLY-ONCE-EFFECT
- `docs/ARCHITECTURE.md` — operation identity/idempotency
- `docs/REQUIREMENTS_TRACEABILITY.md` — SYNC-006/007

**Touch**
- `lib/core/ids/`
- related tests

**Do not touch**
- fake remote
- sync coordinator
- feature screens

**Acceptance**
- One logical operation receives one stable local operation ID.
- One logical operation receives one stable idempotency key.
- Retrying/reloading the same stored operation does not regenerate either identity.
- New user intent creates a different identity.

**Verify**
```bash
flutter test test/core/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md` if applicable
- `docs/HANDOVER.md`

---

## [x] T-OP-001 — Define financial operation model and state transitions

**Risk:** A  
**Size:** S

**Requirements**
- ASM-009
- ASM-010
- ASM-012
- SYNC-014

**Dependencies**
- T-MNY-001
- T-ID-001

**Read first**
- `AGENTS.md` — HC-OFFLINE-DURABILITY, HC-STATE-SEPARATION
- `docs/ARCHITECTURE.md` — operation lifecycle/state separation
- `docs/REQUIREMENTS_TRACEABILITY.md` — Sync requirements

**Touch**
- `lib/sync/domain/`
- unit tests for operation states

**Do not touch**
- Drift implementation
- feature UI
- connectivity implementation

**Acceptance**
- Operation type can represent at least Send and Contribution.
- Operation state distinguishes pending, processing, completed and terminal failure.
- Recoverable sync error metadata can exist without turning a pending operation into a terminal failure.
- Connectivity/sync status is not embedded into the operation enum.
- Invalid transitions are prevented or handled explicitly.

**Verify**
```bash
flutter test test/sync/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-DOM-001 — Decide queued-spendability policy

**Risk:** A  
**Size:** S

**Requirements**
- MNY-006

**Dependencies**
- T-MNY-001
- T-OP-001

**Read first**
- `docs/ARCHITECTURE.md`
- `docs/REQUIREMENTS_TRACEABILITY.md` — MNY-006
- Send Money and NovaSave amount designs

**Touch**
- relevant architecture/requirements documentation
- domain policy/tests if the decision requires code

**Do not touch**
- production-bank rules not supported by the brief
- unrelated feature screens

**Acceptance**
- The project explicitly defines how amount validation behaves when multiple outgoing operations are queued against one cached confirmed balance.
- The decision is simple, defensible for the assessment, and does not pretend to be a production banking rule.
- The policy is testable and documented before Send/Contribution amount validation is finalized.

**Verify**
```bash
flutter test
```

**Update**
- `docs/ARCHITECTURE.md`
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `README.md` only if the trade-off belongs there
- `docs/HANDOVER.md`

---

# Phase 2 — Persistence & Fake Remote

## [x] T-DB-001 — Configure Drift and pending-operation schema

**Risk:** A  
**Size:** M

**Requirements**
- ASM-009
- ASM-012
- SYNC-002
- SYNC-003
- TST-002

**Dependencies**
- T-OP-001
- T-ID-001

**Read first**
- `AGENTS.md` — HC-OFFLINE-DURABILITY
- `docs/ARCHITECTURE.md` — persistence
- `docs/IMPLEMENTATION_PLAN.md` — Phase 2

**Touch**
- `lib/core/persistence/`
- `lib/sync/data/`
- Drift schema/migrations/generated files as required
- persistence tests

**Do not touch**
- feature screens
- sync coordinator
- fake-remote processing

**Acceptance**
- Pending operations persist all data needed to replay the original intent.
- Persistence includes stable operation ID and idempotency key.
- An operation can be inserted, read, updated and restored after database recreation/reopen.
- UI acknowledgment is not part of this task; persistence exposes success/failure to callers.
- Schema/migration strategy is documented and reproducible.

**Verify**
```bash
flutter test test/sync/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-DB-002 — Add local wallet, transaction and goal persistence

**Risk:** A  
**Size:** M

**Requirements**
- WAL-001
- WAL-002
- NSV-001
- NSV-003
- MNY-004
- MNY-005

**Dependencies**
- T-DB-001
- T-MNY-001
- T-MNY-002

**Read first**
- `docs/ARCHITECTURE.md` — local persistence scope
- `docs/REQUIREMENTS_TRACEABILITY.md` — Wallet/NovaSave requirements

**Touch**
- local database models/tables/queries for wallet cache, transactions and goals
- repository tests

**Do not touch**
- full feature UI
- sync coordinator

**Acceptance**
- Wallet balance and transaction rows can be read from local state.
- Savings goals can be persisted/read locally.
- Money values are stored as integer kobo.
- Confirmed data and pending-operation data remain distinguishable.

**Verify**
```bash
flutter test test/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-REMOTE-001 — Implement idempotent fake remote

**Risk:** A  
**Size:** M

**Requirements**
- ASM-006
- ASM-011
- ASM-013
- SYNC-008
- SYNC-009
- TST-003

**Dependencies**
- T-ID-001
- T-OP-001

**Read first**
- `AGENTS.md` — HC-IDEMPOTENCY, HC-EXACTLY-ONCE-EFFECT
- `docs/ARCHITECTURE.md` — fake remote
- `docs/REQUIREMENTS_TRACEABILITY.md` — SYNC-008/009

**Touch**
- `lib/fake_backend/`
- `test/fake_backend/`

**Do not touch**
- feature UI
- sync coordinator
- connectivity

**Acceptance**
- First request with a new idempotency key produces one stored result/effect.
- Repeated request with the same key and same payload returns/reuses the existing result without a second effect.
- Repeated key with conflicting payload is rejected/flagged.
- Send and Contribution are both supported.
- Fake-remote behavior is deterministic in tests.

**Verify**
```bash
flutter test test/fake_backend/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md` if applicable
- `docs/HANDOVER.md`

---

## [x] T-REMOTE-002 — Add deterministic failure simulation

**Risk:** A  
**Size:** S

**Requirements**
- SYNC-011
- SYNC-012
- TST-007
- SND-013
- SND-019
- NSV-015
- NSV-022

**Dependencies**
- T-REMOTE-001

**Read first**
- `docs/ARCHITECTURE.md` — error/failure handling
- relevant Send/NovaSave failure screens

**Touch**
- `lib/fake_backend/failure_simulator.dart` or equivalent
- fake backend tests

**Do not touch**
- UI
- retry policy implementation

**Acceptance**
- Tests can deterministically trigger at least:
  - immediate rejection/failure;
  - transient transport-style failure;
  - response-lost/uncertain outcome after the remote has applied the effect.
- Failure modes can be injected without random/flaky tests.
- Error categories expose enough information for sync/application layers to classify recoverable vs terminal outcomes.

**Verify**
```bash
flutter test test/fake_backend/
flutter analyze
```

**Update**
- `docs/HANDOVER.md`

---

# Phase 3 — Connectivity, Queue & Synchronization

## [x] T-CONN-001 — Implement connectivity abstraction

**Risk:** B  
**Size:** S

**Requirements**
- SYNC-001
- ASM-009
- ASM-011

**Dependencies**
- T-BASE-001

**Read first**
- `docs/ARCHITECTURE.md` — connectivity
- `AGENTS.md` — HC-STATE-SEPARATION

**Touch**
- `lib/core/connectivity/`
- provider/adapter tests

**Do not touch**
- sync logic
- feature UI beyond test harnesses

**Acceptance**
- Application code can observe online/offline through an injectable abstraction.
- Tests can override connectivity deterministically.
- Connectivity state contains only connectivity concerns; no sync status is embedded.

**Verify**
```bash
flutter test test/core/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-SYNC-001 — Implement durable enqueue API

**Risk:** A  
**Size:** S

**Requirements**
- ASM-009
- ASM-012
- SYNC-002
- SND-015
- NSV-017

**Dependencies**
- T-DB-001
- T-OP-001

**Read first**
- `AGENTS.md` — HC-OFFLINE-DURABILITY
- `docs/ARCHITECTURE.md` — queue/repository responsibilities

**Touch**
- `lib/sync/data/`
- `lib/sync/application/` only if needed for enqueue use case
- queue tests

**Do not touch**
- sync replay
- feature screens

**Acceptance**
- Send and Contribution intents can be durably enqueued.
- Caller receives "saved" only after persistence succeeds.
- Failed persistence never produces a false saved/pending acknowledgment.
- Stored operation retains stable IDs/payload across reopen.

**Verify**
```bash
flutter test test/sync/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-SYNC-002 — Implement single shared sync coordinator and operation claim

**Risk:** A  
**Size:** M

**Requirements**
- ASM-011
- ASM-013
- SYNC-004
- SYNC-005
- SYNC-010

**Dependencies**
- T-SYNC-001
- T-REMOTE-001
- T-CONN-001

**Read first**
- `AGENTS.md` — HC-SYNC, HC-EXACTLY-ONCE-EFFECT
- `docs/ARCHITECTURE.md` — synchronization service
- `docs/REQUIREMENTS_TRACEABILITY.md` — SYNC-004/005/010

**Touch**
- `lib/sync/application/`
- sync repository query/claim code
- sync unit/repository tests

**Do not touch**
- Send Money UI
- NovaSave UI

**Acceptance**
- One shared coordinator processes both Send and Contribution operations.
- Eligible operations are claimed atomically/conditionally before processing.
- Two concurrent sync triggers cannot actively process the same operation.
- Processing order is deterministic.
- Successful remote result is persisted locally before operation completion is exposed.

**Verify**
```bash
flutter test test/sync/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md` if applicable
- `docs/HANDOVER.md`

---

## [x] T-SYNC-003 — Implement restart recovery

**Risk:** A  
**Size:** M

**Requirements**
- ASM-012
- ASM-013
- SYNC-003
- SYNC-011
- SND-016
- NSV-019

**Dependencies**
- T-SYNC-002
- T-REMOTE-002

**Read first**
- `AGENTS.md` — HC-OFFLINE-DURABILITY, HC-EXACTLY-ONCE-EFFECT
- `docs/ARCHITECTURE.md` — interruption recovery

**Touch**
- sync/application lifecycle recovery
- operation repository queries/state recovery
- tests

**Do not touch**
- UI except minimal test harness wiring

**Acceptance**
- Pending operation survives process/database reopen.
- Interrupted "processing" state is recovered safely.
- If remote success happened before local completion, replay uses the same idempotency key and causes one financial effect.
- Recovery behavior is deterministic and tested.

**Verify**
```bash
flutter test test/sync/
flutter test test/fake_backend/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md` if applicable
- `docs/HANDOVER.md`

---

## [x] T-SYNC-004 — Implement failure classification and retry policy

**Risk:** A  
**Size:** M

**Requirements**
- ASM-010
- SYNC-012
- SYNC-013
- SND-019
- SND-020
- NSV-022
- NSV-023

**Dependencies**
- T-SYNC-002
- T-REMOTE-002

**Read first**
- `AGENTS.md` — HC-RETRY, HC-STATE-SEPARATION
- `docs/ARCHITECTURE.md` — failures/retry
- Send Money UI-SND-13/UI-SND-18
- NovaSave UI-NSV-15/UI-NSV-21

**Touch**
- `lib/sync/application/`
- operation error metadata/state
- retry tests

**Do not touch**
- final feature UI

**Acceptance**
- Recoverable/uncertain failure retains operation as durable/retryable.
- Terminal rejection can be represented distinctly.
- Manual retry reuses the same operation/idempotency key.
- Automatic processing is trigger-based; there is no uncontrolled timer/retry loop.
- Retry cannot race a currently claimed operation.

**Verify**
```bash
flutter test test/sync/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-SYNC-005 — Prove offline → restart → reconnect kernel

**Risk:** A  
**Size:** M

**Requirements**
- ASM-011
- ASM-012
- ASM-013
- TST-006
- SYNC-011

**Dependencies**
- T-SYNC-003
- T-SYNC-004

**Read first**
- `docs/DEFINITION_OF_DONE.md` — Offline/Sync, Integration
- `docs/REQUIREMENTS_TRACEABILITY.md` — TST-006

**Touch**
- integration/repository-level test harness
- minimal wiring required to exercise the sync kernel

**Do not touch**
- polished feature UI
- design system

**Acceptance**
- Given an offline financial operation, when it is enqueued and the app/data layer is recreated, then the operation is still pending.
- When connectivity is restored, the operation is processed.
- The resulting financial effect occurs once.
- Replaying the same operation again cannot duplicate the effect.
- The test fails if idempotency or restart recovery is removed.

**Verify**
```bash
flutter test
```

Use `flutter test integration_test` if this task is implemented at app-integration level; otherwise the final app-level scenario remains T-TST-003.

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md`
- `docs/HANDOVER.md`

---

# Phase 4 — Design System & App Shell

## [x] T-DS-001 — Implement design tokens, theme, font and icons

**Risk:** C  
**Size:** M

**Requirements**
- DSN-001
- DSN-002
- DSN-003
- DSN-004
- DSN-005
- DSN-006

**Dependencies**
- T-BASE-001

**Read first**
- `docs/DESIGN_SYSTEM.md`
- `docs/design/SCREEN_INDEX.md` — UI-DS-01 through UI-DS-04
- Style Guide PDF

**Touch**
- `lib/design_system/tokens/`
- `lib/design_system/theme/`
- `lib/design_system/icons/`

**Do not touch**
- feature screens
- feature-specific business logic

**Acceptance**
- Approved color scales are centralized.
- Plus Jakarta Sans typography styles are centralized.
- Spacing/radius/elevation tokens are centralized.
- Approved icons are exposed through one project abstraction.
- No feature-specific hardcoded design values are introduced in this task.

**Verify**
```bash
flutter test
flutter analyze
```

**Visual references**
- UI-DS-01
- UI-DS-02
- UI-DS-03
- UI-DS-04

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-DS-002 — Implement shared UI components

**Risk:** B  
**Size:** M

**Requirements**
- DSN-007
- DSN-008
- DSN-009
- DSN-010
- DSN-012
- DSN-013
- DSN-014
- A11Y-001
- A11Y-002

**Dependencies**
- T-DS-001

**Read first**
- `docs/DESIGN_SYSTEM.md`
- `docs/design/SCREEN_INDEX.md` — UI-CMP-01/02/03/04/07/08/09
- Design Components PDF

**Touch**
- `lib/design_system/components/`
- component widget tests

**Do not touch**
- feature controllers/repositories
- feature-specific screen composition

**Acceptance**
- Shared buttons, fields, notifications, status/result visuals, cards/list rows, progress and empty-state primitives exist.
- Components accept state/data rather than fetching their own data.
- Important controls expose Semantics.
- Components tolerate text scaling without fixed-height clipping where practical.

**Verify**
```bash
flutter test test/design_system/
flutter analyze
```

**Visual references**
- UI-CMP-01
- UI-CMP-02
- UI-CMP-03
- UI-CMP-04
- UI-CMP-07
- UI-CMP-08
- UI-CMP-09

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-APP-001 — Implement app shell, routing and bottom navigation

**Risk:** B  
**Size:** M

**Requirements**
- ASM-001
- DSN-011
- A11Y-001

**Dependencies**
- T-DS-001
- T-DS-002

**Read first**
- `docs/ARCHITECTURE.md` — navigation/app shell
- `docs/design/SCREEN_INDEX.md` — UI-CMP-05
- Design Components PDF navigation page

**Touch**
- `lib/app/`
- app-level providers
- routing
- navigation widget tests

**Do not touch**
- feature business logic
- sync internals

**Acceptance**
- App launches into the approved shell.
- Wallet, Send and NovaSave primary destinations are navigable.
- Bottom navigation matches supplied state treatment.
- App-level dependencies/providers can be overridden in tests.
- Canonical visual-QA emulator/device profile is selected and documented after comparing source frames/runtime.

**Verify**
```bash
flutter test
flutter analyze
```

**Visual references**
- UI-CMP-05

**Update**
- `docs/design/SCREEN_INDEX.md` — canonical QA device section
- `docs/HANDOVER.md`

---

# Phase 5 — Wallet

## [x] T-WAL-001 — Implement wallet data projection and repositories

**Risk:** B  
**Size:** M

**Requirements**
- WAL-001
- WAL-002
- MNY-004

**Dependencies**
- T-DB-002
- T-MNY-001

**Read first**
- `docs/ARCHITECTURE.md` — Wallet repository
- `docs/REQUIREMENTS_TRACEABILITY.md` — Wallet
- UI-WAL-01

**Touch**
- `lib/features/wallet/domain/`
- `lib/features/wallet/data/`
- wallet repository tests

**Do not touch**
- polished Wallet screen
- Send Money screens

**Acceptance**
- Wallet repository exposes confirmed balance and transactions.
- Pending/completed operation projections can later be composed into wallet presentation.
- Money remains integer-kobo in domain/data.
- Repository can refresh/replace cached confirmed wallet data through the fake/local source strategy.

**Verify**
```bash
flutter test test/features/wallet/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-WAL-002 — Implement wallet home, lazy transactions and refresh

**Risk:** B  
**Size:** M

**Requirements**
- ASM-002
- ASM-003
- ASM-004
- ASM-017
- WAL-001
- WAL-002
- WAL-003
- PERF-001

**Dependencies**
- T-WAL-001
- T-APP-001

**Read first**
- UI-WAL-01
- UI-WAL-07
- `docs/DESIGN_SYSTEM.md`
- `docs/design/pdf/Wallet.pdf`

**Touch**
- `lib/features/wallet/presentation/`
- Wallet widget tests

**Do not touch**
- Send Money implementation
- NovaSave implementation
- sync coordinator internals

**Acceptance**
- Default Wallet matches UI-WAL-01 materially.
- Balance formats from integer kobo.
- Recent activity is lazy (`ListView.builder` or equivalent).
- Pull-to-refresh triggers the wallet refresh path.
- Refreshing presentation matches UI-WAL-07.
- Visual QA screenshot is compared against source.

**Verify**
```bash
flutter test test/features/wallet/
flutter analyze
```

**Visual references**
- UI-WAL-01
- UI-WAL-07

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-WAL-003 — Implement Wallet offline/pending/reconnect/sync-failure states

**Risk:** B  
**Size:** M

**Requirements**
- WAL-005
- WAL-006
- WAL-007
- WAL-008
- WAL-009
- ASM-009
- ASM-011

**Dependencies**
- T-WAL-002
- T-SYNC-004

**Read first**
- UI-WAL-02 through UI-WAL-06
- Wallet PDF
- Flow 3 Offline Send and Reconnect PDF

**Touch**
- Wallet presentation/projections
- Wallet state/widget tests

**Do not touch**
- sync engine algorithms except through approved interfaces

**Acceptance**
- Offline banner/last-updated state matches UI-WAL-02.
- Pending transfer row matches UI-WAL-03.
- Reconnect/processing projection matches UI-WAL-04.
- Successful operation updates confirmed balance and row once, matching UI-WAL-05.
- Recoverable sync failure preserves the pending intent and matches UI-WAL-06.
- Visual QA is performed for each state.

**Verify**
```bash
flutter test test/features/wallet/
flutter analyze
```

**Visual references**
- UI-WAL-02
- UI-WAL-03
- UI-WAL-04
- UI-WAL-05
- UI-WAL-06

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-WAL-004 — Implement Wallet loading, empty and pending-detail states

**Risk:** B  
**Size:** S

**Requirements**
- WAL-004
- WAL-010
- WAL-011

**Dependencies**
- T-WAL-002

**Read first**
- UI-WAL-08
- UI-WAL-09
- UI-WAL-10
- Wallet PDF

**Touch**
- Wallet presentation
- Wallet widget tests

**Do not touch**
- sync internals

**Acceptance**
- Loading/skeleton state matches UI-WAL-08.
- Empty transaction state matches UI-WAL-09.
- Pending transaction details show amount, recipient, saved time/status and saved-on-phone explanation matching UI-WAL-10.

**Verify**
```bash
flutter test test/features/wallet/
flutter analyze
```

**Visual references**
- UI-WAL-08
- UI-WAL-09
- UI-WAL-10

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

# Phase 6 — Send Money

## [x] T-SND-001 — Implement recipient entry, validation and fake resolution

**Risk:** B  
**Size:** M

**Requirements**
- ASM-005
- SND-001
- SND-002
- SND-003
- SND-004

**Dependencies**
- T-APP-001

**Read first**
- UI-SND-01 through UI-SND-04
- Send Money PDF
- `docs/DESIGN_SYSTEM.md`

**Touch**
- Send Money domain/data/presentation for recipient step
- corresponding tests

**Do not touch**
- amount step
- sync engine

**Acceptance**
- Empty recipient state renders correctly.
- Required error appears when appropriate.
- Invalid fake account is rejected.
- Supported fake account resolves to the designed recipient example/fixture.
- Continue becomes available only for valid resolved input.

**Verify**
```bash
flutter test test/features/send_money/
flutter analyze
```

**Visual references**
- UI-SND-01
- UI-SND-02
- UI-SND-03
- UI-SND-04

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-SND-002 — Implement amount entry and balance validation

**Risk:** A  
**Size:** M

**Requirements**
- SND-005
- SND-006
- SND-007
- SND-008
- MNY-003
- MNY-006

**Dependencies**
- T-SND-001
- T-DOM-001
- T-MNY-001
- T-CONN-001

**Read first**
- UI-SND-05 through UI-SND-09
- Send Money PDF
- queued-spendability policy from architecture

**Touch**
- Send Money amount domain/application/presentation
- tests

**Do not touch**
- confirmation/submit
- sync engine internals

**Acceptance**
- Amount input is based on integer-kobo Money.
- Zero/non-positive amount is rejected.
- Over-balance/spendability amount is rejected according to the documented policy.
- Offline amount state shows last-updated balance copy.
- Display/validation matches approved designs.

**Verify**
```bash
flutter test test/features/send_money/
flutter analyze
```

**Visual references**
- UI-SND-05
- UI-SND-06
- UI-SND-07
- UI-SND-08
- UI-SND-09

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-SND-003 — Implement confirmation and operation creation

**Risk:** A  
**Size:** M

**Requirements**
- SND-009
- SND-010
- SND-014
- SND-015
- ASM-006
- ASM-009

**Dependencies**
- T-SND-002
- T-SYNC-001
- T-ID-001

**Read first**
- UI-SND-10
- UI-SND-14
- `docs/ARCHITECTURE.md` — financial operation submission

**Touch**
- Send Money application/controller
- confirmation screens
- enqueue/online submission wiring
- tests

**Do not touch**
- sync coordinator internals unless an interface defect is discovered and reported

**Acceptance**
- Online confirmation shows recipient, amount, source and balance-after.
- Offline confirmation explains that the operation will be saved.
- One logical transfer creates one stable operation ID/idempotency key.
- Offline confirm persists before pending/saved UI is shown.
- Double tap cannot create two logical operations unintentionally.

**Verify**
```bash
flutter test test/features/send_money/
flutter test test/sync/
flutter analyze
```

**Visual references**
- UI-SND-10
- UI-SND-14

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md` if applicable
- `docs/HANDOVER.md`

---

## [x] T-SND-004 — Implement online processing, success and immediate failure

**Risk:** B  
**Size:** M

**Requirements**
- SND-011
- SND-012
- SND-013
- MNY-004

**Dependencies**
- T-SND-003
- T-REMOTE-002

**Read first**
- UI-SND-11
- UI-SND-12
- UI-SND-13
- Flow 1 Successful Send PDF

**Touch**
- Send Money presentation/application
- widget/integration tests

**Do not touch**
- offline reconnect states except shared result components

**Acceptance**
- Processing state advances without an extra user tap.
- Success shows amount, recipient, reference/date/status.
- Confirmed wallet state changes only after remote success.
- Immediate terminal failure shows that nothing was taken and provides the designed actions.
- Visual QA matches approved states.

**Verify**
```bash
flutter test test/features/send_money/
flutter analyze
```

**Visual references**
- UI-SND-11
- UI-SND-12
- UI-SND-13

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-SND-005 — Implement pending, reconnect and sync-failure Send states

**Risk:** A  
**Size:** M

**Requirements**
- SND-015
- SND-016
- SND-017
- SND-018
- SND-019
- SND-020
- ASM-011
- ASM-012
- ASM-013

**Dependencies**
- T-SND-003
- T-SYNC-004
- T-WAL-003

**Read first**
- UI-SND-15 through UI-SND-18
- Flow 2 Offline Send PDF
- Flow 3 Offline Send and Reconnect PDF

**Touch**
- Send Money presentation/application projections
- relevant widget/integration tests

**Do not touch**
- introduce a second Send-specific sync loop

**Acceptance**
- Pending transfer result matches UI-SND-15 and survives restart.
- Reconnect processing matches UI-SND-16.
- Reconnect success matches UI-SND-17 and updates wallet exactly once.
- Recoverable sync failure matches UI-SND-18 and keeps transfer saved.
- Manual retry reuses the original operation/idempotency key.

**Verify**
```bash
flutter test test/features/send_money/
flutter test test/sync/
flutter analyze
```

**Visual references**
- UI-SND-15
- UI-SND-16
- UI-SND-17
- UI-SND-18

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md` if applicable
- `docs/HANDOVER.md`

---

# Phase 7 — NovaSave Goal Creation

## [x] T-NSV-001 — Implement goal list and empty state

**Risk:** B  
**Size:** M

**Requirements**
- NSV-001
- NSV-002

**Dependencies**
- T-DB-002
- T-APP-001
- T-DS-002

**Read first**
- UI-NSV-01
- UI-NSV-03
- NovaSave PDF

**Touch**
- NovaSave repositories/presentation for goal list
- widget tests

**Do not touch**
- contribution flow

**Acceptance**
- Populated goal cards display name, saved amount, target, percentage and target date.
- Empty state matches approved design.
- Goal list is driven by persisted local data.

**Verify**
```bash
flutter test test/features/novasave/
flutter analyze
```

**Visual references**
- UI-NSV-01
- UI-NSV-03

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-NSV-002 — Implement create-goal form, validation and date picker

**Risk:** B  
**Size:** M

**Requirements**
- ASM-007
- NSV-003
- NSV-004
- NSV-005
- NSV-006
- NSV-007

**Dependencies**
- T-NSV-001
- T-MNY-001

**Read first**
- UI-NSV-04 through UI-NSV-07
- Flow 4 Create Savings Goal PDF
- NovaSave PDF

**Touch**
- NovaSave domain/application/presentation for goal creation
- tests

**Do not touch**
- contribution processing
- sync

**Acceptance**
- Name is required.
- Target amount must be positive integer-kobo Money.
- Target date must be in the future.
- Date picker behavior/layout follows design.
- Valid submission persists a goal and navigates to goal details.

**Verify**
```bash
flutter test test/features/novasave/
flutter analyze
```

**Visual references**
- UI-NSV-04
- UI-NSV-05
- UI-NSV-06
- UI-NSV-07

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-NSV-003 — Implement goal details and progress

**Risk:** B  
**Size:** S

**Requirements**
- ASM-008
- NSV-008
- MNY-003

**Dependencies**
- T-NSV-002
- T-MNY-002

**Read first**
- UI-NSV-08
- Flow 4 Create Savings Goal PDF

**Touch**
- NovaSave goal-detail presentation/domain projection
- tests

**Do not touch**
- contribution submission

**Acceptance**
- Goal detail shows saved amount, target, percentage, remaining amount and target date.
- Values derive from integer-kobo domain data.
- Progress matches the approved design treatment.

**Verify**
```bash
flutter test test/features/novasave/
flutter analyze
```

**Visual references**
- UI-NSV-08

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

# Phase 8 — NovaSave Contribution

## [x] T-NSC-001 — Implement contribution amount and validation

**Risk:** A  
**Size:** M

**Requirements**
- NSV-009
- NSV-010
- MNY-003
- MNY-006

**Dependencies**
- T-NSV-003
- T-DOM-001

**Read first**
- UI-NSV-09
- UI-NSV-10
- NovaSave PDF
- queued-spendability policy

**Touch**
- NovaSave contribution domain/application/presentation
- tests

**Do not touch**
- submission/sync wiring

**Acceptance**
- Contribution amount uses integer-kobo Money.
- Wallet balance is displayed.
- Projected saved amount/progress is exact.
- Over-wallet/spendable-balance contribution is rejected according to documented policy.

**Verify**
```bash
flutter test test/features/novasave/
flutter analyze
```

**Visual references**
- UI-NSV-09
- UI-NSV-10

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-NSC-002 — Implement contribution confirmation and operation creation

**Risk:** A  
**Size:** M

**Requirements**
- NSV-011
- NSV-012
- NSV-016
- NSV-017
- ASM-009
- ASM-013

**Dependencies**
- T-NSC-001
- T-SYNC-001
- T-ID-001

**Read first**
- UI-NSV-11
- UI-NSV-16
- Flow 5/6 Contribution PDFs

**Touch**
- contribution controller/application
- confirm screens
- operation creation/enqueue wiring
- tests

**Do not touch**
- sync engine internals

**Acceptance**
- Online confirmation matches approved design.
- Offline confirmation clearly explains local save behavior.
- One logical contribution creates one stable operation/idempotency identity.
- Offline confirm persists before pending UI is shown.
- Confirmed goal progress is not changed merely by queueing.

**Verify**
```bash
flutter test test/features/novasave/
flutter test test/sync/
flutter analyze
```

**Visual references**
- UI-NSV-11
- UI-NSV-16

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md` if applicable
- `docs/HANDOVER.md`

---

## [x] T-NSC-003 — Implement online contribution processing, success and failure

**Risk:** B  
**Size:** M

**Requirements**
- NSV-013
- NSV-014
- NSV-015
- MNY-005

**Dependencies**
- T-NSC-002
- T-REMOTE-002

**Read first**
- UI-NSV-12 through UI-NSV-15
- Flow 5 Successful Contribution PDF

**Touch**
- NovaSave contribution presentation/application
- widget/integration tests

**Do not touch**
- offline reconnect states

**Acceptance**
- Processing advances automatically.
- Success updates saved amount/progress only after remote success.
- Updated goal details reflect confirmed 40% example behavior where fixture values match.
- Failure states preserve confirmed values and show retry/back actions.
- Visual QA matches approved states.

**Verify**
```bash
flutter test test/features/novasave/
flutter analyze
```

**Visual references**
- UI-NSV-12
- UI-NSV-13
- UI-NSV-14
- UI-NSV-15

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [x] T-NSC-004 — Implement pending, reconnect and sync-failure Contribution states

**Risk:** A  
**Size:** M

**Requirements**
- NSV-017
- NSV-018
- NSV-019
- NSV-020
- NSV-021
- NSV-022
- NSV-023

**Dependencies**
- T-NSC-002
- T-SYNC-004

**Read first**
- UI-NSV-17 through UI-NSV-21
- Flow 6 Offline Contribution and Reconnect PDF

**Touch**
- NovaSave contribution projections/presentation
- widget/integration tests

**Do not touch**
- create a NovaSave-specific sync engine

**Acceptance**
- Pending contribution result matches UI-NSV-17.
- Goal detail shows pending amount separately while confirmed progress remains unchanged, matching UI-NSV-18.
- Pending contribution survives restart.
- Reconnect processing matches UI-NSV-19.
- Reconnect success updates goal once and matches UI-NSV-20.
- Recoverable sync failure keeps contribution saved and matches UI-NSV-21.
- Manual retry reuses original operation/idempotency key.

**Verify**
```bash
flutter test test/features/novasave/
flutter test test/sync/
flutter analyze
```

**Visual references**
- UI-NSV-17
- UI-NSV-18
- UI-NSV-19
- UI-NSV-20
- UI-NSV-21

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md` if applicable
- `docs/HANDOVER.md`

---

# Phase 9 — Cross-Feature Consistency

## [ ] T-XF-001 — Reconcile confirmed wallet and transaction state after operations

**Risk:** A  
**Size:** M

**Requirements**
- MNY-004
- MNY-005
- WAL-008
- SND-018
- NSV-021

**Dependencies**
- T-SND-005
- T-NSC-004

**Read first**
- `docs/ARCHITECTURE.md` — cross-feature consistency
- relevant wallet/send/contribution success designs

**Touch**
- shared repositories/projections needed for confirmed effects
- cross-feature tests

**Do not touch**
- invent unsupported fees/limits/production ledger semantics

**Acceptance**
- Completed Send changes confirmed wallet state once.
- Completed Contribution changes confirmed goal state once.
- Applying remote financial effect to local confirmed balance and setting operation status to completed must execute in a single atomic local database transaction to prevent spendable balance overspend windows.
- Wallet transaction history reflects completed operations consistently.
- Replaying/reloading a completed idempotent operation does not duplicate projections.

**Verify**
```bash
flutter test
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [ ] T-XF-002 — Normalize pending/retry/status presentation across features

**Risk:** B  
**Size:** S

**Requirements**
- WAL-006
- WAL-009
- SND-019
- NSV-018
- NSV-022
- SYNC-014

**Dependencies**
- T-XF-001

**Read first**
- `docs/DESIGN_SYSTEM.md`
- UI-CMP-03
- UI-CMP-04
- relevant Wallet/Send/NovaSave pending/failure states

**Touch**
- shared presentation mappings/components
- feature presentation adapters
- tests

**Do not touch**
- operation lifecycle semantics

**Acceptance**
- Pending, processing, recoverable sync failure and terminal failure use consistent meanings across features.
- Feature-specific copy remains faithful to designs.
- Connectivity banners do not replace transaction/operation statuses.

**Verify**
```bash
flutter test
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

# Phase 10 — Accessibility, Performance & Visual Reconciliation

## [ ] T-A11Y-001 — Accessibility and font-scale pass

**Risk:** B  
**Size:** M

**Requirements**
- ASM-015
- ASM-016
- A11Y-001
- A11Y-002
- A11Y-003

**Dependencies**
- T-SND-005
- T-NSC-004
- T-WAL-004

**Read first**
- `docs/DEFINITION_OF_DONE.md` — Accessibility
- `docs/DESIGN_SYSTEM.md`

**Touch**
- feature/design-system presentation code
- accessibility widget tests

**Do not touch**
- financial/domain logic unless a genuine bug is found and separately reported

**Acceptance**
- Key controls have meaningful Semantics.
- Validation/status meaning is not color-only.
- Critical journeys remain usable at increased system text scale.
- Fixed-height assumptions causing clipped/inaccessible text are corrected.

**Verify**
```bash
flutter test
flutter analyze
```

Also perform manual/emulator checks at increased text scale.

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [ ] T-PERF-001 — Wallet list and low-end usability pass

**Risk:** B  
**Size:** S

**Requirements**
- ASM-017
- PERF-001
- PERF-002

**Dependencies**
- T-WAL-004

**Read first**
- `docs/DEFINITION_OF_DONE.md` — Performance
- assessment operating context

**Touch**
- wallet list/presentation only where needed
- performance-focused tests/review notes

**Do not touch**
- invent a mandatory 10,000-row benchmark

**Acceptance**
- Recent transactions are lazily constructed.
- No obvious avoidable heavy work occurs in item/widget build paths.
- Wallet remains usable with a realistically larger local list.
- Any profiling/hardening beyond the assessment is documented as optional rather than required.

**Verify**
```bash
flutter test test/features/wallet/
flutter analyze
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [ ] T-VIS-001 — Final design reconciliation

**Risk:** B  
**Size:** M

**Requirements**
- DSN-001 through DSN-014
- all implemented UI-* states

**Dependencies**
- T-A11Y-001
- T-PERF-001
- T-XF-002

**Read first**
- `docs/design/SCREEN_INDEX.md`
- `docs/DESIGN_SYSTEM.md`
- all approved design PDFs

**Touch**
- presentation/design-system code only for verified visual mismatches
- optional `docs/design/references/` crops if useful

**Do not touch**
- business logic as visual cleanup

**Acceptance**
- Every mandatory implemented UI state is reviewed against its SCREEN_INDEX source.
- Canonical 1.0 text-scale captures are compared to approved designs.
- Material spacing, typography, color, radius, icon, alignment and component-state differences are corrected.
- Accessibility behavior at enlarged text scale remains intact.
- No state is "fixed" visually by breaking domain/sync behavior.

**Verify**
```bash
flutter test
flutter analyze
```

Plus emulator/device visual review.

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

# Phase 11 — Required Test Completion & Failure Matrix

## [ ] T-TST-001 — Complete required Send Money widget coverage

**Risk:** B  
**Size:** S

**Requirements**
- ASM-022
- TST-004

**Dependencies**
- T-SND-005

**Read first**
- `docs/REQUIREMENTS_TRACEABILITY.md` — Send requirements
- `docs/DEFINITION_OF_DONE.md` — Testing

**Touch**
- `test/features/send_money/`

**Acceptance**
- Widget tests cover the required Send Money journey.
- Validation, confirmation and key result/pending states have regression coverage.
- Tests assert behavior/state, not only existence of widgets.

**Verify**
```bash
flutter test test/features/send_money/
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [ ] T-TST-002 — Complete required NovaSave contribution widget coverage

**Risk:** B  
**Size:** S

**Requirements**
- ASM-023
- TST-005

**Dependencies**
- T-NSC-004

**Read first**
- `docs/REQUIREMENTS_TRACEABILITY.md` — NovaSave contribution
- `docs/DEFINITION_OF_DONE.md` — Testing

**Touch**
- `test/features/novasave/`

**Acceptance**
- Widget tests cover the contribution flow.
- Amount validation, confirmation, processing, success/failure and pending states have appropriate coverage.
- Tests verify confirmed progress does not advance merely because an offline contribution was queued.

**Verify**
```bash
flutter test test/features/novasave/
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [ ] T-TST-003 — Add required app-level offline queue → restart → reconnect integration test

**Risk:** A  
**Size:** M

**Requirements**
- ASM-024
- ASM-012
- ASM-013
- TST-006

**Dependencies**
- T-SND-005
- T-NSC-004
- T-XF-001

**Read first**
- `docs/DEFINITION_OF_DONE.md` — Integration
- `docs/REQUIREMENTS_TRACEABILITY.md` — TST-006

**Touch**
- `integration_test/`
- test-only dependency overrides/helpers if needed

**Do not touch**
- production behavior solely to make the test easy unless the change improves testability through existing abstractions

**Acceptance**
- Test performs a real application-level financial flow while offline.
- Operation is shown/saved as pending.
- Application/data state is restarted/recreated.
- Reconnect triggers sync.
- Completed state appears.
- The financial effect is asserted exactly once.
- The test would fail if the queue were non-durable or idempotency were removed.

**Verify**
```bash
flutter test integration_test
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md` if this produced a meaningful debugging example
- `docs/HANDOVER.md`

---

## [ ] T-TST-004 — Add high-value sync failure regression matrix

**Risk:** A  
**Size:** M

**Requirements**
- TST-007
- SYNC-010
- SYNC-011
- SYNC-012
- SYNC-013

**Dependencies**
- T-TST-003
- T-REMOTE-002

**Read first**
- `docs/ARCHITECTURE.md` — failure/idempotency
- `docs/DEFINITION_OF_DONE.md` — Financial Integrity

**Touch**
- sync/fake-backend unit/integration tests

**Acceptance**
- Regression coverage includes:
  - repeated same-key delivery;
  - conflicting same-key payload;
  - concurrent sync triggers;
  - response lost after remote success;
  - app interruption before local completion;
  - manual retry;
  - transient failure retaining intent.
- Tests remain deterministic.

**Verify**
```bash
flutter test
flutter test integration_test
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `AI_USAGE.md` where relevant
- `docs/HANDOVER.md`

---

# Phase 12 — Documentation & Submission Readiness

## [ ] T-DOC-001 — Finalize README and AI usage

**Risk:** C  
**Size:** S

**Requirements**
- ASM-019
- ASM-020
- ASM-021
- ASM-026
- DOC-001
- DOC-002
- DOC-003

**Dependencies**
- T-TST-004
- T-VIS-001

**Read first**
- assessment deliverables
- `README.md`
- `AI_USAGE.md`

**Touch**
- `README.md`
- `AI_USAGE.md`

**Acceptance**
- README describes implemented architecture, state management, offline/sync design, trade-offs, run/test instructions and targeted Flutter/Dart versions.
- README makes no speculative implementation claims.
- AI_USAGE lists only tools actually used.
- AI_USAGE contains 2–3 concrete prompts/results.
- AI_USAGE includes at least one real wrong/risky AI output and the correction.

**Verify**
- manual submission review
- commands in README are run from the repository

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`

---

## [ ] T-DOC-002 — Final traceability and Definition-of-Done audit

**Risk:** C  
**Size:** S

**Requirements**
- all mandatory ASM/MNY/WAL/SND/NSV/SYNC/A11Y/PERF/DSN/TST rows

**Dependencies**
- T-DOC-001

**Read first**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/DEFINITION_OF_DONE.md`
- Git history/current tests

**Touch**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- documentation corrections only

**Acceptance**
- Every mandatory requirement has an implementation/test mapping.
- No requirement is marked DONE without evidence.
- Remaining TO VERIFY items are either resolved or explicitly documented.
- Optional stretch work is clearly distinguished from mandatory work.

**Verify**
- manual audit against assessment and design sources

**Update**
- `docs/HANDOVER.md`

---

## [ ] T-SUB-001 — Clean setup, full verification and repository submission check

**Risk:** B  
**Size:** M

**Requirements**
- ASM-025
- ASM-027
- DOC-004
- DOC-005

**Dependencies**
- T-DOC-002

**Read first**
- `docs/DEFINITION_OF_DONE.md` — Submission-Level Done
- `docs/GIT_WORKFLOW.md` — final submission

**Touch**
- only defects/documentation exposed by the final verification

**Acceptance**
- Fresh/clean checkout resolves dependencies successfully.
- App starts with the documented standard Flutter command.
- Formatting passes.
- Analyzer passes.
- Unit/widget tests pass.
- Integration tests pass.
- No secrets or restricted assessment source material are accidentally committed.
- Remote repository/access is ready for submission.
- Final `main` contains all mandatory work.

**Verify**
```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test integration_test
flutter run
```

**Update**
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/HANDOVER.md`
- `README.md` only if final commands differ

---

# Optional Stretch Backlog

**Do not start these tasks until T-SUB-001 mandatory readiness is satisfied or the project owner explicitly chooses to spend remaining time on stretch work.**

## [ ] T-STR-001 — Local notification after queued Send sync

**Risk:** B  
**Size:** S  
**Requirement:** STR-001

---

## [ ] T-STR-002 — Send Money localization scaffold

**Risk:** B  
**Size:** M  
**Requirement:** STR-002

Target: English + one Nigerian language.

---

## [ ] T-STR-003 — Wallet-home golden tests

**Risk:** C  
**Size:** S  
**Requirement:** STR-003

---

## [ ] T-STR-004 — Biometric confirmation stub

**Risk:** B  
**Size:** M  
**Requirement:** STR-004

---

# Dependency Summary

Primary execution path:

```text
T-BASE-001
   ↓
T-BASE-002 ──→ T-BASE-003
   ↓
T-MNY-001 ──→ T-MNY-002
   ├────────→ T-ID-001
   │              ↓
   │          T-OP-001
   │              ↓
   └────────→ T-DOM-001
                  ↓
              T-DB-001 ──→ T-DB-002
                  ↓
            T-REMOTE-001 ──→ T-REMOTE-002

T-CONN-001
      ↓
T-SYNC-001
      ↓
T-SYNC-002
   ┌──┴──────────┐
   ↓             ↓
T-SYNC-003   T-SYNC-004
   └──────┬──────┘
          ↓
      T-SYNC-005

T-DS-001 → T-DS-002 → T-APP-001
                         ↓
                      Wallet
                         ↓
                     Send Money
                         ↓
                    NovaSave Goals
                         ↓
                 NovaSave Contribution
                         ↓
                Cross-Feature Consistency
                         ↓
             Accessibility / Performance / Visual
                         ↓
                   Required Test Completion
                         ↓
                 Documentation / Submission
```

Parallel work is allowed only when dependencies and shared-file conflicts permit it. Follow `docs/AGENT_WORKFLOW.md` and `docs/GIT_WORKFLOW.md`.

---

# Mandatory Completion Gate

Do not begin final submission until all non-stretch tasks above are `DONE` or an explicitly documented exception has been approved.

The project must, at minimum, prove:

```text
integer-kobo money correctness
        +
durable offline intent
        +
restart recovery
        +
duplicate-safe replay
        +
required Send/NovaSave widget tests
        +
offline queue → sync integration test
        +
accessibility/font-scale support
        +
lazy transaction list
        +
design reconciliation
        +
truthful README and AI_USAGE
```
