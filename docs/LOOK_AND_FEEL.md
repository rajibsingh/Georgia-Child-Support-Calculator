# Working Numbers — Look and Feel

## Design Goal

Working Numbers for Georgia Family Attorneys should feel like a professional practice tool: fast, readable, and precise. The primary users are attorneys and mediators aged 40+, working under time pressure. The design must prioritize legibility and speed over decoration.

The app is not a consumer finance dashboard and not a government form. It should feel like a well-designed professional tool — calm, authoritative, and easy to use with one hand.

Publisher: Andrea Knight | Intown Mediation LLC.
Primary brand reference: intownmediation.com.

## Color Palette

| Token | Hex | Use |
|-------|-----|-----|
| `IntownColors.teal` | `#006489` | Primary actions, selected states, key result values, navigation tint |
| `IntownColors.text` | `#58585A` | Primary body and label text |
| `IntownColors.secondaryText` | `#666666` | Help text, footnotes, placeholders |
| `IntownColors.border` | `#CCCCCC` | Field borders, dividers |
| `IntownColors.surface` | `#FFFFFF` | Card and field backgrounds |
| `IntownColors.background` | `#F5F5F5` | App background |
| `IntownColors.error` | `#BA2227` | Validation errors |

Avoid gradients, heavy shadows, and decorative color blocks. Color guides attention — it does not carry the design.

## Typography

Use native iOS system fonts throughout. Do not bundle custom fonts.

| Role | Size | Weight |
|------|-----:|--------|
| App name (brand header) | 22 | Semibold |
| Brand subtitle | 16 | Regular |
| Section/panel title | title3 (~20) | Semibold |
| Body / field values | body (~17) | Regular |
| Field labels | subheadline (~15) | Medium |
| Help / footnote text | footnote (~13) | Regular |
| Result amount | 44 | Semibold |
| Result payer label | headline | Regular |
| SET disclaimer (below result) | subheadline | Regular |
| Summary box value | body | Semibold |
| Summary box label | caption | Medium |

Target users are 40+. Do not use text smaller than footnote style for anything the user needs to read to use the app. Reserve caption for summary box labels only.

## Layout

- Scrollable single-column layout within each tab.
- Content grouped into `CalculatorPanel` cards (white surface, 8 px corner radius, 16 px padding).
- 16 px horizontal page margins, 18 px vertical page padding, 16 px gap between cards.
- All text left-aligned. Result amounts left-aligned under the panel title.
- Stable card dimensions — changing values should not shift layout.

## Brand Header

Appears at the top of the Ballpark Child Support tab (and will appear on other built tabs):

```
Working Numbers                         [22pt semibold teal]
for Georgia Family Attorneys            [16pt regular teal]
Back-of-the-envelope estimates for      [footnote gray]
Georgia child support guidelines.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━        [2px teal rule]
```

## Summary Boxes

Three equal-width boxes in a horizontal row below the brand header:

```
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  Combined BCSO  │  │   CP's Share    │  │   NCP's Share   │
│    $2,052       │  │    45.5%        │  │    54.5%        │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

- Label: caption weight medium, gray.
- Value: body weight semibold, teal.
- Show $0 / 0.0% / 0.0% when no income entered.
- Update live as the attorney types.

## Child Count Selector

Full-width segmented bar showing 1–6. Same visual weight and padding as income fields — not small or incidental. Selected value: teal fill, white text. Unselected: teal text, white background, gray dividers. Height: 50 pt.

## Income Fields

Standard `CurrencyField` layout:
- Label above (subheadline medium, dark gray).
- Text field below (decimal keyboard, 12 px horizontal padding, 11 px vertical padding, 1 px gray border, 6 px radius).
- No currency symbol prefix. Attorney types the raw number.

## Parenting Time Picker

Menu-style picker (`.pickerStyle(.menu)`) showing the selected overnight option as a tappable label. Dropdown reveals 7 options including "No parenting-time adjustment." Footnote below explains airline/unusual schedule caveat.

## Expense Rows

Each expense (childcare, insurance) shows:
- Label above.
- Currency field on the left (takes most of the width).
- "Who pays?" label + Menu button on the right, stacked vertically.
- Menu button shows "Select" in gray when no payer chosen, shows "CP" or "NCP" in dark text when chosen.
- No default selection — attorney must affirmatively choose.

## Result Panel

Panel title is dynamic: "NCP Pays" or "CP Pays".

```
NCP Pays                                [panel title, teal, title3 semibold]

$1,119                                  [44pt semibold teal]
NCP pays monthly                        [headline, dark gray]
Simplified ballparker. Use Detailed     [subheadline, secondary gray]
CS Estimator for SET, low income,
customized parenting time and other
adjustments.

▾ More Numbers                          [subheadline medium teal, chevron toggle]
  Combined gross income    $11,000      [caption, dark gray]
  Combined BCSO            $2,052.00
  CP's share BCSO          $933.37
  NCP's share BCSO         $1,118.63
  Parenting time adjustment $xxx.xx     [only shown when schedule selected]
  Estimated monthly support $1,118.63

ⓘ For SET and other adjustments,       [footnote, secondary gray, teal info icon]
  use the Detailed CS Estimator tab.
```

The result panel shows "Enter income above to see an estimate." when no income has been entered yet, rather than a $0 result.

## Thomas Calculator

Same `CalculatorPanel` card structure. Two panels: inputs and results.

Result rows follow the same `ResultMetricRow` style as the child support trace. The check sum row (Non-Marital + Marital = net equity) is displayed in teal to confirm internal consistency.

## Buttons

- **Primary (teal fill):** white text, 8 px radius, 14 px vertical padding, full width. Used for "Proceed to Screen 2."
- **Navigation bar buttons:** system tint (teal), label + SF Symbol.
- **Menu buttons:** white background, 1 px gray border, 6 px radius, teal chevron icon.

Avoid pill-shaped buttons and heavy rounded rectangles.

## Coming Soon Screens

Uses the standard `CalculatorPanel` card layout within a scrollable tab:
- `TabHeader` with the tab's name at top.
- `CalculatorPanel("Coming Soon")` containing:
  - `clock` SF Symbol, 48 pt, teal.
  - "This tool is under development." in body, secondary gray.

## Accessibility

- All controls have `.accessibilityIdentifier` for UI tests.
- All buttons have `.accessibilityLabel`.
- Support Dynamic Type — use SwiftUI text styles, not fixed font sizes where possible. The fixed sizes listed above are baselines; they scale with Dynamic Type.
- Touch targets minimum 44 × 44 pt.
- Do not rely on color alone for validation state.
- VoiceOver labels on all fields, result rows, and interactive controls.

## Voice and Tone

- Direct and plain-spoken.
- Calm about stressful topics.
- Transparent about what the estimate does and does not include.
- No disclaimers on Screen 1 beyond the SET note below the result amount.
- No "legal advice" boilerplate on Screen 1 — this is a professional tool for attorneys.

Current field labels and help text in use:

| Element | Text |
|---------|------|
| App description | Back-of-the-envelope estimates for Georgia child support guidelines. |
| SET disclaimer | Note: ignores SET, low-income adjustment, and other exceptions. Proceed to Screen 2 for more accurate results. |
| CP reversal note | If NCP Pays is negative, CP owes NCP that amount. |
| Parenting time note | Variable or unusual work schedules (including airline flight schedules) may require a custom court-ordered count or deviation analysis. |
| SET screen note | App deducts one-half of SE tax (7.65%) from the SET income entered above before calculating adjusted gross income. |
| Coming soon note | This tool is under development. |
