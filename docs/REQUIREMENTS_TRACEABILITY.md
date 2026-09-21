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
| ASM-001 | Build the solution as a Flutter mobile app covering Send Money and NovaSave contribution journeys | Assessment §2 | whole app | app builds/runs | VERIFIED | TODO |
| ASM-002 | Wallet balance is displayed in Naira from an integer-kobo value | Assessment §2.1, §2.2 | `core/money`, wallet | unit + widget | VERIFIED | TODO |
| ASM-003 | Wallet shows a scrollable recent-transactions list | Assessment §2.1 | `features/wallet` | widget/performance | VERIFIED | TODO |
| ASM-004 | Wallet supports pull-to-refresh | Assessment §2.1 | `features/wallet` | widget | VERIFIED | TODO |
| ASM-005 | Send Money implements Recipient → Amount → Confirm | Assessment §2.1 | `features/send_money` | widget | VERIFIED | TODO |
| ASM-006 | A Send uses idempotency so retry cannot double-process the transfer | Assessment §2.1 | `core/ids`, `sync`, `fake_backend`, send | unit + integration | VERIFIED | TODO |
| ASM-007 | NovaSave supports goal creation with name, target amount and target date | Assessment §2.1 | `features/novasave` | widget/unit | VERIFIED | TODO |
| ASM-008 | NovaSave supports contributions and progress as bar/percentage | Assessment §2.1 | `features/novasave` | widget/unit | VERIFIED | TODO |
| ASM-009 | Send/Contribution while offline is queued locally and shown as Pending rather than lost | Assessment §2.1 | `sync`, feature presentation | repository + widget + integration | VERIFIED | TODO |
| ASM-010 | Offline actions are not silently retried in an uncontrolled loop | Assessment §2.1 | `sync` | unit/integration | VERIFIED | TODO |
| ASM-011 | On reconnect, queued actions are replayed without duplicate financial effect | Assessment §2.1 | `sync`, `fake_backend` | integration | VERIFIED | TODO |
| ASM-012 | A queued action survives an app restart while offline | Assessment §2.2 | Drift persistence / `sync` | integration | VERIFIED | TODO |
| ASM-013 | A queued action is not sent twice after reconnect/restart | Assessment §2.2 | `sync`, `fake_backend` | integration | VERIFIED | TODO |
| ASM-014 | Money calculations never use floating-point arithmetic | Assessment §2.2 | `core/money` | unit/static review | VERIFIED | TODO |
| ASM-015 | Key interactive elements expose proper Flutter `Semantics` | Assessment §2.2 | presentation/design system | widget/accessibility | VERIFIED | TODO |
| ASM-016 | Text respects system font scaling without breaking layout | Assessment §2.2 | presentation/design system | widget/manual at enlarged scale | VERIFIED | TODO |
| ASM-017 | Large recent-transaction lists use `ListView.builder` or equivalent lazy construction | Assessment §2.2 | `features/wallet` | widget/performance review | VERIFIED | TODO |
| ASM-018 | Sensitive mocked auth data, if introduced, is not stored in plain `SharedPreferences` | Assessment §2.2 | security/persistence | code review/test where applicable | VERIFIED | TODO |
| ASM-019 | Repository includes `AI_USAGE.md` describing tools, uses and concrete prompts/results | Assessment §2.2 | root documentation | submission review | VERIFIED | TODO |
| ASM-020 | `AI_USAGE.md` records at least one concrete AI mistake/risky output and how it was caught/fixed | Assessment §2.2 | root documentation | submission review | VERIFIED | TODO |
| ASM-021 | Repository includes README covering architecture, state-management choice, offline/sync design, trade-offs, run/test instructions | Assessment §2.3 | `README.md` | submission review | VERIFIED | TODO |
| ASM-022 | Widget tests cover Send Money | Assessment §2.3 | `test/features/send_money` | `flutter test` | VERIFIED | TODO |
| ASM-023 | Widget tests cover NovaSave contribution | Assessment §2.3 | `test/features/novasave` | `flutter test` | VERIFIED | TODO |
| ASM-024 | At least one integration test covers offline queue → sync | Assessment §2.3 | `integration_test/` | integration test | VERIFIED | TODO |
| ASM-025 | App runs with a single command on a standard Flutter setup | Assessment §2.3 | repository/toolchain | clean-run verification | VERIFIED | TODO |
| ASM-026 | README states targeted Flutter/Dart versions | Assessment §2.3 | `README.md`, toolchain | submission review | VERIFIED | TODO |
| ASM-027 | Submission provides a Git repository link/access | Assessment §2.3 | repository delivery | submission review | VERIFIED | TODO |

### Assessment context that is not a build requirement

The brief references BVN/NIN, NIBSS NIP, USSD, CBN guidance and NDPA 2023 as realistic operating context. The assessment explicitly says candidates are not expected to be regulatory experts. These are not requirements to implement KYC, NIBSS, USSD or production compliance integrations.

---

# 4. Money and Data-Integrity Requirements

These rows make the assessment's highest-risk constraints implementation-testable.

| ID | Requirement | Parent assessment | Implementation | Verification | Evidence status | Status |
|---|---|---|---|---|---|---|
| MNY-001 | Domain/data monetary amounts are integer kobo | ASM-002, ASM-014 | `lib/core/money/` | unit tests | VERIFIED | TODO |
| MNY-002 | Formatting kobo → Naira is exact | ASM-002, ASM-014 | `lib/core/money/` | unit tests | VERIFIED | TODO |
| MNY-003 | Addition/subtraction/progress calculations do not use `double` | ASM-014 | `core/money`, NovaSave domain | unit tests/code review | VERIFIED | TODO |
| MNY-004 | Confirmed wallet balance changes only after a Send is successfully processed | design flows + integrity principle | wallet/send domain | integration + widget | VERIFIED by design | TODO |
| MNY-005 | Confirmed NovaSave progress changes only after contribution success | design flows + integrity principle | NovaSave domain | integration + widget | VERIFIED by design | TODO |
| MNY-006 | Policy for multiple queued outgoing operations against one cached balance must be explicitly chosen and documented | assessment leaves this unspecified | domain/application | unit/integration | UNKNOWN / TO VERIFY | TODO |

`MNY-006` is the only unresolved balance-reservation policy in the supplied material. Do not silently invent production-bank semantics.

---

# 5. Wallet Requirements

Primary visual references are defined in `docs/design/SCREEN_INDEX.md`.

| ID | Requirement / behavior | Parent | Design evidence | Implementation | Verification | Evidence | Status |
|---|---|---|---|---|---|---|---|
| WAL-001 | Show available wallet balance | ASM-002 | UI-WAL-01 | `features/wallet` | widget | VERIFIED | TODO |
| WAL-002 | Render recent transactions lazily | ASM-003, ASM-017 | UI-WAL-01 | `features/wallet` | widget/performance | VERIFIED | TODO |
| WAL-003 | Pull to refresh wallet data | ASM-004 | UI-WAL-07 | `features/wallet` | widget | VERIFIED | TODO |
| WAL-004 | Show empty transaction state | design-derived | UI-WAL-09 | `features/wallet` | widget/visual | VERIFIED by design | TODO |
| WAL-005 | Show wallet offline notification + last-updated state | ASM-009 | UI-WAL-02 | wallet + connectivity | widget/visual | VERIFIED by design | TODO |
| WAL-006 | Show pending transfer in recent activity | ASM-009 | UI-WAL-03 | wallet + sync projection | widget | VERIFIED by design | TODO |
| WAL-007 | Show reconnect/processing state | ASM-011 | UI-WAL-04 | wallet + sync projection | integration/widget | VERIFIED by design | TODO |
| WAL-008 | Show completed transfer and confirmed new balance | ASM-011 | UI-WAL-05 | wallet | integration/widget | VERIFIED by design | TODO |
| WAL-009 | Show sync-failure state while preserving queued intent | ASM-009, ASM-010 | UI-WAL-06 | wallet + sync | integration/widget | VERIFIED by design | TODO |
| WAL-010 | Show loading/skeleton state | design-derived | UI-WAL-08 | wallet | widget/visual | VERIFIED by design | TODO |
| WAL-011 | Show pending transaction details | design-derived | UI-WAL-10 | wallet | widget | VERIFIED by design | TODO |

---

# 6. Send Money Requirements

| ID | Requirement / behavior | Parent | Design evidence | Implementation | Verification | Evidence | Status |
|---|---|---|---|---|---|---|---|
| SND-001 | Recipient entry | ASM-005 | UI-SND-01 | `features/send_money` | widget | VERIFIED | TODO |
| SND-002 | Empty-recipient validation | design-derived | UI-SND-02 | send domain/presentation | unit/widget | VERIFIED by design | TODO |
| SND-003 | Invalid-account validation | design-derived | UI-SND-03 | send domain/presentation | unit/widget | VERIFIED by design | TODO |
| SND-004 | Resolve supported fake recipient and display recipient name | design-derived | UI-SND-04 | fake recipient source/send | unit/widget | VERIFIED by design | TODO |
| SND-005 | Amount entry | ASM-005 | UI-SND-05, UI-SND-06 | send | widget | VERIFIED | TODO |
| SND-006 | Reject zero/non-positive amount | design-derived | UI-SND-08 | send domain | unit/widget | VERIFIED by design | TODO |
| SND-007 | Reject amount above available/spendable balance | design-derived | UI-SND-07 | send domain | unit/widget | VERIFIED by design | TODO |
| SND-008 | Show offline amount state with last-updated balance | ASM-009 | UI-SND-09 | send + connectivity | widget | VERIFIED by design | TODO |
| SND-009 | Show transfer confirmation | ASM-005 | UI-SND-10 | send | widget | VERIFIED | TODO |
| SND-010 | Create one stable operation identity/idempotency key for one logical transfer | ASM-006, ASM-013 | UI-SND-10/14 | send + IDs + sync | unit/integration | INFERRED implementation required by verified idempotency requirement | TODO |
| SND-011 | Online transfer enters Processing | flow/design | UI-SND-11 | send | widget/integration | VERIFIED by design | TODO |
| SND-012 | Online transfer success shows amount, recipient, reference/date/status | flow/design | UI-SND-12 | send | widget/integration | VERIFIED by design | TODO |
| SND-013 | Immediate online failure shows no debit + retry/back actions | flow/design | UI-SND-13 | send | widget/integration | VERIFIED by design | TODO |
| SND-014 | Offline confirmation explains operation will be saved | ASM-009 | UI-SND-14 | send | widget | VERIFIED by design | TODO |
| SND-015 | Offline Send is durably persisted before UI reports it saved | ASM-009, ASM-012 | UI-SND-15 | sync/persistence | repository + integration | VERIFIED | TODO |
| SND-016 | Pending transfer survives restart | ASM-012 | UI-SND-15 + Flow 2 | sync/persistence | integration | VERIFIED | TODO |
| SND-017 | Reconnect transitions pending transfer into processing | ASM-011 | UI-SND-16 | sync | integration/widget | VERIFIED by design | TODO |
| SND-018 | Reconnect success completes once and updates wallet once | ASM-011, ASM-013 | UI-SND-17 | sync/fake backend/wallet | integration | VERIFIED | TODO |
| SND-019 | Sync failure retains the transfer safely and offers retry | ASM-009, ASM-010 | UI-SND-18 | sync/send | integration/widget | VERIFIED by design | TODO |
| SND-020 | Manual retry reuses the same logical operation/idempotency key | ASM-006, ASM-013 | UI-SND-18 | sync/fake backend | unit/integration | INFERRED implementation required by verified idempotency requirement | TODO |

---

# 7. NovaSave Requirements

| ID | Requirement / behavior | Parent | Design evidence | Implementation | Verification | Evidence | Status |
|---|---|---|---|---|---|---|---|
| NSV-001 | Show populated goal list | ASM-007, ASM-008 | UI-NSV-01 | `features/novasave` | widget | VERIFIED by design | TODO |
| NSV-002 | Show empty goal state | design-derived | UI-NSV-03 | NovaSave | widget | VERIFIED by design | TODO |
| NSV-003 | Create goal with name, target amount, target date | ASM-007 | UI-NSV-04, UI-NSV-07 | NovaSave | widget/integration | VERIFIED | TODO |
| NSV-004 | Require goal name | design-derived | UI-NSV-05 | NovaSave domain | unit/widget | VERIFIED by design | TODO |
| NSV-005 | Require positive target amount | design-derived + money rules | UI-NSV-05 | NovaSave domain | unit/widget | VERIFIED by design | TODO |
| NSV-006 | Require future target date | design-derived | UI-NSV-05 | NovaSave domain | unit/widget | VERIFIED by design | TODO |
| NSV-007 | Provide target-date picker | design-derived | UI-NSV-06 | NovaSave presentation | widget/visual | VERIFIED by design | TODO |
| NSV-008 | Show goal details and remaining amount | ASM-008 | UI-NSV-08 | NovaSave | widget/unit | VERIFIED by design | TODO |
| NSV-009 | Show contribution amount entry and projected progress | ASM-008 | UI-NSV-09 | NovaSave | widget/unit | VERIFIED | TODO |
| NSV-010 | Reject contribution above wallet balance | design-derived | UI-NSV-10 | NovaSave domain | unit/widget | VERIFIED by design | TODO |
| NSV-011 | Show contribution confirmation | flow/design | UI-NSV-11 | NovaSave | widget | VERIFIED by design | TODO |
| NSV-012 | Create one stable operation identity/idempotency key for one logical contribution | ASM-011, ASM-013 | UI-NSV-11/16 | NovaSave + IDs + sync | unit/integration | INFERRED implementation required by duplicate-prevention requirement | TODO |
| NSV-013 | Online contribution enters Processing | flow/design | UI-NSV-12 | NovaSave | widget/integration | VERIFIED by design | TODO |
| NSV-014 | Successful contribution updates amount/progress | ASM-008 | UI-NSV-13, UI-NSV-14 | NovaSave | unit/widget/integration | VERIFIED | TODO |
| NSV-015 | Immediate online contribution failure leaves wallet unchanged and offers retry | flow/design | UI-NSV-15 | NovaSave | widget/integration | VERIFIED by design | TODO |
| NSV-016 | Offline confirmation explains contribution will be saved | ASM-009 | UI-NSV-16 | NovaSave | widget | VERIFIED by design | TODO |
| NSV-017 | Offline Contribution is durably persisted before UI reports it saved | ASM-009, ASM-012 | UI-NSV-17 | sync/persistence | repository + integration | VERIFIED | TODO |
| NSV-018 | Pending contribution remains visible while confirmed goal progress is unchanged | ASM-009 | UI-NSV-18 | NovaSave + sync projection | widget/integration | VERIFIED by design | TODO |
| NSV-019 | Pending contribution survives restart | ASM-012 | UI-NSV-17/18 + Flow 6 | sync/persistence | integration | VERIFIED | TODO |
| NSV-020 | Reconnect transitions pending contribution into processing | ASM-011 | UI-NSV-19 | sync | integration/widget | VERIFIED by design | TODO |
| NSV-021 | Reconnect success updates goal once | ASM-011, ASM-013 | UI-NSV-20 | sync/fake backend/NovaSave | integration | VERIFIED | TODO |
| NSV-022 | Sync failure retains contribution safely and offers retry | ASM-009, ASM-010 | UI-NSV-21 | sync/NovaSave | integration/widget | VERIFIED by design | TODO |
| NSV-023 | Manual retry reuses the same logical contribution/idempotency key | ASM-013 | UI-NSV-21 | sync/fake backend | unit/integration | INFERRED implementation required by duplicate-prevention requirement | TODO |

---

# 8. Synchronization and Offline Requirements

| ID | Requirement | Parent | Implementation | Verification | Evidence | Status |
|---|---|---|---|---|---|---|
| SYNC-001 | Observe online/offline connectivity | ASM-009, ASM-011 | `core/connectivity` | unit/widget | VERIFIED | TODO |
| SYNC-002 | Persist pending operation before acknowledging it as saved | ASM-009, ASM-012 | `sync/data`, Drift | repository/integration | VERIFIED | TODO |
| SYNC-003 | Restore pending operations after process restart | ASM-012 | `sync` + persistence | integration | VERIFIED | TODO |
| SYNC-004 | Synchronize eligible pending operations on reconnect | ASM-011 | `sync/application` | integration | VERIFIED | TODO |
| SYNC-005 | Synchronization uses a single shared coordinator, not feature-specific replay loops | ASM-010, ASM-013 | `sync/application` | architectural review/tests | INFERRED implementation | TODO |
| SYNC-006 | One logical operation has one stable operation ID | ASM-013 | `core/ids`, sync | unit | INFERRED implementation | TODO |
| SYNC-007 | One logical operation has one stable idempotency key reused across retry/restart | ASM-006, ASM-013 | `core/ids`, sync, fake backend | unit/integration | INFERRED implementation | TODO |
| SYNC-008 | Fake remote deduplicates repeated idempotency keys | ASM-006, ASM-013 | `fake_backend` | unit/integration | INFERRED implementation required to demonstrate guarantee | TODO |
| SYNC-009 | Repeated key with conflicting payload is rejected/flagged | ASM-013 | fake backend | unit | INFERRED defensive rule | TODO |
| SYNC-010 | Concurrent sync triggers cannot process the same local operation concurrently | ASM-013 | sync + database claim | unit/integration | INFERRED implementation | TODO |
| SYNC-011 | App interruption after remote success but before local completion does not produce a second financial effect | ASM-013 | sync + fake backend | integration/failure injection | INFERRED implementation test of verified requirement | TODO |
| SYNC-012 | Recoverable sync failure keeps operation durable and retryable | ASM-009, ASM-010 | sync | integration | VERIFIED by design | TODO |
| SYNC-013 | Retry is event-triggered/bounded; no uncontrolled background retry loop | ASM-010 | sync | unit/integration | VERIFIED | TODO |
| SYNC-014 | Connectivity status, sync status and operation status remain separate state dimensions | design + architecture | app/sync state | unit/review | INFERRED architecture | TODO |

---

# 9. Accessibility and Performance

| ID | Requirement | Parent | Implementation | Verification | Evidence | Status |
|---|---|---|---|---|---|---|
| A11Y-001 | Key interactive controls expose meaningful Semantics | ASM-015 | design system + feature presentation | widget/manual screen reader | VERIFIED | TODO |
| A11Y-002 | Text scales with system settings | ASM-016 | design system + layouts | widget/manual | VERIFIED | TODO |
| A11Y-003 | Enlarged text does not break critical journeys | ASM-016 | feature presentation | widget/manual at enlarged scale | VERIFIED | TODO |
| PERF-001 | Recent transaction list is lazy | ASM-017 | Wallet list | widget/code review | VERIFIED | TODO |
| PERF-002 | UI remains usable on low-end/patchy-connectivity scenario targeted by brief | assessment context | app architecture | manual/profile review | PARTIALLY VERIFIED | TODO |

No exact row-count benchmark is required by the assessment. Any 10,000-row test is optional engineering hardening, not an authoritative requirement.

---

# 10. Design-System Requirements

These are approved-design requirements, not separate assessor wording.

| ID | Requirement | Design evidence | Implementation | Verification | Evidence | Status |
|---|---|---|---|---|---|---|
| DSN-001 | Implement approved color scales | UI-DS-01 | `design_system/tokens` | visual | VERIFIED | TODO |
| DSN-002 | Use Plus Jakarta Sans with approved type scale | UI-DS-02 | design system/theme | visual + font-scale | VERIFIED | TODO |
| DSN-003 | Use approved icon set | UI-DS-03 | design system/icons | visual | VERIFIED | TODO |
| DSN-004 | Use approved spacing scale | UI-DS-04 | design system/tokens | visual | VERIFIED | TODO |
| DSN-005 | Use approved radii | UI-DS-04 | design system/tokens | visual | VERIFIED | TODO |
| DSN-006 | Use approved elevation/shadow | UI-DS-04 | design system/tokens | visual | VERIFIED | TODO |
| DSN-007 | Implement reusable button states | UI-CMP-01 | design system/components | widget/visual | VERIFIED | TODO |
| DSN-008 | Implement reusable text-field states | UI-CMP-02 | design system/components | widget/visual | VERIFIED | TODO |
| DSN-009 | Implement system notifications | UI-CMP-03 | design system/components | widget/visual | VERIFIED | TODO |
| DSN-010 | Implement status/result components | UI-CMP-04 | design system/components | widget/visual | VERIFIED | TODO |
| DSN-011 | Implement bottom navigation | UI-CMP-05 | app/design system | widget/visual | VERIFIED | TODO |
| DSN-012 | Implement reusable cards/list rows | UI-CMP-07 | design system/components | widget/visual | VERIFIED | TODO |
| DSN-013 | Implement progress treatment | UI-CMP-08 | design system/components | widget/visual | VERIFIED | TODO |
| DSN-014 | Implement sheets/empty-state patterns | UI-CMP-09 | design system/components | widget/visual | VERIFIED | TODO |

For exact token values, `docs/DESIGN_SYSTEM.md` and the authoritative Style Guide PDF control implementation.

---

# 11. Testing and Submission Requirements

| ID | Requirement | Parent | Artifact/area | Verification | Evidence | Status |
|---|---|---|---|---|---|---|
| TST-001 | Unit tests cover Money correctness | ASM-002, ASM-014 | `test/core/money` | `flutter test` | INFERRED test needed for hard constraint | TODO |
| TST-002 | Unit/repository tests cover pending-operation persistence/state transitions | ASM-009, ASM-012 | `test/sync` | `flutter test` | INFERRED test needed for hard constraint | TODO |
| TST-003 | Unit tests cover fake-remote idempotency | ASM-006, ASM-013 | `test/fake_backend` | `flutter test` | INFERRED test needed for hard constraint | TODO |
| TST-004 | Required Send Money widget tests exist | ASM-022 | send tests | `flutter test` | VERIFIED | TODO |
| TST-005 | Required NovaSave contribution widget tests exist | ASM-023 | NovaSave tests | `flutter test` | VERIFIED | TODO |
| TST-006 | Integration test covers offline queue → restart/reconnect → exactly one effect | ASM-024 plus ASM-012/013 | `integration_test` | integration run | VERIFIED + strengthened to catch duplicate regression | TODO |
| TST-007 | Failure/retry path is tested for lost/uncertain response behavior | ASM-013 | sync/fake backend | integration | INFERRED high-value regression test | TODO |
| DOC-001 | README is truthful about implemented state and required architecture/trade-offs/run/test info | ASM-021, ASM-026 | `README.md` | submission review | VERIFIED | TODO |
| DOC-002 | AI usage log is maintained from implementation start | ASM-019, ASM-020 | `AI_USAGE.md` | submission review | VERIFIED | TODO |
| DOC-003 | Flutter/Dart versions are pinned/recorded | ASM-026 | README/pubspec/toolchain | clean setup review | VERIFIED | TODO |
| DOC-004 | App runs with one standard Flutter command after setup | ASM-025 | repository | clean-run verification | VERIFIED | TODO |
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
