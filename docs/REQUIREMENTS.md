# Working Numbers for Georgia Family Attorneys — Requirements

## Purpose

Build an iOS app branded for Andrea Knight | Intown Mediation LLC that gives Georgia family law attorneys fast, reliable back-of-the-envelope estimates for child support and property division. The app is designed for attorneys and mediators, not for litigants directly. Speed and ease of use are the primary values — the app must be faster and less cumbersome than the official Georgia calculator while covering the most common fact patterns.

The app is named **Working Numbers for Georgia Family Attorneys**, published by **Andrea Knight Intown Mediation LLC**.

The statute O.C.G.A. § 19-6-15, current through the 2025 Regular Session and reflected in `docs/O.C.G.A.-_-19-6-15_01.01.2026.pdf`, is the controlling source for all child support calculations.

## App Structure

The app uses a tab-bar navigation with six modes:

| Tab | Status | Description |
|-----|--------|-------------|
| Ballpark Child Support | Built | Quick estimate for typical cases |
| Thomas Calculator | Built | Marital vs. non-marital asset share |
| Detailed Child Support | Coming soon | Full calculation with manual inputs |
| Parenting Time Visualizer | Coming soon | Schedule visualization tool |
| Marital Balance Sheet | Coming soon | Full balance sheet tool |
| Pension Calculator | Coming soon | Pension valuation tool |

The tab bar shows Ballpark CS, Thomas Calc, Detailed CS, Parenting Time, and a More menu (which contains Marital Balance Sheet and Pension Calculator).

## Ballpark Child Support

### Purpose

A single-screen quick estimate for the most common Georgia child support fact patterns. No disclaimers on the screen. Attorneys can enter a few numbers and get an instant ballpark. A "Proceed to Screen 2" button leads to SET and other adjustments.

### Parents

Parents are always labeled **CP** (Custodial Parent) and **NCP** (Noncustodial Parent). No custom name entry. The result panel label flips dynamically between "NCP Pays" and "CP Pays" based on who owes.

### Screen 1 Inputs (top to bottom)

1. **Number of children** — visible 1–6 selector, same visual weight as income fields, default 2, appears at the top of the screen.
2. **NCP Monthly Gross** — currency text field.
3. **CP Monthly Gross** — currency text field.
4. **NCP Overnights** — menu picker with 6 preset values:
   - No parenting-time adjustment
   - 182.5 — 50/50 (week on/week off)
   - 148 — 5 overnights/14 days, split summers
   - 129.5 — Thu–Sun + off-Thu, week-on summer
   - 123.5 — Thu–Sun + off-Thu, 2 summer weeks each
   - 121 — 4 overnights/14 days, 3 summer weeks each
   - 102 — 3 overnights/14 days, 2 summer weeks each
5. **Work-related childcare** — currency text field + "Who pays?" menu (CP / NCP, no default — requires affirmative selection; contributes zero if no payer selected).
6. **Child health insurance** — currency text field + "Who pays?" menu (same behavior).

### Screen 1 Live Summary Boxes

Three boxes at the top of the screen update as the attorney types:
- **Combined BCSO** — the basic child support obligation from the statutory table for the combined income and child count.
- **CP's Share** — CP's percentage of combined adjusted income.
- **NCP's Share** — NCP's percentage of combined adjusted income.

All three show $0 / 0.0% / 0.0% when no income has been entered. They update to show one parent's 100% share when only one income is entered, and show accurate shares when both are entered.

### Screen 1 Result

- Large dollar amount showing the monthly payment.
- Dynamic label: "NCP Pays" or "CP Pays" depending on which parent owes.
- Immediately below the amount: "Note: ignores SET, low-income adjustment, and other exceptions. Proceed to Screen 2 for more accurate results."
- Calculation trace showing combined income, table row, basic obligation, pro rata shares, parenting-time adjusted amount, and estimated monthly payment.
- Footnote: "If NCP Pays is negative, CP owes NCP that amount."
- "Proceed to Screen 2 → SET & other adjustments" button.

### Screen 2: SET Adjustment

A sheet presented over Screen 1 when the attorney taps Proceed.

Inputs:
- NCP gross income subject to SET (text field)
- CP gross income subject to SET (text field)

The app deducts one-half of SE tax (7.65%) from each SET amount before calculating adjusted gross income. This is the same mechanism as the existing `selfEmploymentMonthlyIncome` deduction in the calculation engine.

The screen shows the Screen 1 ballpark result for comparison, then the adjusted result with SET applied.

A "Coming Soon" panel notes that low-income adjustment, SSI, Social Security Title II, and VA disability derivative benefit offsets will be added in a future version.

### Expense Payer Logic

For each expense (childcare, insurance), the attorney selects which parent pays. The NCP's net additional obligation is:

```
NCP additional = (NCP pro-rata share × CP-paid expenses) − (CP pro-rata share × NCP-paid expenses)
```

If no payer is selected, the expense contributes zero to the calculation.

### Terminology

- "Guideline" appears only in the brand header narrative: "Back-of-the-envelope estimates for Georgia child support guidelines."
- "Case" does not appear in any visible UI label.
- Parents are CP and NCP throughout, not "custodial parent" / "noncustodial parent."

### Out of Scope for Ballpark Screen

- Preexisting child support actually paid (too factually intense; deferred permanently for this mode).
- Deviations (available in Detailed Child Support, coming soon).
- Social Security / VA benefit credits (Screen 2 placeholder; full build deferred to future version).
- Low-income adjustment (same).
- Manual overnight entry (available in Detailed Child Support, coming soon).

## Thomas Calculator

### Purpose

Estimates the marital vs. non-marital share of an asset under the Thomas v. Thomas framework used in Georgia equitable division cases.

### Inputs

- Current Market Value (CMV)
- Current Secured Debt (SD) — displayed in reference/check row, does not feed into share formulas directly
- Asset's Value at Date of Marriage (V_DOM)
- Secured Debt at Date of Marriage (SD_DOM)
- Marital Contributions to Asset — e.g. principal portion of mortgage payments made during marriage (MC)

Date of marriage is a reference field only; it does not affect the calculation.

### Outputs

```
Appreciation During Marriage  = CMV − V_DOM − MC
Marital Share Capital         = MC ÷ (V_DOM − SD_DOM)
Estimated Non-Marital Value   = (V_DOM − SD_DOM) + Appreciation × (1 − Marital Share Capital)
Estimated Marital Value       = MC + Appreciation × Marital Share Capital
```

**Sanity check:** Estimated Non-Marital Value + Estimated Marital Value = CMV − SD (current net equity).

The result panel displays the check sum so the attorney can confirm the outputs are internally consistent.

The calculator shows no result until CMV and V_DOM are both entered and the equity at date of marriage (V_DOM − SD_DOM) is positive (required to avoid division by zero in Marital Share Capital).

## Future Modes (Coming Soon)

### Detailed Child Support

Will include everything in Ballpark plus:
- Manual overnight entry for schedules not in the preset list
- Deviations (increase/decrease with statutory categories)
- Social Security Title II and VA disability child benefit credits
- Low-income adjustment
- Other qualified children / theoretical support credit
- Full SET adjustment inline on the main screen

### Parenting Time Visualizer

Schedule visualization tool. Inputs and design TBD.

### Marital Balance Sheet

Full marital vs. separate property balance sheet. Design TBD.

### Pension Calculator

Pension valuation tool. Design TBD.

## Data Requirements

The app shall store statutory tables as versioned, testable Swift data:
- Basic Child Support Obligation Table from O.C.G.A. § 19-6-15(o) — 2026 version encoded.
- Low-Income Adjustment Table from O.C.G.A. § 19-6-15(p) — 2026 version encoded.

All money calculations shall use `Decimal` or integer cents, never `Double` for final values. `Double` is permitted only inside the parenting-time exponent formula, with explicit conversion back.

## Nonfunctional Requirements

- Runs fully on device, no network required.
- All user-entered data stays local.
- Native iOS fonts, SwiftUI controls, Dynamic Type, VoiceOver labels.
- Currency and percentages formatted with U.S. locale.
- Calculation is deterministic: same inputs and table version always produce the same result.
- Target users are attorneys aged 40+. Font sizes and touch targets should be generous.
