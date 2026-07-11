import Foundation

/// Templated copy for the Coach tab (PRD §5.4) — generated from data already
/// on the model instead of a real LLM. What Coach actually promises
/// ("explain your program") is deterministic given `Program`/
/// `ProgramProgression`/`Exercise`, so this covers it at zero marginal cost
/// and no API dependency. Revisit an LLM-backed version only once free-form
/// Q&A demand is actually validated.
enum ProgramExplainer {
    struct FAQ: Identifiable {
        var id: String { question }
        let question: String
        let answer: String
    }

    static func programOverview(_ program: Program) -> String {
        "\(program.name) targets \(focusLabel(program.focus).lowercased()) for \(program.experienceLevel.displayName.lowercased()), using \(program.equipmentLevel.displayName.lowercased()). \(program.summary)"
    }

    static func focusLabel(_ focus: JumpType) -> String {
        switch focus {
        case .standing: return "Standing Vertical"
        case .approach: return "Approach Vertical"
        }
    }

    static func weekExplanation(_ week: ProgramWeek, isBoosted: Bool) -> String {
        if week.isDeload {
            return "Week \(week.weekNumber) is a deload — volume is intentionally lower so your body absorbs the last few weeks of training instead of piling on more fatigue. Deload weeks never get the auto-progression boost."
        }
        if isBoosted {
            return "Week \(week.weekNumber)'s reps/sets are bumped up slightly because you fully completed last week. Miss a session and next week just holds at the program's original numbers instead — nothing regresses."
        }
        return "Week \(week.weekNumber) is at the program's baseline numbers. Complete every session this week and next week's volume nudges up on its own."
    }

    static func exerciseExplanation(for name: String) -> String? {
        ExerciseLibrary.all.first { $0.name == name }?.instructions
    }

    static let faqs: [FAQ] = [
        FAQ(
            question: "What does a deload week mean?",
            answer: "Every few weeks your program backs off volume on purpose. It's not a rest — it's how your body actually adapts and gets stronger from the training you already did."
        ),
        FAQ(
            question: "Why did my sets or reps change?",
            answer: "Vertmax bumps next week's volume by one rep (or one set) only when you fully complete the week before it — deload weeks are never boosted, and boosts never compound across multiple weeks."
        ),
        FAQ(
            question: "What if I miss a session?",
            answer: "Nothing breaks. Just pick up on the next one — missing a session only means next week holds at baseline instead of progressing, it never resets your program."
        ),
        FAQ(
            question: "How often should I retest my vert?",
            answer: "Every 3-4 weeks. Testing more often than that mostly measures day-to-day noise, not real progress."
        ),
        FAQ(
            question: "Why do plyometric exercises matter?",
            answer: "Plyometrics (marked PLYO) train the fast, elastic force production your jump actually depends on — strength work builds the engine, plyos teach you to use it quickly."
        )
    ]
}
