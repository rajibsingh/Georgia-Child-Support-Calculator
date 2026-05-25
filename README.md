# Georgia Child Support Calculator

Intown Mediation-branded iOS app for estimating Georgia child support under the 2026 O.C.G.A. § 19-6-15 guidelines.

The app is a mediation-practice tool, not legal advice, a filing generator, or a replacement for the official Georgia calculator.

## Current App

- SwiftUI iOS app branded for Intown Mediation.
- Parent names with `Mom` and `Dad` defaults.
- Visible child-count selector for 1 through 6 children.
- Live estimate using encoded 2026 Basic Child Support Obligation and Low-Income Adjustment tables.
- Schedule-type parenting-time selector based on Georgia's Parenting Plan day-count examples.
- Work-related child care, child health insurance, deviations, Social Security credits, and VA credits.
- Preexisting child support actually paid is shown as a statute note, not calculated in this simplified flow.
- Reset button restores the default worksheet.

## Project Layout

```text
Georgia Child Support Calculator/
  ContentView.swift
  Georgia_Child_Support_CalculatorApp.swift
  Calculation/
    ChildSupportCalculator.swift
    CalculationInput.swift
    CalculationResult.swift
    Money.swift
    ParentRole.swift
    Tables/

Georgia Child Support CalculatorTests/
  Georgia_Child_Support_CalculatorTests.swift

Georgia Child Support CalculatorUITests/
  Georgia_Child_Support_CalculatorUITests.swift

docs/
  ARCHITECTURE.md
  CALCULATION.md
  LOOK_AND_FEEL.md
  REQUIREMENTS.md
  O.C.G.A.-_-19-6-15_01.01.2026.pdf
```

## Documentation

- [Requirements](docs/REQUIREMENTS.md) defines product scope and calculation behavior.
- [Architecture](docs/ARCHITECTURE.md) explains the calculation core, UI structure, data strategy, and testing approach.
- [Look and Feel](docs/LOOK_AND_FEEL.md) captures the Intown Mediation visual direction.
- [Calculation Notes](docs/CALCULATION.md) provides the simplified user-facing process.

## Build And Test

Open `Georgia Child Support Calculator.xcodeproj` in Xcode, or run:

```sh
xcodebuild -scheme "Georgia Child Support Calculator" -project "Georgia Child Support Calculator.xcodeproj" -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/GeorgiaChildSupportDerivedData CODE_SIGNING_ALLOWED=NO build-for-testing
```

To run tests locally, choose an available simulator:

```sh
xcodebuild -scheme "Georgia Child Support Calculator" -project "Georgia Child Support Calculator.xcodeproj" -destination 'platform=iOS Simulator,name=iPhone 16' test
```

The simulator name may differ by machine. Use `xcrun simctl list devices available` to find installed devices.

Useful test commands:

```sh
# Compile the app, unit tests, and UI tests without launching a simulator.
xcodebuild -scheme "Georgia Child Support Calculator" -project "Georgia Child Support Calculator.xcodeproj" -destination 'generic/platform=iOS Simulator' -derivedDataPath /tmp/GeorgiaChildSupportDerivedData CODE_SIGNING_ALLOWED=NO build-for-testing

# Run all tests on a named simulator.
xcodebuild -scheme "Georgia Child Support Calculator" -project "Georgia Child Support Calculator.xcodeproj" -destination 'platform=iOS Simulator,name=iPhone 16' test

# List available simulator names on the local machine.
xcrun simctl list devices available
```

## Testing Strategy

The project uses two test layers:

- Swift Testing unit tests in `Georgia Child Support CalculatorTests`.
- XCTest UI tests in `Georgia Child Support CalculatorUITests`.

Unit tests are the primary regression safety net for calculation behavior. They assert intermediate values as well as final payments so regressions cannot hide behind offsetting changes.

UI tests are intentionally lighter right now. They verify launch, the default estimate, and the presence of core controls that are easy to regress while the interface is still moving.

## Current Test Coverage

Current unit coverage includes:

- 2026 Basic Child Support Obligation table fixtures from the statutory PDF.
- 2026 Low-Income Adjustment table fixtures from the statutory PDF.
- Exact and nearest-bracket table lookup behavior.
- The Sharon/Henry-style default scenario using the controlling 2026 PDF value.
- Additional expense allocation and Social Security/VA credit handling.
- Credit overpayment clamping so benefits cannot create a reverse payment.
- Parenting-time formula behavior.
- Parenting schedule presets from the Georgia Parenting Plan day-count examples.
- Parent-name display defaults and trimming.
- Low-income cap application.

Current UI coverage includes:

- App launch.
- Default final estimate of `$1,119`.
- Segmented child-count selector presence.
- Parenting schedule selector presence.
- Reset button presence.

Coverage still needed before production:

- Editing inputs and verifying live recalculation through UI tests.
- Validation UI for invalid or incomplete values.
- Screenshot or snapshot coverage once layouts stabilize.
- More official calculator golden fixtures for cross-checking edge cases.

## Data Notes

The 2026 statutory tables are encoded as Swift data under `Calculation/Tables/`:

- `BasicObligationTableData.swift`
- `LowIncomeAdjustmentTableData.swift`

Representative unit tests check encoded values against PDF-derived fixtures, including boundary and middle rows.

One known source reconciliation: `docs/CALCULATION.md` contains an older Sharon/Henry two-child example value of `$1,877`; the 2026 statutory PDF table controls, and the app uses `$2,052` at combined monthly income of `$11,000`.

## Verification Status

`build-for-testing` currently succeeds in this workspace. Full simulator test execution may require running outside this sandbox if `CoreSimulatorService` is unavailable.
