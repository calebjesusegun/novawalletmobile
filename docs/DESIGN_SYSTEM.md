# NovaWallet Design System

**Status:** Finalized pre-implementation specification  
**Authoritative sources:**

- `docs/design/pdf/NovaWallet Style Guide.pdf`
- `docs/design/pdf/NovaWallet Design Components.pdf`
- `docs/design/SCREEN_INDEX.md` for feature-screen/state references

**Last reviewed:** 2026-09-20

## 1. Purpose

This document translates the approved NovaWallet style-guide and component exports into implementation rules for the Flutter application.

It is an implementation specification, not a replacement for the source designs. If this document conflicts with an approved PDF or screen-flow export, the approved source wins and this document must be corrected.

Feature code must consume centralized tokens and shared components. Do not introduce feature-local styling values when an approved token or shared component already exists.

## 2. Source-of-truth rule

For visual implementation, use this order:

1. Approved feature/flow design export for the exact screen/state.
2. `NovaWallet Design Components.pdf` for reusable component appearance/states.
3. `NovaWallet Style Guide.pdf` for design tokens.
4. This document.
5. General Flutter defaults only where the supplied designs do not define the decision.

Use `docs/design/SCREEN_INDEX.md` to locate the correct feature or state reference.

If a value or behaviour is not supported by the supplied source material, do not silently invent a design rule. Record it as `TO VERIFY` or document the implementation decision separately.

---

# 3. Colour Tokens

The values below are transcribed from the approved style guide.

## 3.1 Primary blue

| Token | Hex |
|---|---|
| `blue-50` | `#E6EEF8` |
| `blue-100` | `#C2D3EA` |
| `blue-200` | `#94B0D6` |
| `blue-300` | `#5C84BC` |
| `blue-400` | `#2A5C9E` |
| `blue-500` | `#003A78` |
| `blue-600` | `#00326A` |
| `blue-700` | `#00264F` |
| `blue-800` | `#001C3B` |
| `blue-900` | `#001328` |

## 3.2 Secondary gold

| Token | Hex |
|---|---|
| `gold-50` | `#FFF3CF` |
| `gold-100` | `#FFE69B` |
| `gold-200` | `#FFDA6E` |
| `gold-300` | `#FECB3E` |
| `gold-400` | `#FDC022` |
| `gold-500` | `#FDB913` |
| `gold-600` | `#E0A00B` |
| `gold-700` | `#A67300` |
| `gold-800` | `#7A5600` |
| `gold-900` | `#523A00` |

## 3.3 Grey

| Token | Hex |
|---|---|
| `grey-50` | `#F4F6F9` |
| `grey-100` | `#E5E9EF` |
| `grey-200` | `#C9D1DC` |
| `grey-300` | `#A3AEBD` |
| `grey-400` | `#7B8799` |
| `grey-500` | `#566275` |
| `grey-600` | `#444F61` |
| `grey-700` | `#303A4A` |
| `grey-800` | `#1C2739` |
| `grey-900` | `#0E1A2B` |
| `white` | `#FFFFFF` |

## 3.4 Success green

| Token | Hex |
|---|---|
| `green-50` | `#E1F3E9` |
| `green-100` | `#B9E2CB` |
| `green-200` | `#8CCFAA` |
| `green-300` | `#5DB98A` |
| `green-400` | `#35A06C` |
| `green-500` | `#17784A` |
| `green-600` | `#136A41` |
| `green-700` | `#0F5A37` |
| `green-800` | `#0B472B` |
| `green-900` | `#073320` |

## 3.5 Warning amber

| Token | Hex |
|---|---|
| `amber-50` | `#FFF0D2` |
| `amber-100` | `#FBDA9C` |
| `amber-200` | `#F7BC57` |
| `amber-300` | `#E89B1F` |
| `amber-400` | `#C77A0A` |
| `amber-500` | `#9A5B00` |
| `amber-600` | `#874F00` |
| `amber-700` | `#6E4000` |
| `amber-800` | `#553200` |
| `amber-900` | `#3D2400` |

## 3.6 Error red

| Token | Hex |
|---|---|
| `red-50` | `#FDE8E6` |
| `red-100` | `#F9C4BF` |
| `red-200` | `#F39B93` |
| `red-300` | `#E86A5F` |
| `red-400` | `#D7473B` |
| `red-500` | `#C22F26` |
| `red-600` | `#A9271F` |
| `red-700` | `#8A1F19` |
| `red-800` | `#6B1813` |
| `red-900` | `#4D110E` |

### Colour implementation rule

Keep the complete source palette available as tokens. Semantic aliases such as `surface`, `primaryAction`, `errorText`, or `pendingBackground` may be introduced in Flutter when useful, but they must point to approved palette values and must be derived from the actual component/screen designs rather than invented independently.

The style guide includes contrast information against dark and white references. Do not assume that every palette combination is accessible for text. Verify the actual foreground/background pair used in the implemented component.

---

# 4. Typography

## 4.1 Typeface

The approved typeface is:

```text
Plus Jakarta Sans
```

Bundle the font with the application and define typography centrally.

Do not replace it with a platform-default font for visual convenience.

## 4.2 Source typography scale

The following values are transcribed from the approved style guide.

`Size / line height` values are in logical pixels for Flutter implementation. Letter spacing is recorded exactly as supplied by the export.

### Bold

| Style | Size | Line height | Letter spacing |
|---|---:|---:|---:|
| Headline Bold 40 | 40 | 48 | 0 |
| Headline Bold 32 | 32 | 40 | 0 |
| Headline Bold 28 | 28 | 36 | 0 |
| Headline Bold 24 | 24 | 32 | 0 |
| Title Bold 22 | 22 | 28 | 0 |
| Title Bold 18 | 18 | 24 | 0.15 |
| Title Bold 16 | 16 | 24 | 0.15 |
| Title Bold 14 | 14 | 20 | 0.10 |
| Label Bold 14 | 14 | 20 | 0.10 |
| Label Bold 12 | 12 | 16 | 0.50 |
| Label Bold 11 | 11 | 16 | 0.50 |
| Body Bold 16 | 16 | 24 | 0.15 |
| Body Bold 14 | 14 | 20 | 0.25 |
| Body Bold 12 | 12 | 16 | 0.40 |

### Medium

| Style | Size | Line height | Letter spacing |
|---|---:|---:|---:|
| Headline Medium 32 | 32 | 40 | 0 |
| Headline Medium 28 | 28 | 36 | 0 |
| Headline Medium 24 | 24 | 32 | 0 |
| Title Medium 22 | 22 | 28 | 0 |
| Title Medium 16 | 16 | 24 | 0.15 |
| Title Medium 14 | 14 | 20 | 0.10 |
| Label Medium 14 | 14 | 20 | 0.10 |
| Label Medium 12 | 12 | 16 | 0.50 |
| Label Medium 11 | 11 | 16 | 0.50 |
| Body Medium 16 | 16 | 24 | 0.15 |
| Body Medium 14 | 14 | 20 | 0.25 |
| Body Medium 12 | 12 | 16 | 0.40 |

### Regular

| Style | Size | Line height | Letter spacing |
|---|---:|---:|---:|
| Headline Regular 32 | 32 | 40 | 0 |
| Headline Regular 28 | 28 | 36 | 0 |
| Headline Regular 24 | 24 | 32 | 0 |
| Title Regular 22 | 22 | 28 | 0 |
| Title Regular 16 | 16 | 24 | 0.15 |
| Title Regular 14 | 14 | 20 | 0.10 |
| Label Regular 14 | 14 | 20 | 0.10 |
| Label Regular 12 | 12 | 16 | 0.50 |
| Label Regular 11 | 11 | 16 | 0.50 |
| Body Regular 16 | 16 | 24 | 0.15 |
| Body Regular 14 | 14 | 20 | 0.25 |
| Body Regular 12 | 12 | 16 | 0.40 |

### Typography implementation rules

- Define reusable `TextStyle` tokens rather than constructing styles inside feature widgets.
- Use the source weight, size, line height and letter spacing together.
- Respect the operating system text-scale setting. Do not disable scaling to force a screenshot match.
- Pixel-fidelity review is performed at the canonical design-review font scale; accessibility review is performed separately at enlarged system font scales.
- If the screen export and this transcription disagree, the screen/style-guide export wins.

---

# 5. Spacing

The approved spacing scale is:

| Token | Value |
|---|---:|
| `space-4` | 4 |
| `space-8` | 8 |
| `space-12` | 12 |
| `space-16` | 16 |
| `space-20` | 20 |
| `space-24` | 24 |
| `space-32` | 32 |

Use these values for layout spacing where the source design calls for the corresponding distance.

Do not create a new spacing value merely to make one screen easier to implement. If a source frame genuinely uses a value outside this scale, record it as a specific measured exception rather than silently extending the token system.

---

# 6. Radius

| Token | Value |
|---|---:|
| `radius-sm` | 8 |
| `radius-md` | 12 |
| `radius-lg` | 16 |
| `radius-xl` | 24 |
| `radius-pill` | 999 |

Use centralized `BorderRadius` tokens.

---

# 7. Elevation

The approved style guide defines the shared shadow as:

```text
Y offset: 4
Blur:     48
Opacity:  2%
```

The source export does not provide a separate spread value in the supplied material. Do not invent one unless implementation requires an explicitly documented Flutter approximation.

---

# 8. Iconography

The approved icon set includes:

```text
arrow-left
arrow-up-right
arrow-down-left
chevron-left
chevron-right
chevron-down
refresh
alert-circle
info
wifi
wifi-off
backspace
check
close
wallet
piggy-bank
target
calendar
clock
```

Implementation rules:

- Use one project icon abstraction/mapping.
- Do not mix visually unrelated icon families screen by screen.
- Use the approved icon meaning shown in the component and feature exports.
- Icon size, container treatment and colour must be verified against the specific component/screen reference.

The source material does not define a package name for these icons. Package/library selection is therefore an implementation decision, provided the rendered result matches the approved design.

---

# 9. Shared Components

The approved component export defines reusable component families. These are not optional visual examples; feature screens should reuse equivalent shared Flutter components where practical.

## 9.1 Buttons

The component export shows filled, outlined and text-style button treatments, including enabled and disabled appearances.

Required implementation characteristics:

- centralized typography;
- centralized colours;
- centralized radius;
- disabled appearance matching the source;
- semantic label/action support;
- system text scaling without clipping;
- minimum accessible interaction area where needed without visually changing the approved control.

Exact height, horizontal padding and state-specific colour usage must be verified against the component/feature export during implementation rather than invented here.

## 9.2 Text fields

The component export shows:

- empty/default field;
- focused/active field;
- entered value;
- error state;
- helper/supporting text;
- target-date field;
- target-date error state;
- amount field;
- amount entered state;
- over-balance amount error state.

Feature designs additionally show required/invalid recipient errors, zero-amount validation and NovaSave goal validation.

Field components must support:

- label;
- value/placeholder;
- error text;
- supporting/helper text;
- leading/trailing icon where the design requires it;
- accessible semantics;
- keyboard/focus state where applicable.

Do not encode business validation inside the shared visual field component.

## 9.3 System notifications

The component export defines system-level notification treatments for:

- offline;
- back online;
- sync failure;
- balance updated;
- saved on this phone;
- action will be saved/sent when online;
- nothing was taken from the wallet.

These messages communicate system/connectivity or safety information and are separate from the financial operation's own status.

## 9.4 Status and result components

The source defines the status set:

```text
Completed
Pending
Processing
Failed
```

It also shows corresponding result icon treatments:

- completed/check;
- pending/clock;
- processing/refresh;
- failed/close.

Do not create a separate visual status vocabulary for Send Money and NovaSave when the shared status treatment applies.

A recoverable synchronization failure may still leave an operation pending; presentation logic must not misuse the red `Failed` financial status when the operation is still safely queued.

## 9.5 Cards and lists

The component export includes:

- wallet balance card;
- savings-goal card;
- transaction list item;
- label/value row;
- skeleton/loading list treatment.

Feature implementations should compose these patterns rather than independently redesigning them.

Transaction-list implementation must remain compatible with lazy list construction required by the assessment.

## 9.6 Progress

The source defines horizontal progress-bar treatments used by NovaSave.

Progress values must be calculated from domain money values, not from independently stored floating-point percentages.

The visual percentage/bar is a presentation of domain state.

## 9.7 Navigation

The source defines:

```text
Wallet | Send | NovaSave
```

with distinct selected states for each destination.

The component export also defines a standard screen header/back affordance.

Navigation visuals must match the component export. Routing implementation is separate from the visual component.

## 9.8 Sheets

The component export includes a bottom-sheet pattern containing:

- drag handle;
- title;
- supporting text;
- primary action;
- secondary action.

The target-date picker shown in the NovaSave flow is a separate feature-specific sheet/state and should be matched against its approved screen reference.

## 9.9 Empty states

The source defines at least:

### Wallet

```text
No transactions yet
Your recent wallet activity will appear here.
```

### NovaSave

```text
Start saving toward something
Create your first NovaSave goal.
```

Empty-state illustrations/icons, spacing and copy must follow the approved source.

---

# 10. State Presentation Rules

Visual state must reflect actual application state.

Keep the following concerns separate:

```text
ConnectivityStatus
- online
- offline

SyncStatus
- idle
- syncing
- failed

OperationStatus
- pending
- processing
- completed
- failed
```

The UI can combine these dimensions, for example:

```text
offline + pending
online + syncing + processing
online + failed-sync + pending
online + idle + completed
```

Do not create one giant visual-state enum for every possible combination.

System banners and operation status components remain separate because the supplied component export presents them as separate concepts.

---

# 11. Feature Screen References

Do not duplicate every feature screen inside this document.

Use:

```text
docs/design/SCREEN_INDEX.md
```

for the mapping between implementation state and approved design PDF.

The PDFs in:

```text
docs/design/pdf/
```

remain the authoritative visual source.

Derived PNG references may be generated under `docs/design/references/` when an individual frame is useful for implementation or visual comparison. Those images are convenience artifacts; they do not supersede the approved PDF.

---

# 12. Flutter Design-System Structure

Recommended implementation structure:

```text
lib/design_system/
├── tokens/
│   ├── app_colors.dart
│   ├── app_spacing.dart
│   ├── app_radii.dart
│   ├── app_typography.dart
│   └── app_elevation.dart
├── theme/
├── icons/
└── components/
    ├── buttons/
    ├── fields/
    ├── notifications/
    ├── status/
    ├── cards/
    ├── navigation/
    ├── progress/
    ├── sheets/
    └── empty_states/
```

This directory shape is a project implementation convention, not a requirement from the design export. It may evolve if the architecture requires it, but design tokens must remain centralized and feature widgets must not duplicate them.

---

# 13. Accessibility Rules

The assessment requires the application to remain usable with screen readers and system font scaling.

Therefore shared components must:

- expose meaningful semantics for interactive controls;
- avoid icon-only actions without an accessible name;
- allow text to scale rather than disabling system scaling;
- avoid fixed heights that clip scaled text where possible;
- preserve readable focus/error/status information;
- ensure important state changes can be exposed accessibly;
- maintain usable touch targets.

Accessibility behavior may require responsive layout changes at large text scales. Pixel-perfect fidelity at font scale 1.0 must not be achieved by breaking accessibility at larger scales.

---

# 14. Visual Verification Workflow

Visual verification happens during each UI task, not only at the end of the project.

For every design-backed state:

1. Locate the state in `docs/design/SCREEN_INDEX.md`.
2. Open the authoritative PDF reference.
3. Implement using the shared design system.
4. Run the screen on the canonical visual-QA device/profile.
5. Capture the implemented state.
6. Compare it against the approved design for:
   - typography;
   - colours;
   - spacing;
   - alignment;
   - dimensions;
   - radii;
   - elevation;
   - icons;
   - component state;
   - copy;
   - navigation;
   - empty/error/offline/pending/processing/result presentation.
7. Correct material differences.
8. Re-capture and verify before the task is considered visually complete.

If direct comparison against a multi-screen PDF is inconvenient, generate only the needed frame/reference image under `docs/design/references/`. Do not manually pre-export every screen unless it becomes useful.

Human/design review remains the final visual judgment; raw pixel-difference tooling may assist but should not be the sole acceptance criterion.

---

# 15. Implementation Rules for Coding Agents

When implementing UI, agents must:

- read the relevant `UI-*` entry from `SCREEN_INDEX.md`;
- inspect the corresponding PDF/state before coding;
- use existing tokens and shared components;
- avoid arbitrary one-off visual values;
- keep business logic outside design-system widgets;
- expose semantics required by the assessment;
- support text scaling;
- compare the running result with the approved reference;
- report any source ambiguity rather than redesigning silently.

A UI task is not complete merely because the widget renders.

---

# 16. Remaining TO VERIFY Items

At this stage, the supplied style guide and component exports resolve the core palette, typography, spacing, radius, elevation, icon and component-family questions.

The following details should be resolved through screen-level visual comparison during implementation rather than guessed in advance:

- exact dimensions/padding for individual controls where the export does not publish numeric measurements;
- exact icon package/source used to reproduce the approved shapes;
- any screen-specific measurement that falls outside the documented token scales;
- canonical emulator viewport/device configuration for screenshot comparison, once the Flutter project is running.

These are implementation-verification details, not reasons to delay development.
