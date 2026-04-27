import Foundation

struct CalculationInput: Equatable {
    var numberOfChildren: Int
    var custodialParent: ParentInput
    var noncustodialParent: ParentInput
    var parentingTime: ParentingTimeInput
    var deviations: [DeviationInput]
    var socialSecurityChildBenefit: Money
    var vaDisabilityChildBenefit: Money
}

struct ParentInput: Equatable {
    var grossMonthlyIncome: Money
    var selfEmploymentMonthlyIncome: Money
    var preexistingOrdersActuallyPaid: Money
    var qualifiedChildren: Int
    var workRelatedChildCare: Money
    var childHealthInsurancePremium: Money

    static let empty = ParentInput(
        grossMonthlyIncome: .zero,
        selfEmploymentMonthlyIncome: .zero,
        preexistingOrdersActuallyPaid: .zero,
        qualifiedChildren: 0,
        workRelatedChildCare: .zero,
        childHealthInsurancePremium: .zero
    )
}

struct ParentingTimeInput: Equatable {
    var hasCourtOrderedParentingTime: Bool
    var custodialDays: Decimal
    var noncustodialDays: Decimal

    static let none = ParentingTimeInput(
        hasCourtOrderedParentingTime: false,
        custodialDays: 365,
        noncustodialDays: 0
    )
}

struct DeviationInput: Identifiable, Equatable {
    enum Direction: String, CaseIterable, Identifiable {
        case increase
        case decrease

        var id: String { rawValue }
    }

    var id = UUID()
    var label: String
    var amount: Money
    var direction: Direction
}

