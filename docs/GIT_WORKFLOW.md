# NovaWallet Git Workflow

**Status:** Final pre-implementation baseline  
**Purpose:** Define how NovaWallet changes move from task selection to branch, implementation, review, merge, and handover without losing traceability or allowing multiple agents to create conflicting repository state.

---

## 1. Core Rules

1. `main` must remain stable and releasable.
2. One implementation task maps to one focused branch.
3. Only one coding agent may actively modify a branch at a time.
4. Git history and the working tree are authoritative for implementation state.
5. Do not mix unrelated refactors with feature work.
6. Do not change shared/high-conflict files as a side effect of unrelated work.
7. Every substantive change must map back to a task and requirement.
8. High-risk changes involving money, persistence, sync, idempotency, migrations, or security require the review level defined in `docs/AGENT_WORKFLOW.md`.

---

## 2. Branch Naming

Use short, descriptive branches:

```text
feature/<scope>
fix/<scope>
test/<scope>
docs/<scope>
chore/<scope>
refactor/<scope>
```

Examples:

```text
chore/project-baseline
feature/money-value-object
feature/operation-persistence
feature/sync-engine
feature/wallet-home
feature/send-money
feature/novasave-goal
feature/novasave-contribution
fix/sync-idempotency
test/offline-restart-sync
docs/requirements-traceability
```

If tasks in `docs/TASKS.md` have IDs, include the ID when useful:

```text
feature/T-MNY-001-money
feature/T-SYNC-003-restart-recovery
```

Avoid personal names or tool names in branch names.

---

## 3. Starting a Task

Before making changes:

```bash
git status
git branch --show-current
git log -5 --oneline
```

Then:

1. Confirm the task in `docs/TASKS.md`.
2. Confirm dependencies are already merged.
3. Read:
   - `AGENTS.md`
   - the task entry
   - relevant architecture/requirements/design references
   - `docs/HANDOVER.md` once implementation has begun
4. Create the branch from current `main`.

Example:

```bash
git switch main
git pull --ff-only
git switch -c feature/T-MNY-001-money
```

Do not begin from an unrelated feature branch.

---

## 4. Worktrees for Parallel Agents

If more than one agent works at the same time, use separate worktrees.

Example:

```bash
git worktree add ../novawallet_sync feature/T-SYNC-001-queue
git worktree add ../novawallet_wallet feature/T-WAL-001-home
```

Rules:

- one worktree per active branch;
- one active coding agent per branch;
- do not point two tools at the same worktree;
- avoid parallel work that edits the same shared files;
- domain/data dependencies merge before UI branches that depend on them.

At most two implementation branches should normally be active in parallel during this assessment unless there is a clear reason otherwise.

---

## 5. Shared / High-Conflict Files

Treat these as controlled files:

```text
pubspec.yaml
pubspec.lock
analysis_options.yaml
lib/app/router.dart
lib/app/providers.dart
docs/TASKS.md
docs/HANDOVER.md
docs/REQUIREMENTS_TRACEABILITY.md
AI_USAGE.md
```

Do not modify them casually as a side effect of feature work.

If a task requires a shared-file change:

- make it explicit in the task;
- keep the change minimal;
- merge it quickly before dependent branches proceed.

---

## 6. Commit Style

Use focused conventional-style commits:

```text
chore(app): bootstrap flutter project
feat(money): add integer-kobo value object
feat(sync): persist pending operations
feat(sync): add duplicate-safe operation claim
feat(send-money): implement recipient validation
feat(novasave): add contribution confirmation
test(sync): cover restart then reconnect replay
fix(sync): reuse idempotency key on retry
docs(traceability): map assessment accessibility requirements
```

Prefer one coherent concern per commit.

Avoid:

```text
update stuff
fix things
changes
final
misc
```

---

## 7. WIP Commits

WIP commits are allowed on feature branches when handing work between tools or stopping unexpectedly.

Format:

```text
wip(sync): restart recovery test still failing

Task: T-SYNC-003
```

Rules:

- WIP commits must never land on `main`;
- before merge, squash/rewrite as appropriate;
- `docs/HANDOVER.md` must explain unfinished state.

---

## 8. Verification Before Commit

Run the narrowest relevant verification first.

Examples:

```bash
flutter test test/core/money/
flutter test test/sync/
flutter test test/features/send_money/
flutter analyze
```

Before the PR is considered ready, run:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

When integration tests are configured and relevant:

```bash
flutter test integration_test
```

Do not claim a check passed unless it was actually run.

---

## 9. Feature Workflow

Every task follows:

```text
Task
  ↓
Requirement(s)
  ↓
Design state(s), if UI
  ↓
Branch
  ↓
Implementation + tests
  ↓
Targeted verification
  ↓
Commit(s)
  ↓
Independent review
  ↓
Fix findings
  ↓
Full verification
  ↓
Traceability / AI usage / docs updates
  ↓
Merge
  ↓
Handover update
```

---

## 10. Pull Request Scope

Keep PRs small enough to review meaningfully.

Guideline:

- one task or one tightly related task group;
- avoid unrelated cleanup;
- avoid broad formatting churn;
- explain architectural changes explicitly.

For high-risk money/sync/persistence changes, smaller PRs are preferred even if that means splitting one phase across several branches.

---

## 11. PR Description

Each substantive PR should answer:

### What changed?

Short summary.

### Task / requirements

```text
Task:
Requirements:
Design references:
```

### Why?

What requirement or architectural need does this satisfy?

### Tests

List the exact commands run.

### Visual verification

For UI work:

- reference screen IDs from `docs/design/SCREEN_INDEX.md`;
- emulator/device state used;
- any known visual discrepancy.

### Risks / unresolved items

List any remaining `TO VERIFY`, limitation, or follow-up.

### AI usage

If the work produced a meaningful AI-use example or a caught AI mistake, note that `AI_USAGE.md` was updated.

---

## 12. Review Protocol

The author should not be the only reviewer of substantive work.

Use a different agent/model family where practical.

Review order for ordinary work:

1. task acceptance criteria;
2. requirement compliance;
3. architectural boundaries;
4. tests;
5. design fidelity where applicable;
6. code clarity/style.

Review order for high-risk work:

1. money correctness;
2. idempotency / duplicate safety;
3. durable persistence;
4. restart recovery;
5. concurrent sync triggers;
6. failure classification;
7. tests that would catch regressions;
8. architecture/style.

Reviewer output should be a numbered findings list with file and line references where possible. Reviewers should not silently rewrite the code unless explicitly asked.

---

## 13. Updating From `main`

Before opening a PR:

```bash
git fetch origin
git rebase origin/main
```

Resolve conflicts on the feature branch.

After the rebase:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Run relevant integration tests if the rebased changes touch critical flows.

Do not resolve conflicts directly on `main`.

---

## 14. Merge Strategy

Preferred merge strategy:

```text
Squash and merge
```

Reason:

- keeps `main` history task-oriented;
- allows WIP commits on feature branches;
- makes review and rollback easier.

Use the final squash commit message in conventional format, for example:

```text
feat(sync): implement restart-safe pending operation replay
```

Do not merge a branch with failing required checks.

---

## 15. After Merge

After a successful merge:

1. Update local `main`.
2. Confirm the merge is present.
3. Delete the merged branch/worktree when safe.
4. Update:
   - `docs/TASKS.md`
   - `docs/REQUIREMENTS_TRACEABILITY.md` if status changed
   - `AI_USAGE.md` if applicable
   - `docs/HANDOVER.md`
5. Select the next ready task.

Example:

```bash
git switch main
git pull --ff-only
git branch -d feature/T-MNY-001-money
```

For worktrees:

```bash
git worktree remove ../novawallet_money
```

---

## 16. Documentation Changes

Documentation follows the same branch/review discipline as code when substantive.

Use:

```text
docs/<scope>
```

Small documentation corrections required by a feature may remain in the same feature branch if they are directly related.

Do not let documentation describe behavior that is not implemented.

In particular:

- `README.md` describes current reality;
- `docs/ARCHITECTURE.md` describes approved architecture;
- `docs/IMPLEMENTATION_PLAN.md` describes sequencing;
- `docs/TASKS.md` describes executable work;
- `docs/HANDOVER.md` describes current implementation state.

---

## 17. Design Assets

Approved design PDFs may be stored under:

```text
docs/design/pdf/
```

Use the clean repository filenames defined in `docs/design/SCREEN_INDEX.md`.

Do not commit confidential assessment documents that are marked for restricted/internal distribution unless explicitly permitted.

Generated visual-comparison artifacts and temporary emulator screenshots should normally remain uncommitted unless they are intentionally needed for documentation or golden testing.

---

## 18. AI-Agent Discipline

When Claude Code, Codex, Antigravity, or another coding agent works on the repository:

- it must work on the assigned branch only;
- it must read `AGENTS.md` first;
- it must follow the task contract in `docs/TASKS.md`;
- it must not broaden scope without approval;
- it must report commands actually run;
- it must leave the branch in a reviewable state;
- when handing off, it must update `docs/HANDOVER.md` according to `docs/AGENT_WORKFLOW.md`.

Never let two agents simultaneously edit the same branch.

---

## 19. Before Final Submission

Run a final repository check:

```bash
git status
git log --oneline --decorate -20
```

Then verify:

- [ ] `main` contains all mandatory implementation work.
- [ ] No required work exists only on an unmerged branch.
- [ ] No WIP commit/state is required to run the application.
- [ ] No secrets or sensitive internal assessment material are committed.
- [ ] README matches actual implementation.
- [ ] AI_USAGE is current.
- [ ] Requirements traceability is current.
- [ ] Handover reflects final repository state.
- [ ] Format/analyzer/tests/integration checks pass.
- [ ] Repository access/submission instructions are satisfied.

---

## 20. Guiding Principle

Git should make it possible to answer, at any point:

```text
What requirement are we implementing?
What changed?
Who/what reviewed it?
What tests prove it?
What remains unresolved?
What should the next agent do?
```

If the repository history cannot answer those questions, the workflow is not doing its job.
