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
        MoneyFormatters.currency.string(from: NSDecimalNumber(decimal: dollarsDecimal))
            ?? "$\(wholeDollarsRounded)"
    }

    func formattedWithCents() -> String {
        MoneyFormatters.currencyWithCents.string(from: NSDecimalNumber(decimal: dollarsDecimal))
            ?? "$\(dollarsDecimal)"
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

    // Multiply cents directly to avoid an extra Decimal division round-trip (#5).
    static func * (lhs: Money, rhs: Decimal) -> Money {
        var product = Decimal(lhs.cents) * rhs
        var rounded = Decimal()
        NSDecimalRound(&rounded, &product, 0, .plain)
        return Money(cents: NSDecimalNumber(decimal: rounded).int64Value)
    }

    static func / (lhs: Money, rhs: Decimal) -> Money {
        guard rhs != 0 else { return .zero }
        return Money(decimalDollars: lhs.dollarsDecimal / rhs)
    }
}

// MARK: - Shared formatters (allocated once, reused forever — fix #1)

private enum MoneyFormatters {
    static let currency: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        f.minimumFractionDigits = 0
        return f
    }()

    static let currencyWithCents: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()
}

