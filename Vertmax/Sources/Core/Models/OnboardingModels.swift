import Foundation

enum Sport: String, Codable, CaseIterable {
    case basketball
    case volleyball
    case football
    case general

    var displayName: String {
        switch self {
        case .basketball: return "Basketball"
        case .volleyball: return "Volleyball"
        case .football: return "Football"
        case .general: return "General Fitness"
        }
    }

    /// Only basketball asks the user to choose — every other sport has an
    /// obvious default jump style (PRD §5.1).
    var asksJumpTypePreference: Bool { self == .basketball }

    var defaultJumpType: JumpType {
        switch self {
        case .basketball: return .standing
        case .volleyball: return .approach
        case .football: return .standing
        case .general: return .standing
        }
    }

    var goalOptions: [String] {
        switch self {
        case .basketball:
            return ["Touch rim", "Grab rim", "Dunk a tennis ball", "Dunk", "Just jump higher"]
        case .volleyball:
            return ["Hit higher", "Block higher", "Just jump higher"]
        case .football:
            return ["Improve my combine number", "Just jump higher"]
        case .general:
            return ["Dunk (bucket list)", "Just jump higher"]
        }
    }

    var iconName: String {
        switch self {
        case .basketball: return "figure.basketball"
        case .volleyball: return "figure.volleyball"
        case .football: return "figure.american.football"
        case .general: return "figure.run"
        }
    }
}

enum EquipmentAccess: String, Codable, CaseIterable {
    case fullGym
    case basic
    case bodyweight

    var displayName: String {
        switch self {
        case .fullGym: return "Full Gym"
        case .basic: return "Basic (Dumbbells, Bands)"
        case .bodyweight: return "Bodyweight Only"
        }
    }

    var iconName: String {
        switch self {
        case .fullGym: return "dumbbell.fill"
        case .basic: return "figure.strengthtraining.traditional"
        case .bodyweight: return "figure.core.training"
        }
    }
}

enum ExperienceLevel: String, Codable, CaseIterable {
    case new
    case some
    case experienced

    var displayName: String {
        switch self {
        case .new: return "New to Training"
        case .some: return "Some Experience"
        case .experienced: return "Experienced Lifter"
        }
    }

    var iconName: String {
        switch self {
        case .new: return "leaf.fill"
        case .some: return "figure.walk"
        case .experienced: return "flame.fill"
        }
    }
}

/// Multi-select frustrations surfaced on `OnboardingPainPointsView` and
/// mirrored back with a specific fix on `OnboardingSolutionView`. Kept
/// local to the onboarding session only — not persisted to `UserProfile` or
/// synced, since there's no backend column for it and it's not needed past
/// the flow that reads it.
enum PainPoint: String, CaseIterable, Hashable {
    case noPlan, cantMeasure, gotHurt, genericPlans, noTime, plateaued, noGym

    var label: String {
        switch self {
        case .noPlan: return "I don't know which exercises actually build vert"
        case .cantMeasure: return "I train hard but can't tell if it's working"
        case .gotHurt: return "I've gotten hurt or sore trying to jump higher"
        case .genericPlans: return "Generic workout plans don't fit my sport"
        case .noTime: return "I don't have a lot of time to train"
        case .plateaued: return "I hit a plateau and stopped improving"
        case .noGym: return "I don't have access to a real gym"
        }
    }

    var icon: String {
        switch self {
        case .noPlan: return "questionmark.circle"
        case .cantMeasure: return "ruler"
        case .gotHurt: return "bandage"
        case .genericPlans: return "list.bullet.rectangle"
        case .noTime: return "clock"
        case .plateaued: return "chart.line.downtrend.xyaxis"
        case .noGym: return "dumbbell"
        }
    }
}

struct OnboardingAnswers {
    var sport: Sport = .basketball
    var jumpType: JumpType = .standing
    var goal: String = ""
    var equipment: EquipmentAccess = .bodyweight
    var experience: ExperienceLevel = .new
    var hasInjury: Bool = false
    var painPoints: Set<PainPoint> = []
}
