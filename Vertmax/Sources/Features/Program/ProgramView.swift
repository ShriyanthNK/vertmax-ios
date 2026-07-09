import SwiftUI
import SwiftData

struct ProgramView: View {
    let program: Program
    /// Week numbers with the auto-progression boost active — see
    /// ProgramProgression. Passed in from the resolved program rather than
    /// recomputed here, so this view doesn't need its own completions query
    /// beyond the one it already keeps for the checkmarks.
    let boostedWeeks: Set<Int>

    @Environment(\.modelContext) private var modelContext
    @Query private var completions: [SessionCompletion]
    @State private var explicitSelectedWeek: Int?

    init(program: Program, boostedWeeks: Set<Int> = []) {
        self.program = program
        self.boostedWeeks = boostedWeeks
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
            if boostedWeeks.contains(selectedWeek) {
                Label("Volume up — last week fully completed", systemImage: "arrow.up.forward")
                    .font(VertFont.caption)
                    .foregroundStyle(.voltGreen)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }

    private var weekPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ForEach(program.weeks) { week in
                    ChipToggle(
                        title: week.isDeload ? "Wk \(week.weekNumber) · Deload" : "Week \(week.weekNumber)",
                        isSelected: selectedWeek == week.weekNumber
                    ) {
                        withAnimation(.easeOut(duration: 0.2)) { explicitSelectedWeek = week.weekNumber }
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
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        toggleCompletion(session: session, weekNumber: weekNumber, isComplete: isComplete)
                    }
                } label: {
                    Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 26))
                        .foregroundStyle(isComplete ? .voltGreen : .textMuted)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: Spacing.xs) {
                ForEach(session.exercises) { exercise in
                    exerciseRow(exercise)
                }
            }
        }
        .padding(Spacing.md)
        .cardStyle()
        .opacity(isComplete ? 0.6 : 1)
        .animation(.easeOut(duration: 0.2), value: isComplete)
    }

    private func exerciseRow(_ exercise: ProgramExercise) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack {
                Text(exercise.name)
                    .font(VertFont.body(15, weight: .medium))
                    .foregroundStyle(.textPrimary)
                if exercise.isPlyometric {
                    PlyoBadge()
                }
                Spacer()
                Text("\(exercise.sets) × \(exercise.reps)")
                    .font(VertFont.dataLabel)
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
        WidgetSnapshotRefresher.refresh(context: modelContext)
    }
}
