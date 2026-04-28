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
                    ParentSection(title: "\(draft.custodialDisplayName) (custodial)", parent: $draft.custodialParent)
                    ParentSection(title: "\(draft.noncustodialDisplayName) (noncustodial)", parent: $draft.noncustodialParent)
                    ParentingTimeSection(draft: $draft)
                    OptionalAdjustmentsSection(draft: $draft)
                    ResultSection(result: result, draft: draft)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 20)
            }
            .background(IntownColors.background.ignoresSafeArea())
            .navigationTitle("Intown Mediation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        draft = CalculatorDraft()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .accessibilityIdentifier("resetButton")
                }
            }
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
            PlainTextField(
                title: "Custodial parent name",
                placeholder: "Mom or first name",
                text: $draft.custodialParentName
            )
            PlainTextField(
                title: "Noncustodial parent name",
                placeholder: "Dad or first name",
                text: $draft.noncustodialParentName
            )
            Text("Names help label the worksheet. The official Georgia calculator alphabetizes parent names for column headings on printed forms.")
                .font(.footnote)
                .foregroundStyle(IntownColors.secondaryText)
            ChildCountSelector(count: $draft.numberOfChildren)
        }
    }
}

private struct ChildCountSelector: View {
    @Binding var count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledValue(label: "Children", value: "\(count)")
            HStack(spacing: 0) {
                ForEach(1...6, id: \.self) { value in
                    Button {
                        count = value
                    } label: {
                        Text("\(value)")
                            .font(.body.weight(count == value ? .semibold : .regular))
                            .foregroundStyle(count == value ? Color.white : IntownColors.teal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(count == value ? IntownColors.teal : Color.clear)
                    }
                    .accessibilityLabel("\(value) children")
                    .accessibilityAddTraits(count == value ? .isSelected : [])

                    if value < 6 {
                        Rectangle()
                            .fill(IntownColors.border)
                            .frame(width: 1, height: 24)
                    }
                }
            }
            .background(IntownColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(IntownColors.border, lineWidth: 1)
            }
            .accessibilityIdentifier("childrenSpinner")
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
                    Text("Preexisting child support actually paid may affect the official worksheet. See O.C.G.A. § 19-6-15 and use the official calculator or legal guidance for that adjustment.")
                        .font(.footnote)
                        .foregroundStyle(IntownColors.secondaryText)
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
            Picker("Schedule type", selection: $draft.parentingSchedule) {
                ForEach(ParentingScheduleOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("parentingSchedulePicker")

            Text(draft.parentingSchedule.summary)
                .font(.subheadline)
                .foregroundStyle(IntownColors.text)

            if let noncustodialDays = draft.parentingSchedule.noncustodialDays {
                ResultMetricRow(title: "Noncustodial parenting days", value: noncustodialDays.dayCountText)
                ResultMetricRow(title: "Custodial parenting days", value: (Decimal(365) - noncustodialDays).dayCountText)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Schedule day counts are approximate two-year averages from the Georgia Parenting Plan: Day Counts guide.")
                    .font(.footnote)
                    .foregroundStyle(IntownColors.secondaryText)
                Text("Variable or unusual work schedules, including airline flight schedules, may need a custom court-ordered count or deviation analysis.")
                    .font(.footnote.weight(.medium))
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
    var draft: CalculatorDraft

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
                        Text("\(draft.displayName(for: calculation.payer)) pays monthly")
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

private struct PlainTextField: View {
    var title: String
    var placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(IntownColors.text)
            TextField(placeholder, text: $text)
                .textFieldStyle(IntownTextFieldStyle())
                .textInputAutocapitalization(.words)
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
    var custodialParentName = "Mom"
    var noncustodialParentName = "Dad"
    var custodialParent = ParentDraft(grossMonthlyIncome: "5000")
    var noncustodialParent = ParentDraft(grossMonthlyIncome: "6000")
    var parentingSchedule = ParentingScheduleOption.none
    var deviationIncrease = ""
    var deviationDecrease = ""
    var socialSecurityChildBenefit = ""
    var vaDisabilityChildBenefit = ""

    var custodialDisplayName: String {
        cleanedName(custodialParentName, fallback: "Custodial parent")
    }

    var noncustodialDisplayName: String {
        cleanedName(noncustodialParentName, fallback: "Noncustodial parent")
    }

    func displayName(for role: ParentRole) -> String {
        switch role {
        case .custodial:
            custodialDisplayName
        case .noncustodial:
            noncustodialDisplayName
        }
    }

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
                hasCourtOrderedParentingTime: parentingSchedule.noncustodialDays != nil,
                custodialDays: parentingSchedule.custodialDays,
                noncustodialDays: parentingSchedule.noncustodialDays ?? 0
            ),
            deviations: deviations,
            socialSecurityChildBenefit: socialSecurityChildBenefit.money,
            vaDisabilityChildBenefit: vaDisabilityChildBenefit.money
        )
    }

    private func cleanedName(_ value: String, fallback: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}

struct ParentDraft: Equatable {
    var grossMonthlyIncome = ""
    var selfEmploymentMonthlyIncome = ""
    var qualifiedChildren = 0
    var workRelatedChildCare = ""
    var childHealthInsurancePremium = ""

    var input: ParentInput {
        ParentInput(
            grossMonthlyIncome: grossMonthlyIncome.money,
            selfEmploymentMonthlyIncome: selfEmploymentMonthlyIncome.money,
            qualifiedChildren: qualifiedChildren,
            workRelatedChildCare: workRelatedChildCare.money,
            childHealthInsurancePremium: childHealthInsurancePremium.money
        )
    }
}

enum ParentingScheduleOption: String, CaseIterable, Identifiable {
    case none
    case equalSplit
    case everyOtherThursdayToMondayPlusThursday
    case everyOtherFridayToMondayPlusWednesday
    case everyOtherFridayToMonday
    case everyOtherThursdayToSundayPlusThursday
    case everyOtherThursdayToSundayPlusThursdayEqualSummer
    case variable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none:
            "No court-ordered schedule"
        case .equalSplit:
            "Equal / split parenting time"
        case .everyOtherThursdayToMondayPlusThursday:
            "Every other Thu-Mon + off-week Thu"
        case .everyOtherFridayToMondayPlusWednesday:
            "Every other Fri-Mon + off-week Wed"
        case .everyOtherFridayToMonday:
            "Every other Fri-Mon"
        case .everyOtherThursdayToSundayPlusThursday:
            "Every other Thu-Sun + off-week Thu"
        case .everyOtherThursdayToSundayPlusThursdayEqualSummer:
            "Thu-Sun + off-week Thu, week-on summer"
        case .variable:
            "Variable or unusual schedule"
        }
    }

    var summary: String {
        switch self {
        case .none:
            "No parenting-time adjustment is applied."
        case .equalSplit:
            "Week on/week off, two consecutive summer weeks, holidays divided and alternated."
        case .everyOtherThursdayToMondayPlusThursday:
            "Every other Thursday to Monday, Thursday in the off week, week-on/week-off summer, holidays divided and alternated."
        case .everyOtherFridayToMondayPlusWednesday:
            "Every other Friday to Monday, Wednesday in the off week, three summer weeks each, holidays divided and alternated."
        case .everyOtherFridayToMonday:
            "Every other Friday to Monday, two summer weeks each, holidays divided and alternated."
        case .everyOtherThursdayToSundayPlusThursday:
            "Every other Thursday to Sunday, Thursday in the off week, two summer weeks each, holidays divided and alternated."
        case .everyOtherThursdayToSundayPlusThursdayEqualSummer:
            "Every other Thursday to Sunday, Thursday in the off week, week-on/week-off summer, holidays divided and alternated."
        case .variable:
            "Use this when a repeating template does not fit. The estimate does not apply a parenting-time adjustment for this selection."
        }
    }

    var noncustodialDays: Decimal? {
        switch self {
        case .none, .variable:
            nil
        case .equalSplit:
            Decimal(string: "182.5")!
        case .everyOtherThursdayToMondayPlusThursday:
            Decimal(148)
        case .everyOtherFridayToMondayPlusWednesday:
            Decimal(121)
        case .everyOtherFridayToMonday:
            Decimal(102)
        case .everyOtherThursdayToSundayPlusThursday:
            Decimal(string: "123.5")!
        case .everyOtherThursdayToSundayPlusThursdayEqualSummer:
            Decimal(string: "129.5")!
        }
    }

    var custodialDays: Decimal {
        guard let noncustodialDays else {
            return 365
        }

        return Decimal(365) - noncustodialDays
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

private extension Decimal {
    var dayCountText: String {
        let number = NSDecimalNumber(decimal: self)
        return number.doubleValue.truncatingRemainder(dividingBy: 1) == 0
            ? "\(number.intValue)"
            : "\(number.doubleValue)"
    }
}
