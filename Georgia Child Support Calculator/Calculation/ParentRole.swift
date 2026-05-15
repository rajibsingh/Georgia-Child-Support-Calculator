enum ParentRole: String, CaseIterable, Identifiable, Sendable {
    case custodial
    case noncustodial

    var id: String { rawValue }

    var label: String {
        switch self {
        case .custodial:
            "CP"
        case .noncustodial:
            "NCP"
        }
    }
}

struct ParentPair<Value>: Equatable where Value: Equatable {
    var custodial: Value
    var noncustodial: Value
}

