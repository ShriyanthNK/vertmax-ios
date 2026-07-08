import Foundation
import SwiftData

/// Presence of this record is what gates onboarding vs. the main app —
/// see RootTabView. One profile per signed-in user.
@Model
final class UserProfile {
    var id: UUID
    var sport: Sport
    var jumpTypePreference: JumpType
    var goal: String
    var equipment: EquipmentAccess
    var experience: ExperienceLevel
    var hasInjury: Bool
    var assignedProgramID: String
    var onboardingCompletedAt: Date

    init(
        id: UUID = UUID(),
        sport: Sport,
        jumpTypePreference: JumpType,
        goal: String,
        equipment: EquipmentAccess,
        experience: ExperienceLevel,
        hasInjury: Bool,
        assignedProgramID: String,
        onboardingCompletedAt: Date = .now
    ) {
        self.id = id
        self.sport = sport
        self.jumpTypePreference = jumpTypePreference
        self.goal = goal
        self.equipment = equipment
        self.experience = experience
        self.hasInjury = hasInjury
        self.assignedProgramID = assignedProgramID
        self.onboardingCompletedAt = onboardingCompletedAt
    }
}
