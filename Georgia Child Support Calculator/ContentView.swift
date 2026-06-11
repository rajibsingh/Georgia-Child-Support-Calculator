import SwiftUI

// MARK: - Ballpark Child Support

struct BallparkChildSupportView: View {
    @State private var draft = BallparkDraft()
    @State private var result: Result<CalculationResult, Error>? = nil
    @State private var debounceTask: Task<Void, Never>? = nil
    @FocusState private var focusedField: Bool
    private let calculator = ChildSupportCalculator()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TabHeader(
                        title: "Child Support Ballparker",
                        subtitle: "Back-of-envelope child support estimator for experienced attorneys. Use Detailed CS Estimator for more nuance including self employment, low income and customized parenting time.",
                        showPreviewBadge: true
                    )
                    SummaryBoxRow(result: result)
                    ChildCountPanel(count: $draft.numberOfChildren)
                    IncomePanel(draft: $draft, focusedField: $focusedField)
                    ParentingTimePanel(overnightOption: $draft.overnightOption)
                    ExpensesPanel(draft: $draft, focusedField: $focusedField)
                    ResultPanel(result: result)
                }
                .contentWidth()
            }
            .background(IntownColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        draft = BallparkDraft()
                        focusedField = false
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                    .accessibilityIdentifier("resetButton")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = false
                    }
                }
            }
            // Tap anywhere outside a field to dismiss keyboard
            .onTapGesture {
                focusedField = false
            }
        }
        .tint(IntownColors.teal)
        .onChange(of: draft) { scheduleRecalculate() }
        .onAppear { recalculate() }
    }

    private func scheduleRecalculate() {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await MainActor.run { recalculate() }
        }
    }

    private func recalculate() {
        guard draft.hasAnyIncome else { result = nil; return }
        result = Result { try calculator.calculate(draft.input) }
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
    var focusedField: FocusState<Bool>.Binding

    var body: some View {
        CalculatorPanel("Monthly Gross Income") {
            CurrencyField(label: "NCP Monthly Gross", text: $draft.ncpGrossIncome, focused: focusedField)
            CurrencyField(label: "CP Monthly Gross", text: $draft.cpGrossIncome, focused: focusedField)
        }
    }
}

// MARK: - Parenting time

enum OvernightOption: String, CaseIterable, Identifiable, Equatable {
    case none
    case schedule102
    case schedule121
    case schedule148
    case split182

    var id: String { rawValue }

    var overnights: Decimal? {
        switch self {
        case .none:          return nil
        case .schedule102:   return Decimal(102)
        case .schedule121:   return Decimal(121)
        case .schedule148:   return Decimal(148)
        case .split182:      return Decimal(string: "182.5")!
        }
    }

    /// Full descriptive label shown inside the picker dropdown.
    var label: String {
        switch self {
        case .none:          return "Pick an option"
        case .schedule102:   return "102 — 3 overnights every 2 weeks, 50/50 holidays, 2 summer weeks"
        case .schedule121:   return "121 — 4 overnights every 2 weeks, 50/50 holidays, 3 summer weeks"
        case .schedule148:   return "148 — 5 overnights every 2 weeks, 50/50 summers & holidays"
        case .split182:      return "182.5 — 50/50 parenting time"
        }
    }

    /// Short label shown on the main screen once an option is selected.
    var selectedLabel: String {
        switch self {
        case .none:          return "Pick an option"
        case .schedule102:   return "102 overnights"
        case .schedule121:   return "121 overnights"
        case .schedule148:   return "148 overnights"
        case .split182:      return "182.5 overnights (50/50)"
        }
    }
}

private struct ParentingTimePanel: View {
    @Binding var overnightOption: OvernightOption

    var body: some View {
        CalculatorPanel("NCP Overnights") {
            Menu {
                ForEach(OvernightOption.allCases) { option in
                    Button(option.label) { overnightOption = option }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(overnightOption.selectedLabel)
                        .font(.subheadline)
                        .foregroundStyle(overnightOption == .none ? IntownColors.secondaryText : IntownColors.text)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(IntownColors.secondaryText)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(IntownColors.surface)
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(IntownColors.border, lineWidth: 1)
                }
            }
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
    var focusedField: FocusState<Bool>.Binding

    var body: some View {
        CalculatorPanel("Childcare & Insurance") {
            ExpenseRow(
                label: "Work-related childcare",
                amount: $draft.childcareAmount,
                payer: $draft.childcarePayer,
                focused: focusedField
            )
            Divider()
            ExpenseRow(
                label: "Child health insurance",
                amount: $draft.healthInsuranceAmount,
                payer: $draft.healthInsurancePayer,
                focused: focusedField
            )
        }
    }
}

private struct ExpenseRow: View {
    var label: String
    @Binding var amount: String
    @Binding var payer: ExpensePayer?
    var focused: FocusState<Bool>.Binding

    var body: some View {
        HStack(spacing: 12) {
            CurrencyField(label: label, text: $amount, focused: focused)
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

// MARK: - Result panel

private struct ResultPanel: View {
    var result: Result<CalculationResult, Error>?

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
                        // Final amount rounded to whole dollar only here
                        Text("$\(calc.finalMonthlyPayment.wholeDollarsRounded)")
                            .font(.system(size: 44, weight: .semibold))
                            .foregroundStyle(IntownColors.teal)
                            .accessibilityIdentifier("finalPayment")
                        Text("\(calc.payer.label) pays monthly")
                            .font(.headline)
                            .foregroundStyle(IntownColors.text)
                        Text("NOTE: ballpark estimate.")
                            .font(.subheadline)
                            .foregroundStyle(IntownColors.secondaryText)
                            .padding(.top, 2)
                    }

                    MoreNumbersPanel(calc: calc)

                    // Reference to Detailed CS — no Screen 2 button
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(IntownColors.teal)
                        Text("Use CS Estimator for SET, low income, customized parenting time, etc.")
                            .font(.footnote)
                            .foregroundStyle(IntownColors.secondaryText)
                    }
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

// MARK: - More Numbers disclosure group

private struct MoreNumbersPanel: View {
    var calc: CalculationResult
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("More Numbers")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .foregroundStyle(IntownColors.teal)
                .padding(.vertical, 10)
            }
            .accessibilityIdentifier("moreNumbersToggle")

            if isExpanded {
                VStack(spacing: 0) {
                    TraceRow(title: "Combined gross income", value: calc.combinedAdjustedGrossIncome.formatted())
                    TraceRow(title: "Combined BCSO", value: calc.tableLookup.obligation.formattedWithCents())
                    TraceRow(title: "CP's share BCSO", value: calc.basicObligationShares.custodial.formattedWithCents())
                    TraceRow(title: "NCP's share BCSO", value: calc.basicObligationShares.noncustodial.formattedWithCents())
                    if calc.parentingTimeCredit.cents != 0 {
                        TraceRow(
                            title: "Parenting time adjustment",
                            value: calc.parentingTimeCredit.formattedWithCents()
                        )
                    }
                    if calc.scheduleDExpenses.custodial.cents != 0 {
                        TraceRow(
                            title: "Sch D expenses paid by CP",
                            value: calc.scheduleDExpenses.custodial.formattedWithCents()
                        )
                    }
                    if calc.scheduleDExpenses.noncustodial.cents != 0 {
                        TraceRow(
                            title: "Sch D expenses paid by NCP",
                            value: calc.scheduleDExpenses.noncustodial.formattedWithCents()
                        )
                    }
                    TraceRow(
                        title: "Estimated monthly support",
                        value: calc.finalMonthlyPayment.formattedWithCents()
                    )
                }
                .padding(.bottom, 6)
            }
        }
    }
}

private struct TraceRow: View {
    var title: String
    var value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.caption)
                .foregroundStyle(IntownColors.text)
            Spacer(minLength: 8)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(IntownColors.text)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 7)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(IntownColors.border.opacity(0.5))
                .frame(height: 1)
        }
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
    var focused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(IntownColors.text)
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .focused(focused)
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
