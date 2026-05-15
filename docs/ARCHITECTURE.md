# Working Numbers — Architecture

## Overview

Working Numbers for Georgia Family Attorneys is a SwiftUI iOS app with a pure Swift calculation core. The UI collects inputs, the domain layer performs deterministic calculations, and the results layer explains each step.

The app uses a tab-bar root (`RootTabView`) with six modes. Two modes are currently implemented: Ballpark Child Support and Thomas Calculator. The remaining four are coming-soon placeholders.

## Source Layout

```text
Georgia Child Support Calculator/
  Georgia_Child_Support_CalculatorApp.swift   — @main, launches RootTabView
  RootTabView.swift                           — TabView root, ComingSoonView, MoreMenuView
  ContentView.swift                           — BallparkChildSupportView, SETAdjustmentView,
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
    ParentRole.swift                          — ParentRole enum (custodial/noncustodial), ParentPair<T>
  Calculation/Tables/
    BasicObligationTable.swift                — ObligationTableProviding protocol + production impl
    BasicObligationTableData.swift            — 2026 BCSO table encoded from statutory PDF
    LowIncomeAdjustmentTable.swift            — LowIncomeTableProviding protocol + production impl
    LowIncomeAdjustmentTableData.swift        — 2026 low-income table encoded from statutory PDF
    StatutoryTableVersion.swift               — Version metadata

Georgia Child Support CalculatorTests/
  Georgia_Child_Support_CalculatorTests.swift — Unit tests: tables, calculator, draft model, Thomas calc

Georgia Child Support CalculatorUITests/
  Georgia_Child_Support_CalculatorUITests.swift
  Georgia_Child_Support_CalculatorUITestsLaunchTests.swift
```

The Xcode project uses `PBXFileSystemSynchronizedRootGroup`, so new `.swift` files added to the folder are picked up automatically without editing `project.pbxproj`.

## Architectural Principles

- **Calculation code has no UI dependencies.** `ChildSupportCalculator` and all types in `Calculation/` import only `Foundation`.
- **The UI does not duplicate business logic.** Views bind inputs into `CalculationInput` (or `ThomasDraft`), call the calculation layer, and render results.
- **Statutory tables are data, not branching logic.** Table access is behind protocols so tests can inject small fixture tables.
- **Money uses `Decimal` / integer cents.** `Double` is permitted only inside the parenting-time exponent formula, with explicit conversion back.
- **Every result is traceable.** `CalculationResult.trace` exposes each intermediate step for display and test assertion.

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

struct ParentInput {
    var grossMonthlyIncome: Money
    var selfEmploymentMonthlyIncome: Money // used for SET deduction
    var qualifiedChildren: Int             // for theoretical support credit
    var workRelatedChildCare: Money        // legacy field; zeroed out in Ballpark flow
    var childHealthInsurancePremium: Money // legacy field; zeroed out in Ballpark flow
}

enum ExpensePayer: String, CaseIterable, Identifiable {
    case cp
    case ncp
}
```

Expenses are collected at the `CalculationInput` level (single amount + payer) rather than per-parent. The calculator derives NCP's net additional obligation as:

```
NCP additional = (NCP share × CP-paid expenses) − (CP share × NCP-paid expenses)
```

### Child Support Results

```swift
struct CalculationResult {
    var adjustedIncome: ParentPair<Money>
    var combinedAdjustedGrossIncome: Money
    var proRataShares: ParentPair<Decimal>
    var tableLookup: BasicObligationLookupResult
    var basicObligationShares: ParentPair<Money>
    var parentingTimeAdjustedNoncustodialAmount: Money
    var additionalExpenseShares: ParentPair<Money>
    var presumptiveSupport: Money
    var deviationTotal: Money
    var lowIncomeAdjustment: AppliedLowIncomeAdjustment?
    var credits: AppliedCredits
    var payer: ParentRole
    var finalMonthlyPayment: Money
    var uninsuredHealthcareShares: ParentPair<Decimal>
    var trace: [CalculationStep]
}
```

### Thomas Calculator Model

```swift
struct ThomasDraft {
    var currentMarketValue: String
    var currentSecuredDebt: String
    var valueAtDOM: String       // value at date of marriage
    var securedDebtAtDOM: String // secured debt at date of marriage
    var maritalContributions: String

    var result: ThomasResult? { ... } // computed; nil until CMV and V_DOM are entered
}

struct ThomasResult {
    var appreciationDuringMarriage: Decimal
    var maritalShareCapital: Decimal
    var estimatedNonMaritalValue: Decimal
    var estimatedMaritalValue: Decimal
    var checkSum: Decimal  // should equal CMV − current SD
}
```

### UI Draft Model

```swift
struct BallparkDraft {
    var numberOfChildren: Int
    var ncpGrossIncome: String
    var cpGrossIncome: String
    var overnightOption: OvernightOption
    var childcareAmount: String
    var childcarePayer: ExpensePayer?    // nil = no payer selected → zero contribution
    var healthInsuranceAmount: String
    var healthInsurancePayer: ExpensePayer?

    var hasAnyIncome: Bool              // false → result panel shows placeholder, not $0
    func inputWithSET(ncpSET:cpSET:) -> CalculationInput
}
```

`BallparkDraft` bridges text-field strings to the typed `CalculationInput`. When `childcarePayer` or `healthInsurancePayer` is `nil`, the corresponding amount is zeroed before passing to the calculator.

## Calculation Pipeline

The calculator runs the statutory worksheet flow in a fixed order:

1. Validate child count, income, parenting time.
2. Apply SET deduction (one-half of 7.65% × `selfEmploymentMonthlyIncome`).
3. Apply theoretical support credit for other qualified children (optional; zeroed in Ballpark flow).
4. Compute combined adjusted gross income and pro-rata shares.
5. Look up basic child support obligation by nearest income bracket and child count.
6. Calculate each parent's basic obligation share.
7. Apply parenting-time adjustment (days^2.5 formula) when a schedule with known day count is selected.
8. Compute NCP's net additional expense obligation (payer-aware pro-rata logic).
9. Apply deviations (zeroed in Ballpark flow).
10. Apply low-income adjustment if applicable.
11. Apply SS/VA credits (zeroed in Ballpark flow).
12. Determine payer and final monthly payment.
13. Return traceable `CalculationResult`.

The SET adjustment on Screen 2 re-runs the same pipeline with `selfEmploymentMonthlyIncome` populated from Screen 2 inputs.

## UI Structure

### Tab Bar Root

`RootTabView` owns the `TabView`. Five tabs are shown: Ballpark CS, Thomas Calc, Detailed CS, Parenting Time, and More. More contains a `NavigationStack` list linking to Marital Balance Sheet and Pension Calculator (both `ComingSoonView`).

### Ballpark Child Support

`BallparkChildSupportView` owns `BallparkDraft` as `@State`. It computes `result: Result<CalculationResult, Error>?` — `nil` when `hasAnyIncome` is false, which prevents the result panel from showing a misleading $0 before any income is entered.

Screen 2 (`SETAdjustmentView`) is presented as a `.sheet`. It holds its own `@State` for SET income fields and re-runs `draft.inputWithSET(...)` live.

### Thomas Calculator

`ThomasCalculatorView` owns `ThomasDraft` as `@State`. `ThomasDraft.result` is a computed property — no separate calculation call needed. The result panel appears only when both CMV and V_DOM are entered and equity at DOM is positive.

### Shared Components

All shared UI components are defined in `ContentView.swift` with `internal` or `public` access so they can be used by `ThomasCalculatorView` and future screens:

- `CalculatorPanel` — titled card container
- `CurrencyField` — labeled text field with decimal keyboard
- `ResultMetricRow` — label/value row with separator
- `IntownTextFieldStyle` — consistent field styling
- `IntownColors` — brand color palette
- `BrandHeader` — "Working Numbers / for Georgia Family Attorneys" header card
- `SummaryBox` — live summary metric box

## Statutory Tables

Table access is behind protocols:

```swift
protocol ObligationTableProviding {
    func basicObligation(forCombinedIncome: Money, children: Int) throws -> BasicObligationLookupResult
}

protocol LowIncomeTableProviding {
    func lowIncomeCap(forAdjustedIncome: Money, children: Int) -> Money?
}
```

For income between rows, the app uses the nearest bracket per O.C.G.A. § 19-6-15(b)(4).

## Testing Strategy

Unit tests use Swift Testing (`@Test`). UI tests use XCTest.

Key test areas:
- Table lookups: exact rows, nearest-row matching, boundary behavior.
- Calculator: Sharon/Henry golden fixture ($11,000 combined, $2,052 BCSO, ~$1,119 NCP payment).
- Expense payer logic: CP-paid increases NCP obligation, NCP-paid decreases it.
- Parenting time formula: adjustment reduces NCP obligation when NCP days < 182.5.
- Low-income cap: confirmed against 2026 table values.
- Overnight options: all 6 preset values map to correct day counts.
- BallparkDraft: SET passthrough, nil-payer zeroing behavior.
- Thomas Calculator: sum check (Non-Marital + Marital = CMV − SD), appreciation formula.

## Development Phases

### Completed
- App foundation: Money, ParentRole, CalculationInput/Result, typed errors.
- Full 2026 BCSO and low-income tables encoded and tested.
- Core formula: adjusted income, combined income, pro-rata shares, BCSO lookup.
- Parenting time adjustment (days^2.5 formula).
- Expense allocation (payer-aware pro-rata model).
- Low-income adjustment.
- SS/VA benefit credits.
- Payer determination (with CP-pays reversal).
- Ballpark Child Support UI (Screen 1 + Screen 2 SET).
- Thomas Calculator.
- 6-tab app structure with coming-soon placeholders.

### Next
- Detailed Child Support screen (manual overnight entry, deviations, full SET, SS/VA credits, low-income adjustment).
- Parenting Time Visualizer.
- Marital Balance Sheet.
- Pension Calculator.

## Release Checklist

- Unit tests pass for all calculation rules and table fixtures.
- UI tests pass on a current iPhone simulator.
- Table data verified against statutory PDF.
- No calculation path depends on network access.
- Privacy: all data stays local.
- Accessibility labels and Dynamic Type reviewed.
