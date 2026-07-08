import SwiftUI
import SwiftData

struct ProgramView: View {
    let program: Program

    @Environment(\.modelContext) private var modelContext
    @Query private var completions: [SessionCompletion]
    @State private var explicitSelectedWeek: Int?

    init(program: Program) {
        self.program = program
        let programID = program.id
        _completions = Query(filter: #Predicate<SessionCompletion> { $0.programID == programID })
    }

    /// Defaults to the first week with an incomplete session — following
    /// the plan shouldn't require the user to remember which week they're on.
    private var defaultWeek: Int {
        for week in program.weeks {
            let hasIncomplete = week.sessions.contains { session in
                !completions.contains { $0.weekNumber == week.weekNumber && $0.sessionID == session.id }
            }
            if hasIncomplete { return week.weekNumber }
        }
        return program.weeks.last?.weekNumber ?? 1
    }

    private var selectedWeek: Int { explicitSelectedWeek ?? defaultWeek }

    private var currentWeek: ProgramWeek? {
        program.weeks.first { $0.weekNumber == selectedWeek }
    }

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                if program.weeks.count > 1 {
                    weekPicker
                }

                ScrollView {
                    VStack(spacing: Spacing.md) {
                        if let currentWeek {
                            ForEach(currentWeek.sessions) { session in
                                sessionCard(session, weekNumber: currentWeek.weekNumber)
                            }
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(program.summary)
                .font(VertFont.caption)
                .foregroundStyle(.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }

    private var weekPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(program.weeks) { week in
                    Button {
                        explicitSelectedWeek = week.weekNumber
                    } label: {
                        Text(week.isDeload ? "Wk \(week.weekNumber) · Deload" : "Week \(week.weekNumber)")
                            .font(VertFont.body(14, weight: .semibold))
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(selectedWeek == week.weekNumber ? Color.voltGreen : Color.surface)
                            .foregroundStyle(selectedWeek == week.weekNumber ? .ink : .textPrimary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
    }

    private func sessionCard(_ session: ProgramSession, weekNumber: Int) -> some View {
        let isComplete = completions.contains {
            $0.weekNumber == weekNumber && $0.sessionID == session.id
        }

        return VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(session.dayLabel)
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                    Text(session.name)
                        .font(VertFont.headline)
                        .foregroundStyle(.textPrimary)
                }
                Spacer()
                Button {
                    toggleCompletion(session: session, weekNumber: weekNumber, isComplete: isComplete)
                } label: {
                    Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26))
                        .foregroundStyle(isComplete ? .voltGreen : .textMuted)
                }
            }

            VStack(spacing: Spacing.xs) {
                ForEach(session.exercises) { exercise in
                    exerciseRow(exercise)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .opacity(isComplete ? 0.6 : 1)
    }

    private func exerciseRow(_ exercise: ProgramExercise) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack {
                Text(exercise.name)
                    .font(VertFont.body(15, weight: .medium))
                    .foregroundStyle(.textPrimary)
                if exercise.isPlyometric {
                    Text("PLYO")
                        .font(VertFont.body(10, weight: .bold))
                        .foregroundStyle(.ink)
                        .padding(.horizontal, Spacing.xxs)
                        .padding(.vertical, 2)
                        .background(Color.voltGreen)
                        .clipShape(Capsule())
                }
                Spacer()
                Text("\(exercise.sets) × \(exercise.reps)")
                    .font(VertFont.body(14))
                    .foregroundStyle(.textMuted)
            }
            if let note = exercise.note {
                Text(note)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }

    private func toggleCompletion(session: ProgramSession, weekNumber: Int, isComplete: Bool) {
        if isComplete {
            if let existing = completions.first(where: { $0.weekNumber == weekNumber && $0.sessionID == session.id }) {
                modelContext.delete(existing)
            }
        } else {
            modelContext.insert(SessionCompletion(programID: program.id, weekNumber: weekNumber, sessionID: session.id))
        }
        try? modelContext.save()
    }
}
