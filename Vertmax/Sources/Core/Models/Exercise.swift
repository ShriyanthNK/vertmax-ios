import Foundation

enum ExerciseCategory: String, Codable, CaseIterable {
    case squat
    case hinge
    case lunge
    case plyometric
    case core
    case calf
    case mobility

    var displayName: String {
        switch self {
        case .squat: return "Squat"
        case .hinge: return "Hinge"
        case .lunge: return "Lunge"
        case .plyometric: return "Plyometric"
        case .core: return "Core"
        case .calf: return "Calf / Ankle"
        case .mobility: return "Mobility"
        }
    }

    var iconName: String {
        switch self {
        case .squat: return "figure.strengthtraining.functional"
        case .hinge: return "figure.strengthtraining.traditional"
        case .lunge: return "figure.walk"
        case .plyometric: return "bolt.fill"
        case .core: return "figure.core.training"
        case .calf: return "shoeprints.fill"
        case .mobility: return "figure.flexibility"
        }
    }
}

enum ExerciseDifficulty: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

/// A single reusable entry in the exercise database (Resources/exercises.json).
/// `ProgramExercise` (Program.swift) is the lightweight sets/reps/rest entry
/// that actually appears inside a program session — when a user adds one of
/// these to a custom program, its defaults seed a `ProgramExercise`.
struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let equipmentLevel: EquipmentAccess
    let isPlyometric: Bool
    let difficulty: ExerciseDifficulty
    let instructions: String
    let defaultSets: Int
    let defaultReps: String
    let defaultRestSeconds: Int

    func asProgramExercise() -> ProgramExercise {
        ProgramExercise(
            name: name,
            sets: defaultSets,
            reps: defaultReps,
            restSeconds: defaultRestSeconds,
            isPlyometric: isPlyometric,
            note: nil
        )
    }
}
