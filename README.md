# NovaWallet

**NovaWallet** is a Flutter mobile wallet assessment project focused on two everyday money journeys: sending money and saving toward a goal.

The app is designed for unreliable connectivity. If a user confirms a transfer or savings contribution while offline, the action is saved locally, shown as pending, survives an app restart, and is processed safely when connectivity returns.

Money is stored and calculated as **integer kobo** to avoid floating-point errors.

---

## Description

This repository contains the source code for the NovaWallet assessment app.

The main product areas are:

- **Wallet**
  - Available balance
  - Recent transactions
  - Pull-to-refresh
  - Transaction details
  - Offline, pending, reconnecting and sync-failure states

- **Send Money**
  - Recipient entry and validation
  - Amount entry and balance validation
  - Confirmation
  - Processing, success and failure
  - Offline queueing
  - Pending transfers
  - Reconnect and retry

- **NovaSave**
  - Savings goals
  - Goal creation
  - Target amount and date
  - Goal progress
  - Contributions
  - Offline contributions
  - Pending, reconnect and retry states

The assessment does not provide a real backend, so NovaWallet uses a fake remote implementation behind the same repository boundary the app would use for a real service.

---

## 🚀 Requirements

Make sure the following tools are installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- [Git](https://git-scm.com/)
- Android Studio / Android Emulator, or an iOS simulator

The exact Flutter and Dart versions used by the project are documented in the repository configuration.

---

## 📦 Getting Started

```bash
git clone <repository-url>
cd novawallet
flutter pub get
flutter run
```

Run the standard checks with:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

Run integration tests with:

```bash
flutter test integration_test
```

---

## Project Structure

```text
novawallet/
├── assets/
│   └── fonts/
│
├── lib/
│   ├── app/
│   ├── core/
│   │   ├── connectivity/
│   │   ├── errors/
│   │   ├── ids/
│   │   ├── money/
│   │   ├── persistence/
│   │   ├── time/
│   │   └── utils/
│   │
│   ├── design_system/
│   ├── fake_backend/
│   ├── sync/
│   │
│   ├── features/
│   │   ├── wallet/
│   │   ├── send_money/
│   │   └── novasave/
│   │
│   └── main.dart
│
├── test/
├── integration_test/
│
├── docs/
│   ├── design/
│   │   ├── pdf/
│   │   ├── references/
│   │   └── SCREEN_INDEX.md
│   │
│   ├── ARCHITECTURE.md
│   ├── IMPLEMENTATION_PLAN.md
│   ├── REQUIREMENTS_TRACEABILITY.md
│   ├── DESIGN_SYSTEM.md
│   ├── DEFINITION_OF_DONE.md
│   ├── GIT_WORKFLOW.md
│   ├── AGENT_WORKFLOW.md
│   ├── TASKS.md
│   └── HANDOVER.md
│
├── AGENTS.md
├── AI_USAGE.md
├── README.md
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Architecture

NovaWallet uses a feature-first layered structure:

```text
Presentation
    ↓
Application / State
    ↓
Domain
    ↓
Repositories
    ↓
Local persistence / Fake remote
```

A few rules guide the implementation:

- Business logic stays out of widgets.
- Money is represented as integer kobo.
- Send Money and NovaSave use the same sync engine.
- Offline actions are persisted before the UI reports them as safely saved.
- Retrying the same action reuses the same idempotency key.
- Connectivity state, sync state and transaction state are handled separately.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full architecture.

---

## Offline & Sync

The core offline flow is:

```text
Confirm action
    ↓
Save locally
    ↓
Pending
    ↓
Reconnect
    ↓
Process
    ↓
Completed / retained for retry
```

A queued action must:

- survive an app restart;
- not be lost;
- not be silently retried in an uncontrolled loop;
- not be processed twice.

The fake remote supports idempotency so repeated delivery of the same operation does not create a second debit or contribution.

---

## Design References

The supplied design PDFs are the visual source of truth and live under:

```text
docs/design/pdf/
```

The screen/state map is available in:

[`docs/design/SCREEN_INDEX.md`](docs/design/SCREEN_INDEX.md)

The shared design tokens and component rules are documented in:

[`docs/DESIGN_SYSTEM.md`](docs/DESIGN_SYSTEM.md)

Individual PNG references may be generated when a smaller image is useful for implementation or visual comparison.

---

## Testing

### Unit Tests

Coverage includes:

- Money arithmetic and formatting
- Validation
- Savings progress
- Operation state transitions
- Idempotency
- Retry and recovery logic

### Widget Tests

Required assessment coverage includes:

- Send Money
- NovaSave contribution

### Integration Tests

The critical integration flow covers:

```text
offline action
→ save locally
→ restart app
→ reconnect
→ sync
→ one financial effect
```

---

## Accessibility & Performance

The app is expected to:

- provide meaningful Flutter `Semantics`;
- support increased system font sizes;
- keep critical layouts usable when text scales;
- use lazy rendering for recent transactions;
- keep persistence and sync work outside widget build methods.

---

## Developer Guidelines

- Read [`AGENTS.md`](AGENTS.md) before making changes.
- Work from one task in [`docs/TASKS.md`](docs/TASKS.md) at a time.
- Keep one active coding agent per branch.
- Keep commits focused.
- Do not use floating-point values for money.
- Do not create a new idempotency key when retrying the same operation.
- Do not implement separate sync logic inside Send Money and NovaSave.
- Match UI work against the approved PDFs and [`SCREEN_INDEX.md`](docs/design/SCREEN_INDEX.md).

More details:

- [`docs/AGENT_WORKFLOW.md`](docs/AGENT_WORKFLOW.md)
- [`docs/GIT_WORKFLOW.md`](docs/GIT_WORKFLOW.md)
- [`docs/DEFINITION_OF_DONE.md`](docs/DEFINITION_OF_DONE.md)

---

## AI Usage

AI-assisted development is part of the assessment.

Usage is documented in [`AI_USAGE.md`](AI_USAGE.md), including:

- tools used;
- what each tool was used for;
- concrete prompts;
- useful outputs;
- mistakes or risky suggestions that were caught and corrected.

The project may use ChatGPT, Claude Code, Codex and Antigravity during implementation and review.
