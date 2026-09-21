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
