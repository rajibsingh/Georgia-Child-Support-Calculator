import SwiftUI

// MARK: - Thomas Calculator

struct ThomasCalculatorView: View {
    @State private var draft = ThomasDraft()
    @FocusState private var focusedField: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TabHeader(title: "Thomas Calculator", subtitle: "Estimates marital vs. non-marital share of an asset.")
                    ThomasInputsPanel(draft: $draft, focusedField: $focusedField)
                    if let result = draft.result {
                        ThomasResultPanel(result: result)
                    }
                }
                .contentWidth()
            }
            .background(IntownColors.background.ignoresSafeArea())
            .navigationTitle("Working Numbers")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture { focusedField = false }
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") { focusedField = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        draft = ThomasDraft()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
    }
}

// MARK: - Inputs

private struct ThomasInputsPanel: View {
    @Binding var draft: ThomasDraft
    var focusedField: FocusState<Bool>.Binding

    var body: some View {
        CalculatorPanel("Asset Details") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Date of Marriage")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(IntownColors.text)
                TextField("e.g. January 15, 2005", text: $draft.dateOfMarriage)
                    .textFieldStyle(IntownTextFieldStyle())
                    .focused(focusedField)
                    .autocorrectionDisabled()
            }
            CurrencyField(label: "Current Market Value", text: $draft.currentMarketValue, focused: focusedField)
            CurrencyField(label: "Current Secured Debt (e.g. mortgage balance)", text: $draft.currentSecuredDebt, focused: focusedField)
            CurrencyField(label: "Asset's Value at Date of Marriage", text: $draft.valueAtDOM, focused: focusedField)
            CurrencyField(label: "Secured Debt at Date of Marriage", text: $draft.securedDebtAtDOM, focused: focusedField)
            CurrencyField(label: "Marital Contributions to Asset (e.g. principal paid)", text: $draft.maritalContributions, focused: focusedField)
        }
    }
}

// MARK: - Result

private struct ThomasResultPanel: View {
    var result: ThomasResult

    var body: some View {
        CalculatorPanel("Results") {
            VStack(spacing: 0) {
                ResultMetricRow(
                    title: "Appreciation During Marriage",
                    value: result.appreciationDuringMarriage.thomasFormatted
                )
                ResultMetricRow(
                    title: "Marital Share Capital",
                    value: result.maritalShareCapitalFormatted
                )
                ResultMetricRow(
                    title: "Estimated Non-Marital Value",
                    value: result.estimatedNonMaritalValue.thomasFormatted
                )
                ResultMetricRow(
                    title: "Estimated Marital Value",
                    value: result.estimatedMaritalValue.thomasFormatted
                )
            }

            HStack {
                Text("Non-Marital + Marital =")
                    .font(.subheadline)
                    .foregroundStyle(IntownColors.secondaryText)
                Spacer()
                Text(result.checkSum.thomasFormatted)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(IntownColors.teal)
            }
            .padding(.top, 4)

            Text("Non-Marital + Marital should equal Current Market Value minus Current Secured Debt.")
                .font(.footnote)
                .foregroundStyle(IntownColors.secondaryText)

            Text("This is an estimate, not legal advice.")
                .font(.footnote.weight(.medium))
                .foregroundStyle(IntownColors.secondaryText)
        }
    }
}

// MARK: - Draft & calculation model

struct ThomasDraft: Equatable {
    var dateOfMarriage = ""
    var currentMarketValue = ""
    var currentSecuredDebt = ""
    var valueAtDOM = ""
    var securedDebtAtDOM = ""
    var maritalContributions = ""

    var result: ThomasResult? {
        let cmv = currentMarketValue.asDecimal
        let sd = currentSecuredDebt.asDecimal
        let vDOM = valueAtDOM.asDecimal
        let sdDOM = securedDebtAtDOM.asDecimal
        let mc = maritalContributions.asDecimal

        // Need at least CMV and value at DOM to show anything useful.
        guard cmv > 0, vDOM > 0 else { return nil }

        let equityAtDOM = vDOM - sdDOM
        // Guard against division by zero in marital share capital.
        guard equityAtDOM > 0 else { return nil }

        let appreciation = cmv - vDOM - mc
        let maritalShareCapital = mc / equityAtDOM
        let nonMarital = equityAtDOM + appreciation * (1 - maritalShareCapital)
        let marital = mc + appreciation * maritalShareCapital

        return ThomasResult(
            appreciationDuringMarriage: appreciation,
            maritalShareCapital: maritalShareCapital,
            estimatedNonMaritalValue: nonMarital,
            estimatedMaritalValue: marital,
            checkSum: cmv - sd
        )
    }
}

struct ThomasResult {
    var appreciationDuringMarriage: Decimal
    var maritalShareCapital: Decimal
    var estimatedNonMaritalValue: Decimal
    var estimatedMaritalValue: Decimal
    /// Should equal CMV − current secured debt.
    var checkSum: Decimal

    var maritalShareCapitalFormatted: String {
        ThomasFormatters.percent.string(from: NSDecimalNumber(decimal: maritalShareCapital))
            ?? "\(maritalShareCapital)"
    }
}

// MARK: - Helpers

private extension String {
    var asDecimal: Decimal {
        let cleaned = replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Decimal(string: cleaned) ?? 0
    }
}

private extension Decimal {
    var thomasFormatted: String {
        ThomasFormatters.currency.string(from: NSDecimalNumber(decimal: self)) ?? "\(self)"
    }
}

// MARK: - Shared formatters (allocated once — fix #1)

private enum ThomasFormatters {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f
    }()

    static let percent: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f
    }()
}
