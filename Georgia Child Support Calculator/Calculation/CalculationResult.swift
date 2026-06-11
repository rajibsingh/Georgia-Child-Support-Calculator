import Foundation

struct CalculationResult: Equatable {
    var adjustedIncome: ParentPair<Money>
    var combinedAdjustedGrossIncome: Money
    var proRataShares: ParentPair<Decimal>
    var tableLookup: BasicObligationLookupResult
    var basicObligationShares: ParentPair<Money>
    var parentingTimeAdjustedNoncustodialAmount: Money
    var additionalExpenseShares: ParentPair<Money>
    /// Raw Sch D expenses paid by each parent (childcare + health insurance), before pro-rata allocation.
    var scheduleDExpenses: ParentPair<Money>
    var presumptiveSupport: Money
    var deviationTotal: Money
    var lowIncomeAdjustment: AppliedLowIncomeAdjustment?
    var credits: AppliedCredits
    var payer: ParentRole
    var finalMonthlyPayment: Money
    var uninsuredHealthcareShares: ParentPair<Decimal>
    var trace: [CalculationStep]

    /// The parenting-time credit: how much was subtracted from NCP's BCSO share (positive number for display).
    var parentingTimeCredit: Money {
        let credit = basicObligationShares.noncustodial - parentingTimeAdjustedNoncustodialAmount
        return credit.cents > 0 ? credit : .zero
    }
}

struct AppliedLowIncomeAdjustment: Equatable {
    var originalAmount: Money
    var cappedAmount: Money
}

struct AppliedCredits: Equatable {
    var socialSecurity: Money
    var vaDisability: Money
    var total: Money { socialSecurity + vaDisability }
}

struct CalculationStep: Identifiable, Equatable {
    var id: String { group + title }
    var group: String
    var title: String
    var value: String
    var detail: String?
}

enum CalculationError: LocalizedError, Equatable {
    case invalidChildCount
    case combinedIncomeMustBePositive
    case invalidParentingTime
    case tableLookupFailed

    var errorDescription: String? {
        switch self {
        case .invalidChildCount:
            "Enter a child count from 1 through 6."
        case .combinedIncomeMustBePositive:
            "Combined adjusted monthly income must be greater than zero."
        case .invalidParentingTime:
            "Parenting time days must be between 0 and 365."
        case .tableLookupFailed:
            "The support table could not find a matching row."
        }
    }
}

