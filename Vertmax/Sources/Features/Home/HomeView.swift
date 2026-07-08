import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JumpMeasurement.date, order: .reverse) private var measurements: [JumpMeasurement]
    @Query private var profiles: [UserProfile]
    @Query private var customPrograms: [CustomProgram]
    @Query private var completions: [SessionCompletion]
    @State private var showMeasurementFlow = false

    private var best: JumpMeasurement? {
        measurements.max { $0.heightInches < $1.heightInches }
    }

    /// Core retention event (PRD §5.3): nudge a retest every 3-4 weeks.
    private var daysSinceLastMeasurement: Int? {
        guard let best else { return nil }
        return Calendar.current.dateComponents([.day], from: best.date, to: .now).day
    }

    private var profile: UserProfile? { profiles.first }

    private var assignedProgram: Program? {
        profile.flatMap { ProgramResolver.resolve(id: $0.assignedProgramID, customPrograms: customPrograms) }
    }

    /// First session, in week/day order, with no completion record yet —
    /// same "up next" logic as ProgramTabView, surfaced here so today's work
    /// doesn't require a tab switch to find.
    private var todaySession: (week: ProgramWeek, session: ProgramSession)? {
        guard let assignedProgram else { return nil }
        for week in assignedProgram.weeks {
            for session in week.sessions {
                let isDone = completions.contains { $0.weekNumber == week.weekNumber && $0.sessionID == session.id }
                if !isDone { return (week, session) }
            }
        }
        return nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ink.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    header

                    heroCard

                    if let days = daysSinceLastMeasurement, days >= 21 {
                        retestBanner(days: days)
                    }

                    if let assignedProgram {
                        if let todaySession {
                            todayWorkoutCard(todaySession.week, todaySession.session, program: assignedProgram)
                        } else {
                            allDoneCard
                        }
                    }

                    if best != nil {
                        Button {
                            showMeasurementFlow = true
                        } label: {
                            HStack(spacing: Spacing.xs) {
                                Image(systemName: "camera.fill")
                                Text("Measure Your Vert")
                                    .font(VertFont.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.voltGreen)
                        .foregroundStyle(.ink)
                    }

                    Spacer()
                }
                .padding(Spacing.lg)
            }
            .navigationBarTitleDisplayMode(.inline)
            .profileToolbar()
            .fullScreenCover(isPresented: $showMeasurementFlow) {
                MeasurementFlowView()
            }
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.xs) {
            VertmaxLogoMark()
                .frame(width: 28, height: 28)
            Text("Vertmax")
                .font(VertFont.title)
                .foregroundStyle(.textPrimary)
            Spacer()
        }
        .padding(.top, Spacing.xs)
    }

    private func retestBanner(days: Int) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: "arrow.clockwise")
                .foregroundStyle(.cautionAmber)
            Text("It's been \(days) days. Time to retest and see your progress.")
                .font(VertFont.caption)
                .foregroundStyle(.textPrimary)
            Spacer()
        }
        .padding(Spacing.sm)
        .background(Color.cautionAmber.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm))
    }

    @ViewBuilder
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Best Vert")
                .font(VertFont.caption)
                .foregroundStyle(.textMuted)

            if let best {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                    Text(String(format: "%.1f", best.heightInches))
                        .font(VertFont.heroNumber)
                        .foregroundStyle(.voltGreen)
                    Text("in")
                        .font(VertFont.headline)
                        .foregroundStyle(.textMuted)
                }
                Text(best.date, style: .date)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            } else {
                Text("--")
                    .font(VertFont.heroNumber)
                    .foregroundStyle(.textMuted)
                Text("Take your first measurement to see your vert here.")
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)

                Button {
                    showMeasurementFlow = true
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "camera.fill")
                        Text("Measure Your Vert")
                            .font(VertFont.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(.voltGreen)
                .foregroundStyle(.ink)
                .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private func todayWorkoutCard(_ week: ProgramWeek, _ session: ProgramSession, program: Program) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("TODAY'S WORKOUT")
                        .font(VertFont.body(11, weight: .bold))
                        .foregroundStyle(.voltGreen)
                    Text(session.name)
                        .font(VertFont.headline)
                        .foregroundStyle(.textPrimary)
                    Text(week.isDeload ? "\(session.dayLabel) · Week \(week.weekNumber) (Deload)" : "\(session.dayLabel) · Week \(week.weekNumber)")
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                }
                Spacer()
                Button {
                    completeSession(session, weekNumber: week.weekNumber, programID: program.id)
                } label: {
                    Image(systemName: "circle")
                        .font(.system(size: 26))
                        .foregroundStyle(.textMuted)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                ForEach(session.exercises.prefix(4)) { exercise in
                    Text("• \(exercise.name) · \(exercise.sets)×\(exercise.reps)")
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                }
                if session.exercises.count > 4 {
                    Text("+ \(session.exercises.count - 4) more")
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .strokeBorder(Color.voltGreen.opacity(0.4), lineWidth: 1.5)
        )
    }

    private var allDoneCard: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 32))
                .foregroundStyle(.voltGreen)
            Text("You've completed every session in this program.")
                .font(VertFont.body(15))
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
    }

    private func completeSession(_ session: ProgramSession, weekNumber: Int, programID: String) {
        modelContext.insert(SessionCompletion(programID: programID, weekNumber: weekNumber, sessionID: session.id))
        try? modelContext.save()
    }
}
