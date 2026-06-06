enum IdleVariantKind: CaseIterable {
    case sleepy
    case gaming

    var animationKey: String {
        switch self {
        case .sleepy:
            "idleSleepy"
        case .gaming:
            "idleGaming"
        }
    }
}
