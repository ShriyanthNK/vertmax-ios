import SwiftUI
import SwiftData

/// Top-level "Program" tab — the assigned program's weekly schedule is a
/// first-class section, not a link buried inside Home. Also where a user
/// switches programs or builds their own, since auto-routing at onboarding
/// shouldn't be a permanent lock-in.
struct ProgramTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query private var customPrograms: [CustomProgram]
    @Query private var completions: [SessionCompletion]
    @State private var showBrowser = false

    private var profile: UserProfile? { profiles.first }

    /// Resolved program with the auto-progression layer applied — see
    /// ProgramProgression for what that does and why it's conservative.
    private var progression: ProgramProgression.Result? {
        guard let profile, let base = ProgramResolver.resolve(id: profile.assignedProgramID, customPrograms: customPrograms) else {
            return nil
        }
        return ProgramProgression.applied(to: base, completions: completions)
    }

    private var assignedProgram: Program? { progression?.program }

    /// First session, in week/day order, with no completion record yet.
    private var upNext: (week: ProgramWeek, session: ProgramSession)? {
        guard let program = assignedProgram else { return nil }
        for week in program.weeks {
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

                if let assignedProgram {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            programHeader(assignedProgram)

                            if let upNext {
                                upNextCard(
                                    upNext.week,
                                    upNext.session,
                                    isBoosted: progression?.boostedWeeks.contains(upNext.week.weekNumber) ?? false
                                )
                            } else {
                                allDoneCard
                            }

                            NavigationLink {
                                ProgramView(program: assignedProgram, boostedWeeks: progression?.boostedWeeks ?? [])
                            } label: {
                                HStack {
                                    Text("View Full Schedule")
                                        .font(VertFont.headline)
                                        .foregroundStyle(.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.textMuted)
                                }
                                .padding(Spacing.md)
                                .cardStyle()
                            }
                            .pressableRow()
                        }
                        .padding(Spacing.lg)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("Program")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Switch") { showBrowser = true }
                        .foregroundStyle(.voltGreen)
                }
            }
            .profileToolbar()
            .sheet(isPresented: $showBrowser) {
                ProgramLibraryBrowserView(
                    activeProgramID: profile?.assignedProgramID ?? "",
                    onSelect: { newID in
                        profile?.assignedProgramID = newID
                        try? modelContext.save()
                    }
                )
            }
        }
    }

    private func programHeader(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(program.name)
                .font(VertFont.screenTitle)
                .foregroundStyle(.textPrimary)
            Text(program.summary)
                .font(VertFont.caption)
                .foregroundStyle(.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func upNextCard(_ week: ProgramWeek, _ session: ProgramSession, isBoosted: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("UP NEXT")
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
                Label("Volume up — last week fully completed", systemImage: "arrow.up.forward")
                    .font(VertFont.caption)
                    .foregroundStyle(.voltGreen)
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
            .padding(.top, Spacing.xxs)
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

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 40))
                .foregroundStyle(.textMuted)
            Text("No program assigned yet")
                .font(VertFont.headline)
                .foregroundStyle(.textPrimary)
            Button("Choose a Program") { showBrowser = true }
                .buttonStyle(VoltButtonStyle())
                .padding(.horizontal, Spacing.xl)
        }
    }
}
