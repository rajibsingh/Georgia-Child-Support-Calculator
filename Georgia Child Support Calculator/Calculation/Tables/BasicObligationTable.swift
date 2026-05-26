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

        // Work in whole dollars (rounded) so all comparisons are integer ops — no Decimal overhead.
        let requestedDollars = income.wholeDollarsRounded
        let matched: BasicObligationRow
        let kind: TableMatchKind

        if requestedDollars <= first.combinedIncomeDollars {
            matched = first
            kind = requestedDollars == first.combinedIncomeDollars ? .exact : .belowRange
        } else if requestedDollars >= last.combinedIncomeDollars {
            matched = last
            kind = requestedDollars == last.combinedIncomeDollars ? .exact : .aboveRange
        } else {
            // Binary search: find the first row whose income >= requestedDollars (fix #2).
            // Rows are sorted ascending by combinedIncomeDollars.
            var lo = 0
            var hi = rows.count - 1
            while lo < hi {
                let mid = (lo + hi) / 2
                if rows[mid].combinedIncomeDollars < requestedDollars {
                    lo = mid + 1
                } else {
                    hi = mid
                }
            }
            // lo now points to the first row >= requestedDollars.
            // Check exact hit first, then pick the closer of lo and lo-1.
            if rows[lo].combinedIncomeDollars == requestedDollars {
                matched = rows[lo]
                kind = .exact
            } else {
                // lo > 0 guaranteed because we already handled the below-range case above.
                let below = rows[lo - 1]
                let above = rows[lo]
                let distBelow = requestedDollars - below.combinedIncomeDollars
                let distAbove = above.combinedIncomeDollars - requestedDollars
                matched = distBelow <= distAbove ? below : above
                kind = .nearest
            }
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

