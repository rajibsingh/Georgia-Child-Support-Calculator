# Working Numbers — Architecture

## Overview

Working Numbers for Georgia Family Attorneys is a SwiftUI iOS app with a pure Swift calculation core. The UI collects inputs, the domain layer performs deterministic calculations, and the results layer explains each step.

- **Full app name:** Working Numbers for Georgia Family Attorneys
- **Short app name:** GAWorking
- **Bundle display name:** GAWorking

The app launches into a welcome screen (3-second auto-dismiss), then a tab-bar root (`RootTabView`) with six icon-only tabs.

## Source Layout

```text
Georgia Child Support Calculator/
  Georgia_Child_Support_CalculatorApp.swift   — @main, launches WelcomeScreen then RootTabView
  RootTabView.swift                           — TabView root, ComingSoonView
  WelcomeView.swift                           — 3-second splash, #4782a0 background
  ContentView.swift                           — BallparkChildSupportView, SETAdjustmentView (removed),
                                                BallparkDraft, OvernightOption, shared UI components,
                                                IntownColors, String.asMoney
  ThomasCalculatorView.swift                  — ThomasCalculatorView, ThomasDraft, ThomasResult
  Calculation/
    ChildSupportCalculator.swift              — Stateless calculator struct
    CalculationInput.swift                    — CalculationInput, ParentInput, ParentingTimeInput,
                                                DeviationInput, ExpensePayer
    CalculationResult.swift                   — CalculationResult, CalculationStep, AppliedCredits,
                                                AppliedLowIncomeAdjustment, CalculationError
    Money.swift                               — Money value type (integer cents + Decimal API)
    ParentRole.swift                          — ParentRole enum (cp/ncp), ParentPair<T>
  Calculation/Tables/
    BasicObligationTable.swift                — ObligationTableProviding protocol + production impl
    BasicObligationTableData.swift            — 2026 BCSO table (needs full re-audit and re-encode)
    LowIncomeAdjustmentTable.swift            — LowIncomeTableProviding protocol + production impl
    LowIncomeAdjustmentTableData.swift        — 2026 low-income table
    StatutoryTableVersion.swift               — Version metadata

Georgia Child Support CalculatorTests/
  Georgia_Child_Support_CalculatorTests.swift

Georgia Child Support CalculatorUITests/
  Georgia_Child_Support_CalculatorUITests.swift
  Georgia_Child_Support_CalculatorUITestsLaunchTests.swift
```

The Xcode project uses `PBXFileSystemSynchronizedRootGroup` — new `.swift` files in the folder are picked up automatically.

## Architectural Principles

- **Calculation code has no UI dependencies.** All types in `Calculation/` import only `Foundation`.
- **The UI does not duplicate business logic.** Views bind inputs into typed models, call the calculation layer, and render results.
- **Statutory tables are data, not branching logic.** Table access is behind protocols for testability.
- **Money uses `Decimal` / integer cents.** `Double` only inside the parenting-time exponent formula, with explicit conversion back.
- **Every result is traceable.** `CalculationResult.trace` exposes each intermediate step.
- **Rounding happens once.** All intermediate values carry full decimal precision. The final "NCP Pays" / "CP Pays" display value is the only place rounded to whole dollars.

## App Launch Flow

```
App launch
  → WelcomeView (3 seconds or tap to dismiss, #4782a0 background, white text)
  → RootTabView (6 icon-only tabs)
```

## Domain Model

### Child Support Inputs

```swift
struct CalculationInput {
    var numberOfChildren: Int
    var custodialParent: ParentInput
    var noncustodialParent: ParentInput
    var parentingTime: ParentingTimeInput
    var childcareAmount: Money
    var childcarePayer: ExpensePayer       // .cp or .ncp
    var healthInsuranceAmount: Money
    var healthInsurancePayer: ExpensePayer
    var deviations: [DeviationInput]
    var socialSecurityChildBenefit: Money
    var vaDisabilityChildBenefit: Money
}

enum ExpensePayer: String, CaseIterable, Identifiable {
    case cp
    case ncp
}
```

### UI Draft Model

```swift
struct BallparkDraft {
    var numberOfChildren: Int               // default 2
    var ncpGrossIncome: String
    var cpGrossIncome: String
    var overnightOption: OvernightOption    // default .none ("Pick an option")
    var childcareAmount: String
    var childcarePayer: ExpensePayer?       // nil = no selection → zero contribution
    var healthInsuranceAmount: String
    var healthInsurancePayer: ExpensePayer?

    var hasAnyIncome: Bool
    func inputWithSET(ncpSET:cpSET:) -> CalculationInput
}

enum OvernightOption: CaseIterable {
    case none       // "Pick an option" — no adjustment applied
    case schedule102  // 102 overnights
    case schedule121  // 121 overnights
    case schedule148  // 148 overnights
    case split182     // 182.5 overnights
}
```

### Thomas Calculator Model

```swift
struct ThomasDraft {
    var dateOfMarriage: String      // plain text, reference only
    var currentMarketValue: String
    var currentSecuredDebt: String
    var valueAtDOM: String
    var securedDebtAtDOM: String
    var maritalContributions: String

    var result: ThomasResult?       // computed; nil until inputs are sufficient
}

struct ThomasResult {
    var appreciationDuringMarriage: Decimal
    var maritalShareCapital: Decimal
    var estimatedNonMaritalValue: Decimal
    var estimatedMaritalValue: Decimal
    var checkSum: Decimal           // = CMV − current SD
}
```

## Calculation Pipeline

1. Validate child count, income, parenting time.
2. Apply SET deduction (one-half of 7.65% × `selfEmploymentMonthlyIncome`).
3. Apply theoretical support credit for other qualified children (zeroed in Ballpark).
4. Compute combined adjusted gross income and pro-rata shares.
5. Look up BCSO by nearest income bracket and child count.
6. Calculate each parent's basic obligation share.
7. Apply parenting-time adjustment (days^2.5 formula per O.C.G.A. § 19-6-15(g)(ii)(B)) when a schedule is selected. The **parenting time adjustment** is the delta (step vi of the statute), kept as a positive value for display. NCP pays = NCP BCSO − parenting time adjustment.
8. Compute NCP's net additional expense obligation (payer-aware pro-rata).
9. Apply deviations (zeroed in Ballpark).
10. Apply low-income adjustment if applicable.
11. Apply SS/VA credits (zeroed in Ballpark).
12. Determine payer and final monthly payment.
13. Round final payment to whole dollar. All intermediate values remain full precision.

## Parenting Time Formula

Per O.C.G.A. § 19-6-15(g)(ii)(B):

```
(i)   NCP days ^ 2.5
(ii)  CP days ^ 2.5
(iii) (i) × CP BCSO share
(iv)  (ii) × NCP BCSO share
(v)   (iii) − (iv)
(vi)  (v) ÷ [(i) + (ii)]          → parenting time adjustment (negative = credit to NCP)
(vii) NCP BCSO share + (vi)        → NCP adjusted amount
```

Displayed in "More Numbers" as: **Parenting Time Adjustment** = abs(vi), positive value.

Verified: $10,000 NCP / $6,000 CP / 148 NCP overnights / 2 children → adjustment $879.78, NCP pays $702.72, rounds to **$703**.

## UI Structure

### Welcome Screen (`WelcomeView`)

- Background #4782a0, white text
- Centered contact info for Andrea Knight / Intown Mediation
- Auto-dismisses after 3 seconds or on tap
- Presented modally over `RootTabView` on first render, removed from view hierarchy on dismiss

### Tab Bar Root (`RootTabView`)

6 tabs, icons only, no labels:
1. `baseball.circle.fill` → `BallparkChildSupportView`
2. `list.bullet.circle.fill` → `ComingSoonView("Detailed CS Estimate")`
3. `calendar.circle` → `ComingSoonView("Parenting Time Visualizer")`
4. `equal.circle.fill` → `ComingSoonView("MP Equalizer")`
5. `divide.circle.fill` → `ThomasCalculatorView`
6. `function` → `ComingSoonView("Pension Calculator")`

### Ballpark Child Support (`BallparkChildSupportView`)

- Owns `BallparkDraft` as `@State`
- `result` is `Result<CalculationResult, Error>?` — nil when `hasAnyIncome` is false
- No sheet / Screen 2 — references Detailed CS Estimate instead
- "More Numbers" disclosure group wraps the calculation trace
- Keyboard dismissed via toolbar "Done" button and tap gesture on scroll view

### Thomas Calculator (`ThomasCalculatorView`)

- Owns `ThomasDraft` as `@State`
- Result is a computed property on `ThomasDraft` — no separate call needed
- Results panel always visible, shows placeholder text until inputs are sufficient
- First field: Date of Marriage (plain text)

### Shared Components (defined in `ContentView.swift`, internal access)

- `CalculatorPanel` — titled card
- `CurrencyField` — labeled decimal text field
- `ResultMetricRow` — label/value row with separator
- `IntownTextFieldStyle` — consistent field styling
- `IntownColors` — brand palette
- `BrandHeader` — per-tab header with title and subheading
- `SummaryBox` — live metric box

## Statutory Tables

**⚠️ The BCSO table data has a confirmed error** at $16,000 combined income / 2 children ($2,728 in app vs. $2,532 correct). The full 2026 table must be re-encoded from `docs/O.C.G.A.-_-19-6-15_01.01.2026.pdf` before shipping.

Table protocols:

```swift
protocol ObligationTableProviding {
    func basicObligation(forCombinedIncome: Money, children: Int) throws -> BasicObligationLookupResult
}

protocol LowIncomeTableProviding {
    func lowIncomeCap(forAdjustedIncome: Money, children: Int) -> Money?
}
```

## Known Bugs (to fix in next build)

1. **Parenting time adjustment bug** — when a parenting schedule is selected, the app reports the parenting-time adjusted amount as the final child support rather than subtracting the adjustment from NCP's BCSO share.
2. **Early rounding** — intermediate values are being rounded to whole dollars before the final output step.

## Development Phases

### Completed
- App foundation, Money, ParentRole, typed errors
- 2026 BCSO and low-income tables (BCSO needs re-audit)
- Core formula: adjusted income, combined income, pro-rata, BCSO lookup
- Parenting time adjustment (days^2.5, verified against official calculator)
- Expense allocation (payer-aware pro-rata)
- Low-income adjustment, SS/VA credits, payer determination
- Ballpark Child Support UI
- Thomas Calculator
- 6-tab app structure with coming-soon placeholders

### Next Build
- Welcome screen
- App name / branding audit (full name + GAWorking short name)
- Tab bar icon-only, 6 tabs in correct order
- Ballpark tab: overnight picker reorder/relabel, remove Screen 2 references, "More Numbers" disclosure group, trace relabeling, keyboard dismiss
- Thomas tab: Date of Marriage field, fix results display
- Bug fixes: parenting time adjustment calculation, early rounding
- BCSO table re-encode

### Future
- Detailed CS Estimate
- MP Equalizer
- Parenting Time Visualizer
- Pension Calculator
