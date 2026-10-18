import Foundation

/// A per-turn extrapolation of raw tokens, not an official token allowance.
public struct FiveHourEstimate: Equatable {
    public let totalTokens: Double
    public let percentagePointsUsed: Double

    public init?(tokens: Int, before: Double, after: Double) {
        guard tokens > 0, before.isFinite, after.isFinite else { return nil }
        let decline = before - after
        guard decline > 0 else { return nil }
        let total = Double(tokens) * 100 / decline
        guard total.isFinite, total > 0 else { return nil }
        totalTokens = total
        percentagePointsUsed = decline
    }
}
