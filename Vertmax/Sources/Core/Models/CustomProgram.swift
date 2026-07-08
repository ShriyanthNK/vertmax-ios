import Foundation
import SwiftData

/// A user-built program, assembled from the exercise database. Reuses the
/// same `ProgramWeek`/`ProgramSession`/`ProgramExercise` shapes as the
/// bundled JSON programs (Program.swift), just persisted as an encoded
/// blob instead of shipped as a bundle resource — so `ProgramView` renders
/// both without knowing the difference (see ProgramResolver).
///
/// Kept to a single repeating week for v1: simpler to build in-app than a
/// full multi-week planner, and still lets a user structure their own
/// session split from real exercises instead of being stuck with the 5
/// prebuilt programs.
@Model
final class CustomProgram {
    var id: UUID
    var name: String
    var summary: String
    private var sessionsData: Data
    var createdAt: Date

    init(id: UUID = UUID(), name: String, summary: String, sessions: [ProgramSession] = [], createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.summary = summary
        self.sessionsData = (try? JSONEncoder().encode(sessions)) ?? Data()
        self.createdAt = createdAt
    }

    var sessions: [ProgramSession] {
        get { (try? JSONDecoder().decode([ProgramSession].self, from: sessionsData)) ?? [] }
        set { sessionsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    /// The ID stored on `UserProfile.assignedProgramID` when this is active.
    var referenceID: String { "custom:\(id.uuidString)" }

    func asProgram() -> Program {
        Program(
            id: referenceID,
            name: name,
            summary: summary,
            equipmentLevel: .bodyweight,
            experienceLevel: .some,
            focus: .standing,
            weeks: [ProgramWeek(weekNumber: 1, isDeload: false, sessions: sessions)]
        )
    }
}
