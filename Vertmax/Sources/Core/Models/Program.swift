import Foundation

/// Programs are content, not code (PRD §5.3) — these types just decode the
/// bundled JSON in Resources/Programs/, so new programs ship without an app
/// update.
struct ProgramExercise: Codable, Identifiable, Hashable {
    var id: String { name }
    var name: String
    var sets: Int
    var reps: String
    var restSeconds: Int
    var isPlyometric: Bool
    var note: String?
}

struct ProgramSession: Codable, Identifiable, Hashable {
    var id: String
    var dayLabel: String
    var name: String
    var exercises: [ProgramExercise]
}

struct ProgramWeek: Codable, Identifiable, Hashable {
    var id: Int { weekNumber }
    let weekNumber: Int
    let isDeload: Bool
    let sessions: [ProgramSession]
}

struct Program: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let summary: String
    let equipmentLevel: EquipmentAccess
    let experienceLevel: ExperienceLevel
    let focus: JumpType
    let weeks: [ProgramWeek]
}
