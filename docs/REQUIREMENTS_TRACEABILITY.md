# NovaWallet Requirements Traceability

**Status:** Reconciled pre-implementation baseline  
**Last updated:** 2026-09-20  
**Purpose:** Map authoritative assessment requirements and approved design states to implementation areas, verification, and delivery status.

This document is a working engineering traceability matrix. It does not replace the assessment brief or approved design exports.

---

## 1. Source-of-Truth Order

When sources disagree, use this order:

1. Original assessment / assignment brief
2. Detailed requirements and approved screen-flow documents
3. Approved design exports and screenshots
4. Current repository / code
5. Project engineering documentation
6. `TASKS.md` / `HANDOVER.md` operational context
7. Previous conversational or agent reasoning
8. General engineering assumptions

Do not preserve an older engineering decision merely because it is documented if a higher-priority source contradicts it.

---

## 2. Traceability Model

```text
Assessment requirement
        ↓
Detailed flow / design state
        ↓
Implementation area
        ↓
Test / verification
        ↓
Implementation status
```

### Evidence status

| Status | Meaning |
|---|---|
| `VERIFIED` | Directly supported by the assessment and/or approved design evidence |
| `PARTIALLY VERIFIED` | Source supports the requirement but leaves part of the implementation policy open |
| `INFERRED` | Engineering interpretation needed to satisfy verified higher-level requirements |
| `UNKNOWN / TO VERIFY` | Not supported by the supplied evidence |
| `CONTRADICTED` | Earlier documentation/assumption conflicts with authoritative material |

### Implementation status

`TODO` · `IN PROGRESS` · `BLOCKED` · `DONE`

Because implementation has not started, all implementation rows are currently `TODO` unless stated otherwise.

---

# 3. Authoritative Assessment Requirements

These IDs represent the original assessment rather than invented feature requirements.

| ID | Assessment requirement | Evidence | Implementation area | Required verification | Evidence status | Impl. status |
|---|---|---|---|---|---|---|
| ASM-001 | Build the solution as a Flutter mobile app covering Send Money and NovaSave contribution journeys | Assessment §2 | whole app | app builds/runs | VERIFIED | IN_PROGRESS |
| ASM-002 | Wallet balance is displayed in Naira from an integer-kobo value | Assessment §2.1, §2.2 | `core/money`, wallet | unit + widget | VERIFIED | TODO |
| ASM-003 | Wallet shows a scrollable recent-transactions list | Assessment §2.1 | `features/wallet` | widget/performance | VERIFIED | TODO |
| ASM-004 | Wallet supports pull-to-refresh | Assessment §2.1 | `features/wallet` | widget | VERIFIED | TODO |
| ASM-005 | Send Money implements Recipient → Amount → Confirm | Assessment §2.1 | `features/send_money` | widget | VERIFIED | TODO |
| ASM-006 | A Send uses idempotency so retry cannot double-process the transfer | Assessment §2.1 | `core/ids`, `sync`, `fake_backend`, send | unit + integration | VERIFIED | IN_PROGRESS |
| ASM-007 | NovaSave supports goal creation with name, target amount and target date | Assessment §2.1 | `features/novasave` | widget/unit | VERIFIED | TODO |
| ASM-008 | NovaSave supports contributions and progress as bar/percentage | Assessment §2.1 | `features/novasave` | widget/unit | VERIFIED | IN_PROGRESS |
| ASM-009 | Send/Contribution while offline is queued locally and shown as Pending rather than lost | Assessment §2.1 | `sync`, feature presentation | repository + widget + integration | VERIFIED | IN_PROGRESS |
| ASM-010 | Offline actions are not silently retried in an uncontrolled loop | Assessment §2.1 | `sync` | unit/integration | VERIFIED | DONE |
| ASM-011 | On reconnect, queued actions are replayed without duplicate financial effect | Assessment §2.1 | `sync`, `fake_backend` | integration | VERIFIED | DONE |
| ASM-012 | A queued action survives an app restart while offline | Assessment §2.2 | Drift persistence / `sync` | integration | VERIFIED | DONE |
| ASM-013 | A queued action is not sent twice after reconnect/restart | Assessment §2.2 | `sync`, `fake_backend` | integration | VERIFIED | DONE |
| ASM-014 | Money calculations never use floating-point arithmetic | Assessment §2.2 | `core/money`, `features/novasave/domain` | unit/static review | VERIFIED | IN_PROGRESS |
| ASM-015 | Key interactive elements expose proper Flutter `Semantics` | Assessment §2.2 | presentation/design system | widget/accessibility | VERIFIED | DONE |
| ASM-016 | Text respects system font scaling without breaking layout | Assessment §2.2 | presentation/design system | widget/manual at enlarged scale | VERIFIED | DONE |
| ASM-017 | Large recent-transaction lists use `ListView.builder` or equivalent lazy construction | Assessment §2.2 | `features/wallet` | widget/performance review | VERIFIED | DONE |
| ASM-018 | Sensitive mocked auth data, if introduced, is not stored in plain `SharedPreferences` | Assessment §2.2 | security/persistence | code review/test where applicable | VERIFIED | TODO |
| ASM-019 | Repository includes `AI_USAGE.md` describing tools, uses and concrete prompts/results | Assessment §2.2 | root documentation | submission review | VERIFIED | TODO |
| ASM-020 | `AI_USAGE.md` records at least one concrete AI mistake/risky output and how it was caught/fixed | Assessment §2.2 | root documentation | submission review | VERIFIED | TODO |
| ASM-021 | Repository includes README covering architecture, state-management choice, offline/sync design, trade-offs, run/test instructions | Assessment §2.3 | `README.md` | submission review | VERIFIED | TODO |
| ASM-022 | Widget tests cover Send Money | Assessment §2.3 | `test/features/send_money` | `flutter test` | VERIFIED | DONE |
| ASM-023 | Widget tests cover NovaSave contribution | Assessment §2.3 | `test/features/novasave` | `flutter test` | VERIFIED | TODO |
| ASM-024 | At least one integration test covers offline queue → sync | Assessment §2.3 | `integration_test/` | integration test | VERIFIED | TODO |
| ASM-025 | App runs with a single command on a standard Flutter setup | Assessment §2.3 | repository/toolchain | clean-run verification | VERIFIED | IN_PROGRESS |
| ASM-026 | README states targeted Flutter/Dart versions | Assessment §2.3 | `README.md`, toolchain | submission review | VERIFIED | DONE |
| ASM-027 | Submission provides a Git repository link/access | Assessment §2.3 | repository delivery | submission review | VERIFIED | TODO |

### Assessment context that is not a build requirement

The brief references BVN/NIN, NIBSS NIP, USSD, CBN guidance and NDPA 2023 as realistic operating context. The assessment explicitly says candidates are not expected to be regulatory experts. These are not requirements to implement KYC, NIBSS, USSD or production compliance integrations.

---

# 4. Money and Data-Integrity Requirements

These rows make the assessment's highest-risk constraints implementation-testable.

| ID | Requirement | Parent assessment | Implementation | Verification | Evidence status | Status |
|---|---|---|---|---|---|---|
| MNY-001 | Domain/data monetary amounts are integer kobo | ASM-002, ASM-014 | `lib/core/money/` | unit tests | VERIFIED | DONE |
| MNY-002 | Formatting kobo → Naira is exact | ASM-002, ASM-014 | `lib/core/money/` | unit tests | VERIFIED | DONE |
| MNY-003 | Addition/subtraction/progress calculations do not use `double` | ASM-014 | `core/money`, `features/novasave/domain` | unit tests/code review | VERIFIED | DONE |
| MNY-004 | Confirmed wallet balance changes only after a Send is successfully processed | design flows + integrity principle | wallet/send domain | integration + widget/unit | VERIFIED by design | DONE |
| MNY-005 | Confirmed NovaSave progress changes only after contribution success | design flows + integrity principle | NovaSave domain | integration + widget/unit | VERIFIED by design | DONE |
| MNY-006 | Policy for multiple queued outgoing operations against one cached balance must be explicitly chosen and documented | assessment leaves this unspecified | `lib/sync/domain/spendable_balance_policy.dart`, `docs/ARCHITECTURE.md` | `test/sync/domain/spendable_balance_policy_test.dart` | DECISION / INFERRED | DONE |

`MNY-006` balance-reservation policy is resolved: headline balance displays confirmed cached balance, while outgoing entry forms validate against spendable balance (confirmed minus active pending outgoing operations). Implemented in `SpendableBalancePolicy`.

---

# 5. Wallet Requirements

Primary visual references are defined in `docs/design/SCREEN_INDEX.md`.

| ID | Requirement / behavior | Parent | Design evidence | Implementation | Verification | Evidence | Status |
|---|---|---|---|---|---|---|---|
| WAL-001 | Show available wallet balance | ASM-002 | UI-WAL-01 | `features/wallet` | widget/unit | VERIFIED | IMPLEMENTED |
| WAL-002 | Render recent transactions lazily | ASM-003, ASM-017 | UI-WAL-01 | `features/wallet` | widget/performance/unit | VERIFIED | IMPLEMENTED |
| WAL-003 | Pull to refresh wallet data | ASM-004 | UI-WAL-07 | `features/wallet` | widget | VERIFIED | IMPLEMENTED |
| WAL-004 | Show empty transaction state | design-derived | UI-WAL-09 | `features/wallet` | widget/visual | VERIFIED by design | IMPLEMENTED |
| WAL-005 | Show wallet offline notification + last-updated state | ASM-009 | UI-WAL-02 | wallet + connectivity | widget/visual | VERIFIED by design | IMPLEMENTED |
| WAL-006 | Show pending transfer in recent activity | ASM-009 | UI-WAL-03 | wallet + sync projection | widget | VERIFIED by design | IMPLEMENTED |
| WAL-007 | Show reconnect/processing state | ASM-011 | UI-WAL-04 | wallet + sync projection | integration/widget | VERIFIED by design | IMPLEMENTED |
| WAL-008 | Show completed transfer and confirmed new balance | ASM-011 | UI-WAL-05 | wallet | integration/widget | VERIFIED by design | IMPLEMENTED |
| WAL-009 | Show sync-failure state while preserving queued intent | ASM-009, ASM-010 | UI-WAL-06 | wallet + sync | integration/widget | VERIFIED by design | IMPLEMENTED |
| WAL-010 | Show loading/skeleton state | design-derived | UI-WAL-08 | wallet | widget/visual | VERIFIED by design | IMPLEMENTED |
| WAL-011 | Show pending transaction details | design-derived | UI-WAL-10 | wallet | widget | VERIFIED by design | IMPLEMENTED |

---

# 6. Send Money Requirements

| ID | Requirement / behavior | Parent | Design evidence | Implementation | Verification | Evidence | Status |
|---|---|---|---|---|---|---|---|
| SND-001 | Recipient entry | ASM-005 | UI-SND-01 | `features/send_money` | widget (`test/features/send_money/presentation/recipient_entry_screen_test.dart`) | VERIFIED | IMPLEMENTED |
| SND-002 | Empty-recipient validation | design-derived | UI-SND-02 | send domain/presentation | unit/widget (`test/features/send_money/presentation/recipient_entry_screen_test.dart`) | VERIFIED by design | IMPLEMENTED |
| SND-003 | Invalid-account validation | design-derived | UI-SND-03 | send domain/presentation | unit/widget (`test/features/send_money/presentation/recipient_entry_screen_test.dart`) | VERIFIED by design | IMPLEMENTED |
| SND-004 | Resolve supported fake recipient and display recipient name | design-derived | UI-SND-04 | fake recipient source/send | unit/widget (`test/features/send_money/data/fake_recipient_directory_test.dart`) | VERIFIED by design | IMPLEMENTED |
| SND-005 | Amount entry | ASM-005 | UI-SND-05, UI-SND-06 | send presentation (`AmountEntryScreen`) | widget (`test/features/send_money/presentation/amount_entry_screen_test.dart`) | VERIFIED | IMPLEMENTED |
| SND-006 | Reject zero/non-positive amount | design-derived | UI-SND-08 | send presentation/controller | unit/widget (`test/features/send_money/presentation/amount_entry_controller_test.dart`) | VERIFIED by design | IMPLEMENTED |
| SND-007 | Reject amount above available/spendable balance | design-derived | UI-SND-07 | send presentation/controller | unit/widget (`test/features/send_money/presentation/amount_entry_controller_test.dart`) | VERIFIED by design | IMPLEMENTED |
| SND-008 | Show offline amount state with last-updated balance | ASM-009 | UI-SND-09 | send + connectivity | widget (`test/features/send_money/presentation/amount_entry_screen_test.dart`) | VERIFIED by design | IMPLEMENTED |
| SND-009 | Show transfer confirmation | ASM-005 | UI-SND-10 | send presentation (`TransferConfirmationScreen`) | widget (`test/features/send_money/presentation/transfer_confirmation_screen_test.dart`) | VERIFIED | IMPLEMENTED |
| SND-010 | Create one stable operation identity/idempotency key for one logical transfer | ASM-006, ASM-013 | UI-SND-10/14 | send + IDs + sync | unit/integration (`test/features/send_money/presentation/transfer_confirmation_controller_test.dart`) | INFERRED implementation required by verified idempotency requirement | IMPLEMENTED |
| SND-011 | Online transfer enters Processing | flow/design | UI-SND-11 | send presentation (`TransferResultScreen`) | widget (`test/features/send_money/presentation/transfer_result_screen_test.dart`) | VERIFIED by design | IMPLEMENTED |
| SND-012 | Online transfer success shows amount, recipient, reference/date/status | flow/design | UI-SND-12 | send presentation (`TransferResultScreen`) | widget (`test/features/send_money/presentation/transfer_result_screen_test.dart`) | VERIFIED by design | IMPLEMENTED |
| SND-013 | Immediate online failure shows no debit + retry/back actions | flow/design | UI-SND-13 | send presentation (`TransferResultScreen`) | widget (`test/features/send_money/presentation/transfer_result_screen_test.dart`) | VERIFIED by design | IMPLEMENTED |
| SND-014 | Offline confirmation explains operation will be saved | ASM-009 | UI-SND-14 | send presentation (`TransferConfirmationScreen`) | widget (`test/features/send_money/presentation/transfer_confirmation_screen_test.dart`) | VERIFIED by design | IMPLEMENTED |
| SND-015 | Offline Send is durably persisted before UI reports it saved | ASM-009, ASM-012 | UI-SND-15 | `TransferResultScreen` (`UI-SND-15`) + sync/persistence | repository + unit/widget (`test/features/send_money/presentation/transfer_result_screen_test.dart`) | VERIFIED | DONE |
| SND-016 | Pending transfer survives restart | ASM-012 | UI-SND-15 + Flow 2 | sync/persistence | integration | VERIFIED | DONE |
| SND-017 | Reconnect transitions pending transfer into processing | ASM-011 | UI-SND-16 | `TransferResultScreen` (`UI-SND-16`) | widget (`test/features/send_money/presentation/transfer_result_screen_test.dart`) + integration | VERIFIED by design | DONE |
| SND-018 | Reconnect success completes once and updates wallet once | ASM-011, ASM-013 | UI-SND-17 | `TransferResultScreen` (`UI-SND-17`) + sync/fake backend/wallet | widget (`test/features/send_money/presentation/transfer_result_screen_test.dart`) + integration | VERIFIED | DONE |
| SND-019 | Sync failure retains the transfer safely and offers retry | ASM-009, ASM-010 | UI-SND-18 | `TransferResultScreen` (`UI-SND-18`) | widget (`test/features/send_money/presentation/transfer_result_screen_test.dart`) | VERIFIED by design | DONE |
| SND-020 | Manual retry reuses the same logical operation/idempotency key | ASM-006, ASM-013 | UI-SND-18 | `TransferResultScreen` (`UI-SND-18`) + sync/fake backend | unit/widget (`test/features/send_money/presentation/transfer_result_screen_test.dart`) + integration | INFERRED implementation required by verified idempotency requirement | DONE |

---

# 7. NovaSave Requirements

| ID | Requirement / behavior | Parent | Design evidence | Implementation | Verification | Evidence | Status |
|---|---|---|---|---|---|---|---|
| NSV-001 | Show populated goal list | ASM-007, ASM-008 | UI-NSV-01 | `features/novasave` (`GoalsListScreen`, `GoalCard`) | widget/unit | VERIFIED by design | COMPLETED |
| NSV-002 | Show empty goal state | design-derived | UI-NSV-03 | `features/novasave` (`GoalsListScreen`, `AppEmptyState`) | widget | VERIFIED by design | COMPLETED |
| NSV-003 | Create goal with name, target amount, target date | ASM-007 | UI-NSV-04, UI-NSV-07 | `features/novasave` (`CreateGoalScreen`, `GoalDetailsScreen`) | widget/integration/unit | VERIFIED by design | COMPLETED |
| NSV-004 | Require goal name | design-derived | UI-NSV-05 | `features/novasave` (`CreateGoalScreen`) | unit/widget | VERIFIED by design | COMPLETED |
| NSV-005 | Require positive target amount | design-derived + money rules | UI-NSV-05 | `features/novasave` (`CreateGoalScreen`, `HC-MONEY`) | unit/widget | VERIFIED by design | COMPLETED |
| NSV-006 | Require future target date | design-derived | UI-NSV-05 | `features/novasave` (`CreateGoalScreen`, `TargetDatePickerSheet`) | unit/widget | VERIFIED by design | COMPLETED |
| NSV-007 | Provide target-date picker | design-derived | UI-NSV-06 | `features/novasave` (`TargetDatePickerSheet`) | widget/visual | VERIFIED by design | COMPLETED |
| NSV-008 | Show goal details and remaining amount | ASM-008 | UI-NSV-08 | `features/novasave` (`GoalDetailsScreen`, `domain`) | widget/unit | VERIFIED by design | COMPLETED |
| NSV-009 | Show contribution amount entry and projected progress | ASM-008 | UI-NSV-09 | `features/novasave` (`ContributeAmountScreen`, `domain`) | widget/unit | VERIFIED | COMPLETED |
| NSV-010 | Reject contribution above wallet balance | design-derived | UI-NSV-10 | `features/novasave` (`ContributeAmountController`, `MNY-006`) | unit/widget | VERIFIED by design | COMPLETED |
| NSV-011 | Show contribution confirmation | flow/design | UI-NSV-11 | `features/novasave` (`ContributionConfirmationScreen`) | widget | VERIFIED by design | COMPLETED |
| NSV-012 | Create one stable operation identity/idempotency key for one logical contribution | ASM-011, ASM-013 | UI-NSV-11/16 | `features/novasave` (`ContributionConfirmationController`) | unit/widget | INFERRED implementation required by duplicate-prevention requirement | COMPLETED |
| NSV-013 | Online contribution enters Processing | flow/design | UI-NSV-12 | `features/novasave` (`ContributionResultScreen`) | widget/integration | VERIFIED by design | COMPLETED |
| NSV-014 | Successful contribution updates amount/progress | ASM-008 | UI-NSV-13, UI-NSV-14 | `features/novasave` (`ContributionResultScreen`, `domain`) | unit/widget/integration | VERIFIED | COMPLETED |
| NSV-015 | Immediate online contribution failure leaves wallet unchanged and offers retry | flow/design | UI-NSV-15 | `features/novasave` (`ContributionResultScreen`) | widget/integration | VERIFIED by design | COMPLETED |
| NSV-016 | Offline confirmation explains contribution will be saved | ASM-009 | UI-NSV-16 | `features/novasave` (`ContributionConfirmationScreen`) | widget | VERIFIED by design | COMPLETED |
| NSV-017 | Offline Contribution is durably persisted before UI reports it saved | ASM-009, ASM-012 | UI-NSV-17 | `features/novasave` (`ContributionConfirmationController`, `OperationRepository`) | unit/widget/integration | VERIFIED | COMPLETED |
| NSV-018 | Pending contribution remains visible while confirmed goal progress is unchanged | ASM-009 | UI-NSV-18 | `features/novasave` (`GoalDetailsScreen`, `ContributionResultScreen`) | widget/integration | VERIFIED by design | COMPLETED |
| NSV-019 | Pending contribution survives restart | ASM-012 | UI-NSV-17/18 + Flow 6 | sync/persistence | integration | VERIFIED | DONE |
| NSV-020 | Reconnect transitions pending contribution into processing | ASM-011 | UI-NSV-19 | `features/novasave` (`ContributionResultScreen`), sync | integration/widget | VERIFIED by design | COMPLETED |
| NSV-021 | Reconnect success updates goal once | ASM-011, ASM-013 | UI-NSV-20 | sync/fake backend/NovaSave | integration | VERIFIED | DONE |
| NSV-022 | Sync failure retains contribution safely and offers retry | ASM-009, ASM-010 | UI-NSV-21 | `features/novasave` (`ContributionResultScreen`), sync | integration/widget | VERIFIED by design | COMPLETED |
| NSV-023 | Manual retry reuses the same logical contribution/idempotency key | ASM-013 | UI-NSV-21 | sync/fake backend | unit/integration | INFERRED implementation required by duplicate-prevention requirement | DONE |

---

# 8. Synchronization and Offline Requirements

| ID | Requirement | Parent | Implementation | Verification | Evidence | Status |
|---|---|---|---|---|---|---|
| SYNC-001 | Observe online/offline connectivity | ASM-009, ASM-011 | `core/connectivity` | unit/widget | VERIFIED | DONE |
| SYNC-002 | Persist pending operation before acknowledging it as saved | ASM-009, ASM-012 | `sync/data`, Drift | repository/integration | VERIFIED | DONE |
| SYNC-003 | Restore pending operations after process restart | ASM-012 | `sync` + persistence | integration | VERIFIED | DONE |
| SYNC-004 | Synchronize eligible pending operations on reconnect | ASM-011 | `sync/application` | integration | VERIFIED | DONE |
| SYNC-005 | Synchronization uses a single shared coordinator, not feature-specific replay loops | ASM-010, ASM-013 | `sync/application` | architectural review/tests | INFERRED implementation | DONE |
| SYNC-006 | One logical operation has one stable operation ID | ASM-013 | `core/ids`, sync | unit | INFERRED implementation | DONE |
| SYNC-007 | One logical operation has one stable idempotency key reused across retry/restart | ASM-006, ASM-013 | `core/ids`, sync, fake backend | unit/integration | INFERRED implementation | DONE |
| SYNC-008 | Fake remote deduplicates repeated idempotency keys | ASM-006, ASM-013 | `fake_backend` | unit/integration | INFERRED implementation required to demonstrate guarantee | DONE |
| SYNC-009 | Repeated key with conflicting payload is rejected/flagged | ASM-013 | fake backend | unit | INFERRED defensive rule | DONE |
| SYNC-010 | Concurrent sync triggers cannot process the same local operation concurrently | ASM-013 | sync + database claim | unit/integration | INFERRED implementation | DONE |
| SYNC-011 | App interruption after remote success but before local completion does not produce a second financial effect | ASM-013 | sync + fake backend | integration/failure injection | INFERRED implementation test of verified requirement | DONE |
| SYNC-012 | Recoverable sync failure keeps operation durable and retryable | ASM-009, ASM-010 | sync | integration | VERIFIED by design | DONE |
| SYNC-013 | Retry is event-triggered/bounded; no uncontrolled background retry loop | ASM-010 | sync | unit/integration | VERIFIED | DONE |
| SYNC-014 | Connectivity status, sync status and operation status remain separate state dimensions | design + architecture | app/sync state | unit/review | INFERRED architecture | DONE |

---

# 9. Accessibility and Performance

| ID | Requirement | Parent | Implementation | Verification | Evidence | Status |
|---|---|---|---|---|---|---|
| A11Y-001 | Key interactive controls expose meaningful Semantics | ASM-015 | design system + feature presentation | widget/manual screen reader | VERIFIED | DONE |
| A11Y-002 | Text scales with system settings | ASM-016 | design system + layouts | widget/manual | VERIFIED | DONE |
| A11Y-003 | Enlarged text does not break critical journeys | ASM-016 | feature presentation | widget/manual at enlarged scale | VERIFIED | DONE |
| PERF-001 | Recent transaction list is lazy | ASM-017 | Wallet list | widget/code review | VERIFIED | DONE |
| PERF-002 | UI remains usable on low-end/patchy-connectivity scenario targeted by brief | assessment context | app architecture | manual/profile review | PARTIALLY VERIFIED | DONE |

No exact row-count benchmark is required by the assessment. Any 10,000-row test is optional engineering hardening, not an authoritative requirement.

---

# 10. Design-System Requirements

These are approved-design requirements, not separate assessor wording.

| ID | Requirement | Design evidence | Implementation | Verification | Evidence | Status |
|---|---|---|---|---|---|---|
| DSN-001 | Implement approved color scales | UI-DS-01 | `lib/design_system/tokens/app_colors.dart` | unit | test/design_system/tokens_test.dart | DONE |
| DSN-002 | Use Plus Jakarta Sans with approved type scale | UI-DS-02 | `lib/design_system/tokens/app_typography.dart`, `lib/design_system/theme/app_theme.dart` | unit + widget | test/design_system/tokens_test.dart, test/design_system/theme_test.dart | DONE |
| DSN-003 | Use approved icon set | UI-DS-03 | `lib/design_system/icons/app_icons.dart` | unit + widget | test/design_system/icons_test.dart | DONE |
| DSN-004 | Use approved spacing scale | UI-DS-04 | `lib/design_system/tokens/app_spacing.dart` | unit | test/design_system/tokens_test.dart | DONE |
| DSN-005 | Use approved radii | UI-DS-04 | `lib/design_system/tokens/app_radii.dart` | unit | test/design_system/tokens_test.dart | DONE |
| DSN-006 | Use approved elevation/shadow | UI-DS-04 | `lib/design_system/tokens/app_elevation.dart` | unit | test/design_system/tokens_test.dart | DONE |
| DSN-007 | Implement reusable button states | UI-CMP-01 | `lib/design_system/components/buttons/app_button.dart` | widget | test/design_system/components_test.dart | DONE |
| DSN-008 | Implement reusable text-field states | UI-CMP-02 | `lib/design_system/components/fields/` | widget | test/design_system/components_test.dart | DONE |
| DSN-009 | Implement system notifications | UI-CMP-03 | `lib/design_system/components/notifications/app_system_notification.dart` | widget | test/design_system/components_test.dart | DONE |
| DSN-010 | Implement status/result components | UI-CMP-04 | `lib/design_system/components/status/` | widget | test/design_system/components_test.dart | DONE |
| DSN-011 | Implement bottom navigation | UI-CMP-05 | `lib/app/navigation/app_bottom_nav_bar.dart` | widget | test/app/app_shell_test.dart | DONE |
| DSN-012 | Implement reusable cards/list rows | UI-CMP-07 | `lib/design_system/components/cards/` | widget | test/design_system/components_test.dart | DONE |
| DSN-013 | Implement progress treatment | UI-CMP-08 | `lib/design_system/components/progress/app_progress_bar.dart` | widget | test/design_system/components_test.dart | DONE |
| DSN-014 | Implement sheets/empty-state patterns | UI-CMP-09 | `lib/design_system/components/sheets/`, `lib/design_system/components/empty_states/` | widget | test/design_system/components_test.dart | DONE |

For exact token values, `docs/DESIGN_SYSTEM.md` and the authoritative Style Guide PDF control implementation.

---

# 11. Testing and Submission Requirements

| ID | Requirement | Parent | Artifact/area | Verification | Evidence | Status |
|---|---|---|---|---|---|---|
| TST-001 | Unit tests cover Money correctness | ASM-002, ASM-014 | `test/core/money` | `flutter test` | INFERRED test needed for hard constraint | DONE |
| TST-002 | Unit/repository tests cover pending-operation persistence/state transitions | ASM-009, ASM-012 | `test/sync` | `flutter test` | INFERRED test needed for hard constraint | DONE |
| TST-003 | Unit tests cover fake-remote idempotency | ASM-006, ASM-013 | `test/fake_backend` | `flutter test` | INFERRED test needed for hard constraint | DONE |
| TST-004 | Required Send Money widget tests exist | ASM-022 | `test/features/send_money/` | `flutter test` | VERIFIED | DONE |
| TST-005 | Required NovaSave contribution widget tests exist | ASM-023 | NovaSave tests | `flutter test` | VERIFIED | TODO |
| TST-006 | Integration test covers offline queue → restart/reconnect → exactly one effect | ASM-024 plus ASM-012/013 | `test/sync/kernel` & `integration_test` | integration run | VERIFIED + strengthened to catch duplicate regression | IN_PROGRESS |
| TST-007 | Failure/retry path is tested for lost/uncertain response behavior | ASM-013 | sync/fake backend | integration | INFERRED high-value regression test | DONE |
| DOC-001 | README is truthful about implemented state and required architecture/trade-offs/run/test info | ASM-021, ASM-026 | `README.md` | submission review | VERIFIED | TODO |
| DOC-002 | AI usage log is maintained from implementation start | ASM-019, ASM-020 | `AI_USAGE.md` | submission review | VERIFIED | TODO |
| DOC-003 | Flutter/Dart versions are pinned/recorded | ASM-026 | README/pubspec/toolchain | clean setup review | VERIFIED | DONE |
| DOC-004 | App runs with one standard Flutter command after setup | ASM-025 | repository | clean-run verification | VERIFIED | IN_PROGRESS |
| DOC-005 | Repository link/access is ready for submission | ASM-027 | remote repo | submission review | VERIFIED | TODO |

---

# 12. Optional Stretch Goals

These must not block mandatory requirements.

| ID | Optional item | Assessment source | Status |
|---|---|---|---|
| STR-001 | Local notification when queued Send syncs | Stretch goals | TODO / OPTIONAL |
| STR-002 | Basic localization scaffold: English + one Nigerian language for at least Send Money | Stretch goals | TODO / OPTIONAL |
| STR-003 | Wallet-home golden tests | Stretch goals | TODO / OPTIONAL |
| STR-004 | Biometric-confirmation stub above threshold | Stretch goals | TODO / OPTIONAL |

Do not implement stretch work until mandatory assessment requirements are complete and stable.

---

# 13. Known Open Item

| ID | Open question | Current classification | Action |
|---|---|---|---|
| OPEN-001 | How should multiple queued outgoing Send/Contribution operations be validated against one stale cached balance? | UNKNOWN / TO VERIFY | Choose a documented assessment-safe policy before implementing spendable-balance validation for multiple pending debits. Do not silently assume production reservation semantics. |

The supplied brief/designs do not resolve this case.

---

# 14. Maintenance Rules

When implementation starts:

1. A task in `docs/TASKS.md` must reference the requirement IDs it satisfies.
2. UI tasks must also reference the corresponding `UI-*` IDs from `docs/design/SCREEN_INDEX.md`.
3. Implementation paths in this matrix should be updated once concrete files exist.
4. Tests must be linked to the requirements they protect.
5. Mark a requirement `DONE` only after implementation, required tests, and applicable visual/accessibility verification pass.
6. If implementation uncovers a source conflict, do not rewrite the requirement silently. Record the conflict and resolve it according to the source-of-truth order.
7. New requirements derived only from engineering preference must be labelled `INFERRED`, not presented as assessor requirements.
8. Keep `TO VERIFY` items genuinely unresolved; do not convert them into facts without evidence or an explicit documented project decision.

---

# 15. Completion Gate

Before submission, this file should show:

- every mandatory `ASM-*` requirement mapped to implementation and verification;
- no unresolved mandatory requirement accidentally hidden under a feature-level ID;
- required Send Money and NovaSave widget-test coverage;
- offline/restart/exactly-once integration coverage;
- money correctness coverage;
- accessibility/font-scale coverage;
- lazy transaction-list verification;
- README and AI-usage deliverables present;
- only intentionally deferred optional stretch goals remaining incomplete.
