import SwiftUI
import SwiftData

/// Templated program explainer, swapping the LLM-backed Coach placeholder
/// (PRD §5.4) for zero-cost canned copy — see ProgramExplainer for the copy
/// itself and why a real chat/API layer isn't worth it yet.
struct CoachView: View {
    @Query private var profiles: [UserProfile]
    @Query private var customPrograms: [CustomProgram]
    @Query private var completions: [SessionCompletion]
    @State private var expandedExercise: String?
    @State private var expandedFAQ: String?

    private var profile: UserProfile? { profiles.first }

    /// Resolved program with the auto-progression layer applied — see
    /// ProgramProgression for what that does and why it's conservative.
    private var progression: ProgramProgression.Result? {
        guard let profile, let base = ProgramResolver.resolve(id: profile.assignedProgramID, customPrograms: customPrograms) else {
            return nil
        }
        return ProgramProgression.applied(to: base, completions: completions)
    }

    /// Same "first incomplete session" resolution as Home/Program tab — kept
    /// as a local hand-copy rather than a shared helper, matching how those
    /// two already do it (see their own comments on this).
    private func resolveCurrentSession(in program: Program) -> (week: ProgramWeek, session: ProgramSession)? {
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
        let current = assignedProgram.flatMap { resolveCurrentSession(in: $0) }

        return NavigationStack {
            ZStack {
                Color.ink.ignoresSafeArea()

                if let assignedProgram {
                    ScrollView {
                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            programCard(assignedProgram)

                            if let current {
                                weekCard(
                                    current.week,
                                    isBoosted: progression?.boostedWeeks.contains(current.week.weekNumber) ?? false
                                )
                                exercisesCard(current.session)
                            }

                            faqCard
                        }
                        .padding(Spacing.lg)
                        .padding(.bottom, Spacing.xl)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("Coach")
            .profileToolbar()
        }
    }

    private func programCard(_ program: Program) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("YOUR PROGRAM")
                .font(VertFont.eyebrow)
                .foregroundStyle(.voltGreen)
                .eyebrowTracking()
            Text(program.name)
                .font(VertFont.headline)
                .foregroundStyle(.textPrimary)
            Text(ProgramExplainer.programOverview(program))
                .font(VertFont.body(15))
                .foregroundStyle(.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .cardStyle()
    }

    private func weekCard(_ week: ProgramWeek, isBoosted: Bool) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("THIS WEEK")
                .font(VertFont.eyebrow)
                .foregroundStyle(.voltGreen)
                .eyebrowTracking()
            Text(ProgramExplainer.weekExplanation(week, isBoosted: isBoosted))
                .font(VertFont.body(15))
                .foregroundStyle(.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .cardStyle(accent: isBoosted ? .voltGreen : nil)
    }

    private func exercisesCard(_ session: ProgramSession) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("TODAY'S EXERCISES, EXPLAINED")
                .font(VertFont.eyebrow)
                .foregroundStyle(.voltGreen)
                .eyebrowTracking()

            VStack(spacing: 0) {
                ForEach(session.exercises) { exercise in
                    explainerRow(
                        title: exercise.name,
                        subtitle: "\(exercise.sets)×\(exercise.reps)",
                        detail: ProgramExplainer.exerciseExplanation(for: exercise.name),
                        id: exercise.name,
                        expanded: $expandedExercise
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .cardStyle()
    }

    private var faqCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("COMMON QUESTIONS")
                .font(VertFont.eyebrow)
                .foregroundStyle(.voltGreen)
                .eyebrowTracking()

            VStack(spacing: 0) {
                ForEach(ProgramExplainer.faqs) { faq in
                    explainerRow(
                        title: faq.question,
                        subtitle: nil,
                        detail: faq.answer,
                        id: faq.question,
                        expanded: $expandedFAQ
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.lg)
        .cardStyle()
    }

    private func explainerRow(title: String, subtitle: String?, detail: String?, id: String, expanded: Binding<String?>) -> some View {
        let isExpanded = expanded.wrappedValue == id
        return VStack(alignment: .leading, spacing: Spacing.xxs) {
            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    expanded.wrappedValue = isExpanded ? nil : id
                }
            } label: {
                HStack(alignment: .top, spacing: Spacing.xs) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(VertFont.body(15, weight: .medium))
                            .foregroundStyle(.textPrimary)
                        if let subtitle {
                            Text(subtitle)
                                .font(VertFont.dataCaption)
                                .foregroundStyle(.textMuted)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.textMuted)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityHint(isExpanded ? "Collapse" : "Expand")

            if isExpanded, let detail {
                Text(detail)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
                    .padding(.top, Spacing.xxs)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, Spacing.xs)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 32))
                .foregroundStyle(.textMuted)
                .padding(Spacing.md)
                .background(Circle().fill(Color.surface))
            Text("No program assigned yet")
                .font(VertFont.headline)
                .foregroundStyle(.textPrimary)
            Text("Choose a program on the Program tab and Coach will walk you through it.")
                .font(VertFont.caption)
                .foregroundStyle(.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
