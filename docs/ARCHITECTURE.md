# Intown Mediation Child Support Calculator Architecture

## Overview

This app should be built as an Intown Mediation-branded SwiftUI iOS application with a pure Swift calculation core. The UI collects worksheet-style inputs, the domain layer performs deterministic Georgia guideline calculations, and the results layer explains each step used to produce the final estimate.

The project currently includes:

- App target: `Georgia Child Support Calculator`
- Unit test target: `Georgia Child Support CalculatorTests`
- UI test target: `Georgia Child Support CalculatorUITests`
- Source documents in `docs/`

The first engineering milestone should replace the default SwiftData sample screen with the calculator workflow and establish the calculation module plus tests before adding complex UI polish.

## Source Layout

Recommended app source structure:

```text
Georgia Child Support Calculator/
  App/
    Georgia_Child_Support_CalculatorApp.swift
  Calculation/
    ChildSupportCalculator.swift
    CalculationInput.swift
    CalculationResult.swift
    Money.swift
    ParentRole.swift
    RoundingPolicy.swift
  Calculation/Tables/
    BasicObligationTable.swift
    LowIncomeAdjustmentTable.swift
    StatutoryTableVersion.swift
  Calculation/Rules/
    IncomeRules.swift
    AdjustmentRules.swift
    ParentingTimeRules.swift
    ExpenseRules.swift
    DeviationRules.swift
    CreditRules.swift
  Scenarios/
    SupportScenario.swift
    ScenarioStore.swift
  UI/
    CalculatorFlowView.swift
    CaseSetupView.swift
    ParentIncomeView.swift
    AdjustmentsView.swift
    ParentingTimeView.swift
    AdditionalExpensesView.swift
    DeviationsView.swift
    ResultsView.swift
    Components/
  Resources/
    basic_obligation_2026.json
    low_income_adjustment_2026.json
```

Recommended test source structure:

```text
Georgia Child Support CalculatorTests/
  CalculationTests/
    BasicObligationTableTests.swift
    IncomeRulesTests.swift
    AdjustmentRulesTests.swift
    ParentingTimeRulesTests.swift
    ExpenseRulesTests.swift
    LowIncomeAdjustmentTests.swift
    CreditRulesTests.swift
    FinalPayerTests.swift
    GoldenScenarioTests.swift

Georgia Child Support CalculatorUITests/
  CalculatorFlowUITests.swift
  LaunchTests.swift
```

## Architectural Principles

Calculation code shall not depend on SwiftUI, SwiftData, UIKit, or device state.

The UI shall not duplicate business logic. It should bind user inputs into `CalculationInput`, call the calculator, and render `CalculationResult`.

Statutory tables shall be data, not hard-coded branching logic. Table parsing/loading can be isolated behind protocols so tests can inject small fixture tables. The production table data shall be converted from the statutory PDF and covered by tests that compare encoded values against PDF-derived reference fixtures.

Money shall be represented by integer cents or `Decimal`. Avoid `Double` for final money values. `Double` may be used only inside the parenting time exponent formula, then converted back through an explicit rounding policy.

Every calculation step shall produce traceable output. Results should include enough intermediate values to explain the estimate and to make failing tests easy to diagnose.

## Domain Model

Core input types:

```swift
struct CalculationInput {
    var numberOfChildren: Int
    var custodialParent: ParentInput
    var noncustodialParent: ParentInput
    var parentingTime: ParentingTimeInput
    var deviations: [DeviationInput]
    var socialSecurityChildBenefit: Money
    var vaDisabilityChildBenefit: Money
}

struct ParentInput {
    var grossMonthlyIncome: Money
    var selfEmploymentMonthlyIncome: Money
    var preexistingOrdersActuallyPaid: [PreexistingOrder]
    var qualifiedChildren: Int
    var workRelatedChildCare: Money
    var childHealthInsurancePremium: Money
}
```

Core output types:

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
    var deviations: [AppliedDeviation]
    var lowIncomeAdjustment: AppliedLowIncomeAdjustment?
    var credits: AppliedCredits
    var payer: ParentRole
    var finalMonthlyPayment: Money
    var uninsuredHealthcareShares: ParentPair<Decimal>
    var trace: [CalculationStep]
}
```

Use a small `ParentPair<T>` value type to keep custodial and noncustodial values together and reduce swapped-parent mistakes.

## Calculation Pipeline

The calculator should run the statutory worksheet flow in a fixed order:

1. Validate child count, income, parenting time, and expense inputs.
2. Calculate monthly gross income for each parent.
3. Apply adjusted income deductions: self-employment tax, preexisting orders, then theoretical support for qualified children.
4. Add adjusted incomes to produce combined adjusted gross income.
5. Lookup the basic child support obligation using the nearest statutory income bracket and child count.
6. Calculate each parent's pro rata income share.
7. Calculate each parent's basic child support obligation share.
8. Apply the 2026 parenting time adjustment when a court ordered parenting time input exists.
9. Allocate child health insurance and work related child care by pro rata share.
10. Calculate presumptive child support.
11. Apply user-entered deviations.
12. Apply the low-income adjustment when the table applies.
13. Apply qualifying Social Security Title II and VA disability credits.
14. Determine the payer and final monthly payment.
15. Return a traceable result for UI display and tests.

## Statutory Tables

Create versioned resource files for the Basic Child Support Obligation Table and Low-Income Adjustment Table. The app should load these through:

```swift
protocol ObligationTableProviding {
    func basicObligation(forCombinedIncome income: Money, children: Int) throws -> BasicObligationLookupResult
}

protocol LowIncomeTableProviding {
    func lowIncomeCap(forAdjustedIncome income: Money, children: Int) -> Money?
}
```

`BasicObligationLookupResult` should include:

- Requested combined adjusted income.
- Matched table income.
- Whether the match was exact, nearest, below range, or above range.
- Number of children.
- Obligation amount.

For income between rows, use the nearest bracket required by O.C.G.A. § 19-6-15(b)(4), not the simplified guide's round-down shortcut.

Table conversion should be treated as its own implementation slice:

- Extract source values from `docs/O.C.G.A.-_-19-6-15_01.01.2026.pdf`.
- Normalize money values to integer cents or whole-dollar `Money` values.
- Encode production lookup data as JSON or generated Swift, whichever is easiest to audit and safest to load in the app target.
- Store a small PDF-derived verification fixture separately from production data.
- Test production data against the verification fixture, including first and last rows, middle rows, all child-count columns, nearest-row behavior, and low-income table boundaries.

## Persistence

The first release shall not include saved scenarios. Keep the calculation state in memory during the active session.

Future saved scenarios can use SwiftData once the domain model is stable. Persisted scenario records should store user-entered inputs and table version, not only final outputs. This allows saved scenarios to be recalculated when rules or tables change while still showing which version produced the original result.

Do not store sensitive data in analytics or remote services.

## SwiftUI Structure

The UI should be a focused calculator workflow:

- `CalculatorFlowView` owns the draft scenario and navigation state.
- Step views edit a narrow slice of the scenario.
- `ResultsView` renders `CalculationResult` and its trace.
- Shared field components handle currency, percentages, child counts, and validation.

All UI controls used by UI tests shall have stable accessibility identifiers.

The result should update live when inputs are valid. Invalid or incomplete inputs should show actionable inline validation and keep the previous valid result out of the primary result area to avoid stale estimates.

Advanced 2026 adjustments should be available without making the common path feel busy. Use collapsed optional sections, disclosure groups, or "Add adjustment" flows for low-frequency inputs such as deviations, Social Security/VA credits, theoretical child support orders, and nonstandard healthcare allocations.

## Error Handling

Calculation errors should be typed and user-presentable:

- Missing required input.
- Invalid child count.
- Combined adjusted gross income not greater than zero.
- Table data missing or malformed.
- Parenting time days outside expected range.
- Expense or deviation amount below zero.

Developer diagnostics should include the failing calculation step and table version.

## Testing Strategy

Use Swift Testing for domain and calculation tests in `Georgia Child Support CalculatorTests`.

Use XCTest UI tests in `Georgia Child Support CalculatorUITests` for end-to-end calculator flows.

Calculation tests should use fixture inputs and assert intermediate values, not only final payment. This protects against regressions that accidentally cancel each other out.

Golden fixtures should include:

- Sharon and Henry from `docs/CALCULATION.md`, reconciled to the controlling 2026 statutory PDF table: custodial adjusted income $5,000, noncustodial adjusted income $6,000, combined income $11,000, pro rata shares 45.45 percent and 54.55 percent, two-child basic obligation $2,052, and noncustodial basic obligation about $1,119 before 2026 parenting time and additional adjustments. The simplified guide's older $1,877 example is treated as superseded by the 2026 PDF.
- Exact statutory table row lookup.
- Between-row nearest statutory table lookup.
- Above $40,000 high-income cap behavior.
- Low-income table cap behavior.
- Parenting time adjustment with unequal court ordered days.
- Social Security and VA credit scenarios where the credit partially offsets and fully satisfies the payment.
- Production table verification fixtures extracted from the statutory PDF for both the Basic Child Support Obligation Table and the Low-Income Adjustment Table.

UI tests should complete at least one valid happy path scenario and one validation path. Once visual design stabilizes, add screenshot regression coverage for the main input and result states.

Recommended local verification command:

```sh
xcodebuild -scheme "Georgia Child Support Calculator" -project "Georgia Child Support Calculator.xcodeproj" -destination 'platform=iOS Simulator,name=iPhone 16' test
```

The exact simulator name may vary by installed Xcode runtime. CI should use an explicitly available simulator discovered by `xcrun simctl list devices available`.

## Development Phases

### Phase 1: Foundation

- Remove the starter SwiftData item UI or quarantine it behind a placeholder.
- Add `Money`, parent roles, calculation input/result types, and typed errors.
- Add basic unit test files and fixture helpers.
- Add versioned table-loading interfaces with small test tables.
- Add the statutory table conversion workflow and PDF-derived verification fixtures.

### Phase 2: Core Formula

- Implement gross income, adjusted income, combined income, pro rata shares, and basic obligation lookup.
- Add the Sharon/Henry golden test and table lookup tests.
- Enter or import the full 2026 Basic Child Support Obligation Table and verify converted values against the PDF-derived fixture.

### Phase 3: 2026 Adjustments

- Implement parenting time adjustment.
- Implement additional expense allocation for health insurance and work related child care.
- Implement future uninsured healthcare percentage output.
- Add regression tests for each formula.

### Phase 4: Discretionary and Edge Rules

- Implement deviations as user-entered adjustments with statutory categories.
- Implement low-income adjustment using the 2026 table.
- Implement Social Security and VA child benefit credits.
- Add payer determination tests, including negative noncustodial obligation behavior.

### Phase 5: Calculator UI

- Build the SwiftUI step flow.
- Add inline validation and result trace rendering.
- Add accessibility identifiers.
- Add UI tests for launch, happy path, edit/recalculate, and validation.

### Phase 6: Persistence and Polish

- Consider local saved scenarios.
- Consider comparison view for multiple scenarios.
- Add exportable summary if needed.
- Add screenshot regression tests after layouts settle.

## Release Checklist

- Unit tests pass for all calculation rules and table fixtures.
- UI tests pass on a current iPhone simulator.
- Table data has been checked against the statutory PDF or an official source.
- Results screen includes disclaimer language.
- Accessibility labels and Dynamic Type have been reviewed.
- No calculation path depends on network access.
- Privacy review confirms all scenario data remains local.
