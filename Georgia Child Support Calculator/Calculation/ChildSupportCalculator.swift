import Foundation

struct ChildSupportCalculator {
    var obligationTable: ObligationTableProviding = BasicObligationTable()
    var lowIncomeTable: LowIncomeTableProviding = LowIncomeAdjustmentTable()

    func calculate(_ input: CalculationInput) throws -> CalculationResult {
        guard (1...6).contains(input.numberOfChildren) else {
            throw CalculationError.invalidChildCount
        }

        guard input.parentingTime.custodialDays >= 0,
              input.parentingTime.custodialDays <= 365,
              input.parentingTime.noncustodialDays >= 0,
              input.parentingTime.noncustodialDays <= 365 else {
            throw CalculationError.invalidParentingTime
        }

        let adjustedCustodial = adjustedIncome(for: input.custodialParent, children: input.numberOfChildren)
        let adjustedNoncustodial = adjustedIncome(for: input.noncustodialParent, children: input.numberOfChildren)
        let combined = adjustedCustodial + adjustedNoncustodial

        guard combined.cents > 0 else {
            throw CalculationError.combinedIncomeMustBePositive
        }

        let custodialShare = adjustedCustodial.dollarsDecimal / combined.dollarsDecimal
        let noncustodialShare = adjustedNoncustodial.dollarsDecimal / combined.dollarsDecimal
        let lookup = try obligationTable.basicObligation(forCombinedIncome: combined, children: input.numberOfChildren)
        let custodialBasic = lookup.obligation * custodialShare
        let noncustodialBasic = lookup.obligation * noncustodialShare

        let parentingTimeAdjusted = parentingTimeAdjustedAmount(
            custodialBasic: custodialBasic,
            noncustodialBasic: noncustodialBasic,
            parentingTime: input.parentingTime
        )

        let totalAdditionalExpenses = input.custodialParent.workRelatedChildCare
            + input.custodialParent.childHealthInsurancePremium
            + input.noncustodialParent.workRelatedChildCare
            + input.noncustodialParent.childHealthInsurancePremium
        let custodialAdditional = totalAdditionalExpenses * custodialShare
        let noncustodialAdditional = totalAdditionalExpenses * noncustodialShare

        var presumptive = parentingTimeAdjusted + noncustodialAdditional
        let deviationTotal = input.deviations.reduce(Money.zero) { partial, deviation in
            switch deviation.direction {
            case .increase:
                partial + deviation.amount
            case .decrease:
                partial - deviation.amount
            }
        }
        presumptive = presumptive + deviationTotal

        let lowIncomeAdjustment = appliedLowIncomeAdjustment(
            currentAmount: presumptive,
            adjustedIncome: adjustedNoncustodial,
            children: input.numberOfChildren
        )
        let afterLowIncome = lowIncomeAdjustment?.cappedAmount ?? presumptive
        let credits = AppliedCredits(
            socialSecurity: input.socialSecurityChildBenefit,
            vaDisability: input.vaDisabilityChildBenefit
        )
        let creditedAmount = afterLowIncome.cents >= 0
            ? max(afterLowIncome - credits.total, .zero)
            : afterLowIncome
        let payer: ParentRole = creditedAmount.cents >= 0 ? .noncustodial : .custodial
        let finalPayment = creditedAmount.cents >= 0 ? creditedAmount : -creditedAmount

        return CalculationResult(
            adjustedIncome: ParentPair(custodial: adjustedCustodial, noncustodial: adjustedNoncustodial),
            combinedAdjustedGrossIncome: combined,
            proRataShares: ParentPair(custodial: custodialShare, noncustodial: noncustodialShare),
            tableLookup: lookup,
            basicObligationShares: ParentPair(custodial: custodialBasic, noncustodial: noncustodialBasic),
            parentingTimeAdjustedNoncustodialAmount: parentingTimeAdjusted,
            additionalExpenseShares: ParentPair(custodial: custodialAdditional, noncustodial: noncustodialAdditional),
            presumptiveSupport: presumptive,
            deviationTotal: deviationTotal,
            lowIncomeAdjustment: lowIncomeAdjustment,
            credits: credits,
            payer: payer,
            finalMonthlyPayment: finalPayment,
            uninsuredHealthcareShares: ParentPair(custodial: custodialShare, noncustodial: noncustodialShare),
            trace: trace(
                lookup: lookup,
                combined: combined,
                custodialShare: custodialShare,
                noncustodialShare: noncustodialShare,
                parentingTimeAdjusted: parentingTimeAdjusted,
                finalPayment: finalPayment
            )
        )
    }

    private func adjustedIncome(for parent: ParentInput, children: Int) -> Money {
        let selfEmploymentDeduction = parent.selfEmploymentMonthlyIncome * Decimal(string: "0.0765")!
        let theoretical = theoreticalSupportCredit(for: parent, children: children)
        let adjusted = parent.grossMonthlyIncome - selfEmploymentDeduction - parent.preexistingOrdersActuallyPaid - theoretical
        return max(adjusted, .zero)
    }

    private func theoreticalSupportCredit(for parent: ParentInput, children: Int) -> Money {
        guard parent.qualifiedChildren > 0,
              let lookup = try? obligationTable.basicObligation(
                forCombinedIncome: parent.grossMonthlyIncome,
                children: min(parent.qualifiedChildren, 6)
              ) else {
            return .zero
        }
        return lookup.obligation * Decimal(string: "0.75")!
    }

    private func parentingTimeAdjustedAmount(
        custodialBasic: Money,
        noncustodialBasic: Money,
        parentingTime: ParentingTimeInput
    ) -> Money {
        guard parentingTime.hasCourtOrderedParentingTime else {
            return noncustodialBasic
        }

        let custodialDays = max(0, NSDecimalNumber(decimal: parentingTime.custodialDays).doubleValue)
        let noncustodialDays = max(0, NSDecimalNumber(decimal: parentingTime.noncustodialDays).doubleValue)
        let denominator = pow(noncustodialDays, 2.5) + pow(custodialDays, 2.5)
        guard denominator > 0 else {
            return noncustodialBasic
        }

        let termA = pow(noncustodialDays, 2.5) * NSDecimalNumber(decimal: custodialBasic.dollarsDecimal).doubleValue
        let termB = pow(custodialDays, 2.5) * NSDecimalNumber(decimal: noncustodialBasic.dollarsDecimal).doubleValue
        let delta = (termA - termB) / denominator
        return Money(decimalDollars: noncustodialBasic.dollarsDecimal + Decimal(delta))
    }

    private func appliedLowIncomeAdjustment(
        currentAmount: Money,
        adjustedIncome: Money,
        children: Int
    ) -> AppliedLowIncomeAdjustment? {
        guard let cap = lowIncomeTable.lowIncomeCap(forAdjustedIncome: adjustedIncome, children: children),
              cap < currentAmount else {
            return nil
        }

        return AppliedLowIncomeAdjustment(originalAmount: currentAmount, cappedAmount: cap)
    }

    private func trace(
        lookup: BasicObligationLookupResult,
        combined: Money,
        custodialShare: Decimal,
        noncustodialShare: Decimal,
        parentingTimeAdjusted: Money,
        finalPayment: Money
    ) -> [CalculationStep] {
        [
            CalculationStep(title: "Combined adjusted income", value: combined.formatted()),
            CalculationStep(title: "Table row used", value: lookup.matchedIncome.formatted()),
            CalculationStep(title: "Basic obligation", value: lookup.obligation.formatted()),
            CalculationStep(title: "Custodial share", value: percent(custodialShare)),
            CalculationStep(title: "Noncustodial share", value: percent(noncustodialShare)),
            CalculationStep(title: "Parenting-time adjusted amount", value: parentingTimeAdjusted.formatted()),
            CalculationStep(title: "Estimated monthly payment", value: finalPayment.formatted())
        ]
    }
}

func percent(_ decimal: Decimal) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 1
    return formatter.string(from: NSDecimalNumber(decimal: decimal)) ?? "\(decimal)"
}
