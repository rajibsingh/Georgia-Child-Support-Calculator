import Foundation
import Testing
@testable import Georgia_Child_Support_Calculator

@MainActor
struct GeorgiaChildSupportCalculatorTests {

    // MARK: - Table lookups

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

    // MARK: - Child support calculator

    @Test func calculatesSimpleEstimateFrom2026Table() throws {
        let result = try ChildSupportCalculator().calculate(baseInput())
        #expect(result.combinedAdjustedGrossIncome == Money(dollars: 11_000))
        #expect(result.tableLookup.obligation == Money(dollars: 2_052))
        #expect(result.finalMonthlyPayment.wholeDollarsRounded == 1119)
        #expect(result.payer == .noncustodial)
    }

    @Test func expensePaidByCPIncreasesNCPObligation() throws {
        var input = baseInput()
        input.childcareAmount = Money(dollars: 400)
        input.childcarePayer = .cp
        let result = try ChildSupportCalculator().calculate(input)
        // NCP owes their pro-rata share (~54.5%) of $400 = ~$218 extra
        #expect(result.additionalExpenseShares.noncustodial > .zero)
        #expect(result.finalMonthlyPayment.wholeDollarsRounded > 1119)
    }

    @Test func expensePaidByNCPDecreasesNCPObligation() throws {
        var input = baseInput()
        input.healthInsuranceAmount = Money(dollars: 400)
        input.healthInsurancePayer = .ncp
        let result = try ChildSupportCalculator().calculate(input)
        // NCP already paying, so their net obligation decreases
        #expect(result.additionalExpenseShares.noncustodial < .zero)
        #expect(result.finalMonthlyPayment.wholeDollarsRounded < 1119)
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
    }

    @Test func appliesLowIncomeCapWhenApplicable() throws {
        let result = try ChildSupportCalculator().calculate(
            CalculationInput(
                numberOfChildren: 1,
                custodialParent: ParentInput(
                    grossMonthlyIncome: Money(dollars: 1_000),
                    selfEmploymentMonthlyIncome: .zero,
                    qualifiedChildren: 0,
                    workRelatedChildCare: .zero,
                    childHealthInsurancePremium: .zero
                ),
                noncustodialParent: ParentInput(
                    grossMonthlyIncome: Money(dollars: 1_500),
                    selfEmploymentMonthlyIncome: .zero,
                    qualifiedChildren: 0,
                    workRelatedChildCare: .zero,
                    childHealthInsurancePremium: .zero
                ),
                parentingTime: .none,
                childcareAmount: .zero,
                childcarePayer: .cp,
                healthInsuranceAmount: .zero,
                healthInsurancePayer: .cp,
                deviations: [],
                socialSecurityChildBenefit: .zero,
                vaDisabilityChildBenefit: .zero
            )
        )
        #expect(result.lowIncomeAdjustment?.cappedAmount == Money(dollars: 285))
        #expect(result.finalMonthlyPayment == Money(dollars: 285))
    }

    // MARK: - Overnight options

    @Test func overnightOptionsMapsToExpectedDayCounts() {
        #expect(OvernightOption.none.overnights == nil)
        #expect(OvernightOption.split182.overnights == Decimal(182))
        #expect(OvernightOption.schedule148.overnights == Decimal(148))
        #expect(OvernightOption.schedule121.overnights == Decimal(121))
        #expect(OvernightOption.schedule102.overnights == Decimal(102))
    }

    @Test func parentingTimeAdjustment148Overnights() throws {
        // NCP $10,000 / CP $6,000 gross monthly, 148 NCP overnights, 1 child
        // Expected: NCP 62.5%, BCSO $2,532, NCP share $1,582.50,
        //           parenting time adjustment $702.72, presumptive support $879.78
        let result = try ChildSupportCalculator().calculate(CalculationInput(
            numberOfChildren: 2,
            custodialParent: ParentInput(
                grossMonthlyIncome: Money(dollars: 6_000),
                selfEmploymentMonthlyIncome: .zero,
                qualifiedChildren: 0,
                workRelatedChildCare: .zero,
                childHealthInsurancePremium: .zero
            ),
            noncustodialParent: ParentInput(
                grossMonthlyIncome: Money(dollars: 10_000),
                selfEmploymentMonthlyIncome: .zero,
                qualifiedChildren: 0,
                workRelatedChildCare: .zero,
                childHealthInsurancePremium: .zero
            ),
            parentingTime: ParentingTimeInput(
                hasCourtOrderedParentingTime: true,
                custodialDays: 217,
                noncustodialDays: 148
            ),
            childcareAmount: .zero,
            childcarePayer: .cp,
            healthInsuranceAmount: .zero,
            healthInsurancePayer: .cp,
            deviations: [],
            socialSecurityChildBenefit: .zero,
            vaDisabilityChildBenefit: .zero
        ))
        // Combined income and BCSO
        #expect(result.combinedAdjustedGrossIncome == Money(dollars: 16_000))
        #expect(result.tableLookup.obligation == Money(dollars: 2_532))
        // NCP share BCSO = 62.5% × $2,532 = $1,582.50
        #expect(result.basicObligationShares.noncustodial == Money(cents: 158_250))
        // Parenting time credit displayed = $702.72
        #expect(result.parentingTimeCredit == Money(cents: 70_272))
        // Post-adjustment NCP obligation = $879.78
        #expect(result.parentingTimeAdjustedNoncustodialAmount == Money(cents: 87_978))
        // Presumptive support = $879.78, big box = $880
        #expect(result.presumptiveSupport == Money(cents: 87_978))
        #expect(result.finalMonthlyPayment.wholeDollarsRounded == 880)
    }

    // MARK: - BallparkDraft

    @Test func ballparkDraftTogglesSETIncome() {
        var draft = BallparkDraft()
        draft.ncpGrossIncome = "6000"
        draft.cpGrossIncome = "5000"
        let noSET = draft.input
        let withSET = draft.inputWithSET(ncpSET: Money(dollars: 2000), cpSET: .zero)
        #expect(noSET.noncustodialParent.selfEmploymentMonthlyIncome == .zero)
        #expect(withSET.noncustodialParent.selfEmploymentMonthlyIncome == Money(dollars: 2000))
    }

    @Test func ballparkDraftIgnoresExpenseWithNoPayerSelected() {
        var draft = BallparkDraft()
        draft.ncpGrossIncome = "6000"
        draft.cpGrossIncome = "5000"
        draft.childcareAmount = "500"
        draft.childcarePayer = nil   // no payer selected → contributes zero
        let input = draft.input
        #expect(input.childcareAmount == .zero)
    }

    // MARK: - Thomas Calculator

    @Test func thomasCalculatorSumsToNetEquity() {
        var draft = ThomasDraft()
        draft.currentMarketValue = "500000"
        draft.currentSecuredDebt = "200000"
        draft.valueAtDOM = "300000"
        draft.securedDebtAtDOM = "250000"
        draft.maritalContributions = "40000"

        guard let result = draft.result else {
            Issue.record("Expected a result but got nil")
            return
        }

        // Non-Marital + Marital must equal CMV − current SD = 300,000
        let sum = result.estimatedNonMaritalValue + result.estimatedMaritalValue
        #expect(sum == result.checkSum)
        #expect(result.checkSum == 300_000)
    }

    @Test func thomasCalculatorAppreicationFormula() {
        var draft = ThomasDraft()
        draft.currentMarketValue = "400000"
        draft.currentSecuredDebt = "100000"
        draft.valueAtDOM = "200000"
        draft.securedDebtAtDOM = "180000"
        draft.maritalContributions = "30000"

        // Appreciation = 400000 - 200000 - 30000 = 170000
        #expect(draft.result?.appreciationDuringMarriage == 170_000)
    }

    // MARK: - Helpers

    private func baseInput() -> CalculationInput {
        CalculationInput(
            numberOfChildren: 2,
            custodialParent: ParentInput(
                grossMonthlyIncome: Money(dollars: 5_000),
                selfEmploymentMonthlyIncome: .zero,
                qualifiedChildren: 0,
                workRelatedChildCare: .zero,
                childHealthInsurancePremium: .zero
            ),
            noncustodialParent: ParentInput(
                grossMonthlyIncome: Money(dollars: 6_000),
                selfEmploymentMonthlyIncome: .zero,
                qualifiedChildren: 0,
                workRelatedChildCare: .zero,
                childHealthInsurancePremium: .zero
            ),
            parentingTime: .none,
            childcareAmount: .zero,
            childcarePayer: .cp,
            healthInsuranceAmount: .zero,
            healthInsurancePayer: .cp,
            deviations: [],
            socialSecurityChildBenefit: .zero,
            vaDisabilityChildBenefit: .zero
        )
    }
}
