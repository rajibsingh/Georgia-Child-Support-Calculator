import Foundation
import Testing
@testable import Georgia_Child_Support_Calculator

struct GeorgiaChildSupportCalculatorTests {
    @Test func looksUpPdfConvertedBasicObligationRows() throws {
        let table = BasicObligationTable()

        let first = try table.basicObligation(forCombinedIncome: Money(dollars: 800), children: 1)
        #expect(first.obligation == Money(dollars: 170))
        #expect(first.matchKind == .exact)

        let sharonHenry = try table.basicObligation(forCombinedIncome: Money(dollars: 11_000), children: 2)
        #expect(sharonHenry.obligation == Money(dollars: 2_052))

        let last = try table.basicObligation(forCombinedIncome: Money(dollars: 40_000), children: 6)
        #expect(last.obligation == Money(dollars: 7_375))
        #expect(last.matchKind == .exact)
    }

    @Test func usesNearestBracketForBetweenRowIncome() throws {
        let table = BasicObligationTable()

        let lower = try table.basicObligation(forCombinedIncome: Money(dollars: 10_024), children: 2)
        #expect(lower.matchedIncome == Money(dollars: 10_000))
        #expect(lower.matchKind == .nearest)

        let upper = try table.basicObligation(forCombinedIncome: Money(dollars: 10_026), children: 2)
        #expect(upper.matchedIncome == Money(dollars: 10_050))
        #expect(upper.matchKind == .nearest)
    }

    @Test func looksUpPdfConvertedLowIncomeRows() {
        let table = LowIncomeAdjustmentTable()

        #expect(table.lowIncomeCap(forAdjustedIncome: Money(dollars: 1_500), children: 1) == Money(dollars: 285))
        #expect(table.lowIncomeCap(forAdjustedIncome: Money(dollars: 1_600), children: 2) == Money(dollars: 389))
        #expect(table.lowIncomeCap(forAdjustedIncome: Money(dollars: 1_575), children: 2) == Money(dollars: 389))
        #expect(table.lowIncomeCap(forAdjustedIncome: Money(dollars: 3_950), children: 6) == Money(dollars: 1_774))
        #expect(table.lowIncomeCap(forAdjustedIncome: Money(dollars: 2_500), children: 1) == nil)
    }

    @Test func calculatesSimpleGuidelineEstimateFrom2026Table() throws {
        let result = try ChildSupportCalculator().calculate(
            CalculationInput(
                numberOfChildren: 2,
                custodialParent: ParentInput(
                    grossMonthlyIncome: Money(dollars: 5_000),
                    selfEmploymentMonthlyIncome: .zero,
                    preexistingOrdersActuallyPaid: .zero,
                    qualifiedChildren: 0,
                    workRelatedChildCare: .zero,
                    childHealthInsurancePremium: .zero
                ),
                noncustodialParent: ParentInput(
                    grossMonthlyIncome: Money(dollars: 6_000),
                    selfEmploymentMonthlyIncome: .zero,
                    preexistingOrdersActuallyPaid: .zero,
                    qualifiedChildren: 0,
                    workRelatedChildCare: .zero,
                    childHealthInsurancePremium: .zero
                ),
                parentingTime: .none,
                deviations: [],
                socialSecurityChildBenefit: .zero,
                vaDisabilityChildBenefit: .zero
            )
        )

        #expect(result.combinedAdjustedGrossIncome == Money(dollars: 11_000))
        #expect(result.tableLookup.obligation == Money(dollars: 2_052))
        #expect(result.finalMonthlyPayment.wholeDollarsRounded == 1119)
        #expect(result.payer == .noncustodial)
    }

    @Test func appliesAdditionalExpensesAndCredits() throws {
        var input = baseInput()
        input.custodialParent.workRelatedChildCare = Money(dollars: 400)
        input.noncustodialParent.childHealthInsurancePremium = Money(dollars: 200)
        input.socialSecurityChildBenefit = Money(dollars: 100)
        input.vaDisabilityChildBenefit = Money(dollars: 50)

        let result = try ChildSupportCalculator().calculate(input)

        #expect(result.additionalExpenseShares.noncustodial.wholeDollarsRounded == 327)
        #expect(result.credits.total == Money(dollars: 150))
        #expect(result.finalMonthlyPayment.wholeDollarsRounded == 1296)
    }

    @Test func creditsCannotCreateReversePayment() throws {
        var input = baseInput()
        input.socialSecurityChildBenefit = Money(dollars: 2_000)

        let result = try ChildSupportCalculator().calculate(input)

        #expect(result.credits.total == Money(dollars: 2_000))
        #expect(result.finalMonthlyPayment == .zero)
        #expect(result.payer == .noncustodial)
    }

    @Test func appliesParentingTimeAdjustmentWhenCourtOrdered() throws {
        var input = baseInput()
        input.parentingTime = ParentingTimeInput(
            hasCourtOrderedParentingTime: true,
            custodialDays: 265,
            noncustodialDays: 100
        )

        let result = try ChildSupportCalculator().calculate(input)

        #expect(result.parentingTimeAdjustedNoncustodialAmount < result.basicObligationShares.noncustodial)
        #expect(result.finalMonthlyPayment < result.basicObligationShares.noncustodial)
    }

    @Test func appliesLowIncomeCapWhenApplicable() throws {
        let result = try ChildSupportCalculator().calculate(
            CalculationInput(
                numberOfChildren: 1,
                custodialParent: ParentInput(
                    grossMonthlyIncome: Money(dollars: 1_000),
                    selfEmploymentMonthlyIncome: .zero,
                    preexistingOrdersActuallyPaid: .zero,
                    qualifiedChildren: 0,
                    workRelatedChildCare: .zero,
                    childHealthInsurancePremium: .zero
                ),
                noncustodialParent: ParentInput(
                    grossMonthlyIncome: Money(dollars: 1_500),
                    selfEmploymentMonthlyIncome: .zero,
                    preexistingOrdersActuallyPaid: .zero,
                    qualifiedChildren: 0,
                    workRelatedChildCare: .zero,
                    childHealthInsurancePremium: .zero
                ),
                parentingTime: .none,
                deviations: [],
                socialSecurityChildBenefit: .zero,
                vaDisabilityChildBenefit: .zero
            )
        )

        #expect(result.lowIncomeAdjustment?.cappedAmount == Money(dollars: 285))
        #expect(result.finalMonthlyPayment == Money(dollars: 285))
    }

    private func baseInput() -> CalculationInput {
        CalculationInput(
            numberOfChildren: 2,
            custodialParent: ParentInput(
                grossMonthlyIncome: Money(dollars: 5_000),
                selfEmploymentMonthlyIncome: .zero,
                preexistingOrdersActuallyPaid: .zero,
                qualifiedChildren: 0,
                workRelatedChildCare: .zero,
                childHealthInsurancePremium: .zero
            ),
            noncustodialParent: ParentInput(
                grossMonthlyIncome: Money(dollars: 6_000),
                selfEmploymentMonthlyIncome: .zero,
                preexistingOrdersActuallyPaid: .zero,
                qualifiedChildren: 0,
                workRelatedChildCare: .zero,
                childHealthInsurancePremium: .zero
            ),
            parentingTime: .none,
            deviations: [],
            socialSecurityChildBenefit: .zero,
            vaDisabilityChildBenefit: .zero
        )
    }
}
