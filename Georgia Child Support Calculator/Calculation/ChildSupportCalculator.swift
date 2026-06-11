import Foundation

// MARK: - Calculation constants (fix #3 — defined once, no repeated string parsing)

private enum CalculationConstants {
    /// One-half of self-employment FICA rate used to compute the SE income deduction
    /// per O.C.G.A. § 19-6-15(f)(1)(B).
    static let selfEmploymentTaxRate: Decimal = Decimal(765) / Decimal(10_000)   // 0.0765

    /// Fraction of a parent's basic obligation used as the theoretical support credit
    /// for other qualified children per O.C.G.A. § 19-6-15(f)(4).
    static let theoreticalSupportFraction: Decimal = Decimal(3) / Decimal(4)     // 0.75
}

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

        let cpPaidExpenses: Money = (input.childcarePayer == .cp ? input.childcareAmount : .zero)
            + (input.healthInsurancePayer == .cp ? input.healthInsuranceAmount : .zero)
        let ncpPaidExpenses: Money = (input.childcarePayer == .ncp ? input.childcareAmount : .zero)
            + (input.healthInsurancePayer == .ncp ? input.healthInsuranceAmount : .zero)
        let noncustodialAdditional = cpPaidExpenses * noncustodialShare - ncpPaidExpenses * custodialShare
        let custodialAdditional = ncpPaidExpenses * custodialShare - cpPaidExpenses * noncustodialShare

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
            scheduleDExpenses: ParentPair(custodial: cpPaidExpenses, noncustodial: ncpPaidExpenses),
            presumptiveSupport: presumptive,
            deviationTotal: deviationTotal,
            lowIncomeAdjustment: lowIncomeAdjustment,
            credits: credits,
            payer: payer,
            finalMonthlyPayment: finalPayment,
            uninsuredHealthcareShares: ParentPair(custodial: custodialShare, noncustodial: noncustodialShare),
            trace: trace(
                input: input,
                adjustedCustodial: adjustedCustodial,
                adjustedNoncustodial: adjustedNoncustodial,
                lookup: lookup,
                combined: combined,
                custodialShare: custodialShare,
                noncustodialShare: noncustodialShare,
                custodialBasic: custodialBasic,
                noncustodialBasic: noncustodialBasic,
                parentingTimeAdjusted: parentingTimeAdjusted,
                cpPaidExpenses: cpPaidExpenses,
                ncpPaidExpenses: ncpPaidExpenses,
                noncustodialAdditional: noncustodialAdditional,
                deviationTotal: deviationTotal,
                presumptive: presumptive,
                lowIncomeAdjustment: lowIncomeAdjustment,
                credits: credits,
                finalPayment: finalPayment
            )
        )
    }

    private func adjustedIncome(for parent: ParentInput, children: Int) -> Money {
        let selfEmploymentDeduction = parent.selfEmploymentMonthlyIncome * CalculationConstants.selfEmploymentTaxRate
        let theoretical = theoreticalSupportCredit(for: parent, children: children)
        let adjusted = parent.grossMonthlyIncome - selfEmploymentDeduction - theoretical
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
        return lookup.obligation * CalculationConstants.theoreticalSupportFraction
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
        // Per O.C.G.A. § 19-6-15(g)(2): delta = (termA − termB) / denominator.
        // Delta is negative when NCP has fewer overnights than CP; its negation is the
        // post-adjustment NCP obligation (NCP's BCSO share minus the parenting-time credit).
        let delta = (termA - termB) / denominator
        return Money(decimalDollars: Decimal(max(-delta, 0)))
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
        input: CalculationInput,
        adjustedCustodial: Money,
        adjustedNoncustodial: Money,
        lookup: BasicObligationLookupResult,
        combined: Money,
        custodialShare: Decimal,
        noncustodialShare: Decimal,
        custodialBasic: Money,
        noncustodialBasic: Money,
        parentingTimeAdjusted: Money,
        cpPaidExpenses: Money,
        ncpPaidExpenses: Money,
        noncustodialAdditional: Money,
        deviationTotal: Money,
        presumptive: Money,
        lowIncomeAdjustment: AppliedLowIncomeAdjustment?,
        credits: AppliedCredits,
        finalPayment: Money
    ) -> [CalculationStep] {
        var steps: [CalculationStep] = []

        func step(_ group: String, _ title: String, _ value: String, detail: String? = nil) {
            steps.append(CalculationStep(group: group, title: title, value: value, detail: detail))
        }

        // Inputs
        let g0 = "Inputs"
        step(g0, "Children", "\(input.numberOfChildren)")
        step(g0, "NCP gross monthly income", input.noncustodialParent.grossMonthlyIncome.formatted())
        step(g0, "CP gross monthly income", input.custodialParent.grossMonthlyIncome.formatted())
        if input.noncustodialParent.selfEmploymentMonthlyIncome.cents > 0 {
            step(g0, "NCP self-employment income", input.noncustodialParent.selfEmploymentMonthlyIncome.formatted())
        }
        if input.custodialParent.selfEmploymentMonthlyIncome.cents > 0 {
            step(g0, "CP self-employment income", input.custodialParent.selfEmploymentMonthlyIncome.formatted())
        }
        if input.noncustodialParent.qualifiedChildren > 0 {
            step(g0, "NCP qualified other children", "\(input.noncustodialParent.qualifiedChildren)")
        }
        if input.custodialParent.qualifiedChildren > 0 {
            step(g0, "CP qualified other children", "\(input.custodialParent.qualifiedChildren)")
        }

        // Adjusted incomes
        let g1 = "Adjusted Gross Income"
        let ncpSEDed = input.noncustodialParent.selfEmploymentMonthlyIncome * CalculationConstants.selfEmploymentTaxRate
        let cpSEDed = input.custodialParent.selfEmploymentMonthlyIncome * CalculationConstants.selfEmploymentTaxRate
        if ncpSEDed.cents > 0 {
            step(g1, "NCP SE deduction (7.65%)", ncpSEDed.formatted(), detail: "½ of SE tax withheld from NCP self-employment income")
        }
        if cpSEDed.cents > 0 {
            step(g1, "CP SE deduction (7.65%)", cpSEDed.formatted(), detail: "½ of SE tax withheld from CP self-employment income")
        }
        step(g1, "NCP adjusted gross income", adjustedNoncustodial.formatted(), detail: "Gross − SE deduction − theoretical support credit")
        step(g1, "CP adjusted gross income", adjustedCustodial.formatted(), detail: "Gross − SE deduction − theoretical support credit")
        step(g1, "Combined adjusted gross income", combined.formatted())

        // Table lookup
        let g2 = "Basic Child Support Obligation (BCSO)"
        let matchNote: String
        switch lookup.matchKind {
        case .exact: matchNote = "exact match"
        case .nearest: matchNote = "nearest row (interpolated)"
        case .belowRange: matchNote = "below table range — using lowest row"
        case .aboveRange: matchNote = "above table range — using highest row"
        }
        step(g2, "Requested combined income", lookup.requestedIncome.formatted())
        step(g2, "Table row matched", lookup.matchedIncome.formatted(), detail: matchNote)
        step(g2, "Combined BCSO from table", lookup.obligation.formatted(), detail: "Row obligation for \(input.numberOfChildren) child\(input.numberOfChildren == 1 ? "" : "ren")")

        // Pro-rata shares
        let g3 = "Pro-Rata Shares"
        step(g3, "NCP pro-rata share", percent(noncustodialShare), detail: "NCP adjusted income ÷ combined adjusted income")
        step(g3, "CP pro-rata share", percent(custodialShare), detail: "CP adjusted income ÷ combined adjusted income")
        step(g3, "NCP basic obligation share", noncustodialBasic.formatted(), detail: "Combined BCSO × NCP share")
        step(g3, "CP basic obligation share", custodialBasic.formatted(), detail: "Combined BCSO × CP share")

        // Parenting time
        let g4 = "Parenting-Time Adjustment"
        if input.parentingTime.hasCourtOrderedParentingTime {
            let ncpDays = input.parentingTime.noncustodialDays
            let cpDays = input.parentingTime.custodialDays
            step(g4, "NCP overnights", "\(ncpDays)")
            step(g4, "CP overnights", "\(cpDays)")
            step(g4, "Parenting-time adjusted amount", parentingTimeAdjusted.formatted(),
                 detail: "Georgia non-linear formula: −(NCP_days^2.5 × CP_basic − CP_days^2.5 × NCP_basic) ÷ (NCP^2.5 + CP^2.5)")
        } else {
            step(g4, "Parenting-time adjustment", "None", detail: "No court-ordered parenting time; NCP pays full basic share")
            step(g4, "NCP obligation after parenting time", parentingTimeAdjusted.formatted())
        }

        // Expenses
        let g5 = "Additional Expenses"
        if input.childcareAmount.cents > 0 {
            step(g5, "Work-related childcare", input.childcareAmount.formatted(), detail: "Paid by \(input.childcarePayer.label)")
        }
        if input.healthInsuranceAmount.cents > 0 {
            step(g5, "Child health insurance premium", input.healthInsuranceAmount.formatted(), detail: "Paid by \(input.healthInsurancePayer.label)")
        }
        if cpPaidExpenses.cents > 0 {
            step(g5, "Total expenses paid by CP", cpPaidExpenses.formatted())
            step(g5, "NCP's share of CP-paid expenses", (cpPaidExpenses * noncustodialShare).formatted(), detail: "CP-paid expenses × NCP share")
        }
        if ncpPaidExpenses.cents > 0 {
            step(g5, "Total expenses paid by NCP", ncpPaidExpenses.formatted())
            step(g5, "CP's share of NCP-paid expenses", (ncpPaidExpenses * custodialShare).formatted(), detail: "NCP-paid expenses × CP share")
        }
        if noncustodialAdditional.cents != 0 {
            step(g5, "Net additional obligation (NCP)", noncustodialAdditional.formatted(),
                 detail: "CP-paid expenses × NCP share − NCP-paid expenses × CP share")
        }

        // Deviations
        if !input.deviations.isEmpty {
            let g6 = "Deviations"
            for dev in input.deviations {
                let sign = dev.direction == .increase ? "+" : "−"
                step(g6, dev.label.isEmpty ? "Deviation" : dev.label, "\(sign)\(dev.amount.formatted())")
            }
            step(g6, "Total deviation", deviationTotal.formatted())
        }

        // Presumptive
        let g7 = "Presumptive Support"
        step(g7, "Presumptive support amount", presumptive.formatted(),
             detail: "Parenting-time amount + net additional expenses + deviations")

        // Low-income adjustment
        if let lia = lowIncomeAdjustment {
            let g8 = "Low-Income Adjustment"
            step(g8, "Unadjusted amount", lia.originalAmount.formatted())
            step(g8, "Low-income cap", lia.cappedAmount.formatted(), detail: "NCP adjusted income falls within low-income table range")
            step(g8, "Amount after cap", lia.cappedAmount.formatted())
        }

        // Credits
        let g9 = "Credits & Final Amount"
        if credits.socialSecurity.cents > 0 {
            step(g9, "Social Security child benefit credit", credits.socialSecurity.formatted())
        }
        if credits.vaDisability.cents > 0 {
            step(g9, "VA disability child benefit credit", credits.vaDisability.formatted())
        }
        if credits.total.cents > 0 {
            step(g9, "Total credits", credits.total.formatted())
        }
        step(g9, "Final monthly payment", finalPayment.formatted())

        return steps
    }
}

// Shared percent formatter — allocated once (fix #1).
private let percentFormatter: NumberFormatter = {
    let f = NumberFormatter()
    f.numberStyle = .percent
    f.minimumFractionDigits = 1
    f.maximumFractionDigits = 1
    return f
}()

func percent(_ decimal: Decimal) -> String {
    percentFormatter.string(from: NSDecimalNumber(decimal: decimal)) ?? "\(decimal)"
}
