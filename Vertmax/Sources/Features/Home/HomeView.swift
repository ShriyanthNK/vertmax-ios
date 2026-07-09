import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \JumpMeasurement.date, order: .reverse) private var measurements: [JumpMeasurement]
    @Query private var profiles: [UserProfile]
    @Query private var customPrograms: [CustomProgram]
    @Query private var completions: [SessionCompletion]
    @State private var showMeasurementFlow = false
    @State private var appeared = false

    private var best: JumpMeasurement? {
        measurements.max { $0.heightInches < $1.heightInches }
    }

    /// Core retention event (PRD §5.3): nudge a retest every 3-4 weeks.
    private var daysSinceLastMeasurement: Int? {
        StreakCalculator.daysSince(best?.date)
    }

    /// Consecutive days with a completed session or a measurement — either
    /// counts, since both mean the user showed up.
    private var currentStreak: Int {
        StreakCalculator.currentStreak(
            sessionDates: completions.map(\.completedAt),
            measurementDates: measurements.map(\.date)
        )
    }

    private var profile: UserProfile? { profiles.first }

    /// Resolved program with the auto-progression layer applied — see
    /// ProgramProgression for what that does and why it's conservative.
    private var progression: ProgramProgression.Result? {
        guard let profile, let base = ProgramResolver.resolve(id: profile.assignedProgramID, customPrograms: customPrograms) else {
            return nil
        }
        return ProgramProgression.applied(to: base, completions: completions)
    }

    /// First session, in week/day order, with no completion record yet —
    /// same "up next" logic as ProgramTabView, surfaced here so today's work
    /// doesn't require a tab switch to find. Takes the already-resolved
    /// program rather than re-deriving it, so callers compute `progression`
    /// exactly once per body evaluation instead of once per read site.
    private func resolveTodaySession(in program: Program) -> (week: ProgramWeek, session: ProgramSession)? {
        for week in program.weeks {
            for session in week.sessions {
                let isDone = completions.contains {
                    $0.programID == program.id && $0.weekNumber == week.weekNumber && $0.sessionID == session.id
                }
                if !isDone { return (week, session) }
            }
        }
        return nil
    }

    var body: some View {
        let progression = self.progression
        let assignedProgram = progression?.program
        let todaySession = assignedProgram.flatMap { resolveTodaySession(in: $0) }

        return NavigationStack {
            ZStack {
                Color.ink.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            heroCard
                                .reveal(appeared, delay: 0.02)

                            if let days = daysSinceLastMeasurement, days >= 21 {
                                retestBanner(days: days)
                                    .reveal(appeared, delay: 0.08)
                            }

                            if let assignedProgram {
                                Group {
                                    if let todaySession {
                                        todayWorkoutCard(
                                            todaySession.week,
                                            todaySession.session,
                                            program: assignedProgram,
                                            isBoosted: progression?.boostedWeeks.contains(todaySession.week.weekNumber) ?? false
                                        )
                                    } else {
                                        allDoneCard
                                    }
                                }
                                .reveal(appeared, delay: 0.14)
                            }

                            if best != nil {
                                Button {
                                    showMeasurementFlow = true
                                } label: {
                                    HStack(spacing: Spacing.xs) {
                                        Image(systemName: "camera.fill")
                                        Text("Measure Your Vert")
                                    }
                                }
                                .buttonStyle(VoltButtonStyle())
                                .reveal(appeared, delay: 0.2)
                            }
                        }
                        .padding(Spacing.lg)
                        .padding(.bottom, Spacing.xl)
                    }
                    .animation(.easeInOut(duration: 0.3), value: completions.count)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .profileToolbar()
            .fullScreenCover(isPresented: $showMeasurementFlow) {
                MeasurementFlowView()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
                WidgetSnapshotRefresher.refresh(context: modelContext)
            }
        }
    }

    private var header: some View {
        HStack(spacing: Spacing.xs) {
            VertmaxLogoMark()
                .frame(width: 26, height: 26)
            Text("VERTMAX")
                .font(VertFont.wordmark)
                .foregroundStyle(.textPrimary)
                .eyebrowTracking()
            Spacer()
            if currentStreak > 0 {
                streakBadge
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xs)
        .padding(.bottom, Spacing.sm)
    }

    private var streakBadge: some View {
        HStack(spacing: Spacing.xxs) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13))
            Text("\(currentStreak)")
                .font(VertFont.dataLabel)
        }
        .foregroundStyle(.voltGreen)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs)
        .background(Color.voltGreen.opacity(0.12))
        .clipShape(Capsule())
    }

    private func retestBanner(days: Int) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "arrow.clockwise")
                .foregroundStyle(.cautionAmber)
            Text("It's been \(days) days. Time to retest and see your progress.")
                .font(VertFont.caption)
                .foregroundStyle(.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(Spacing.sm)
        .background(Color.cautionAmber.opacity(0.12))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                .strokeBorder(Color.cautionAmber.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
    }

    @ViewBuilder
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("BEST VERT")
                .font(VertFont.eyebrow)
                .foregroundStyle(.textMuted)
                .eyebrowTracking()

            if let best {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
                    Text(String(format: "%.1f", best.heightInches))
                        .font(VertFont.heroNumber)
                        .foregroundStyle(.voltGreen)
                        .contentTransition(.numericText())
                    Text("in")
                        .font(VertFont.heroUnit)
                        .foregroundStyle(.textMuted)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: best.heightInches)

                Text(best.date, style: .date)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            } else {
                Text("––.–")
                    .font(VertFont.heroNumber)
                    .foregroundStyle(.textMuted.opacity(0.5))
                Text("Measure your first jump to set your baseline.")
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)

                Button {
                    showMeasurementFlow = true
                } label: {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "camera.fill")
                        Text("Measure Your Vert")
                    }
                }
                .buttonStyle(VoltButtonStyle())
                .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .background(alignment: .topTrailing) {
            Circle()
                .fill(RadialGradient.voltGlow)
                .frame(width: 260, height: 260)
                .offset(x: 80, y: -90)
                .allowsHitTesting(false)
        }
        .trajectoryBackdrop(opacity: best != nil ? 0.16 : 0.08)
        .cardStyle()
    }

    private func todayWorkoutCard(_ week: ProgramWeek, _ session: ProgramSession, program: Program, isBoosted: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("TODAY'S WORKOUT")
                        .font(VertFont.eyebrow)
                        .foregroundStyle(.voltGreen)
                        .eyebrowTracking()
                    Text(session.name)
                        .font(VertFont.headline)
                        .foregroundStyle(.textPrimary)
                    Text(week.isDeload ? "\(session.dayLabel) · Week \(week.weekNumber) (Deload)" : "\(session.dayLabel) · Week \(week.weekNumber)")
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                    if isBoosted {
                        BoostBadge()
                    }
                }
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        completeSession(session, weekNumber: week.weekNumber, programID: program.id)
                    }
                    // Outside the animated transaction — this is bookkeeping
                    // for the widget, not part of what the spring should be
                    // animating, and shouldn't delay the animation starting.
                    WidgetSnapshotRefresher.refresh(context: modelContext)
                } label: {
                    Image(systemName: "circle")
                        .font(.system(size: 26))
                        .foregroundStyle(.textMuted)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Mark session complete")
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                ForEach(session.exercises.prefix(4)) { exercise in
                    ExerciseSummaryRow(name: exercise.name, sets: exercise.sets, reps: exercise.reps)
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
        .cardStyle(accent: .voltGreen)
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
        .cardStyle(accent: .voltGreen)
    }

    private func completeSession(_ session: ProgramSession, weekNumber: Int, programID: String) {
        // Guards the same race ProgramView.toggleCompletion already guards
        // against: a fast double-tap during the completion spring animation
        // shouldn't insert two rows for the same session.
        let alreadyDone = completions.contains {
            $0.programID == programID && $0.weekNumber == weekNumber && $0.sessionID == session.id
        }
        guard !alreadyDone else { return }
        modelContext.insert(SessionCompletion(programID: programID, weekNumber: weekNumber, sessionID: session.id))
        try? modelContext.save()
    }
}
