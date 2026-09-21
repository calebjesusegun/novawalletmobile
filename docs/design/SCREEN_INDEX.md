# NovaWallet Screen Index

**Status:** Pre-implementation visual reference map  
**Last updated:** 2026-09-20  
**Purpose:** Map every implementation state to the approved design source that coding and review agents must inspect.

The approved PDF exports are the authoritative visual source. This file is an index, not a replacement for the PDFs. `docs/design/references/` is optional and should contain only generated crops/reference PNGs that are useful for a specific implementation or visual-comparison task.

## 1. Repository Convention

```text
docs/design/
├── pdf/
│   ├── Wallet.pdf
│   ├── Send Money.pdf
│   ├── NovaSave.pdf
│   ├── Flow 1 Successful Send.pdf
│   ├── Flow 2 Offline Send.pdf
│   ├── Flow 3 Offline Send and Reconnect.pdf
│   ├── Flow 4 Create Savings Goal.pdf
│   ├── Flow 5 Successful Contribution.pdf
│   ├── Flow 6 Offline Contribution and Reconnect.pdf
│   ├── NovaWallet Design Components.pdf
│   └── NovaWallet Style Guide.pdf
├── SCREEN_INDEX.md
└── references/            # optional/generated as needed
```

If the files are renamed before implementation, update the paths in this index once and keep task references stable through the IDs below.

The original assessment brief belongs with internal assessment material, not in this visual-reference directory.

---

## 2. How Agents Use This File

Every UI task must list the relevant `UI-*` IDs from this document.

Example:

```text
Visual references:
- UI-SND-05 Amount — valid
- UI-SND-07 Amount — insufficient balance
- UI-SYS-01 Offline notification
```

Workflow:

1. Read the referenced entry.
2. Inspect the named PDF.
3. Implement the exact state.
4. If the PDF is awkward to compare because it contains many frames, generate only the relevant crop into `docs/design/references/`.
5. Run the app on the canonical visual-QA device.
6. Capture the implemented state and compare against the approved design.
7. Correct material differences before the task is considered visually complete.

Do not create a second source of truth from generated PNGs. The PDF remains authoritative.

---

## 3. Global Design-System Sources

| ID | Area | Authoritative source | Notes |
|---|---|---|---|
| UI-DS-01 | Color palette | `pdf/NovaWallet Style Guide.pdf` p.1 | Blue, gold, grey, success, warning, error, white |
| UI-DS-02 | Typography | `pdf/NovaWallet Style Guide.pdf` p.2 | Plus Jakarta Sans; size/line-height/letter-spacing/weight |
| UI-DS-03 | Iconography | `pdf/NovaWallet Style Guide.pdf` p.3 | Approved icon set |
| UI-DS-04 | Spacing/radius/elevation | `pdf/NovaWallet Style Guide.pdf` p.4 | 4–32 spacing scale, radii, shadow |
| UI-CMP-01 | Buttons | `pdf/NovaWallet Design Components.pdf` p.1 | Button states |
| UI-CMP-02 | Text fields | `pdf/NovaWallet Design Components.pdf` p.2 | Empty, entered, helper/error, amount/date states |
| UI-CMP-03 | System notifications | `pdf/NovaWallet Design Components.pdf` p.3 | Offline, back online, sync failure, saved/safe messages |
| UI-CMP-04 | Status/results | `pdf/NovaWallet Design Components.pdf` p.4 | Completed, Pending, Processing, Failed |
| UI-CMP-05 | Navigation | `pdf/NovaWallet Design Components.pdf` p.5 | Wallet / Send / NovaSave |
| UI-CMP-06 | System elements | `pdf/NovaWallet Design Components.pdf` p.6 | Status/system chrome reference |
| UI-CMP-07 | Cards/lists | `pdf/NovaWallet Design Components.pdf` p.7 | Goal card, balance card, transaction rows, key-value rows |
| UI-CMP-08 | Progress | `pdf/NovaWallet Design Components.pdf` p.8 | Progress indicator treatment |
| UI-CMP-09 | Sheets/empty states | `pdf/NovaWallet Design Components.pdf` p.9 | Sheet anatomy and empty-state patterns |

---

## 4. Wallet

Primary source: `pdf/Wallet.pdf`.

| ID | State | Source | Key behavior/visual cue |
|---|---|---|---|
| UI-WAL-01 | Wallet — default | `Wallet.pdf` | Balance, Send Money, NovaSave, recent transactions, bottom nav |
| UI-WAL-02 | Wallet — offline | `Wallet.pdf` | Offline system notification; balance shows last-updated time |
| UI-WAL-03 | Wallet — pending transfer | `Wallet.pdf` | Pending Send remains visible in recent transactions |
| UI-WAL-04 | Wallet — reconnecting | `Wallet.pdf` | Back-online notification; balance updating; pending row processing |
| UI-WAL-05 | Wallet — post-send success | `Wallet.pdf` | Confirmed lower balance and completed transfer row |
| UI-WAL-06 | Wallet — sync failure | `Wallet.pdf` | Sync-failure notification; saved transfer remains retryable |
| UI-WAL-07 | Wallet — refreshing | `Wallet.pdf` | Refreshing balance state |
| UI-WAL-08 | Wallet — loading/skeleton | `Wallet.pdf` | Loading placeholders/skeleton state |
| UI-WAL-09 | Wallet — empty | `Wallet.pdf` | Zero-balance example and “No transactions yet” empty state |
| UI-WAL-10 | Transaction details — pending | `Wallet.pdf` | Pending amount, recipient, saved time/status, saved-on-phone explanation |

Supporting flow sources:

- `pdf/Flow 1 Successful Send.pdf`
- `pdf/Flow 2 Offline Send.pdf`
- `pdf/Flow 3 Offline Send and Reconnect.pdf`

---

## 5. Send Money

Primary source: `pdf/Send Money.pdf`.

| ID | State | Source | Key behavior/visual cue |
|---|---|---|---|
| UI-SND-01 | Recipient — empty | `Send Money.pdf` | Recipient field + Continue |
| UI-SND-02 | Recipient — required error | `Send Money.pdf` | “Enter who you are sending to.” |
| UI-SND-03 | Recipient — invalid account | `Send Money.pdf` | Invalid-account helper text |
| UI-SND-04 | Recipient — resolved | `Send Money.pdf` | `0123456789` resolved to John Doe |
| UI-SND-05 | Amount — empty/zero display | `Send Money.pdf` | Amount entry + available balance + keypad |
| UI-SND-06 | Amount — valid | `Send Money.pdf` | ₦10,000 example |
| UI-SND-07 | Amount — insufficient balance | `Send Money.pdf` | Over-balance validation copy |
| UI-SND-08 | Amount — zero validation | `Send Money.pdf` | Greater-than-zero validation copy |
| UI-SND-09 | Amount — offline | `Send Money.pdf` | Offline notification + last-updated balance |
| UI-SND-10 | Confirm transfer — online | `Send Money.pdf` | Recipient, amount, source, balance-after rows |
| UI-SND-11 | Processing — online | `Send Money.pdf` | “Sending ₦10,000.00” processing state |
| UI-SND-12 | Transfer success — online | `Send Money.pdf` | Amount, recipient, reference, date, Completed |
| UI-SND-13 | Transfer failure — online | `Send Money.pdf` | “Nothing was taken from your wallet.” + retry |
| UI-SND-14 | Confirm transfer — offline | `Send Money.pdf` | Offline explanation that transfer will be saved |
| UI-SND-15 | Transfer pending | `Send Money.pdf` | Pending result + Saved/Sending/Successful progression |
| UI-SND-16 | Reconnect processing | `Send Money.pdf` | Back-online notification + Sending state |
| UI-SND-17 | Reconnect success | `Send Money.pdf` | Success after reconnect |
| UI-SND-18 | Sync failure / retry | `Send Money.pdf` | Operation remains saved; Try again now |

Journey-focused sources:

| Journey | Source |
|---|---|
| Online successful send | `pdf/Flow 1 Successful Send.pdf` |
| Offline send and persisted Pending | `pdf/Flow 2 Offline Send.pdf` |
| Pending → reconnect → processing → success / sync failure | `pdf/Flow 3 Offline Send and Reconnect.pdf` |

---

## 6. NovaSave

Primary source: `pdf/NovaSave.pdf`.

| ID | State | Source | Key behavior/visual cue |
|---|---|---|---|
| UI-NSV-01 | Goals — populated | `NovaSave.pdf` | Goal cards with percentage, amount and target date |
| UI-NSV-02 | Goals — offline/pending contribution | `NovaSave.pdf` | Pending contribution remains visible on goal |
| UI-NSV-03 | Goals — empty | `NovaSave.pdf` | “Start saving toward something” empty state |
| UI-NSV-04 | Create goal — empty | `NovaSave.pdf` | Name, target amount, target date |
| UI-NSV-05 | Create goal — validation errors | `NovaSave.pdf` | Missing name, non-positive amount, non-future date |
| UI-NSV-06 | Create goal — date picker | `NovaSave.pdf` | December 2026 picker example |
| UI-NSV-07 | Create goal — valid form | `NovaSave.pdf` | Emergency Fund / ₦500,000 / 30 Dec 2026 |
| UI-NSV-08 | Goal details — 30% | `NovaSave.pdf` | Saved, target, remaining, target date, Contribute |
| UI-NSV-09 | Contribution — valid amount | `NovaSave.pdf` | ₦50,000 contribution and projected 40% |
| UI-NSV-10 | Contribution — insufficient wallet balance | `NovaSave.pdf` | Over-wallet-balance validation |
| UI-NSV-11 | Confirm contribution — online | `NovaSave.pdf` | Goal, contribution, current and after balances |
| UI-NSV-12 | Contribution processing — online | `NovaSave.pdf` | “Adding ₦50,000.00” |
| UI-NSV-13 | Contribution success — online | `NovaSave.pdf` | 30% → 40% progress result |
| UI-NSV-14 | Goal details — updated 40% | `NovaSave.pdf` | Saved ₦200,000; remaining ₦300,000 |
| UI-NSV-15 | Contribution failure — online | `NovaSave.pdf` | Nothing taken + retry/back to goal |
| UI-NSV-16 | Confirm contribution — offline | `NovaSave.pdf` | Offline save explanation |
| UI-NSV-17 | Contribution pending | `NovaSave.pdf` | Pending result + Saved/Adding/Added progression |
| UI-NSV-18 | Goal details — pending contribution | `NovaSave.pdf` | Confirmed progress unchanged; pending amount shown separately |
| UI-NSV-19 | Reconnect processing | `NovaSave.pdf` | Back-online + Adding state |
| UI-NSV-20 | Reconnect success | `NovaSave.pdf` | Success after reconnect |
| UI-NSV-21 | Sync failure / retry | `NovaSave.pdf` | Contribution remains saved; Try again now |

Journey-focused sources:

| Journey | Source |
|---|---|
| Create savings goal | `pdf/Flow 4 Create Savings Goal.pdf` |
| Successful contribution | `pdf/Flow 5 Successful Contribution.pdf` |
| Offline contribution → pending → reconnect → success | `pdf/Flow 6 Offline Contribution and Reconnect.pdf` |

---

## 7. Canonical Visual-QA Device

**Status:** TO SET DURING PHASE 4.

Record the actual profile once the project runs and the source frames can be inspected against the emulator/device:

```text
Device/emulator:
Logical viewport:
Device pixel ratio:
Orientation: portrait
Theme: light
System text scale for fidelity capture: 1.0
Accessibility text-scale checks: enlarged separately (target 2.0 unless implementation evidence requires another documented value)
```

Do not hardcode a guessed viewport before Phase 4.

---

## 8. Visual Sign-Off Checklist

For each required `UI-*` state:

- [ ] Correct source PDF inspected.
- [ ] Copy matches approved design where the design specifies copy.
- [ ] Shared components use `docs/DESIGN_SYSTEM.md` tokens/components.
- [ ] Typography hierarchy matches.
- [ ] Spacing and alignment match materially.
- [ ] Colors/status treatment match.
- [ ] Icons match the approved set.
- [ ] Buttons/fields/cards/progress/navigation match their approved component patterns.
- [ ] Implemented state captured on canonical visual-QA device.
- [ ] Material differences corrected.
- [ ] Enlarged-text/accessibility behavior checked separately where applicable.

A generated crop/reference image may support this process, but it does not override the PDF.
