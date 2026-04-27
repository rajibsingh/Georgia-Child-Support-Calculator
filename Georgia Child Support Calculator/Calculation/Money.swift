import Foundation

struct Money: Equatable, Comparable, Hashable, Codable, Sendable {
    var cents: Int64

    static let zero = Money(cents: 0)

    init(cents: Int64) {
        self.cents = cents
    }

    init(dollars: Int) {
        self.cents = Int64(dollars) * 100
    }

    init(decimalDollars: Decimal) {
        var value = decimalDollars * Decimal(100)
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 0, .plain)
        self.cents = NSDecimalNumber(decimal: rounded).int64Value
    }

    var dollarsDecimal: Decimal {
        Decimal(cents) / Decimal(100)
    }

    var wholeDollarsRounded: Int {
        Int((cents + (cents >= 0 ? 50 : -50)) / 100)
    }

    var isPositive: Bool {
        cents > 0
    }

    func formatted() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSDecimalNumber(decimal: dollarsDecimal)) ?? "$\(wholeDollarsRounded)"
    }

    static func < (lhs: Money, rhs: Money) -> Bool {
        lhs.cents < rhs.cents
    }

    static func + (lhs: Money, rhs: Money) -> Money {
        Money(cents: lhs.cents + rhs.cents)
    }

    static func - (lhs: Money, rhs: Money) -> Money {
        Money(cents: lhs.cents - rhs.cents)
    }

    static prefix func - (value: Money) -> Money {
        Money(cents: -value.cents)
    }

    static func * (lhs: Money, rhs: Decimal) -> Money {
        Money(decimalDollars: lhs.dollarsDecimal * rhs)
    }

    static func / (lhs: Money, rhs: Decimal) -> Money {
        guard rhs != 0 else { return .zero }
        return Money(decimalDollars: lhs.dollarsDecimal / rhs)
    }
}

