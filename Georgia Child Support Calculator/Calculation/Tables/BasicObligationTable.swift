import Foundation

struct BasicObligationRow: Equatable {
    var combinedIncomeDollars: Int
    var obligationsDollars: [Int]
}

enum TableMatchKind: Equatable {
    case exact
    case nearest
    case belowRange
    case aboveRange
}

struct BasicObligationLookupResult: Equatable {
    var requestedIncome: Money
    var matchedIncome: Money
    var childCount: Int
    var obligation: Money
    var matchKind: TableMatchKind
}

protocol ObligationTableProviding {
    func basicObligation(forCombinedIncome income: Money, children: Int) throws -> BasicObligationLookupResult
}

struct BasicObligationTable: ObligationTableProviding {
    var rows: [BasicObligationRow] = BasicObligationTableData.rows

    func basicObligation(forCombinedIncome income: Money, children: Int) throws -> BasicObligationLookupResult {
        guard (1...6).contains(children) else {
            throw CalculationError.invalidChildCount
        }
        guard let first = rows.first, let last = rows.last else {
            throw CalculationError.tableLookupFailed
        }

        let requestedDollars = income.dollarsDecimal
        let matched: BasicObligationRow
        let kind: TableMatchKind

        if requestedDollars <= Decimal(first.combinedIncomeDollars) {
            matched = first
            kind = requestedDollars == Decimal(first.combinedIncomeDollars) ? .exact : .belowRange
        } else if requestedDollars >= Decimal(last.combinedIncomeDollars) {
            matched = last
            kind = requestedDollars == Decimal(last.combinedIncomeDollars) ? .exact : .aboveRange
        } else if let exact = rows.first(where: { Decimal($0.combinedIncomeDollars) == requestedDollars }) {
            matched = exact
            kind = .exact
        } else {
            matched = rows.min { lhs, rhs in
                abs(Decimal(lhs.combinedIncomeDollars) - requestedDollars) < abs(Decimal(rhs.combinedIncomeDollars) - requestedDollars)
            } ?? first
            kind = .nearest
        }

        return BasicObligationLookupResult(
            requestedIncome: income,
            matchedIncome: Money(dollars: matched.combinedIncomeDollars),
            childCount: children,
            obligation: Money(dollars: matched.obligationsDollars[children - 1]),
            matchKind: kind
        )
    }
}

