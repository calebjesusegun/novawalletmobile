# NovaWallet Agent Workflow

This document defines how AI coding agents work on the NovaWallet repository.

`AGENTS.md` contains the permanent engineering rules and hard constraints. This file defines the operating workflow: how work is selected, how branches and sessions are handled, how changes are reviewed, and how one tool hands work to another.

The workflow is intentionally tool-agnostic. Claude Code, Codex, Antigravity, or another coding agent may act as author, reviewer, or visual verifier. The repository and Git history remain the source of implementation truth.

---

## 1. Core Working Principles

1. **One executable task at a time.** Work starts from a task in `docs/TASKS.md`, not from a broad prompt such as "build NovaWallet".
2. **One task, one branch, one active implementation agent.** Do not let two agents edit the same branch or working directory concurrently.
3. **Git is implementation truth.** If `HANDOVER.md`, chat history, or an agent summary disagrees with the branch, inspect Git and the code first.
4. **The repository carries project memory.** Decisions that another agent needs must live in committed project documentation, code, tests, or Git history.
5. **Spend the most scrutiny where mistakes are expensive.** Money, persistence, idempotency, synchronization, migrations, and security receive the highest review level.
6. **Prefer small coherent changes.** Avoid broad refactors, speculative abstractions, and unrelated cleanup inside feature tasks.
7. **Tests must prove the important guarantee.** A passing happy path is not enough for money or offline behavior.
8. **Documentation follows reality.** Do not update README or traceability to claim behavior before the code and tests support it.

---

## 2. Engineering Risk Levels

Every executable task in `docs/TASKS.md` should carry a risk level. Risk determines the amount of planning, test rigor, and review required. It does **not** permanently assign a particular vendor or model to the task.

| Risk | Meaning | Typical work | Required review |
|---|---|---|---|
| **A** | Failure can create incorrect money movement, data loss, duplicate processing, or unsafe persistence | `Money`, operation identity, queue schema, sync engine, fake-server idempotency, migrations, security-sensitive storage | Independent review; second high-scrutiny review for critical data-integrity changes |
| **B** | Normal product behavior with bounded impact | screens, controllers/notifiers, repositories, validation, widget tests, integration wiring | Independent review |
| **C** | Mechanical or low-risk change | docs, token transcription, renames, formatting, generated boilerplate | Normal review as needed |

Rules:

- If a task turns out materially riskier than its assigned level, stop and report the reason instead of silently expanding scope.
- A Risk A task should have its invariants and test cases clear before implementation proceeds.
- Generated files inherit the risk of the behavior they support but do not require line-by-line human review if they are reproducible from committed source.

---

## 3. Before Implementation Begins

The first implementation session begins only after the planning set is finalized:

```text
AGENTS.md
docs/ARCHITECTURE.md
docs/IMPLEMENTATION_PLAN.md
docs/REQUIREMENTS_TRACEABILITY.md
docs/DESIGN_SYSTEM.md
docs/DEFINITION_OF_DONE.md
docs/GIT_WORKFLOW.md
docs/AGENT_WORKFLOW.md
docs/TASKS.md
AI_USAGE.md
HANDOVER.md
```

`HANDOVER.md` is created at this point for the first time. It should state that planning is complete, implementation has not yet started, and identify the first task.

Before this point, the absence of `HANDOVER.md` is intentional.

---

## 4. Task Contract

Each task in `docs/TASKS.md` should be executable without requiring a repository-wide survey.

A task should contain:

- task ID;
- title;
- risk level;
- approximate size (`S`, `M`, or `L`);
- authoritative requirement IDs;
- dependencies/prerequisites;
- files or areas to read first;
- expected files/areas to touch;
- explicit areas not to change where useful;
- acceptance criteria;
- targeted verification command(s);
- expected documentation/traceability updates.

Suggested size guidance:

- **S** — focused change, usually a few hours;
- **M** — substantial but coherent task, roughly a working day;
- **L** — large task that should be reconsidered for splitting before implementation.

A task that spans unrelated concerns or requires broad changes across multiple architectural layers should usually be split.

Example:

```markdown
## T-MNY-001 — Money value object

Risk: A
Size: S

Requirements:
- ASM-MONEY-001
- ASM-MONEY-002

Read first:
- AGENTS.md — HC-MONEY
- docs/ARCHITECTURE.md — Money
- docs/REQUIREMENTS_TRACEABILITY.md — ASM-MONEY-001/002

Touch:
- lib/core/money/
- test/core/money/

Do not touch:
- routing
- persistence schema
- feature UI

Acceptance:
- Given `12545000` kobo, when formatted, then the UI value is `₦125,450.00`.
- Given monetary addition/subtraction, when calculated, then no floating-point representation is used.

Verify:
- `flutter test test/core/money/`
```

---

## 5. Starting a Task

Before editing code, the authoring agent must:

1. Confirm the requested task ID.
2. Confirm the correct branch/working tree with `git status` and `git branch --show-current`.
3. Read `AGENTS.md`.
4. Read the task entry in `docs/TASKS.md`.
5. Read only the relevant sections of architecture, requirements, design documentation, and `HANDOVER.md`.
6. Inspect existing code/tests in the task's scope.
7. Run the task's targeted verification command once to establish the baseline.
8. Report any conflict between the task and a higher-priority source before changing code.

Do not begin by performing an unrestricted repository audit unless the task explicitly requires one.

### Standard task-start prompt

```text
Read AGENTS.md first. Then read the task <TASK_ID> in docs/TASKS.md, the relevant sections it references,
and HANDOVER.md. Confirm the current branch and git status. Run the task's baseline verification command
before editing. Work only on <TASK_ID>. If the task conflicts with a higher-priority requirement or hard
constraint, stop and report the conflict instead of guessing.
```

---

## 6. Implementation Loop

During implementation:

1. Make the smallest coherent change that advances the task.
2. For Risk A behavior, create or update regression tests with the implementation; prefer tests first when the invariant is clear.
3. Run the narrowest relevant tests after meaningful changes.
4. Use scoped analysis where practical.
5. Keep unrelated refactors out of the diff.
6. Do not add dependencies, migrations, routing changes, or shared-file edits as side effects. If required, make them explicit in the task or stop for approval.
7. Keep user-visible copy aligned with the approved design/source material.
8. Update `AI_USAGE.md` when there is meaningful AI usage worth preserving, especially wrong/risky output that influenced the implementation.

For money, operations, and synchronization, the implementation loop must continually check the applicable hard constraints in `AGENTS.md`, especially:

- `HC-MONEY`;
- `HC-OFFLINE-DURABILITY`;
- `HC-IDEMPOTENCY`;
- `HC-EXACTLY-ONCE-EFFECT`;
- `HC-SYNC`;
- `HC-RETRY`;
- `HC-STATE-SEPARATION`.

---

## 7. Verification Commands

Use repository commands that actually exist. Do not invent wrappers in documentation.

Baseline Flutter commands:

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

During iteration, prefer targeted tests, for example:

```bash
flutter test test/core/money/
flutter test test/sync/
flutter test test/features/send_money/
```

Rules:

- Run targeted tests frequently.
- Run the full required verification suite before a PR is considered ready.
- Run integration tests when the task affects the critical offline/sync path or when the task explicitly requires them.
- If CI is configured, local verification does not remove the requirement for CI to pass.
- Do not hide or truncate a failing result in the handover; summarize the actual failure and retain the useful command/output reference.

---

## 8. Checkpoints and Session Boundaries

A **task** maps to one branch. A task does not have to map to exactly one chat/session if the context remains reliable.

Create a checkpoint when:

- stopping work before the task is complete;
- handing work to a different coding tool;
- reaching a coherent intermediate state that another agent could continue safely;
- a significant failing test or unresolved decision must be preserved.

At a checkpoint:

1. run the narrow verification relevant to the current state;
2. commit coherent work when safe to do so;
3. push the branch if remote workflow is available;
4. update `HANDOVER.md` with the exact state;
5. identify the next concrete action.

Do **not** store token counts, model usage limits, or other transient product telemetry in repository handovers.

Start a fresh agent session when:

- the task changes;
- a different agent takes over;
- context has become noisy or unreliable;
- a review begins.

---

## 9. Handover Rules

`HANDOVER.md` contains temporary operational state. It is not an architectural authority.

A handover should contain only information needed to continue safely:

- current task ID and title;
- branch name;
- last relevant commit;
- work completed;
- files changed;
- tests/checks run and their result;
- known failing tests or blockers;
- unresolved `TO VERIFY` items relevant to the task;
- decisions made during the task that are not yet captured elsewhere;
- exact next steps;
- explicit "do not do" warnings if needed.

If the handover disagrees with Git or the code, trust Git/code and investigate the discrepancy.

### Receiving prompt

```text
Read AGENTS.md, then HANDOVER.md, then the referenced task in docs/TASKS.md. Confirm the branch and git status.
Inspect git log/diff for the current task and run the task's verification command before changing anything.
If HANDOVER.md conflicts with Git or a higher-priority requirement, trust Git/requirements and report the conflict.
Continue only from the documented next step.
```

### Incomplete work commits

Use a normal focused commit whenever possible. If a tool must stop with intentionally incomplete but useful work, a clearly labeled WIP commit is acceptable:

```text
wip(sync): persist claim logic; restart test still failing

Task: T-SYNC-003
```

Do not merge WIP commits directly to `main`; clean/fix them before merge or squash them during the approved merge workflow.

---

## 10. Review Protocol

Implementation and review are separate roles. Prefer a different agent/tool for independent review when practical.

### Review order

Review in this order:

1. authoritative requirement and task acceptance criteria;
2. applicable `AGENTS.md` hard constraints;
3. money/data-integrity/offline/sync correctness;
4. architecture boundaries;
5. tests and regression strength;
6. accessibility/performance where relevant;
7. design fidelity and user-visible copy;
8. maintainability/style.

### Review scope

Start from:

```bash
git diff main...HEAD
```

The reviewer may inspect surrounding or referenced code when a finding depends on it. "Diff only" must not prevent validating a real invariant.

### Findings format

Report findings as a numbered list. Each finding should include:

- severity (`blocking`, `high`, `medium`, `low`);
- file and line/range when available;
- violated requirement/hard constraint where applicable;
- why it matters;
- expected correction.

Do not rewrite the implementation during review unless explicitly asked to switch from reviewer to author.

### Risk A review

Risk A changes require independent review. Changes involving idempotency, queue claiming, persistence migrations, lost-response recovery, or financial arithmetic should receive an additional high-scrutiny pass before merge.

### Standard review prompt

```text
Review this branch against its task acceptance criteria and AGENTS.md. Start with the authoritative requirement,
then check applicable hard constraints, especially money, offline durability, idempotency, exactly-once effect,
sync/retry behavior, and state separation. Review git diff main...HEAD and inspect surrounding code only when needed
to validate a finding. Report a numbered list with severity, file/line, violated rule or requirement, impact, and
expected correction. Do not rewrite code. If the diff contains a real example of risky or incorrect AI-generated
output that was caught, draft an AI_USAGE.md entry for the author to verify.
```

---

## 11. Fix and Merge Loop

After review:

1. the author evaluates each finding;
2. valid findings are fixed in new commits;
3. disputed findings are resolved against source-of-truth documents, tests, and code evidence;
4. targeted verification is rerun;
5. the full required suite is run once the branch is ready;
6. traceability/status documentation is updated to match reality;
7. README is updated only if the implemented repository behavior changed what it truthfully claims;
8. `AI_USAGE.md` is updated with verified, real AI evidence where applicable;
9. the branch is merged according to `docs/GIT_WORKFLOW.md`.

Prefer squash merge when it keeps the project history clear, unless the repository workflow later specifies otherwise.

---

## 12. Coordinating Multiple Agents

Parallel work is allowed only when tasks are genuinely independent.

Rules:

- one branch/worktree per active implementation agent;
- never two active agents editing the same branch;
- avoid parallel tasks that both modify shared files such as `pubspec.yaml`, routing, persistence schema, generated localization files, or `docs/TASKS.md`;
- foundational domain/data changes should merge before dependent UI work;
- rebase/update from `main` before final review when required by the Git workflow;
- resolve conflicts on the feature branch, not on `main`;
- default to one active implementation task when uncertainty is high.

Git worktrees are optional but recommended for true parallel work, for example:

```bash
git worktree add ../novawallet-sync feat/sync-engine
```

### Suggested temporary roles

Roles are assigned per task, not permanently per tool:

- **Author** — implements the task and tests;
- **Reviewer** — independently checks requirements, hard constraints, code, and tests;
- **Visual verifier** — compares implemented UI/states against the approved design on an emulator/device.

A tool may take a different role on the next task.

---

## 13. Shared Files

Treat the following as high-contention files:

- `pubspec.yaml` / `pubspec.lock`;
- router/navigation configuration;
- Drift schema/migrations;
- localization source files;
- `docs/TASKS.md`;
- `AGENTS.md`;
- CI configuration.

Do not change a shared file as an incidental side effect. If a task requires the change, make it explicit and keep the diff focused.

Generated files may be committed where the project deliberately chooses that strategy, but the generating source and reproducible command must remain clear.

---

## 14. Visual Verification Workflow

For tasks that implement or alter UI:

1. identify the exact approved design state(s) referenced by the task;
2. implement from centralized design tokens/components;
3. run the screen on an emulator/device;
4. compare layout, typography, spacing, colors, icons, copy, and state presentation against the approved design;
5. also test at larger system font scale so visual fidelity does not hide accessibility failures;
6. record material mismatches before considering the task complete.

Do not change product behavior solely to make a static screenshot easier to match.

---

## 15. AI Usage Logging

`AI_USAGE.md` is a living assessment artifact, not a retrospective essay.

Record entries when they provide useful evidence, including:

- a substantial prompt that shaped architecture or implementation;
- a coding-agent prompt that produced meaningful work;
- a review prompt that caught a real defect;
- AI output that was wrong or risky and required correction.

For a risky-output entry, capture:

1. tool used;
2. relevant prompt;
3. what the AI proposed/generated;
4. why it was unsafe or incorrect;
5. how it was detected;
6. what was changed;
7. test or guard added, when applicable;
8. related commit/PR.

Do not manufacture an error example to satisfy the assessment.

---

## 16. Task Completion

A task is complete only when its own acceptance criteria and applicable Definition of Done items are satisfied.

Before marking a task done:

- targeted tests pass;
- required full verification for the task/PR passes;
- relevant accessibility/performance checks pass;
- approved design states are verified when UI changed;
- traceability status is updated;
- `AI_USAGE.md` is updated if warranted;
- documentation reflects implemented reality;
- `HANDOVER.md` points to the next task or states that the phase is ready for review.

Do not mark a task complete while an applicable high-risk defect or unresolved blocking `TO VERIFY` item remains.

---

## 17. Anti-Patterns

Avoid:

- asking an agent to "understand the whole codebase" before every small task;
- one branch containing several unrelated tasks;
- two agents editing one branch/worktree concurrently;
- inventing Makefiles or wrapper commands in documentation before they exist;
- running the full test suite after every tiny edit;
- skipping the full suite before merge;
- adding dependencies because they are fashionable or familiar;
- letting UI code own persistence, synchronization, or idempotency behavior;
- retry loops that hide repeated financial attempts from the user;
- generating a new idempotency key on retry;
- trusting `HANDOVER.md` over Git/code;
- updating README with planned behavior in present tense;
- implementing optional stretch goals before mandatory requirements are stable;
- using a long-running chat as the only record of an important engineering decision.

---

## 18. Default End-to-End Work Cycle

```text
Select task from docs/TASKS.md
        ↓
Create/open task branch
        ↓
Read AGENTS + task + relevant evidence + HANDOVER
        ↓
Run baseline verification
        ↓
Implement smallest coherent change + tests
        ↓
Run targeted verification
        ↓
Commit/checkpoint
        ↓
Independent review
        ↓
Fix findings
        ↓
Run full required verification
        ↓
Visual verification if UI changed
        ↓
Update traceability / AI_USAGE / truthful docs
        ↓
Merge according to Git workflow
        ↓
Update HANDOVER.md
        ↓
Start next task in fresh task context
```

This loop is the default unless a higher-priority requirement or explicit task instruction says otherwise.
