# Intown Mediation Child Support Calculator Requirements

## Purpose

Build an Intown Mediation-branded iOS app that helps Georgia parents estimate guideline child support under O.C.G.A. § 19-6-15, current through the 2025 Regular Session and reflected in `docs/O.C.G.A.-_-19-6-15_01.01.2026.pdf`. The app should make the calculation understandable, repeatable, and easy to sanity check, while clearly communicating that only a court can enter a binding support order.

The simplified flow in `docs/CALCULATION.md` is the onboarding model for users. The statute is the controlling source when the simplified guide omits detail or conflicts with the statute.

## Product Scope

The first production version shall support a standard two-parent Georgia child support estimate for one to six children, including all 2026 guideline adjustments:

- Monthly gross income collection for both parents.
- Adjusted income deductions for applicable self-employment taxes, preexisting current child support orders actually paid, and optional theoretical child support orders for other qualified children.
- Combined adjusted gross income and each parent's pro rata percentage.
- Basic child support obligation lookup from the statutory table.
- 2026 parenting time adjustment using court ordered parenting time.
- Work related child care and child health insurance premium allocation.
- Presumptive child support amount.
- Optional deviations, low-income adjustment, and credits for qualifying Social Security or VA disability payments.
- Final payer determination and monthly estimated payment.
- Allocation percentages for future uninsured healthcare expenses.

The app shall not generate legal filings, replace the official Georgia calculator, or present estimates as legal advice.

The app shall be branded primarily for Intown Mediation. "Georgia child support calculator" may appear as a descriptive product category or subtitle, but the trusted source and visual identity should be Intown Mediation.

## Calculation Requirements

### Inputs

The app shall collect the following case-level inputs:

- Number of children whose support is being calculated, limited to 1 through 6 for table lookup.
- Custody arrangement sufficient to identify the custodial and noncustodial parent under O.C.G.A. § 19-6-15(a)(9) and (a)(14).
- Court ordered parenting time for each parent, expressed as annual average days. Days may be overnights or recurring daytime hours divided by 24.
- Whether there is a court order awarding parenting time. The parenting time adjustment applies only when such an order exists.

The app shall collect the following parent-level inputs:

- Monthly gross income from all included sources.
- Self-employment income, when applicable.
- Preexisting current child support orders and evidence-ready monthly amount actually paid.
- Other qualified children living in the parent's home, when the user wants to model a theoretical child support order.
- Work related child care paid by that parent or a nonparent custodian.
- Child health insurance premium paid by that parent or a nonparent custodian.
- Optional deviation amounts and reason categories.
- Social Security Title II child benefit received on the noncustodial parent's account.
- VA disability child benefit received on the noncustodial parent's account.

The UI shall progressively disclose advanced inputs. Core income, child count, custody, and parenting time fields should be visible in the main flow. Less common adjustments, deviations, and credits should be collapsed, minimized, or presented as optional sections so the calculator remains simple for standard cases.

### Income

Gross income shall include all statutory sources before taxes and ordinary deductions, including wages, commissions, self-employment income, bonuses, overtime, severance, recurring retirement income, interest, dividends, trust income, annuities, capital gains, Social Security Title II disability or retirement benefits, VA disability benefits, workers' compensation, unemployment benefits, personal injury recoveries, gifts convertible to cash, prizes, lottery winnings, alimony from non-parties, family-supporting assets, and other income.

Gross income shall exclude child support received for another relationship, means-tested public assistance, SSI, certain disabled adult child Social Security benefits, foster care payments, nonparent custodian income, and adoption assistance.

Variable income shall be modeled as an averaged monthly amount over a user-selected reasonable period. The app shall store both the averaged amount and the period notes for transparency.

Self-employment income shall be modeled as gross receipts minus ordinary and reasonable business expenses required to produce income. The app shall not assume tax return net income is automatically the child support income amount.

### Adjusted Income

Adjusted monthly gross income shall deduct, when applicable:

- One-half of self-employment and Medicare taxes calculated from self-employment income.
- Preexisting current child support orders actually paid, capped at the average current support actually paid over the prior 12 months or the life of the order if shorter.
- Theoretical child support orders for other qualified children, when allowed by the court or modeled by the user.

Theoretical child support orders shall be calculated from the parent's monthly gross income, using only the self-employment tax adjustment, then multiplied by 75 percent before subtracting from that parent's monthly gross income.

When multiple family adjustments exist, preexisting orders shall be applied before theoretical child support order credits.

### Basic Child Support Obligation

The app shall add both parents' adjusted monthly gross incomes to calculate combined adjusted gross income.

The app shall locate the basic child support obligation in the statutory table for the combined adjusted gross income and child count. If income falls between table rows, the app shall use the income bracket most closely matched to the combined adjusted gross income. This follows the statute and supersedes the simplified document's "round down" instruction.

For combined adjusted gross income above $40,000 per month, the app shall use the highest table amount and flag the case as a possible high-income upward deviation scenario.

### Pro Rata Shares

Each parent's pro rata percentage shall equal that parent's adjusted monthly gross income divided by combined adjusted gross income.

Each parent's basic obligation shall equal the basic child support obligation multiplied by that parent's pro rata percentage.

The app shall handle zero or negative adjusted income defensively by blocking final calculation until the inputs can produce a valid combined adjusted gross income greater than zero.

### Parenting Time Adjustment

When there is a court ordered parenting time arrangement, the app shall calculate the noncustodial parent's parenting time adjusted basic obligation as:

```text
noncustodialDaysPower = noncustodialDays ^ 2.5
custodialDaysPower = custodialDays ^ 2.5
termA = noncustodialDaysPower * custodialBasicShare
termB = custodialDaysPower * noncustodialBasicShare
adjustmentDelta = (termA - termB) / (noncustodialDaysPower + custodialDaysPower)
parentingTimeAdjustedAmount = noncustodialBasicShare + adjustmentDelta
```

For multiple children with different court ordered parenting time, the app shall use the average number of court ordered days. For split parenting, future support shall require separate worksheets per custodial parent.

If there is no court ordered parenting time, the app shall skip this adjustment and use the noncustodial parent's basic share.

### Additional Expenses

The app shall add work related child care costs and child health insurance premiums as additional expenses, prorated by each parent's pro rata income share.

Only the amount actually paid for child care after means-tested subsidies shall be included.

If the child is covered by a family health insurance policy and the child-specific premium is not verifiable, the app shall prorate the premium by covered persons and multiply by the number of children in the current support case who are covered.

Future uninsured healthcare expenses shall not change the monthly child support amount. The app shall display each parent's pro rata responsibility unless the user enters a court-ordered alternative.

### Deviations

The app shall support user-entered deviations as transparent adjustments with a category, amount, direction, and note. Categories shall include high income, other health related insurance, life insurance, child and dependent care tax credit, travel expenses, alimony, mortgage, permanency or foster care plan, extraordinary educational expenses, special child-rearing expenses, extraordinary medical expenses, and nonspecific deviations.

The app shall explain that deviations require court findings and best-interest analysis. It shall not automatically recommend discretionary deviations, except for clear statutory prompts such as high income above the table maximum.

### Low-Income Adjustment

When a parent's monthly adjusted gross income and child count are within the low-income adjustment table, the app shall compare that parent's current presumptive amount after deviations with the table amount and use the lesser amount.

The statutory low-income table shall be represented as versioned app data and covered by fixture tests.

### Social Security and VA Credits

Qualifying Social Security Title II benefits paid to the child on the noncustodial parent's account shall be applied against the noncustodial parent's final child support amount.

Qualifying VA disability benefits paid to the child on the noncustodial parent's account shall be applied against the noncustodial parent's final child support amount.

If either benefit equals or exceeds the applicable support amount, the noncustodial parent's remaining payment shall be zero. Excess benefits shall not reduce arrears or otherwise create a negative payment.

### Payer Determination

If the noncustodial parent's final obligation is positive, the noncustodial parent is the payer.

If the noncustodial parent's final obligation is negative after all worksheet schedules, the custodial parent is the payer and the payment amount is the positive equivalent of that negative amount.

## User Experience Requirements

The first screen shall be the calculator workflow, not a marketing landing page.

The app shall guide users through a compact, reviewable worksheet flow:

- Case setup.
- Parent income.
- Adjustments.
- Parenting time.
- Additional expenses.
- Deviations and credits.
- Results.

Each step shall show live validation and concise help text for legal terms. Help text shall clarify the data being requested without crowding the workflow.

The results view shall show:

- Estimated monthly payment and payer.
- Combined adjusted gross income.
- Basic child support obligation table row used.
- Each parent's pro rata share.
- Parenting time adjustment, if applied.
- Additional expense allocation.
- Deviations, low-income adjustment, and credits.
- Future uninsured healthcare allocation.
- A clear disclaimer that the result is an estimate, not legal advice or a court order.

The app shall not support saved scenarios in the first release. Saved local scenarios and scenario comparison should be tracked as future work. Cloud sync, account creation, and document generation are also out of scope for the first release unless added later.

## Data Requirements

The app shall store statutory tables as versioned, testable data files:

- Basic Child Support Obligation Table from O.C.G.A. § 19-6-15(o).
- Low-Income Adjustment Table from O.C.G.A. § 19-6-15(p).

Each data file shall include:

- Effective date.
- Source citation.
- Maximum child count.
- Income brackets.
- Values as integer cents or whole dollars, consistently documented.

The app shall avoid floating-point money calculations for final dollar amounts. Use `Decimal` or integer cents in the domain model.

The full 2026 support tables shall be encoded from `docs/O.C.G.A.-_-19-6-15_01.01.2026.pdf` into the format that best supports deterministic lookup and review, likely JSON or generated Swift data. The conversion process shall be documented and reproducible enough that future table updates can be audited.

## Testing Requirements

The codebase already contains Xcode unit and UI test targets. Development shall keep both targets active and make them meaningful before calculation work expands.

Unit tests shall cover:

- Gross income inclusion and exclusion helpers.
- Self-employment tax adjustment.
- Preexisting order adjustment caps.
- Theoretical child support order calculation.
- Basic obligation lookup, including exact rows, between-row nearest matching, below-minimum, and above-maximum behavior.
- Converted Basic Child Support Obligation Table data checked against values extracted from the statutory PDF.
- Converted Low-Income Adjustment Table data checked against values extracted from the statutory PDF.
- Pro rata share calculations and rounding behavior.
- Parenting time adjustment formula.
- Additional expense allocation.
- Deviation application.
- Low-income adjustment comparison.
- Social Security and VA credit handling.
- Final payer determination.
- Fixture tests for examples from `docs/CALCULATION.md`, including the Sharon and Henry scenario.

UI tests shall cover:

- Launch and initial calculator screen availability.
- Completing a simple two-parent scenario.
- Editing an input and verifying the result updates.
- Validation for invalid income, child count, and missing custody inputs.
- Accessibility identifiers for all form controls needed by UI automation.

Snapshot or screenshot regression tests should be added once the main calculator UI stabilizes.

Every calculation behavior that maps to a statutory table or formula shall have at least one regression test before it is exposed in the UI.

Table conversion tests shall compare representative and boundary rows from the app's encoded data against the PDF-derived source values. These tests should include the first row, last row, several middle rows, all child-count columns, and low-income table boundaries.

## Nonfunctional Requirements

The app shall run fully on device with no network requirement for calculations.

The app shall be privacy-first: user-entered family and income data shall stay local unless the user explicitly exports it in a future feature.

The app shall use native iOS fonts, accessible SwiftUI controls, Dynamic Type, VoiceOver labels, and clear currency formatting.

The app shall format currency and percentages consistently using U.S. locale conventions.

The calculation engine shall be deterministic: the same inputs, table version, and rounding policy shall always produce the same result.

## Open Questions

- Whether to include official Georgia worksheet export in a later release.
- Whether to support nonparent custodian scenarios in the first release or reserve them for a second phase.
- Whether split parenting should be implemented in the first release or documented as a manual/court worksheet scenario.
- Which official Georgia calculator outputs should become golden fixtures for cross-checking.
- Whether future saved scenarios should be local-only or include export/share workflows.
