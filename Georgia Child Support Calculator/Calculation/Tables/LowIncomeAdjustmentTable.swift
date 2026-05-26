import Foundation

protocol LowIncomeTableProviding {
    func lowIncomeCap(forAdjustedIncome income: Money, children: Int) -> Money?
}

struct LowIncomeAdjustmentRow: Equatable {
    var adjustedIncomeDollars: Int
    var capsDollars: [Int?]
}

struct LowIncomeAdjustmentTable: LowIncomeTableProviding {
    var rows: [LowIncomeAdjustmentRow] = LowIncomeAdjustmentTableData.rows
    private let atOrBelow1500Percentages = LowIncomeAdjustmentTableData.atOrBelow1500Percentages

    func lowIncomeCap(forAdjustedIncome income: Money, children: Int) -> Money? {
        guard (1...6).contains(children), income.cents > 0 else {
            return nil
        }

        if income <= Money(dollars: 1_500) {
            return inputBasedCap(income: income, children: children)
        }

        // Binary search for the first row whose adjustedIncomeDollars >= income (fix #2).
        // Rows are sorted ascending by adjustedIncomeDollars.
        let requestedDollars = income.wholeDollarsRounded
        var lo = 0
        var hi = rows.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if rows[mid].adjustedIncomeDollars < requestedDollars {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        guard lo < rows.count, let cap = rows[lo].capsDollars[children - 1] else {
            return nil
        }
        return Money(dollars: cap)
    }

    private func inputBasedCap(income: Money, children: Int) -> Money? {
        guard let percentage = atOrBelow1500Percentages[children] else {
            return nil
        }

        return income * percentage
    }
}
