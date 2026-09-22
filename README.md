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

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (verified with Flutter `3.47.5`, channel stable)
- [Dart SDK](https://dart.dev/get-dart) (verified with Dart `3.13.4`, SDK constraint `^3.13.4`)
- [Git](https://git-scm.com/)
- Android Studio / Android Emulator, or an iOS simulator

Targeted versions:
- Flutter: `3.47.5` (channel stable)
- Dart: `3.13.4`

---

## 📦 Getting Started

```bash
git clone https://github.com/calebjesusegun/novawalletmobile.git
cd novawalletmobile
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

### Continuous Integration

Pull requests and pushes to `main` are automatically verified via GitHub Actions (`.github/workflows/ci.yml`) running the exact same baseline checks:
- Formatting: `dart format --output=none --set-exit-if-changed .`
- Static analysis: `flutter analyze`
- Unit and widget tests: `flutter test`

---

## Project Structure

```text
novawalletmobile/
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

## Architecture & State Management

NovaWallet follows a clean, feature-first layered architecture driven by domain boundaries:

```text
Presentation (Widgets, Screens, Theme)
    ↓
Application / State (Riverpod Notifiers & Providers)
    ↓
Domain (Entities, Value Objects, Policies, Use Cases)
    ↓
Repositories (Abstract interfaces coordinating local & remote)
    ↓
Data Sources
    ├── Local Persistence (Drift SQLite Tables & DAOs)
    └── Fake Remote Service (Idempotent Ledger & Failure Simulation)
```

### Core Architecture Rules

- **Zero Business Logic in Widgets:** Presentation components strictly render immutable UI state and dispatch user intentions.
- **Integer Kobo Money Representation (`HC-MONEY`):** All financial computations, balances, and thresholds are modeled in integer kobo using the immutable `Money` value object. Double/floating-point types are strictly forbidden in domain and storage layers.
- **Centralized Synchronization (`HC-SYNC`):** Send Money and NovaSave share a unified synchronization pipeline (`SyncCoordinator`). Feature modules never implement ad-hoc replay loops.
- **Three-Dimensional State Separation (`HC-STATE-SEPARATION`):**
  - `ConnectivityStatus`: `online` | `offline` (physical network state)
  - `SyncStatus`: `idle` | `syncing` | `failed` (coordinating pipeline status)
  - `OperationStatus`: `pending` | `processing` | `completed` | `failed` (financial operation lifecycle)

---

## Technical Trade-offs & Decisions

| Area | Chosen Solution | Alternative Considered | Key Rationale / Trade-off |
|---|---|---|---|
| **State Management** | **Flutter Riverpod** | BLoC / Provider / GetX | Riverpod provides compile-safe dependency injection, declarative provider scoping, and frictionless dependency overriding in tests (`container.overrideWithValue`) without requiring mock objects or widget tree context. |
| **Local Persistence** | **Drift (SQLite)** | SharedPreferences / Hive / Isar | SharedPreferences cannot offer ACID transactional safety, and pure key-value stores risk corruption during sudden process termination. Drift provides typed, ACID-compliant SQL persistence, robust schema migration, and observable reactive queries. |
| **Sync Strategy** | **Centralized Mutex Coordinator** | Independent feature replay loops | Independent retry loops cause duplicate delivery, race conditions, and uncontrolled battery/network drain. A single `SyncCoordinator` serializes pending operations, guarantees at-most-once delivery per trigger, and coalesces concurrent triggers. |
| **Money Representation** | **Integer Kobo (`Money` value object)** | IEEE 754 `double` / `num` | Floating-point arithmetic introduces cumulative precision errors (e.g., `0.1 + 0.2 != 0.3`). Integer kobo guarantees exact mathematical correctness for all balances, transfers, and goal progress. |
| **Remote Integration** | **In-Engine Fake Remote Ledger** | Dio / Mockito HTTP Stubs | Assessment explicitly specifies no production backend. A deterministic fake remote with an in-memory/drift ledger allows rigorous testing of idempotency deduplication, response-loss scenarios, and server 500 retries without flaky network dependencies. |

---

## Offline & Centralized Synchronization Engine

The synchronization subsystem is architected to guarantee that user intent survives offline disconnection, process termination, and uncertain network responses without causing duplicate financial debits:

```text
User Confirms Action (Offline)
    ↓
Durable Local Enqueue (SQLite Transaction)
    ↓
UI Displays "Pending" (Headline Balance Unchanged)
    ↓
[App Kill / Reboot / Offline Storage Survival]
    ↓
Device Reconnects / User Taps Retry
    ↓
SyncCoordinator Mutex Claims Operation
    ↓
Remote Execution with Stable Idempotency Key
    ↓
Settlement: Remote Deduplication + Local Database Commit
```

### Key Durability Guarantees

1. **Durable Intent (`HC-OFFLINE-DURABILITY`):** When confirmed offline, transfers and contributions are committed to SQLite before informing the user. Operations survive sudden process kills and OS reboots.
2. **Stable Idempotency Key (`HC-IDEMPOTENCY`):** A unique `IdempotencyKey` is generated once at user confirmation and permanently stored with the operation record. Subsequent retries, reconnects, or app restarts reuse the exact same key.
3. **Exactly-Once Financial Settlement (`HC-EXACTLY-ONCE-EFFECT`):** The remote backend ledger maintains an idempotency table. If a request was processed remotely but the network dropped before the client received the response (`SYNC-010`, `TST-007`), replaying with the same key returns the cached successful result (`isDuplicate: true`) without deducting funds a second time.
4. **Spendable Balance Reservation (`MNY-004`):** Unconfirmed pending debits hold a spendable balance reservation preventing double-spending while keeping the authoritative headline balance intact until confirmation.


## Design References

The visual design is defined in Figma:
- [NovaWallet Figma Design](https://www.figma.com/design/GzSZpqJTOnlGn2yDec8qtm/NovaWallet-Design?node-id=4-5&p=f&t=cV6FJkAzaLck0PB7-0)

The supplied design PDFs are also available as visual references and live under:

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

---

Let's build **NovaWallet** together 🌍

