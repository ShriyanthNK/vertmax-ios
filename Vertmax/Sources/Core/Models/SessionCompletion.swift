import Foundation
import SwiftData

/// One record per checked-off session, keyed by the program/week/session IDs
/// from the bundled program JSON (see Program.swift).
@Model
final class SessionCompletion {
    var id: UUID
    var programID: String
    var weekNumber: Int
    var sessionID: String
    var completedAt: Date

    init(
        id: UUID = UUID(),
        programID: String,
        weekNumber: Int,
        sessionID: String,
        completedAt: Date = .now
    ) {
        self.id = id
        self.programID = programID
        self.weekNumber = weekNumber
        self.sessionID = sessionID
        self.completedAt = completedAt
    }
}
