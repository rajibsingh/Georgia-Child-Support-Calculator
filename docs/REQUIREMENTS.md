# Working Numbers for Georgia Family Attorneys — Requirements

## Purpose

Build an iOS app branded for Andrea Knight | Intown Mediation LLC that gives Georgia family law attorneys fast, reliable back-of-the-envelope estimates for child support and property division. The app is designed for attorneys and mediators, not for litigants directly. Speed and ease of use are the primary values — the app must be faster and less cumbersome than the official Georgia calculator while covering the most common fact patterns.

- **Full app name:** Working Numbers for Georgia Family Attorneys
- **Short app name:** GAWorking
- **Publisher:** Andrea Knight Intown Mediation LLC
- **Statute reference:** O.C.G.A. § 19-6-15, current through 2025 Regular Session, effective 2026

## App Structure

The app uses a tab bar with 6 icon-only tabs (no text labels):

| # | Tab Name | Icon | Status |
|---|----------|------|--------|
| 1 | Child Support Ballparker | `baseball.circle.fill` | Built |
| 2 | Detailed CS Estimate | `list.bullet.circle.fill` | Coming soon |
| 3 | Parenting Time Visualizer | `calendar.circle` | Coming soon |
| 4 | MP Equalizer | `equal.circle.fill` | Coming soon |
| 5 | Thomas Calculator | `divide.circle.fill` | Built |
| 6 | Pension Calculator | `function` | Coming soon |

## Welcome Screen

Displayed every time the app opens. Fades in on appear. Auto-dismisses after 3.5 seconds or on tap (fades out).

- Background color: `IntownColors.teal` (#006489)
- Text color: white (varying opacity for hierarchy)
- Links not tappable
- Content (top to bottom):
  - SF Symbol app icon (`scalemass.fill`, 56pt)
  - App name: "Working Numbers"
  - Subtitle: "Georgia Family Law Calculator"
  - Divider
  - "Created by" label
  - "Andrea Knight"
  - "Intown Mediation"
  - "(404) 588-3000"
  - "calendly.com/andreaknight"
  - "Tap to continue" hint (bottom)

## Screen Headers

Each tab uses its own name as the header top line with a subheading below in smaller font. Tabs without built content have no subheading yet.

| Tab | Header | Subheading |
|-----|--------|------------|
| 1 | Child Support Ballparker | Back-of-envelope child support estimator for experienced attorneys. Use Detailed CS Estimator for more nuance including self employment, low income and customized parenting time. |
| 2 | Detailed CS Estimate | *(none until content is built)* |
| 3 | Parenting Time Visualizer | *(none until content is built)* |
| 4 | MP Equalizer | Calculate payment needed to equalize marital property. |
| 5 | Thomas Calculator | Estimates marital vs. non-marital share of an asset. |
| 6 | Pension Calculator | *(none until content is built)* |

## Ballpark Child Support (Tab 1)

### Purpose

Quick estimate for the most common Georgia child support fact patterns. No disclaimers on the main screen beyond the note below the result. Attorneys reference Detailed CS Estimate for more complex scenarios.

### Parents

Always labeled **CP** (Custodial Parent) and **NCP** (Noncustodial Parent). No custom name entry. Result panel label flips dynamically between "NCP Pays" and "CP Pays."

### Screen Inputs (top to bottom)

1. **Number of children** — visible 1–6 selector, same visual weight as income fields, default 2
2. **NCP Monthly Gross** — currency text field
3. **CP Monthly Gross** — currency text field
4. **NCP Overnights** — menu picker, default label "Pick an option", 4 presets smallest to largest:
   - 102 — 3 overnights every 2 weeks, 50/50 holidays, 2 summer weeks
   - 121 — 4 overnights every 2 weeks, 50/50 holidays, 3 summer weeks
   - 148 — 5 overnights every 2 weeks, 50/50 summers & holidays
   - 182.5 — 50/50 parenting time
5. **Work-related childcare** — currency text field + "Who pays?" menu (CP/NCP, no default)
6. **Child health insurance** — currency text field + "Who pays?" menu (CP/NCP, no default)

### Live Summary Boxes

Three boxes update as attorney types:
- **Combined BCSO** — basic child support obligation from statutory table
- **CP's Share** — CP's percentage of combined adjusted income
- **NCP's Share** — NCP's percentage of combined adjusted income

Show $0 / 0.0% / 0.0% when no income entered.

### Result Panel

- Dynamic label: "NCP Pays" or "CP Pays"
- Final amount rounded to whole dollar only — all intermediate values shown in full decimal precision
- Note text: "Simplified ballparker. Use Detailed CS Estimator for SET, low income, customized parenting time and other adjustments."
- Info row below note: "For SET and other adjustments, use the Detailed CS Estimator tab." (teal info icon, footnote text)
- **"More Numbers"** — collapsible disclosure group showing intermediate calculation steps in smaller font:
  - Combined gross income
  - Combined BCSO
  - CP's share BCSO
  - NCP's share BCSO
  - Parenting time adjustment (positive value, shown only when a schedule is selected)
  - Estimated monthly support
- No Screen 2 button or Screen 2 references

### Expense Payer Logic

```
NCP additional = (NCP share × CP-paid expenses) − (CP share × NCP-paid expenses)
```

No payer selected → expense contributes zero.

### Keyboard

- "Done" button above keyboard dismisses it
- Tapping outside a field also dismisses

### Terminology Rules

- "Guideline" only in brand header narrative
- "Case" not used anywhere in UI
- No references to "Screen 2" — reference "Detailed CS Estimator" instead

## Thomas Calculator (Tab 5)

### Purpose

Estimates marital vs. non-marital share of an asset under the Thomas v. Thomas framework.

### Inputs (in order)

1. Date of Marriage — plain text field, reference only, does not affect calculation
2. Current Market Value (CMV)
3. Current Secured Debt (SD)
4. Asset's Value at Date of Marriage (V_DOM)
5. Secured Debt at Date of Marriage (SD_DOM)
6. Marital Contributions to Asset (MC) — e.g. principal paid on mortgage during marriage

### Outputs

```
Appreciation During Marriage  = CMV − V_DOM − MC
Marital Share Capital         = MC ÷ (V_DOM − SD_DOM)
Estimated Non-Marital Value   = (V_DOM − SD_DOM) + Appreciation × (1 − Marital Share Capital)
Estimated Marital Value       = MC + Appreciation × Marital Share Capital
```

**Check sum:** Non-Marital + Marital = CMV − SD (current net equity)

Results panel is always visible and updates live as inputs are entered. No result shown until CMV and V_DOM are entered and equity at DOM (V_DOM − SD_DOM) is positive.

## Future Modes (Coming Soon)

### Detailed CS Estimate (Tab 2)

Full child support calculation including:
- Manual overnight entry
- SET adjustment inline
- Deviations
- SS/VA benefit credits
- Low-income adjustment
- Other qualified children / theoretical support credit

### MP Equalizer (Tab 4)

Calculates payment needed to equalize marital property between spouses.

### Parenting Time Visualizer (Tab 3)

Schedule visualization tool. Design TBD.

### Pension Calculator (Tab 6)

Pension valuation tool. Design TBD.

## BCSO Table Data

The full 2026 Basic Child Support Obligation Table must be re-encoded from the statute. A confirmed error exists at $16,000 combined income / 2 children ($2,728 in current app vs. $2,532 correct per official calculator). The entire table should be audited before shipping.

## Parenting Time Formula

Uses the statutory days^2.5 formula per O.C.G.A. § 19-6-15(g)(ii)(B):

```
(i)   NCP days ^ 2.5
(ii)  CP days ^ 2.5
(iii) (i) × CP share of BCSO
(iv)  (ii) × NCP share of BCSO
(v)   (iii) − (iv)
(vi)  (v) ÷ [(i) + (ii)]  → parenting time adjustment
(vii) NCP BCSO share − parenting time adjustment → NCP pays
```

Formula only applies when a parenting schedule is selected. At zero or no selected overnights, NCP pays their full pro-rata BCSO share.

Formula verified against official Georgia calculator: $10,000 NCP / $6,000 CP / 148 overnights / 2 children produces $702.72 parenting time adjustment and $880 final support.

## Nonfunctional Requirements

- Runs fully on device, no network required
- All user data stays local
- Native iOS fonts, Dynamic Type, VoiceOver labels
- Target users are attorneys 40+: generous font sizes and touch targets
- Calculation is deterministic: same inputs always produce same result
- All intermediate values in full decimal precision; round to whole dollar only in final output
