import Foundation

/// Adaptive layer on top of the authored program content: when a week is
/// completed in full, the next week's volume nudges up slightly. When it
/// isn't, the next week holds at the program's authored baseline — this
/// never regresses below what was written, only adds a small boost on top.
///
/// Deliberately conservative: there's no weight/RPE tracking in this app to
/// inform real periodization, so this only ever adds +1 rep (or +1 set, for
/// exercises with non-numeric rep schemes like "AMRAP") off the baseline,
/// never compounding across multiple good weeks — each week's boost is
/// computed fresh from the originally authored numbers, using only the
/// immediately preceding week's completion rate. Deload weeks are never
/// boosted or used as the basis for a boost — they're intentionally reduced.
enum ProgramProgression {
    struct Result {
        let program: Program
        /// Week numbers where the boost is currently active, so the UI can
        /// tell the user why their numbers moved instead of just showing a
        /// silently different program.
        let boostedWeeks: Set<Int>
    }

    static func applied(to program: Program, completions: [SessionCompletion]) -> Result {
        var newWeeks: [ProgramWeek] = []
        var boostedWeeks: Set<Int> = []
        var previousWeekFullyCompleted = false

        for week in program.weeks {
            let boost = !week.isDeload && previousWeekFullyCompleted
            if boost { boostedWeeks.insert(week.weekNumber) }

            let sessions = week.sessions.map { session -> ProgramSession in
                guard boost else { return session }
                var session = session
                session.exercises = session.exercises.map(progressed)
                return session
            }
            newWeeks.append(ProgramWeek(weekNumber: week.weekNumber, isDeload: week.isDeload, sessions: sessions))

            previousWeekFullyCompleted = week.isDeload ? false : isFullyCompleted(week, completions: completions)
        }

        let adjusted = Program(
            id: program.id,
            name: program.name,
            summary: program.summary,
            equipmentLevel: program.equipmentLevel,
            experienceLevel: program.experienceLevel,
            focus: program.focus,
            weeks: newWeeks
        )
        return Result(program: adjusted, boostedWeeks: boostedWeeks)
    }

    private static func isFullyCompleted(_ week: ProgramWeek, completions: [SessionCompletion]) -> Bool {
        guard !week.sessions.isEmpty else { return false }
        return week.sessions.allSatisfy { session in
            completions.contains { $0.weekNumber == week.weekNumber && $0.sessionID == session.id }
        }
    }

    private static func progressed(_ exercise: ProgramExercise) -> ProgramExercise {
        var exercise = exercise
        if let numericReps = Int(exercise.reps) {
            exercise.reps = String(numericReps + 1)
        } else {
            exercise.sets = min(exercise.sets + 1, 6)
        }
        return exercise
    }
}
