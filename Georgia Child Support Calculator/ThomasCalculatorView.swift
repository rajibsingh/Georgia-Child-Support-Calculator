import SwiftUI

// MARK: - Thomas Calculator

struct ThomasCalculatorView: View {
    @State private var draft = ThomasDraft()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ThomasHeader()
                    ThomasInputsPanel(draft: $draft)
                    if let result = draft.result {
                        ThomasResultPanel(result: result)
                    }
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
                        draft = ThomasDraft()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
    }
}

private struct ThomasHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Thomas Calculator")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(IntownColors.teal)
                .accessibilityAddTraits(.isHeader)
            Text("Estimates marital vs. non-marital share of an asset.")
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

// MARK: - Inputs

private struct ThomasInputsPanel: View {
    @Binding var draft: ThomasDraft

    var body: some View {
        CalculatorPanel("Asset Details") {
            CurrencyField(label: "Current Market Value", text: $draft.currentMarketValue)
            CurrencyField(label: "Current Secured Debt (e.g. mortgage balance)", text: $draft.currentSecuredDebt)
            CurrencyField(label: "Asset's Value at Date of Marriage", text: $draft.valueAtDOM)
            CurrencyField(label: "Secured Debt at Date of Marriage", text: $draft.securedDebtAtDOM)
            CurrencyField(label: "Marital Contributions to Asset (e.g. principal paid)", text: $draft.maritalContributions)
            Text("Date of marriage is for reference only — enter dollar amounts above for the calculation.")
                .font(.footnote)
                .foregroundStyle(IntownColors.secondaryText)
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSDecimalNumber(decimal: maritalShareCapital)) ?? "\(maritalShareCapital)"
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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: self)) ?? "\(self)"
    }
}
