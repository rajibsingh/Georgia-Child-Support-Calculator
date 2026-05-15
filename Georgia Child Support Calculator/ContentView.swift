import SwiftUI

// MARK: - Ballpark Child Support (Screen 1)

struct BallparkChildSupportView: View {
    @State private var draft = BallparkDraft()
    @State private var showScreen2 = false
    private let calculator = ChildSupportCalculator()

    private var result: Result<CalculationResult, Error>? {
        guard draft.hasAnyIncome else { return nil }
        return Result { try calculator.calculate(draft.input) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    BrandHeader()
                    SummaryBoxRow(result: result)
                    ChildCountPanel(count: $draft.numberOfChildren)
                    IncomePanel(draft: $draft)
                    ParentingTimePanel(overnightOption: $draft.overnightOption)
                    ExpensesPanel(draft: $draft)
                    ResultPanel(result: result, onProceed: { showScreen2 = true })
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .background(IntownColors.background.ignoresSafeArea())
            .navigationTitle("Working Numbers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        draft = BallparkDraft()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .accessibilityIdentifier("resetButton")
                }
            }
        }
        .sheet(isPresented: $showScreen2) {
            SETAdjustmentView(ballparkResult: result, draft: $draft)
        }
    }
}

// MARK: - Brand header

struct BrandHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Working Numbers")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(IntownColors.teal)
                .accessibilityAddTraits(.isHeader)
            Text("for Georgia Family Attorneys")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(IntownColors.teal)
            Text("Back-of-the-envelope estimates for Georgia child support guidelines.")
                .font(.footnote)
                .foregroundStyle(IntownColors.secondaryText)
            Rectangle()
                .fill(IntownColors.teal)
                .frame(height: 2)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(IntownColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Live summary boxes

private struct SummaryBoxRow: View {
    var result: Result<CalculationResult, Error>?

    private var calc: CalculationResult? {
        guard case .success(let r) = result else { return nil }
        return r
    }

    var body: some View {
        HStack(spacing: 10) {
            SummaryBox(
                label: "Combined BCSO",
                value: calc.map { $0.tableLookup.obligation.formatted() } ?? "$0"
            )
            SummaryBox(
                label: "CP's Share",
                value: calc.map { percent($0.proRataShares.custodial) } ?? "0.0%"
            )
            SummaryBox(
                label: "NCP's Share",
                value: calc.map { percent($0.proRataShares.noncustodial) } ?? "0.0%"
            )
        }
    }
}

struct SummaryBox: View {
    var label: String
    var value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(IntownColors.secondaryText)
                .multilineTextAlignment(.center)
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(IntownColors.teal)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(IntownColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Child count

private struct ChildCountPanel: View {
    @Binding var count: Int

    var body: some View {
        CalculatorPanel("Number of Children") {
            HStack(spacing: 0) {
                ForEach(1...6, id: \.self) { value in
                    Button {
                        count = value
                    } label: {
                        Text("\(value)")
                            .font(.title3.weight(count == value ? .semibold : .regular))
                            .foregroundStyle(count == value ? Color.white : IntownColors.teal)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(count == value ? IntownColors.teal : Color.clear)
                    }
                    .accessibilityLabel("\(value) \(value == 1 ? "child" : "children")")
                    .accessibilityAddTraits(count == value ? .isSelected : [])

                    if value < 6 {
                        Rectangle()
                            .fill(IntownColors.border)
                            .frame(width: 1, height: 30)
                    }
                }
            }
            .background(IntownColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(IntownColors.border, lineWidth: 1)
            }
            .accessibilityIdentifier("childrenSelector")
        }
    }
}

// MARK: - Income

private struct IncomePanel: View {
    @Binding var draft: BallparkDraft

    var body: some View {
        CalculatorPanel("Monthly Gross Income") {
            CurrencyField(label: "NCP Monthly Gross", text: $draft.ncpGrossIncome)
            CurrencyField(label: "CP Monthly Gross", text: $draft.cpGrossIncome)
        }
    }
}

// MARK: - Parenting time

enum OvernightOption: String, CaseIterable, Identifiable, Equatable {
    case none
    case split182
    case schedule148
    case schedule129
    case schedule123
    case schedule121
    case schedule102

    var id: String { rawValue }

    var overnights: Decimal? {
        switch self {
        case .none:         return nil
        case .split182:     return Decimal(string: "182.5")!
        case .schedule148:  return Decimal(148)
        case .schedule129:  return Decimal(string: "129.5")!
        case .schedule123:  return Decimal(string: "123.5")!
        case .schedule121:  return Decimal(121)
        case .schedule102:  return Decimal(102)
        }
    }

    var label: String {
        switch self {
        case .none:         return "No parenting-time adjustment"
        case .split182:     return "182.5 — 50/50 (week on/week off)"
        case .schedule148:  return "148 — 5 overnights/14 days, split summers"
        case .schedule129:  return "129.5 — Thu–Sun + off-Thu, week-on summer"
        case .schedule123:  return "123.5 — Thu–Sun + off-Thu, 2 summer weeks each"
        case .schedule121:  return "121 — 4 overnights/14 days, 3 summer weeks each"
        case .schedule102:  return "102 — 3 overnights/14 days, 2 summer weeks each"
        }
    }
}

private struct ParentingTimePanel: View {
    @Binding var overnightOption: OvernightOption

    var body: some View {
        CalculatorPanel("NCP Overnights") {
            Picker("NCP Overnights", selection: $overnightOption) {
                ForEach(OvernightOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier("overnightPicker")

            Text("Variable or unusual work schedules (including airline flight schedules) may require a custom court-ordered count or deviation analysis.")
                .font(.footnote)
                .foregroundStyle(IntownColors.secondaryText)
        }
    }
}

// MARK: - Expenses

private struct ExpensesPanel: View {
    @Binding var draft: BallparkDraft

    var body: some View {
        CalculatorPanel("Childcare & Insurance") {
            ExpenseRow(
                label: "Work-related childcare",
                amount: $draft.childcareAmount,
                payer: $draft.childcarePayer
            )
            Divider()
            ExpenseRow(
                label: "Child health insurance",
                amount: $draft.healthInsuranceAmount,
                payer: $draft.healthInsurancePayer
            )
        }
    }
}

private struct ExpenseRow: View {
    var label: String
    @Binding var amount: String
    @Binding var payer: ExpensePayer?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(IntownColors.text)
            HStack(spacing: 12) {
                CurrencyField(label: label, text: $amount)
                    .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Who pays?")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(IntownColors.secondaryText)
                    Menu {
                        Button("CP") { payer = .cp }
                        Button("NCP") { payer = .ncp }
                        Button("Clear") { payer = nil }
                    } label: {
                        HStack(spacing: 4) {
                            Text(payer?.label ?? "Select")
                                .font(.subheadline)
                                .foregroundStyle(payer == nil ? IntownColors.secondaryText : IntownColors.text)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption)
                                .foregroundStyle(IntownColors.secondaryText)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(IntownColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(IntownColors.border, lineWidth: 1)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Result panel

private struct ResultPanel: View {
    var result: Result<CalculationResult, Error>?
    var onProceed: () -> Void

    var body: some View {
        CalculatorPanel(payerLabel) {
            switch result {
            case .none:
                Text("Enter income above to see an estimate.")
                    .font(.body)
                    .foregroundStyle(IntownColors.secondaryText)

            case .some(.success(let calc)):
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(calc.finalMonthlyPayment.formatted())
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(IntownColors.teal)
                            .accessibilityIdentifier("finalPayment")
                        Text("\(calc.payer.label) pays monthly")
                            .font(.headline)
                            .foregroundStyle(IntownColors.text)
                        Text("Note: ignores SET, low-income adjustment, and other exceptions. Proceed to Screen 2 for more accurate results.")
                            .font(.subheadline)
                            .foregroundStyle(IntownColors.secondaryText)
                            .padding(.top, 2)
                    }

                    VStack(spacing: 0) {
                        ForEach(calc.trace) { step in
                            ResultMetricRow(title: step.title, value: step.value)
                        }
                    }

                    if let lia = calc.lowIncomeAdjustment {
                        ResultMetricRow(
                            title: "Low-income adjustment",
                            value: "\(lia.originalAmount.formatted()) → \(lia.cappedAmount.formatted())"
                        )
                    }

                    Text("If NCP Pays is negative, CP owes NCP that amount.")
                        .font(.footnote)
                        .foregroundStyle(IntownColors.secondaryText)

                    Button(action: onProceed) {
                        Text("Proceed to Screen 2 → SET & other adjustments")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(IntownColors.teal)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityIdentifier("proceedButton")
                }

            case .some(.failure(let error)):
                Text(error.localizedDescription)
                    .font(.body)
                    .foregroundStyle(IntownColors.error)
                    .accessibilityIdentifier("calculationError")
            }
        }
    }

    private var payerLabel: String {
        guard case .some(.success(let calc)) = result else { return "NCP Pays" }
        return "\(calc.payer.label) Pays"
    }
}

// MARK: - Screen 2: SET Adjustment

struct SETAdjustmentView: View {
    var ballparkResult: Result<CalculationResult, Error>?
    @Binding var draft: BallparkDraft
    @Environment(\.dismiss) private var dismiss
    private let calculator = ChildSupportCalculator()

    @State private var ncpSETIncome = ""
    @State private var cpSETIncome = ""

    private var adjustedResult: Result<CalculationResult, Error>? {
        guard draft.hasAnyIncome else { return nil }
        return Result { try calculator.calculate(draft.inputWithSET(ncpSET: ncpSETIncome.asMoney, cpSET: cpSETIncome.asMoney)) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let ballpark = ballparkResult, case .success(let r) = ballpark {
                        CalculatorPanel("Ballpark (Screen 1)") {
                            ResultMetricRow(title: "Before SET adjustment", value: r.finalMonthlyPayment.formatted())
                            ResultMetricRow(title: "Payer", value: r.payer.label)
                        }
                    }

                    CalculatorPanel("Self-Employment Income") {
                        CurrencyField(label: "NCP gross income subject to SET", text: $ncpSETIncome)
                        CurrencyField(label: "CP gross income subject to SET", text: $cpSETIncome)
                        Text("App deducts one-half of SE tax (7.65%) from the SET income entered above before calculating adjusted gross income.")
                            .font(.footnote)
                            .foregroundStyle(IntownColors.secondaryText)
                    }

                    if let adjusted = adjustedResult {
                        CalculatorPanel(adjustedPayerLabel(from: adjusted)) {
                            switch adjusted {
                            case .success(let calc):
                                VStack(alignment: .leading, spacing: 14) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(calc.finalMonthlyPayment.formatted())
                                            .font(.system(size: 44, weight: .semibold))
                                            .foregroundStyle(IntownColors.teal)
                                        Text("\(calc.payer.label) pays monthly")
                                            .font(.headline)
                                            .foregroundStyle(IntownColors.text)
                                    }
                                    VStack(spacing: 0) {
                                        ForEach(calc.trace) { step in
                                            ResultMetricRow(title: step.title, value: step.value)
                                        }
                                    }
                                }
                            case .failure(let error):
                                Text(error.localizedDescription)
                                    .foregroundStyle(IntownColors.error)
                            }
                        }
                    }

                    CalculatorPanel("Coming Soon") {
                        Text("Low-income adjustment, SSI, Social Security Title II, and VA disability derivative benefit offsets will be added in a future version.")
                            .font(.body)
                            .foregroundStyle(IntownColors.secondaryText)
                    }
                }
                .padding(16)
            }
            .background(IntownColors.background.ignoresSafeArea())
            .navigationTitle("SET & Adjustments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { dismiss() }
                }
            }
        }
    }

    private func adjustedPayerLabel(from result: Result<CalculationResult, Error>) -> String {
        guard case .success(let calc) = result else { return "NCP Pays" }
        return "\(calc.payer.label) Pays (with SET)"
    }
}

// MARK: - Draft model

struct BallparkDraft: Equatable {
    var numberOfChildren = 2
    var ncpGrossIncome = ""
    var cpGrossIncome = ""
    var overnightOption: OvernightOption = .none
    var childcareAmount = ""
    var childcarePayer: ExpensePayer? = nil
    var healthInsuranceAmount = ""
    var healthInsurancePayer: ExpensePayer? = nil

    var hasAnyIncome: Bool {
        ncpGrossIncome.asMoney.cents > 0 || cpGrossIncome.asMoney.cents > 0
    }

    var input: CalculationInput {
        inputWithSET(ncpSET: .zero, cpSET: .zero)
    }

    func inputWithSET(ncpSET: Money, cpSET: Money) -> CalculationInput {
        let ncpDays = overnightOption.overnights ?? 0
        return CalculationInput(
            numberOfChildren: numberOfChildren,
            custodialParent: ParentInput(
                grossMonthlyIncome: cpGrossIncome.asMoney,
                selfEmploymentMonthlyIncome: cpSET,
                qualifiedChildren: 0,
                workRelatedChildCare: .zero,
                childHealthInsurancePremium: .zero
            ),
            noncustodialParent: ParentInput(
                grossMonthlyIncome: ncpGrossIncome.asMoney,
                selfEmploymentMonthlyIncome: ncpSET,
                qualifiedChildren: 0,
                workRelatedChildCare: .zero,
                childHealthInsurancePremium: .zero
            ),
            parentingTime: ParentingTimeInput(
                hasCourtOrderedParentingTime: overnightOption != .none,
                custodialDays: Decimal(365) - ncpDays,
                noncustodialDays: ncpDays
            ),
            childcareAmount: childcarePayer != nil ? childcareAmount.asMoney : .zero,
            childcarePayer: childcarePayer ?? .cp,
            healthInsuranceAmount: healthInsurancePayer != nil ? healthInsuranceAmount.asMoney : .zero,
            healthInsurancePayer: healthInsurancePayer ?? .cp,
            deviations: [],
            socialSecurityChildBenefit: .zero,
            vaDisabilityChildBenefit: .zero
        )
    }
}

// MARK: - Shared UI components

struct CalculatorPanel<Content: View>: View {
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
        .padding(16)
        .background(IntownColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct CurrencyField: View {
    var label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(IntownColors.text)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .textFieldStyle(IntownTextFieldStyle())
                .accessibilityIdentifier(label.replacingOccurrences(of: " ", with: "_"))
        }
    }
}

struct ResultMetricRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(IntownColors.text)
            Spacer(minLength: 16)
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

struct IntownTextFieldStyle: TextFieldStyle {
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

// MARK: - Colors

enum IntownColors {
    static let teal = Color(red: 0.0, green: 0.392, blue: 0.537)
    static let text = Color(red: 0.345, green: 0.345, blue: 0.353)
    static let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.4)
    static let border = Color(red: 0.8, green: 0.8, blue: 0.8)
    static let surface = Color.white
    static let background = Color(red: 0.961, green: 0.961, blue: 0.961)
    static let error = Color(red: 0.729, green: 0.133, blue: 0.153)
}

// MARK: - String helpers

extension String {
    var asMoney: Money {
        let cleaned = replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Money(decimalDollars: Decimal(string: cleaned) ?? 0)
    }
}
