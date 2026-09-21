# AI Usage

AI tools are used in this project as part of the development and review workflow.

The assessment explicitly allows AI-assisted development and requires documenting:

- which tools were used and what they were used for;
- 2–3 concrete prompts and the resulting output;
- at least one case where AI output was wrong, risky, or incomplete;
- how that issue was identified and corrected.

This file is updated throughout implementation. It is an engineering record, not a transcript of every AI interaction.

---

## Tools Used

| Tool | Primary use |
|---|---|
| ChatGPT | Assessment review, architecture validation, planning, documentation review |
| Claude Code | Implementation and targeted code changes |
| Codex | Implementation and independent code review |
| Antigravity | Implementation support, emulator/UI inspection and visual verification |

Only tools actually used should remain in the final submitted version.

---

## Prompt Log

Record only prompts that materially influenced the project.

### Prompt 1 — Assessment and architecture review

**Tool:** ChatGPT  
**Stage:** Planning / assessment reconciliation

**Prompt**

> Review the complete NovaWallet assessment, detailed flows, design exports and existing engineering documents. Treat the assessment and approved designs as the source of truth, challenge previous assumptions, identify contradictions and missing requirements, and recommend the next implementation step.

**Result**

The review confirmed the offline-first direction but identified several corrections to the earlier plan, including:

- money must be represented as integer kobo;
- the assessment provides no real backend, so a default Dio/HTTP layer was unnecessary;
- idempotency must be treated as an explicit requirement rather than a backend-dependent option;
- accessibility, font scaling, lazy list rendering and required test coverage needed to be added to traceability;
- connectivity, sync state and operation state should remain separate concerns.

**Action taken**

The architecture, implementation plan, requirements traceability, agent rules and definition of done were revised before implementation began.

---

### Prompt 2 — Flutter project bootstrap (T-BASE-001)

**Tool:** Antigravity  
**Stage:** Phase 0 — Toolchain & Project Baseline  

**Prompt**

> Read FIRST_AGENT_PROMPT.md and execute it exactly. Do not start the next task.

**Result**

- Initialized Flutter application in existing repository root with package name `novawallet` on mobile platforms (Android/iOS).
- Preserved existing project documentation (`README.md`, `docs/`, `AGENTS.md`) and maintained `.gitignore` protection for `docs_internal/`.
- Downloaded and verified static Plus Jakarta Sans font assets (Regular 400, Medium 500, SemiBold 600, Bold 700) into `assets/fonts/` and registered them in `pubspec.yaml`.
- Added `flutter_riverpod` baseline dependency as approved in `AGENTS.md`.
- Documented verified Flutter (3.47.5 stable) and Dart (3.13.4) versions in `README.md` and repository config.
- Ran `dart format`, `flutter analyze`, and `flutter test` with zero issues.

**Action taken**

Completed task `T-BASE-001`, verified all baseline checks, updated `docs/REQUIREMENTS_TRACEABILITY.md`, and prepared handover for `T-BASE-002`.

---

### Prompt 3 — Linting configuration and test layout scaffolding (T-BASE-002)

**Tool:** Antigravity  
**Stage:** Phase 0 — Toolchain & Project Baseline (T-BASE-002)

**Prompt**

> Configure strict analyzer and linter rules in analysis_options.yaml:
> Enable strict language checks under analyzer:
> language:
>   strict-casts: true
>   strict-inference: true
>   strict-raw-types: true
> Configure recommended linter rules per AGENTS.md and docs/DEFINITION_OF_DONE.md (e.g. unawaited futures, prefer const, avoid print, avoid relative imports).
> Scaffold the project test layout to mirror the architecture:
> test/core/
> test/features/
> test/sync/
> test/fake_backend/
> integration_test/ (initialized with a driver or baseline smoke file for later offline/sync testing)
> Do NOT implement feature logic, Drift persistence schemas, or sync logic yet.
> Verify that dart format, flutter analyze, and flutter test pass with 0 warnings or errors.

**Result**

- Configured strict analyzer language checks (`strict-casts`, `strict-inference`, `strict-raw-types`) and recommended linter rules in `analysis_options.yaml`.
- Added `integration_test: sdk: flutter` to `pubspec.yaml` `dev_dependencies`.
- Scaffolded test directories mirroring the approved architecture: `test/core/`, `test/features/`, `test/sync/`, `test/fake_backend/`.
- Created baseline smoke test in `integration_test/app_test.dart` and integration driver script in `test_driver/integration_test.dart`.
- Fixed deprecated lint rule `unnecessary_await_in_return` identified during `flutter analyze`.

**Action taken**

- Ran `dart format`, `flutter analyze`, and `flutter test`, achieving zero warnings/errors.
- Updated `docs/TASKS.md`, `docs/HANDOVER.md`, and recorded prompt in `AI_USAGE.md`.

---

### Prompt 4 — CI workflow configuration (T-BASE-003)

**Tool:** Antigravity  
**Stage:** Phase 0 — Toolchain & Project Baseline (T-BASE-003)

**Prompt**

> Read AGENTS.md first, then docs/HANDOVER.md, and then task T-BASE-003 in docs/TASKS.md.
> Confirm:
> - You are on branch main and git status is clean.
> - Latest commit includes T-BASE-002.
> Then:
> 1. Create task branch chore/T-BASE-003-ci from main.
> 2. Follow docs/GIT_WORKFLOW.md and docs/DEFINITION_OF_DONE.md.
> 3. Implement T-BASE-003 — Add CI verification (configure GitHub Actions workflow for flutter analyze, dart format, and flutter test).
> 4. Run local baseline verification before and after changes.
> 5. Update docs/TASKS.md, AI_USAGE.md, and docs/HANDOVER.md before finishing.

**Result**

- Verified clean working tree and latest commit including T-BASE-002 on `main`.
- Created task branch `chore/T-BASE-003-ci`.
- Added GitHub Actions workflow in `.github/workflows/ci.yml` with triggers for push to `main`, pull request to `main`, and `workflow_dispatch`.
- Configured steps with `subosito/flutter-action@v2` targeting Flutter `3.47.5` (channel `stable`) with tool/pub caching.
- Enforced identical repository-supported verification commands: `flutter pub get`, `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, and `flutter test`.
- Validated YAML syntax and updated `README.md` to document CI verification.

**Action taken**

- Verified local checks pass with zero issues.
- Updated `docs/TASKS.md`, `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

### Prompt 5 — Launch configuration and README Figma updates

**Tool:** Antigravity  
**Stage:** Toolchain & Documentation refinement

**Prompt**

> So before we move to phase 1... I want us to create a chore branch to update the launch.json file and the readme file to include the figma link to the design: https://www.figma.com/design/GzSZpqJTOnlGn2yDec8qtm/NovaWallet-Design?node-id=4-5&p=f&t=cV6FJkAzaLck0PB7-0
> Also remove this part in the readme: The project may use ChatGPT, Claude Code, Codex and Antigravity during implementation and review.
> Then lastly I want the readme to end with "Let's build NovaWallet together 🌍"

**Result**

- Created branch `chore/readme-launch-config`.
- Preserved updated `.vscode/launch.json` targeting emulator, simulator, and test configurations.
- Added official Figma design link under Design References in `README.md`.
- Removed specified AI tools sentence in `README.md` and appended closing motto "Let's build NovaWallet together 🌍".
- Ran format, analyze, and test verification checks with 0 issues.

**Action taken**

- Updated `README.md`, `.vscode/launch.json`, `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

### Prompt 6 — Integer-kobo Money value object (T-MNY-001)

**Tool:** Antigravity  
**Stage:** Phase 1 — Money, Identity & Core Operation Model (T-MNY-001)

**Prompt**

> Read AGENTS.md first, then docs/HANDOVER.md, and then task T-MNY-001 in docs/TASKS.md.
> Confirm:
> - You are on branch main and git status is clean.
> - Latest commit includes the completion of Phase 0.
> Then:
> 1. Create task branch feature/T-MNY-001-money from main.
> 2. Follow docs/GIT_WORKFLOW.md and docs/DEFINITION_OF_DONE.md.
> 3. Implement T-MNY-001 — Implement integer-kobo Money value object:
>    - Create the Money value object in lib/core/money/
>    - Enforce integer-kobo representation (never double/floating point for money)
>    - Support addition, subtraction, comparison, zero and negative validations
>    - Implement exact currency formatting (e.g. 12545000 kobo -> ₦125,450.00; 1000000 kobo -> ₦10,000.00)
>    - Add unit tests in test/core/money/ covering all arithmetic, invariants, edge cases, and formatting rules
>    - Do NOT touch persistence, routing, or feature UI
> 4. Run targeted and full baseline checks before and after changes:
>    - flutter test test/core/money/
>    - dart format --output=none --set-exit-if-changed .
>    - flutter analyze
>    - flutter test
> 5. Update docs/REQUIREMENTS_TRACEABILITY.md, docs/TASKS.md, AI_USAGE.md, and docs/HANDOVER.md before finishing.

**Result**

- Created branch `feature/T-MNY-001-money` from clean `main`.
- Implemented `Money` value object in `lib/core/money/money.dart` backed strictly by `final int kobo`.
- Implemented exact integer arithmetic (`+`, `-`, `-()`, `*`, `~/`), relational operators (`<`, `<=`, `>`, `>=`), `Comparable<Money>`, value equality, and hash code.
- Added validation methods and properties (`isZero`, `isPositive`, `isNegative`, `isNonNegative`, `ensurePositive`, `ensureNonNegative`, `checkPositive`, `checkNonNegative`, and `MoneyValidationException`).
- Implemented exact string parsing (`Money.parse`, `Money.tryParse`, `MoneyParseException`) without any floating-point conversions.
- Implemented exact currency formatting with thousands separators and two-digit decimal kobo (`12545000` -> `₦125,450.00`; `1000000` -> `₦10,000.00`; negative amounts -> `-₦125,450.00`).
- Authored 38 focused unit tests in `test/core/money/money_test.dart` verifying all invariants, acceptance criteria, arithmetic exactness, and edge cases.
- Replaced deprecated `IntegerDivisionByZeroException` with standard `UnsupportedError` per Dart 3 analyzer.

**Action taken**

- Ran `flutter test test/core/money/` (38/38 tests passing).
- Ran full baseline checks (`dart format`, `flutter analyze`, `flutter test`), all passing with 0 warnings/errors.
- Updated `docs/REQUIREMENTS_TRACEABILITY.md`, `docs/TASKS.md`, `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

### Prompt 7 — Exact savings-progress calculation (T-MNY-002)

**Tool:** Antigravity  
**Stage:** Phase 1 — Money, Identity & Core Operation Model (T-MNY-002)

**Prompt**

> Read AGENTS.md first, then docs/HANDOVER.md, and then task T-MNY-002 in docs/TASKS.md.
> Confirm:
> - You are on branch main and git status is clean.
> - Latest commit includes completion and merge of T-MNY-001 (commit 7e1c9c0 / ad871bb).
> Then:
> 1. Create task branch feature/T-MNY-002-savings-progress from main.
> 2. Follow docs/GIT_WORKFLOW.md and docs/DEFINITION_OF_DONE.md.
> 3. Implement T-MNY-002 — Implement exact savings-progress calculation:
>    - Location: lib/features/novasave/domain/ (e.g. savings_progress.dart or savings_goal.dart domain calculation model).
>    - Touch: NovaSave domain calculation code and unit tests in test/features/novasave/.
>    - Do NOT touch: NovaSave screens, sync logic, or database persistence schemas.
>    - Enforce HC-MONEY: All calculations must be derived from exact integer kobo (using Money value object from lib/core/money/money.dart). Never use double or floating-point arithmetic for domain money logic.
>    - For UI rendering fractions (0.0 to 1.0) needed by Flutter progress indicators, provide an explicit display converter at the boundary only, keeping domain calculations (basis points / percentage) strictly exact and rational.
>    - Fulfill acceptance criteria from docs/TASKS.md:
>      * Given ₦150,000 saved toward ₦500,000, progress resolves to 30%.
>      * Given a successful ₦50,000 contribution, projected/confirmed progress resolves to 40%.
>      * Remaining amount calculation is exact integer kobo (e.g. ₦500,000 - ₦150,000 = ₦350,000 remaining).
>      * Explicitly handle edge cases: zero target amount (reject or throw argument error), saved amount exceeding target (cap progress at 100% or allow over-achievement flag), and negative contribution attempts.
>    - Add comprehensive unit tests in test/features/novasave/ covering all progress calculations, projected contributions, edge cases, and boundary values.
> 4. Run targeted and full baseline checks before and after changes:
>    - flutter test test/features/novasave/
>    - dart format --output=none --set-exit-if-changed .
>    - flutter analyze
>    - flutter test
> 5. Update docs/REQUIREMENTS_TRACEABILITY.md, docs/TASKS.md, AI_USAGE.md, and docs/HANDOVER.md before finishing.

**Result**

- Created feature branch `feature/T-MNY-002-savings-progress` from `main`.
- Implemented `SavingsProgress` domain calculation model in `lib/features/novasave/domain/savings_progress.dart` backed strictly by integer kobo via `Money` per HC-MONEY.
- Implemented `SavingsGoal` entity in `lib/features/novasave/domain/savings_goal.dart` adhering to `docs/ARCHITECTURE.md` §8.2 with derived progress and remaining amount.
- Engineered exact integer basis points calculation (`10000 bps = 100%`) using intermediate `BigInt` arithmetic (`savedKobo * 10000 ~/ targetKobo`), preventing 64-bit integer multiplication overflow on large balances.
- Calculated remaining amount as exact integer kobo (`targetAmount - savedAmount`), guaranteeing that over-saving yields `Money.zero()` (never negative balance), with `excessAmount` tracking surplus.
- Implemented capped percentage (0-100%) and basis points (0-10,000 bps) alongside uncapped raw metrics (`rawPercentage`, `rawBasisPoints`) and over-achievement flags (`isGoalReached`, `isOverTarget`).
- Implemented string formatting (`formatPercentage`) via pure integer division without `double`.
- Isolated floating-point arithmetic strictly to the UI presentation boundary (`toProgressFraction({bool clamp = true})`, `progressFraction`).
- Enforced domain invariants: rejected non-positive target amounts, negative saved amounts, and negative contributions with descriptive `ArgumentErrors`.
- Authored 28 unit tests across `test/features/novasave/savings_progress_test.dart` and `test/features/novasave/savings_goal_test.dart`, bringing the total project test suite to 80 passing tests.

**Action taken**

- Ran `flutter test test/features/novasave/` (28/28 tests passing).
- Ran full baseline checks (`dart format`, `flutter analyze`, `flutter test`), all passing with 0 warnings/errors.
- Updated `docs/REQUIREMENTS_TRACEABILITY.md` (MNY-003 marked DONE; ASM-008, ASM-014, NSV-008, NSV-009, NSV-014 updated to IN_PROGRESS), `docs/TASKS.md` (T-MNY-002 checked off), `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

### Prompt 8 — Stable operation and idempotency identities (T-ID-001)

**Tool:** Antigravity  
**Stage:** Phase 1 — Money, Identity & Core Operation Model (T-ID-001)

**Prompt**

> Read AGENTS.md first, then docs/HANDOVER.md, and then task T-ID-001 in docs/TASKS.md.
> Confirm:
> - You are on branch main and git status is clean.
> - Latest commit includes completion and merge of T-MNY-002 (commit 012db7f / 55af79d).
> Then:
> 1. Create task branch feature/T-ID-001-identities from main.
> 2. Follow docs/GIT_WORKFLOW.md and docs/DEFINITION_OF_DONE.md.
> 3. Implement T-ID-001 — Implement stable operation and idempotency identities:
>    - Location: lib/core/ids/ (e.g. operation_id.dart, idempotency_key.dart).
>    - Touch: Core identity models and unit tests in test/core/ids/.
>    - Do NOT touch: sync queue schemas, UI screens, or fake backend yet.
>    - Enforce HC-IDEMPOTENCY:
>      * Model stable operation identities (OperationId) and stable idempotency keys (IdempotencyKey).
>      * Distinguish clearly between operation identity (identifying the logical action) and idempotency key (identifying the financial delivery attempt/logical request).
>      * Keys must be stable, immutable, deterministic/UUID-backed, and safely reusable across retries.
>      * Validate invariants: non-empty, non-whitespace, valid formatting.
>    - Add comprehensive unit tests in test/core/ids/ covering equality, hashing, validation, string formatting, and retry key stability.
> 4. Run targeted and full baseline checks before and after changes:
>    - flutter test test/core/ids/
>    - dart format --output=none --set-exit-if-changed .
>    - flutter analyze
>    - flutter test
> 5. Update docs/REQUIREMENTS_TRACEABILITY.md, docs/TASKS.md, AI_USAGE.md, and docs/HANDOVER.md before finishing.

**Result**

- Created feature branch `feature/T-ID-001-identities` from clean `main`.
- Implemented `Uuid` utility in `lib/core/ids/uuid.dart` providing cryptographically secure RFC 4122 v4 UUID generation (`Uuid.v4([Random? random])`) and validation (`isValid`, `isValidV4`, `isGeneralUuid`) without third-party dependencies.
- Implemented `OperationId` domain value object in `lib/core/ids/operation_id.dart` representing stable local operation identity for durable storage.
- Implemented `IdempotencyKey` domain value object in `lib/core/ids/idempotency_key.dart` representing remote deduplication identity per HC-IDEMPOTENCY and HC-EXACTLY-ONCE-EFFECT.
- Clearly differentiated `OperationId` and `IdempotencyKey` by type, preventing cross-assignment and ensuring distinct hash codes and non-equality even with identical underlying values.
- Supported deterministic key binding (`IdempotencyKey.fromOperationId(operationId, {String? prefix})`) and reproducible seed-based UUID generation.
- Enforced strict domain invariants: rejected empty strings, whitespace (leading, trailing, internal), characters outside permitted set (`[a-zA-Z0-9_\-\.:]`), and lengths exceeding 255 with `ArgumentError`.
- Canonicalized RFC 4122 UUID representations to lowercase across both identity objects to guarantee casing consistency in hash sets and persistence.
- Exported identity types via barrel `lib/core/ids/ids.dart`.
- Authored 52 unit tests across `test/core/ids/uuid_test.dart`, `test/core/ids/operation_id_test.dart`, and `test/core/ids/idempotency_key_test.dart`, verifying invariants, retry stability, reload recovery, type differentiation, and RFC 4122 compliance (total project tests increased from 81 to 133).

**Action taken**

- Ran targeted tests `flutter test test/core/ids/` (52/52 passing).
- Ran full baseline checks (`dart format`, `flutter analyze`, `flutter test`), all passing with 0 warnings/errors across all 133 tests.
- Updated `docs/REQUIREMENTS_TRACEABILITY.md` (`SYNC-006` marked DONE; `ASM-006`, `ASM-013`, `SND-010`, `NSV-012`, `SYNC-007` updated to IN_PROGRESS), `docs/TASKS.md` (checked off T-ID-001), `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

### Prompt 9 — Financial operation model and state transitions (T-OP-001)

**Tool:** Antigravity  
**Stage:** Phase 1 — Money, Identity & Core Operation Model (T-OP-001)

**Prompt**

> Implement T-OP-001 — Define financial operation model and state transitions:
> - Location: lib/sync/domain/ (financial_operation.dart, operation_status.dart, operation_type.dart, operation_payload.dart, sync_error.dart, connectivity_status.dart, sync_status.dart, sync_domain.dart).
> - Touch: Operation model, state transitions, recoverable error metadata, and unit tests in test/sync/domain/.
> - Do NOT touch: Drift implementation, feature UI, connectivity implementation.
> - Acceptance criteria:
>   * Operation type represents at least Send and Contribution.
>   * Operation state distinguishes pending, processing, completed and terminal failure.
>   * Recoverable sync error metadata can exist without turning a pending operation into a terminal failure.
>   * Connectivity/sync status is not embedded into the operation enum (HC-STATE-SEPARATION).
>   * Invalid transitions are prevented or handled explicitly.
> - Verify: flutter test test/sync/, dart format, flutter analyze, flutter test.
> - Update: docs/REQUIREMENTS_TRACEABILITY.md, docs/TASKS.md, AI_USAGE.md, docs/HANDOVER.md.

**Result**

- Created task branch `feature/T-OP-001-operation-model`.
- Modeled independent state dimensions per HC-STATE-SEPARATION:
  * `ConnectivityStatus` (`online`, `offline`) in `lib/sync/domain/connectivity_status.dart`
  * `SyncStatus` (`idle`, `syncing`, `failed`) in `lib/sync/domain/sync_status.dart`
  * `OperationStatus` (`pending`, `processing`, `completed`, `failed`) in `lib/sync/domain/operation_status.dart`
- Implemented `OperationType` (`send`, `contribution`) in `lib/sync/domain/operation_type.dart`.
- Implemented `OperationPayload` hierarchy (`SendMoneyPayload`, `ContributionPayload`) in `lib/sync/domain/operation_payload.dart` backed strictly by integer kobo `Money` per HC-MONEY with JSON serialization.
- Implemented `SyncError` in `lib/sync/domain/sync_error.dart` distinguishing recoverable errors from terminal failures.
- Implemented `FinancialOperation` (aliased as `PendingOperation` per `docs/ARCHITECTURE.md` §8.3) in `lib/sync/domain/financial_operation.dart` managing state transitions:
  * `pending` -> `processing`: atomic claim for delivery.
  * `processing` -> `completed`: successful remote settlement with reference.
  * `processing` -> `pending`: recoverable sync error (keeps operation queued and retryable).
  * `processing` -> `failed`: terminal failure.
  * Explicitly rejected invalid transitions with `InvalidOperationTransitionException`.
- Exported all models via barrel `lib/sync/domain/sync_domain.dart`.
- Authored 32 unit tests across `test/sync/domain/` covering state separation, payload serialization, lifecycle transitions, and invalid transition guards (total project tests increased from 133 to 165).

**Action taken**

- Ran `flutter test test/sync/` (33/33 tests passing).
- Ran full verification (`dart format`, `flutter analyze`, `flutter test`), all passing with 0 warnings/errors across all 165 tests.
- Updated `docs/REQUIREMENTS_TRACEABILITY.md` (`SYNC-014` marked DONE; `ASM-009`, `ASM-010`, `ASM-012` marked IN_PROGRESS), `docs/TASKS.md` (checked off T-OP-001), `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

### Prompt 10 — Queued-spendability policy (T-DOM-001)

**Tool:** Antigravity  
**Stage:** Phase 1 — Money, Identity & Core Operation Model (T-DOM-001)

**Prompt**

> Implement T-DOM-001 — Decide queued-spendability policy:
> - Define domain policy model: `SpendableBalancePolicy` in `lib/sync/domain/spendable_balance_policy.dart`.
> - Export via `lib/sync/domain/sync_domain.dart`.
> - Fulfill requirement MNY-006:
>   * Confirmed balance remains the cached local/remote balance per design (AD-09).
>   * Spendable balance = max(0, confirmedBalance - sum(activePendingKobo)).
>   * Active pending includes both `pending` and `processing` outgoing operations (transfers and contributions).
>   * Completed operations do not double-deduct once remote/confirmed balance reflects them.
>   * Terminally failed operations release reservations immediately.
>   * Provide validation helper `canSpend(confirmedBalance, pendingOperations, candidateAmount)`.
> - Add comprehensive unit tests in `test/sync/domain/spendable_balance_policy_test.dart`.
> - Update `docs/ARCHITECTURE.md` §16 and §26, `docs/REQUIREMENTS_TRACEABILITY.md` (MNY-006 -> DONE), `docs/TASKS.md` (check off T-DOM-001), `AI_USAGE.md`, and `docs/HANDOVER.md`.

**Result**

- Implemented `SpendableBalancePolicy` in `lib/sync/domain/spendable_balance_policy.dart` using exact integer kobo `Money` arithmetic per HC-MONEY.
- Reconciled design requirement AD-09 (headline balance displays confirmed cached balance) with safe offline spending preventing accidental overdrafts.
- Created `canSpend`, `calculateSpendableBalance`, and `calculateReservedAmount` methods accounting for both `SendMoneyPayload` and `ContributionPayload` in `pending` and `processing` statuses.
- Handled negative edge cases gracefully using `Money.zero()` floor.
- Documented the policy comprehensively in `docs/ARCHITECTURE.md` §16 and §26.
- Authored 12 unit tests in `test/sync/domain/spendable_balance_policy_test.dart` verifying multi-operation reservation, failure release, completion handling, and edge cases (suite total: 177 tests, all passing).

**Action taken**

- Ran `flutter test test/sync/domain/spendable_balance_policy_test.dart` (12/12 passing).
- Ran full verification (`dart format`, `flutter analyze`, `flutter test`), all passing with 0 warnings/errors.
- Updated `docs/ARCHITECTURE.md`, `docs/REQUIREMENTS_TRACEABILITY.md`, `docs/TASKS.md`, `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

### Prompt 11 — Configure Drift and pending-operation schema (T-DB-001)

**Tool:** Antigravity  
**Stage:** Phase 2 — Persistence & Fake Remote (T-DB-001)

**Prompt**

> Begin Phase 2 with T-DB-001 — Configure Drift and pending-operation schema:
> 1. Create task branch `feature/T-DB-001-drift-persistence` from clean `main`.
> 2. Configure Drift (using sqlite3 / drift / path_provider / drift_flutter or equivalent testable setup) in `lib/core/persistence/` and `lib/sync/data/`.
> 3. Model the durable pending operations table according to docs/ARCHITECTURE.md §11 and §16.
> 4. Provide clean mapping between Drift database row entities and domain entities (`FinancialOperation.restore`, `OperationPayload`, `OperationType`, `OperationStatus`, `SyncError`).
> 5. Support in-memory SQLite instances for fast, deterministic unit testing.
> 6. Author thorough unit/data tests in `test/sync/data/` verifying:
>    - Insert and load pending operation preserving exact integer-kobo amount, stable identities, UTC timestamps, and payload.
>    - Status and attempt count updates.
>    - Restart simulation: re-opening a database file preserves queued operations across connection cycles.
> 7. Run full baseline checks: format, analyze, test.
> 8. Update documentation, push, open PR, and prepare for T-DB-002.

**Result**

- Configured Drift (`drift`, `drift_dev`, `sqlite3`, `path_provider`, `path`) and ran code generation via `build_runner`.
- Modeled `PendingOperations` Drift table in `lib/sync/data/pending_operations_table.dart` capturing stable operation ID, stable unique idempotency key, operation type, JSON payload, exact integer kobo amount (`BigInt` / 64-bit int), lifecycle status, attempt count, UTC timestamps, serialized sync error, remote reference, and completion timestamp.
- Implemented `AppDatabase` in `lib/core/persistence/app_database.dart` with support for lazy file storage in production, explicit file connections for restart testing, and in-memory SQLite instances for fast, isolated unit tests.
- Implemented `PendingOperationMapper` in `lib/sync/data/pending_operation_mapper.dart` ensuring strict rehydration through `FinancialOperation.restore` enforcing all domain invariants.
- Implemented `PendingOperationsDao` in `lib/sync/data/pending_operations_dao.dart` providing atomic claiming (`claimOperation`), lifecycle updates (`updateOperation`), crash recovery query (`recoverInterruptedOperations`), and spendable balance active operation watchers (`getActiveOperations`, `watchActiveOperations`).
- Authored 8 unit tests in `test/sync/data/pending_operations_dao_test.dart` verifying exact integer kobo storage, unique idempotency key constraint, atomic claiming, lifecycle progression with recoverable error metadata, and multi-connection database restart simulation across file open/close cycles (bringing test suite total from 193 to 201 tests).

**Action taken**

- Ran `flutter test test/sync/data/` (8/8 passing).
- Ran full baseline checks (`dart format`, `flutter analyze`, `flutter test`), all passing with 0 warnings/errors across all 201 tests.
- Updated `docs/TASKS.md`, `docs/REQUIREMENTS_TRACEABILITY.md`, `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

### Prompt 12 — Add local wallet, transaction and goal persistence (T-DB-002)

**Tool:** Antigravity  
**Stage:** Phase 2 — Persistence & Fake Remote (T-DB-002)

**Prompt**

> Implement T-DB-002 — Add local wallet, transaction and goal persistence:
> 1. Create task branch `feature/T-DB-002-wallet-goal-persistence` from clean `main`.
> 2. Implement Drift tables `WalletCache`, `TransactionsTable`, and `SavingsGoalsTable` in `lib/core/persistence/local_tables.dart`.
> 3. Register tables in `AppDatabase` (`lib/core/persistence/app_database.dart`) and regenerate code with `build_runner`.
> 4. Implement domain entities and repository boundaries:
>    - `WalletSnapshot`, `WalletTransaction`, `TransactionType`, `TransactionStatus`, `WalletRepository`, `LocalWalletRepository` in `lib/features/wallet/`.
>    - `NovaSaveRepository`, `LocalNovaSaveRepository` in `lib/features/novasave/`.
> 5. Create dedicated DAOs: `WalletDao`, `TransactionDao`, `SavingsGoalDao` with integer-kobo money mapping, atomic contribution application, and paginated/lazy recent transaction queries (`HC-PERFORMANCE`).
> 6. Author comprehensive unit tests in `test/features/wallet/data/` and `test/features/novasave/data/` including restart simulation tests verifying records survive database close and file reopen.
> 7. Run full baseline checks (format, analyze, test).
> 8. Update documentation, push, open PR, and merge.

**Result**

- Implemented `WalletSnapshot` and `WalletTransaction` domain entities strictly using `Money` value object for integer-kobo precision (HC-MONEY).
- Created Drift tables: `WalletCache` (singleton balance cache), `TransactionsTable` (confirmed activity history), and `SavingsGoalsTable` (savings goals definitions and progress).
- Created `WalletDao` and `TransactionDao` with support for lazy recent-transactions querying (`limit`, `offset`) per HC-PERFORMANCE and reactive stream watchers.
- Created `SavingsGoalDao` with atomic contribution incrementing (`applyContribution`) and reactive goal stream watchers.
- Created `WalletRepository` and `NovaSaveRepository` interfaces with `LocalWalletRepository` and `LocalNovaSaveRepository` implementations hiding Drift persistence details.
- Authored 10 unit tests across `test/features/wallet/data/wallet_persistence_test.dart` and `test/features/novasave/data/savings_goals_persistence_test.dart` verifying integer kobo storage, singleton wallet updates, reactive streams, lazy pagination, atomic contributions, and multi-connection file reopen survival across database lifecycle cycles (bringing suite total from 201 to 211 tests).

**Action taken**

- Ran targeted tests for wallet and novasave data persistence (10/10 passing).
- Ran full baseline checks (`dart format`, `flutter analyze`, `flutter test`), all passing with 0 warnings/errors across all 211 tests.
- Updated `docs/TASKS.md`, `docs/REQUIREMENTS_TRACEABILITY.md`, `AI_USAGE.md`, and `docs/HANDOVER.md`.

### Prompt 13 — Implement idempotent fake remote (T-REMOTE-001)

**Tool:** Antigravity  
**Stage:** Phase 2 — Persistence & Fake Remote (T-REMOTE-001)

**Prompt**

> Implement T-REMOTE-001 — Implement idempotent fake remote:
> 1. Create task branch `feature/T-REMOTE-001-fake-remote` from clean `main`.
> 2. Follow `AGENTS.md` (HC-IDEMPOTENCY, HC-EXACTLY-ONCE-EFFECT, HC-MONEY, HC-STATE-SEPARATION) and `docs/ARCHITECTURE.md` §11, §14.
> 3. Create `RemoteApi` interface with `sendMoney`, `contribute`, `submitOperation`, `fetchWalletSnapshot`, and `fetchTransactions`.
> 4. Implement `FakeRemoteApi` with `RemoteIdempotencyLedger` interface supporting both `InMemoryRemoteLedger` (for fast isolated testing) and `DriftRemoteLedger` (persisting across SQLite file close/reopen).
> 5. Implement payload conflict detection per requirement SYNC-009, throwing `ConflictingIdempotencyKeyException` if a key is reused with mismatched amount, recipient, bank, narration, or goal.
> 6. Enforce that legitimate duplicate requests reuse the existing result (`isDuplicate: true`) without creating a second financial effect (HC-EXACTLY-ONCE-EFFECT).
> 7. Author comprehensive unit and restart simulation tests in `test/fake_backend/` covering both Send and Contribution, conflict rejection, and restart survival.
> 8. Verify all format, analyze, and test checks pass.

**Result**

- Created `RemoteApi` interface in `lib/fake_backend/remote_api.dart`.
- Implemented `RemoteOperationResult`, `RemoteApiException`, `ConflictingIdempotencyKeyException`, `InsufficientRemoteFundsException`, and `InvalidRemoteOperationException`.
- Created `RemoteIdempotencyRecord` with deep payload validation against incoming `OperationPayload` (`matchesPayload`).
- Implemented `RemoteIdempotencyLedger` interface with `InMemoryRemoteLedger` and `DriftRemoteLedger` backed by Drift tables (`RemoteIdempotencyTable`, `RemoteWalletStateTable`, `RemoteTransactionsTable`) respecting the persistence boundary in `docs/ARCHITECTURE.md` §11.4.
- Implemented `FakeRemoteApi` supporting deterministic injected clocks and reference generators, balance checking, and exact-once financial effects.
- Authored 18 tests across `test/fake_backend/fake_remote_api_test.dart` and `test/fake_backend/drift_remote_ledger_test.dart`, bringing total tests from 211 to 228 (all passing).

**Action taken**

- Caught and resolved timestamp precision nuance when restoring timestamps from SQLite milliseconds (`millisecondsSinceEpoch`).
- Ran full verification suite (`dart format`, `flutter analyze`, `flutter test`), passing with 0 warnings/errors.
- Updated `docs/REQUIREMENTS_TRACEABILITY.md` (`SYNC-008`, `SYNC-009`, `TST-002`, `TST-003` to `DONE`), `docs/TASKS.md`, `AI_USAGE.md`, and `docs/HANDOVER.md`.

### Prompt 14 — Add deterministic failure simulation (T-REMOTE-002)

**Tool:** Antigravity  
**Stage:** Phase 2 — Persistence & Fake Remote (T-REMOTE-002)

**Prompt**

> Implement T-REMOTE-002 — Add deterministic failure simulation:
> 1. Create task branch `feature/T-REMOTE-002-failure-simulation` from clean `main`.
> 2. Implement `FailureSimulator` and `SimulatedFailureType` supporting:
>    - transient transport/network failures (`RemoteTransportException`, recoverable);
>    - transient server errors (`RemoteServerException`, recoverable);
>    - terminal business rejections (`RemoteBusinessRejectionException`, terminal);
>    - response lost in flight after settlement (`RemoteResponseLostException`, recoverable/uncertain per SYNC-011 and TST-007).
> 3. Enhance `RemoteApiException` hierarchy with `isRecoverable` and domain `toSyncError()` mapping.
> 4. Integrate `FailureSimulator` with `FakeRemoteApi` for pre-execution and post-execution checks.
> 5. Author comprehensive unit tests in `test/fake_backend/failure_simulator_test.dart` verifying that:
>    - Pre-execution failures result in zero remote balance deductions.
>    - Response-lost scenario settles remote debit and records idempotency entry, and subsequent client replay with the same key returns the duplicate result without a second debit (HC-EXACTLY-ONCE-EFFECT).
>    - Single-shot, multi-attempt, and key-specific rules operate deterministically.
> 6. Verify all checks pass across formatting, static analysis, and all 237 tests.

**Result**

- Created `FailureSimulator` in `lib/fake_backend/failure_simulator.dart` with support for `failNext`, `failNextN`, `failForIdempotencyKey`, and custom `FailureRule`s.
- Enhanced `RemoteApiException` with `isRecoverable`, `code`, and `toSyncError()` method mapping directly to `SyncError`.
- Added `RemoteTransportException`, `RemoteServerException`, `RemoteResponseLostException`, and `RemoteBusinessRejectionException`.
- Integrated `failureSimulator` into `FakeRemoteApi` for both `sendMoney` and `contribute`.
- Authored 9 exhaustive tests in `test/fake_backend/failure_simulator_test.dart` bringing test suite to 237 passing tests.

**Action taken**

- Identified and fixed asynchronous test expectation pattern where unawaited closures in `expect` allowed tests to execute assertions before future resolution. Replaced with `await expectLater(...)`.
- Ran full project verification (`dart format`, `flutter analyze`, `flutter test`), passing cleanly with 0 warnings/errors across 237 tests.
- Updated documentation across `docs/REQUIREMENTS_TRACEABILITY.md`, `docs/TASKS.md`, `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

### Prompt 15 — Implement connectivity abstraction (T-CONN-001)

**Tool:** Antigravity  
**Stage:** Phase 3 — Connectivity, Queue & Synchronization (T-CONN-001)

**Prompt**

> Implement T-CONN-001 — Implement connectivity abstraction:
> 1. Create task branch `feature/T-CONN-001-connectivity-abstraction` from clean `main`.
> 2. Add `connectivity_plus: ^7.3.1` dependency to `pubspec.yaml` (justified per AGENTS.md §5).
> 3. Implement `ConnectivityStatus` enum (`online`, `offline`) in `lib/core/connectivity/connectivity_status.dart` adhering strictly to HC-STATE-SEPARATION (zero sync/operation states embedded).
> 4. Implement `ConnectivityService` abstract interface in `lib/core/connectivity/connectivity_service.dart`.
> 5. Implement `InMemoryConnectivityService` in `lib/core/connectivity/in_memory_connectivity_service.dart` for deterministic test overrides and interactive simulation.
> 6. Implement `ConnectivityPlusService` in `lib/core/connectivity/connectivity_plus_service.dart` mapping `connectivity_plus` results to `ConnectivityStatus`.
> 7. Implement Riverpod providers `connectivityServiceProvider`, `connectivityStatusStreamProvider`, and `connectivityStatusProvider` in `lib/core/connectivity/connectivity_providers.dart`.
> 8. Author comprehensive unit and provider tests in `test/core/connectivity/`.
> 9. Verify all checks pass across formatting, static analysis, and all tests.

**Result**

- Added `connectivity_plus: ^7.3.1` to `pubspec.yaml`.
- Created `ConnectivityStatus` enum with `isOnline` and `isOffline` getters, strictly separated from sync and operation statuses per `HC-STATE-SEPARATION`.
- Created `ConnectivityService` interface with `checkConnectivity()`, `onConnectivityChanged` stream, and `dispose()`.
- Created `InMemoryConnectivityService` supporting default/custom initial statuses, `setStatus`, `toggle`, broadcast listeners, and state guards.
- Created `ConnectivityPlusService` with static `mapResults` handling multi-interface results (WiFi, cellular, Ethernet, VPN, none, empty).
- Created Riverpod providers (`connectivityServiceProvider`, `connectivityStatusStreamProvider`, `connectivityStatusProvider`).
- Authored 21 unit and provider tests across 4 test suites in `test/core/connectivity/`, bringing total tests to 258.

**Action taken**

- Ran full project verification (`dart format`, `flutter analyze`, `flutter test`), passing cleanly with 0 warnings/errors across 258 tests.
- Updated `docs/TASKS.md`, `docs/REQUIREMENTS_TRACEABILITY.md` (marked `SYNC-001` as `DONE`), `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

### Prompt 16 — Implement durable enqueue API (T-SYNC-001)

**Tool:** Antigravity  
**Stage:** Phase 3 — Connectivity, Queue & Synchronization (T-SYNC-001)

**Prompt**

> Implement T-SYNC-001 — Implement durable enqueue API:
> 1. Create task branch `feature/T-SYNC-001-durable-enqueue` from clean `main`.
> 2. Define `OperationRepository` abstract interface in `lib/sync/domain/operation_repository.dart` specifying `enqueue`, `enqueueSendMoney`, `enqueueContribution`, `claim`, `update`, `markPendingWithError`, `markCompleted`, `markFailed`, `recoverInterrupted`, `watchPendingOperations`, and `watchActiveOperations`.
> 3. Implement `LocalOperationRepository` in `lib/sync/data/local_operation_repository.dart` backed by `PendingOperationsDao` and Drift SQLite:
>    - Ensure operations must be in `pending` status with `attemptCount == 0`.
>    - Confirm write back from persistent storage.
>    - Throw on constraint or persistence errors so caller NEVER receives a false saved/pending acknowledgment (HC-OFFLINE-DURABILITY, SYNC-002).
> 4. Implement Riverpod providers `appDatabaseProvider`, `operationRepositoryProvider`, `pendingOperationsStreamProvider`, and `activeOperationsStreamProvider`.
> 5. Author comprehensive unit, lifecycle transition, and restart simulation tests in `test/sync/data/local_operation_repository_test.dart` verifying that:
>    - Send and Contribution intents are durably stored.
>    - Duplicate operation ID or idempotency key throws and prevents false saved acknowledgments.
>    - Operations survive database file close and reopen with exact integer-kobo amounts and stable identities.
>    - Riverpod stream providers emit updates reactively.
> 6. Verify all checks pass across formatting, static analysis, and all tests.

**Result**

- Created `OperationRepository` interface in `lib/sync/domain/operation_repository.dart`.
- Created `LocalOperationRepository` in `lib/sync/data/local_operation_repository.dart`.
- Created `appDatabaseProvider` in `lib/core/persistence/persistence_providers.dart` and sync providers (`operationRepositoryProvider`, `pendingOperationsStreamProvider`, `activeOperationsStreamProvider`) in `lib/sync/data/sync_providers.dart`.
- Authored 10 tests in `test/sync/data/local_operation_repository_test.dart` bringing test suite total to 268 passing tests.

**Action taken**

- Corrected test assertion type mismatch (`Money.kobo` is `int`, not `BigInt`).
- Ran full project verification (`dart format`, `flutter analyze`, `flutter test`), passing cleanly with 0 warnings/errors across all 268 tests.
- Updated `docs/TASKS.md`, `docs/REQUIREMENTS_TRACEABILITY.md` (`SYNC-002` and `SYNC-003` marked `DONE`; `SND-015` and `NSV-017` marked `IN_PROGRESS`), `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

### Prompt 17 — Implement single shared sync coordinator and operation claim (T-SYNC-002)

**Tool:** Antigravity  
**Stage:** Phase 3 — Connectivity, Queue & Synchronization (T-SYNC-002)

**Prompt**

> Implement T-SYNC-002 — Implement single shared sync coordinator and operation claim:
> 1. Create task branch `feature/T-SYNC-002-sync-coordinator` from clean `main`.
> 2. Implement `SyncCoordinator` in `lib/sync/application/sync_coordinator.dart`:
>    - Own all pending-operation synchronization centrally across Send Money and NovaSave (HC-SYNC, SYNC-005).
>    - Ensure atomic operation claim (`claim(id)`) before dispatching to remote (SYNC-010).
>    - Deterministic FIFO processing order (oldest first by `createdAt`).
>    - Strict serialization across concurrent sync triggers (coalesce concurrent runs; SYNC-010).
>    - Offline skipping: if offline or disconnected mid-pass, skip remote calls cleanly.
>    - Auto-subscribe to reconnect events (`ConnectivityService.onConnectivityChanged`) to trigger replay (ASM-011, SYNC-004).
>    - Apply local side-effects (wallet balance debit, transaction record, and NovaSave goal progress) BEFORE exposing operation completion (docs/ARCHITECTURE.md §12, §16).
>    - Handle transient errors by setting `SyncStatus.failed` and keeping operations pending with `SyncError`; terminal failures mark operations failed and continue queue.
>    - Support direct single operation retry (`retryOperation(id)`).
> 3. Implement `SyncRunResult` and `SyncTrigger` in `lib/sync/application/sync_result.dart`.
> 4. Implement Riverpod providers `syncCoordinatorProvider`, `syncStatusStreamProvider`, and `syncStatusProvider` in `lib/sync/application/sync_coordinator_provider.dart`.
> 5. Wire feature providers (`wallet_providers.dart`, `novasave_providers.dart`, `fake_backend_providers.dart`).
> 6. Author comprehensive unit and integration tests in `test/sync/application/sync_coordinator_test.dart` covering:
>    - Single shared coordinator processing both Send and Contribution operations.
>    - Deterministic FIFO processing order.
>    - Concurrent sync calls coalescing and atomic claiming.
>    - Offline skipping.
>    - Reconnect automatic sync.
>    - Recoverable network error handling and SyncError retention.
>    - Terminal error handling.
>    - Response-lost retry recovery with exact-once financial effect (SYNC-011, TST-007, HC-EXACTLY-ONCE-EFFECT).
>    - Direct single-operation retry (`retryOperation`).
>    - Riverpod container wire-up.
> 7. Verify full checks pass: format, analyzer, tests.

**Result**

- Implemented `SyncCoordinator` in `lib/sync/application/sync_coordinator.dart`.
- Implemented `SyncRunResult` and `SyncTrigger` in `lib/sync/application/sync_result.dart`.
- Implemented `syncCoordinatorProvider`, `syncStatusStreamProvider`, and `syncStatusProvider` in `lib/sync/application/sync_coordinator_provider.dart`.
- Created provider files `wallet_providers.dart`, `novasave_providers.dart`, and `fake_backend_providers.dart` for clean dependency injection.
- Authored 10 exhaustive unit and integration tests in `test/sync/application/sync_coordinator_test.dart`, bringing total tests to 278.

**Action taken**

- Fixed initial domain property mismatches (`payload.amount`, `savedAmount`, and `TransactionType.debit`).
- Ran full project verification (`dart format`, `flutter analyze`, `flutter test`), passing cleanly with 0 warnings/errors across all 278 tests.
- Updated `docs/TASKS.md`, `docs/REQUIREMENTS_TRACEABILITY.md` (`SYNC-004`, `SYNC-005`, `SYNC-007`, `SYNC-010`, `SYNC-011`, `SYNC-012`, `SYNC-013` marked `DONE`), `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

### Prompt 18 — Implement restart recovery (T-SYNC-003)

**Tool:** Antigravity  
**Stage:** Phase 3 — Connectivity, Queue & Synchronization (T-SYNC-003)

**Prompt**

> Implement T-SYNC-003 — Implement restart recovery:
> 1. Create task branch `feature/T-SYNC-003-restart-recovery` from clean `main`.
> 2. Add `recoverInterrupted()` and `startup({bool triggerSyncIfOnline = true})` lifecycle methods on `SyncCoordinator` in `lib/sync/application/sync_coordinator.dart`:
>    - Call `operationRepository.recoverInterrupted()` to reset orphaned in-flight `processing` operations back to `pending` with preserved attempt count and stable idempotency key.
>    - Conditionally trigger `synchronize(trigger: SyncTrigger.startup)` if online.
> 3. Author exhaustive end-to-end restart simulation tests in `test/sync/application/restart_recovery_test.dart` using persistent SQLite files (`AppDatabase.forFile`) across distinct process lifecycles:
>    - Queued Send Money and NovaSave operations survive process termination and restart (`ASM-012`, `SYNC-003`, `SND-016`, `NSV-019`).
>    - In-flight `processing` operations are recovered to `pending` on startup (`ASM-012`, `ASM-013`).
>    - Crash after remote execution but before local persistence commits replays with the identical idempotency key; remote returns deduplicated result; local wallet balance, ledger, and goal progress are finalized; remote balance is not debited twice (`SYNC-011`, `HC-EXACTLY-ONCE-EFFECT`).
>    - Mixed queue states (`completed`, `failed`, `pending`, `processing`) leave completed and failed immutable, while pending and recovered operations sync in FIFO order.
> 4. Verify all tests pass with 0 analyzer warnings/errors and correct formatting.

**Result**

- Added `recoverInterrupted()` and `startup({bool triggerSyncIfOnline = true})` to `SyncCoordinator`.
- Authored 4 multi-connection restart recovery tests in `test/sync/application/restart_recovery_test.dart` and 1 additional test in `test/sync/application/sync_coordinator_test.dart`, bringing total suite to 283 tests.

**Action taken**

- Ran full project verification (`dart format`, `flutter analyze`, `flutter test`), passing cleanly with 0 warnings/errors across all 283 tests.
- Updated `docs/TASKS.md` (`T-SYNC-003` marked `[x]`), `docs/REQUIREMENTS_TRACEABILITY.md` (`ASM-012`, `ASM-013`, `SND-016`, `NSV-019`, `TST-007` marked `DONE`), `AI_USAGE.md`, and `docs/HANDOVER.md`.

---

## AI Mistakes / Risky Output

At least one real example must be included before submission.

Do not invent an example. Add an entry when an AI suggestion is actually found to be unsafe, incorrect, incomplete or misleading.

### AI-RISK-001 — Treating server idempotency as optional

**Tool:** ChatGPT-assisted planning  
**Stage:** Architecture review

**Risky output / assumption**

An earlier working architecture described idempotency as something to use only "where supported by the backend contract" and kept the exact backend/API contract as `TO VERIFY`.

**Why this was risky**

The assessment explicitly states that:

- no real backend is provided;
- the candidate owns the fake implementation;
- Send Money must generate an idempotency key per attempt/logical operation so retry cannot double-process;
- queued operations must not be sent twice after reconnect or app restart.

Leaving idempotency dependent on an unknown backend would weaken one of the main assessment guarantees.

**How it was caught**

The original assessment was re-read and treated as the highest-priority source of truth.

**Correction**

The project architecture now requires:

- one stable operation identity for each logical Send or Contribution;
- one stable idempotency key reused on retry;
- durable queue persistence;
- duplicate-safe operation claiming;
- an idempotent fake remote that returns the existing result for a repeated key.

**Regression protection**

Implementation must include tests covering repeated delivery, restart recovery and exactly-one financial effect.

---

### AI-RISK-002 — Silent integer overflow and malformed parsing in Money value object

**Tool:** Antigravity (initial implementation & refactor) & Codex (peer code review)  
**Stage:** Phase 1 — Core Money implementation (T-MNY-001)

**Risky output / assumption**

Antigravity initially implemented the `Money` value object using native Dart 64-bit `int` operations directly (`+`, `-`, `*`, `~/`, `fromNaira`, and parsing) without overflow guards or boundary checks, and used naive character-stripping in string parsing.

**Why this was risky**

In 64-bit Dart (AOT/VM on mobile), native integer operations silently wrap around under two's-complement arithmetic instead of throwing an exception:
- Adding to a large positive balance (`maxInt + 1`) silently rolls over to `minInt`, turning a positive balance negative.
- Subtracting from a deficit (`minInt - 1`) rolls over to positive `maxInt`.
- In 64-bit two's complement, `-minInt` and `minInt.abs()` cannot fit in the positive 64-bit integer range, evaluating back to `minInt` (remaining negative).
- `fromNaira(naira)` executing `naira * 100` wraps around silently if `naira > 92,233,720,368,547,758`.
- In string parsing, removing all commas and spaces before validation allowed malformed inputs like `"1,2,3"` to be silently accepted as `123`, `"1 0"` as `10`, and `"."` as zero.
- In financial applications, silent overflow and permissive parsing corrupt balances and invalidate financial invariants without triggering errors.

**How it was caught**

The user submitted Antigravity's initial implementation to Codex for independent peer code review. Codex reviewed the code and caught two issues:
1. `[P1]` Integer overflow can silently corrupt financial amounts because native Dart arithmetic wraps around, and boundary tests were missing.
2. `[P2]` Malformed monetary inputs were accepted because commas and spaces were stripped before digit validation.

**Correction**

Antigravity reviewed Codex's findings, confirmed the flaws, and refactored `Money`:
- Used `BigInt` for intermediate arithmetic calculations funneled through a centralized `_checked(BigInt value)` helper enforcing signed 64-bit bounds (`[-9223372036854775808, 9223372036854775807]`), matching SQLite's integer storage.
- Throws `MoneyOverflowException` on arithmetic overflow (`+`, `-`, `*`, `~/`), `fromNaira` bounds breach, and oversized string parsing.
- Safe `operator -()` and `abs()` that reject `minInt`, preventing negative rollover.
- Added strict regex validation in parsing (`_thousandsRegex`, `_digitsOnlyRegex`) rejecting internal spaces, malformed commas, and empty digits (`"."`).
- Preserved `const Money.fromKobo` and `const Money.zero()`.

**Regression protection**

Added exhaustive tests in `test/core/money/money_test.dart` asserting that `maxKobo + 1`, `minKobo - 1`, `-minKobo`, `minKobo.abs()`, `minKobo ~/ -1`, multiplication overflow, `fromNaira` boundary overflow, oversized strings, and malformed inputs (`"1,2,3"`, `"1 0"`, `"."`, `"1,00"`) fail fast and reject invalid values.

---

### AI-RISK-003 — Leaking double getters and silent BigInt saturation in savings progress

**Tool:** Antigravity (initial implementation) & Codex (peer code review)  
**Stage:** Phase 1 — NovaSave Savings Progress Calculation (T-MNY-002)

**Risky output / assumption**

1. Antigravity initially exposed convenience getters `double get progressFraction` on both `SavingsProgress` and `SavingsGoal`, and supported `toProgressFraction(clamp: false)` returning values above `1.0`.
2. Antigravity implemented `rawBasisPoints` by calculating intermediate values in `BigInt` but immediately calling `.toInt()`. In Dart, converting an oversized `BigInt` to a 64-bit `int` silently saturates to `int.max` (`9223372036854775807`) rather than throwing or preserving exactness. For extreme ratios (e.g. `savedAmount = Money.maxKobo` and `targetAmount = 1 kobo`), the mathematical basis points value is `92233720368547758070000`, but `.toInt()` returned `9223372036854775807`.

**Why this was risky**

1. Exposing floating-point getters on domain models violates boundary isolation and encourages domain logic or consumers to rely on `double` rather than exact integer kobo and basis points.
2. Silent integer saturation corrupts uncapped progress metrics without signaling an error or preserving mathematical exactness.

**How it was caught**

The user submitted Antigravity's implementation to Codex for independent peer review. Codex flagged:
- `[P1]` Floating-point values escape the required presentation-boundary converter via `progressFraction` getters and `clamp: false`.
- `[P2]` Uncapped progress silently loses exactness when the quotient exceeds 64-bit int because `.toInt()` saturates.

**Correction**

Antigravity refactored `SavingsProgress` and `SavingsGoal`:
1. Removed `progressFraction` getters from both `SavingsProgress` and `SavingsGoal`.
2. Strictly clamped `toProgressFraction()` to `[0.0, 1.0]` for Flutter progress widgets, isolating `double` strictly to this boundary method.
3. Performed capping comparison (`raw > _maxBasisPoints`) directly in `BigInt` before invoking `.toInt()` on `basisPoints`, guaranteeing `.toInt()` is never called on values exceeding 10,000.
4. Exposed uncapped metrics as `BigInt get uncappedBasisPoints`, eliminating lossy 64-bit integer saturation.
5. Added an explicit regression test in `savings_progress_test.dart` asserting that extreme ratios (`maxKobo / 1 kobo`) calculate without saturation or overflow.

**Regression protection**

Automated tests in `test/features/novasave/savings_progress_test.dart` and `test/features/novasave/savings_goal_test.dart` assert that all domain calculations remain strictly integer/BigInt-based, boundary fractions are strictly clamped to `[0.0, 1.0]`, and extreme ratios preserve exact `BigInt` precision.

### AI-RISK-004 — Unchecked 64-bit integer arithmetic in SpendableBalancePolicy and silent truncation in Money / SavingsProgress

**Tool:** Antigravity (initial implementation) & Codex + Claude Code (peer code reviews)  
**Stage:** Phase 1 — Spendability Policy, Money, and Savings Progress (T-DOM-001, T-MNY-001, T-MNY-002)

**Risky output / assumption**

1. In `SpendableBalancePolicy`, reservation aggregation unwrapped `Money.kobo` and accumulated amounts using native Dart 64-bit `int` addition (`+=`) and subtraction (`-`).
2. In `SavingsProgress`, rounding logic in `roundedPercentage` and `formatPercentage(decimalPlaces: 1)` rounded unreached goals (e.g. 9,995 of 10,000 kobo) up to `100%` / `100.0%` despite unreached target and remaining balance.
3. In `Money.format`, setting `includeKobo: false` silently truncated non-zero fractional kobo (rendering `₦125,450.75` as `₦125,450`).
4. In `Money.parse`, trailing dots (`"50."`) and leading zeros (`"007"`, `"0,001"`) were accepted.

**Why this was risky**

1. Accumulating large pending operations using native 64-bit integer addition causes silent two's-complement wrap-around in Dart VM. Multiple large operations sum to negative/wrapped values, causing the policy to report zero reservations and leak spendable balance, directly violating HC-MONEY and MNY-006.
2. Reporting 100% progress when money is still required to meet the goal creates misleading and inaccurate financial displays.
3. Silently dropping non-zero fractional kobo in formatting hides real monetary value from the user.

**How it was caught**

Both Codex and Claude Code conducted independent adversarial peer reviews of Phase 1. Claude Code confirmed the defect using a probe test: a confirmed balance of ₦1.00 with two pending operations of 5×10¹⁸ kobo wrapped around to report a spendable balance of ~₦84 quadrillion.

**Correction**

1. Refactored `SpendableBalancePolicy` to accumulate reservations using exact `Money` arithmetic and to fail closed (`Money.zero()`) on `MoneyOverflowException` or non-positive confirmed balances. Added `excluding: OperationId?` to prevent self-counting during re-validation.
2. Refactored `SavingsProgress`: capped `roundedPercentage` at 99% if `!isGoalReached`, used floored tenths for 1-decimal-place formatting (never reporting 100.0% prematurely), and aligned `toProgressFraction()` to `basisPoints / 10000.0`.
3. Added `Money.formatCompact()` and ensured `Money.format(includeKobo: false)` preserves fractional kobo when non-zero.
4. Enforced strict grammar in `Money._parseInternal` (rejecting trailing dots, leading zeroes, lowercase `ngn`, and inputs > 40 chars).

**Regression protection**

Added adversarial tests in `test/sync/domain/spendable_balance_policy_test.dart`, `test/features/novasave/savings_progress_test.dart`, and `test/core/money/money_test.dart` asserting that large 64-bit operations fail closed, premature 100% is impossible, non-zero kobo is preserved, and malformed numeric strings are rejected.

---

## Additional Risk Entries

Add further entries when they happen.

Use this format:

### AI-RISK-XXX — Short title

**Tool:**  
**Stage:**  

**Risky output / assumption**

Describe the suggestion or generated implementation.

**Why this was risky**

Explain the possible consequence.

**How it was caught**

Explain the review, test, design comparison or source material that exposed the issue.

**Correction**

Describe what changed.

**Regression protection**

List the test, rule or review step added to prevent recurrence.

---

## Review Guidelines

When using AI on NovaWallet:

- Treat the assessment, approved flows and design exports as authoritative.
- Do not accept generated financial logic without checking integer-kobo handling.
- Verify retries reuse the same idempotency identity.
- Review offline persistence and restart behaviour carefully.
- Do not accept UI output without comparing it against the approved design references.
- Do not accept package/dependency additions without a concrete need.
- Run the relevant tests and analyzer rather than relying on an AI claim that code is correct.
- Record a meaningful AI mistake here when one is actually discovered.

---

## Submission Checklist

Before submitting:

- [ ] Every listed tool was actually used.
- [ ] Tool descriptions are accurate.
- [ ] At least 2–3 concrete prompts are included.
- [ ] Each prompt includes the resulting output and what was done with it.
- [ ] At least one real risky/incorrect AI output is documented.
- [ ] The correction is explained.
- [ ] A test, rule or review step protecting against recurrence is identified where applicable.
- [ ] No secrets, private credentials or unnecessary internal conversation content are included.
- [ ] The file reflects actual project history rather than reconstructed or fabricated examples.
