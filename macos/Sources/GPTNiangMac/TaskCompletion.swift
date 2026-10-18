import Foundation

struct TaskCompletion {
    let id: String
    let finishedAt: Double
    let stopped: Bool
    var tokens: Int?
    var before: Double?
    var after: Double?
    var estimatedTotal: Double?
    var previousEstimatedTotal: Double?
    var estimateNote: String
}
