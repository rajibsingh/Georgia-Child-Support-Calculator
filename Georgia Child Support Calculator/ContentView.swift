import SwiftUI

struct ContentView: View {
    @State private var draft = CalculatorDraft()
    private let calculator = ChildSupportCalculator()

    private var result: Result<CalculationResult, Error> {
        Result { try calculator.calculate(draft.input) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    BrandHeader()
                    CaseSetupSection(draft: $draft)
                    ParentSection(title: "Custodial parent", parent: $draft.custodialParent)
                    ParentSection(title: "Noncustodial parent", parent: $draft.noncustodialParent)
                    ParentingTimeSection(draft: $draft)
                    OptionalAdjustmentsSection(draft: $draft)
                    ResultSection(result: result)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 20)
            }
            .background(IntownColors.background.ignoresSafeArea())
            .navigationTitle("Intown Mediation")
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(IntownColors.teal)
    }
}

private struct BrandHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Child Support Calculator")
                .font(.system(size: 30, weight: .regular, design: .default))
                .foregroundStyle(IntownColors.teal)
                .accessibilityAddTraits(.isHeader)
            Text("Guideline estimate for Georgia parents")
                .font(.body)
                .foregroundStyle(IntownColors.text)
            Rectangle()
                .fill(IntownColors.teal)
                .frame(height: 3)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(IntownColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct CaseSetupSection: View {
    @Binding var draft: CalculatorDraft

    var body: some View {
        CalculatorPanel("Case") {
            Stepper(value: $draft.numberOfChildren, in: 1...6) {
                LabeledValue(label: "Children", value: "\(draft.numberOfChildren)")
            }
            .accessibilityIdentifier("childrenStepper")
        }
    }
}

private struct ParentSection: View {
    var title: String
    @Binding var parent: ParentDraft

    var body: some View {
        CalculatorPanel(title) {
            CurrencyTextField(
                title: "Monthly gross income",
                text: $parent.grossMonthlyIncome
            )
            CurrencyTextField(
                title: "Work related child care",
                text: $parent.workRelatedChildCare
            )
            CurrencyTextField(
                title: "Child health insurance premium",
                text: $parent.childHealthInsurancePremium
            )

            DisclosureGroup("Less common adjustments") {
                VStack(spacing: 14) {
                    CurrencyTextField(
                        title: "Self-employment income",
                        text: $parent.selfEmploymentMonthlyIncome
                    )
                    CurrencyTextField(
                        title: "Preexisting support actually paid",
                        text: $parent.preexistingOrdersActuallyPaid
                    )
                    Stepper(value: $parent.qualifiedChildren, in: 0...6) {
                        LabeledValue(label: "Other qualified children", value: "\(parent.qualifiedChildren)")
                    }
                }
                .padding(.top, 10)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(IntownColors.teal)
        }
    }
}

private struct ParentingTimeSection: View {
    @Binding var draft: CalculatorDraft

    var body: some View {
        CalculatorPanel("Parenting Time") {
            Toggle("Court ordered parenting time", isOn: $draft.hasCourtOrderedParentingTime)
                .accessibilityIdentifier("parentingTimeToggle")

            if draft.hasCourtOrderedParentingTime {
                NumberTextField(
                    title: "Custodial annual days",
                    text: $draft.custodialDays
                )
                NumberTextField(
                    title: "Noncustodial annual days",
                    text: $draft.noncustodialDays
                )
                Text("Use annual average days. Recurring daytime hours can be divided by 24.")
                    .font(.footnote)
                    .foregroundStyle(IntownColors.secondaryText)
            }
        }
    }
}

private struct OptionalAdjustmentsSection: View {
    @Binding var draft: CalculatorDraft

    var body: some View {
        CalculatorPanel("Optional Adjustments") {
            DisclosureGroup("Deviations and credits") {
                VStack(spacing: 14) {
                    CurrencyTextField(title: "Deviation increase", text: $draft.deviationIncrease)
                    CurrencyTextField(title: "Deviation decrease", text: $draft.deviationDecrease)
                    CurrencyTextField(title: "Social Security child benefit", text: $draft.socialSecurityChildBenefit)
                    CurrencyTextField(title: "VA disability child benefit", text: $draft.vaDisabilityChildBenefit)
                    Text("Deviations require court findings. Use these fields to model known adjustments, not as legal advice.")
                        .font(.footnote)
                        .foregroundStyle(IntownColors.secondaryText)
                }
                .padding(.top, 10)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(IntownColors.teal)
        }
    }
}

private struct ResultSection: View {
    var result: Result<CalculationResult, Error>

    var body: some View {
        CalculatorPanel("Estimate") {
            switch result {
            case .success(let calculation):
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(calculation.finalMonthlyPayment.formatted())
                            .font(.system(size: 40, weight: .semibold))
                            .foregroundStyle(IntownColors.teal)
                            .accessibilityIdentifier("finalPayment")
                        Text("\(calculation.payer.label) pays monthly")
                            .font(.headline)
                            .foregroundStyle(IntownColors.text)
                    }

                    VStack(spacing: 0) {
                        ForEach(calculation.trace) { step in
                            ResultMetricRow(title: step.title, value: step.value)
                        }
                    }

                    if let lowIncomeAdjustment = calculation.lowIncomeAdjustment {
                        ResultMetricRow(
                            title: "Low-income adjustment",
                            value: "\(lowIncomeAdjustment.originalAmount.formatted()) to \(lowIncomeAdjustment.cappedAmount.formatted())"
                        )
                    }

                    Text("This estimate is not legal advice or a court order.")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(IntownColors.secondaryText)
                }
            case .failure(let error):
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundStyle(IntownColors.error)
                    .accessibilityIdentifier("calculationError")
            }
        }
    }
}

private struct CalculatorPanel<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(IntownColors.teal)
                .accessibilityAddTraits(.isHeader)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(IntownColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct CurrencyTextField: View {
    var title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(IntownColors.text)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .textFieldStyle(IntownTextFieldStyle())
                .accessibilityIdentifier(title.replacingOccurrences(of: " ", with: "_"))
        }
    }
}

private struct NumberTextField: View {
    var title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(IntownColors.text)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .textFieldStyle(IntownTextFieldStyle())
        }
    }
}

private struct LabeledValue: View {
    var label: String
    var value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(IntownColors.text)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(IntownColors.teal)
        }
    }
}

private struct ResultMetricRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(IntownColors.text)
            Spacer(minLength: 18)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(IntownColors.text)
                .multilineTextAlignment(.trailing)
        }
        .font(.body)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(IntownColors.border.opacity(0.6))
                .frame(height: 1)
        }
    }
}

private struct IntownTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.body)
            .foregroundStyle(IntownColors.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(IntownColors.surface)
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(IntownColors.border, lineWidth: 1)
            }
    }
}

private enum IntownColors {
    static let teal = Color(red: 0.0, green: 0.392, blue: 0.537)
    static let text = Color(red: 0.345, green: 0.345, blue: 0.353)
    static let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    static let border = Color(red: 0.8, green: 0.8, blue: 0.8)
    static let surface = Color.white
    static let background = Color(red: 0.961, green: 0.961, blue: 0.961)
    static let error = Color(red: 0.729, green: 0.133, blue: 0.153)
}

struct CalculatorDraft: Equatable {
    var numberOfChildren = 2
    var custodialParent = ParentDraft(grossMonthlyIncome: "5000")
    var noncustodialParent = ParentDraft(grossMonthlyIncome: "6000")
    var hasCourtOrderedParentingTime = false
    var custodialDays = "365"
    var noncustodialDays = "0"
    var deviationIncrease = ""
    var deviationDecrease = ""
    var socialSecurityChildBenefit = ""
    var vaDisabilityChildBenefit = ""

    var input: CalculationInput {
        var deviations: [DeviationInput] = []
        if deviationIncrease.money.isPositive {
            deviations.append(DeviationInput(label: "Deviation increase", amount: deviationIncrease.money, direction: .increase))
        }
        if deviationDecrease.money.isPositive {
            deviations.append(DeviationInput(label: "Deviation decrease", amount: deviationDecrease.money, direction: .decrease))
        }

        return CalculationInput(
            numberOfChildren: numberOfChildren,
            custodialParent: custodialParent.input,
            noncustodialParent: noncustodialParent.input,
            parentingTime: ParentingTimeInput(
                hasCourtOrderedParentingTime: hasCourtOrderedParentingTime,
                custodialDays: custodialDays.decimalValue(default: 365),
                noncustodialDays: noncustodialDays.decimalValue(default: 0)
            ),
            deviations: deviations,
            socialSecurityChildBenefit: socialSecurityChildBenefit.money,
            vaDisabilityChildBenefit: vaDisabilityChildBenefit.money
        )
    }
}

struct ParentDraft: Equatable {
    var grossMonthlyIncome = ""
    var selfEmploymentMonthlyIncome = ""
    var preexistingOrdersActuallyPaid = ""
    var qualifiedChildren = 0
    var workRelatedChildCare = ""
    var childHealthInsurancePremium = ""

    var input: ParentInput {
        ParentInput(
            grossMonthlyIncome: grossMonthlyIncome.money,
            selfEmploymentMonthlyIncome: selfEmploymentMonthlyIncome.money,
            preexistingOrdersActuallyPaid: preexistingOrdersActuallyPaid.money,
            qualifiedChildren: qualifiedChildren,
            workRelatedChildCare: workRelatedChildCare.money,
            childHealthInsurancePremium: childHealthInsurancePremium.money
        )
    }
}

private extension String {
    var money: Money {
        Money(decimalDollars: decimalValue(default: 0))
    }

    func decimalValue(default defaultValue: Decimal) -> Decimal {
        let cleaned = replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: cleaned) ?? defaultValue
    }
}
