import Foundation

/// Maps onboarding answers to one of the bundled programs (PRD §5.1/§5.3).
/// "In-season maintenance" has no dedicated onboarding question, so it's
/// reachable only via manual browsing, not auto-routing.
enum ProgramRouter {
    static func assign(_ answers: OnboardingAnswers) -> String {
        // Injury gate overrides everything else with the most conservative option.
        if answers.hasInjury {
            return "beginner-bodyweight"
        }

        if answers.jumpType == .approach {
            return "approach-jump-focus"
        }

        switch answers.equipment {
        case .bodyweight:
            return "beginner-bodyweight"
        case .basic, .fullGym:
            return answers.experience == .new ? "beginner-gym" : "intermediate-gym"
        }
    }
}
