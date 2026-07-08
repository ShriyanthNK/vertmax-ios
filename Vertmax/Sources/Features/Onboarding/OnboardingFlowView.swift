import SwiftUI
import SwiftData

private enum OnboardingStepKind: Hashable {
    case sport, jumpType, goal, equipment, experience, injury, building, reveal
}

/// 5-tap Q&A onboarding (PRD §5.1), followed by a "building your program"
/// anticipation screen and a personalized reveal before the first
/// measurement — the payoff-before-paywall pattern used by Noom/Fitbod,
/// which independent tests show lifts trial starts and paid conversion by
/// double digits versus dropping users straight into the app.
struct OnboardingFlowView: View {
    let onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var answers = OnboardingAnswers()
    @State private var stepIndex = 0
    @State private var showInjuryCaution = false
    @State private var assignedProgram: Program?
    @State private var showMeasurementFlow = false
    @State private var hapticTick = 0

    private var steps: [OnboardingStepKind] {
        var s: [OnboardingStepKind] = [.sport]
        if answers.sport.asksJumpTypePreference { s.append(.jumpType) }
        s.append(contentsOf: [.goal, .equipment, .experience, .injury, .building, .reveal])
        return s
    }

    private var currentKind: OnboardingStepKind { steps[stepIndex] }
    private var showsBackChevron: Bool {
        stepIndex > 0 && currentKind != .building && currentKind != .reveal
    }

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                header

                Group {
                    switch currentKind {
                    case .sport: sportStep
                    case .jumpType: jumpTypeStep
                    case .goal: goalStep
                    case .equipment: equipmentStep
                    case .experience: experienceStep
                    case .injury: injuryStep
                    case .building:
                        BuildingProgramView(onFinished: advance)
                    case .reveal:
                        ProgramRevealView(
                            program: assignedProgram,
                            sport: answers.sport,
                            goal: answers.goal,
                            onMeasureNow: { showMeasurementFlow = true },
                            onExploreLater: onComplete
                        )
                    }
                }
                .id(currentKind)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()
            }
            .padding(Spacing.lg)
        }
        .sensoryFeedback(.selection, trigger: hapticTick)
        .sheet(isPresented: $showInjuryCaution) {
            InjuryCautionView(onContinue: {
                showInjuryCaution = false
                createProfileAndProgram()
                advance()
            })
        }
        .fullScreenCover(isPresented: $showMeasurementFlow) {
            MeasurementFlowView()
                .onDisappear { onComplete() }
        }
    }

    private var header: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.xxs) {
                ForEach(steps.indices, id: \.self) { i in
                    Capsule()
                        .fill(i <= stepIndex ? Color.voltGreen : Color.raised)
                        .frame(height: 4)
                }
            }
            if showsBackChevron {
                HStack {
                    Button {
                        withAnimation(.easeInOut) { stepIndex -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(.textMuted)
                    }
                    Spacer()
                }
            }
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Steps

    private var sportStep: some View {
        stepContainer(title: "What's your sport?") {
            ForEach(Sport.allCases, id: \.self) { sport in
                optionButton(sport.displayName, icon: sport.iconName) {
                    answers.sport = sport
                    advance()
                }
            }
        }
    }

    private var jumpTypeStep: some View {
        stepContainer(title: "How do you jump?") {
            optionButton("Standing (No Steps)", subtitle: "Jump straight up", icon: "arrow.up") {
                answers.jumpType = .standing
                advance()
            }
            optionButton("Approach (Run-Up)", subtitle: "A few steps before you jump", icon: "figure.run") {
                answers.jumpType = .approach
                advance()
            }
        }
    }

    private var goalStep: some View {
        stepContainer(
            title: "What's your goal?",
            subtitle: "As a \(answers.sport.displayName.lowercased()) player, this shapes your whole program."
        ) {
            ForEach(answers.sport.goalOptions, id: \.self) { goal in
                optionButton(goal, icon: "target") {
                    answers.goal = goal
                    advance()
                }
            }
        }
    }

    private var equipmentStep: some View {
        stepContainer(title: "What do you have access to?") {
            ForEach(EquipmentAccess.allCases, id: \.self) { equipment in
                optionButton(equipment.displayName, icon: equipment.iconName) {
                    answers.equipment = equipment
                    advance()
                }
            }
        }
    }

    private var experienceStep: some View {
        stepContainer(title: "Training experience?") {
            ForEach(ExperienceLevel.allCases, id: \.self) { level in
                optionButton(level.displayName, icon: level.iconName) {
                    answers.experience = level
                    advance()
                }
            }
        }
    }

    private var injuryStep: some View {
        stepContainer(
            title: "Any current pain or recent lower-body injuries?",
            subtitle: "This just helps us keep your program safe. Most people answer no."
        ) {
            optionButton("No", icon: "checkmark") {
                answers.hasInjury = false
                createProfileAndProgram()
                advance()
            }
            optionButton("Yes", icon: "exclamationmark.triangle") {
                answers.hasInjury = true
                showInjuryCaution = true
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func stepContainer<Content: View>(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(VertFont.title)
                    .foregroundStyle(.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                }
            }
            .padding(.top, Spacing.lg)

            VStack(spacing: Spacing.sm) {
                content()
            }
        }
    }

    private func optionButton(_ title: String, subtitle: String? = nil, icon: String, action: @escaping () -> Void) -> some View {
        Button {
            hapticTick += 1
            action()
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(.voltGreen)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(title)
                        .font(VertFont.headline)
                        .foregroundStyle(.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(VertFont.caption)
                            .foregroundStyle(.textMuted)
                    }
                }
                Spacer()
            }
            .padding(Spacing.md)
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }

    private func advance() {
        withAnimation(.easeInOut) {
            if stepIndex < steps.count - 1 {
                stepIndex += 1
            }
        }
    }

    private func createProfileAndProgram() {
        if !answers.sport.asksJumpTypePreference {
            answers.jumpType = answers.sport.defaultJumpType
        }
        let programID = ProgramRouter.assign(answers)
        assignedProgram = ProgramLibrary.program(withID: programID)

        let profile = UserProfile(
            sport: answers.sport,
            jumpTypePreference: answers.jumpType,
            goal: answers.goal,
            equipment: answers.equipment,
            experience: answers.experience,
            hasInjury: answers.hasInjury,
            assignedProgramID: programID
        )
        modelContext.insert(profile)
        try? modelContext.save()
    }
}

/// The Noom/Fitbod "anticipation" beat: a staged checklist makes it visible
/// that the prior answers are actually doing something, so the reveal that
/// follows lands as a delivered result rather than an abrupt tab switch.
private struct BuildingProgramView: View {
    let onFinished: () -> Void
    @State private var checkedCount = 0

    private let items = [
        "Analyzing your sport and goal",
        "Matching your equipment",
        "Setting a safe training volume",
        "Finalizing your program",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Building Your Program…")
                .font(VertFont.title)
                .foregroundStyle(.textPrimary)
                .padding(.top, Spacing.lg)

            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(items.indices, id: \.self) { i in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: i < checkedCount ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(i < checkedCount ? .voltGreen : .textMuted)
                        Text(items[i])
                            .font(VertFont.body(16, weight: i < checkedCount ? .semibold : .regular))
                            .foregroundStyle(i < checkedCount ? .textPrimary : .textMuted)
                    }
                }
            }
        }
        .task {
            for i in items.indices {
                try? await Task.sleep(for: .milliseconds(450))
                withAnimation(.easeOut) { checkedCount = i + 1 }
            }
            try? await Task.sleep(for: .milliseconds(400))
            onFinished()
        }
    }
}

/// The payoff moment: delivers the personalized program before the first
/// measurement, echoing the user's own answers back to them.
private struct ProgramRevealView: View {
    let program: Program?
    let sport: Sport
    let goal: String
    let onMeasureNow: () -> Void
    let onExploreLater: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.voltGreen)
                Text("Your Program Is Ready")
                    .font(VertFont.title)
                    .foregroundStyle(.textPrimary)
            }
            .padding(.top, Spacing.lg)

            if let program {
                VStack(spacing: Spacing.xxs) {
                    Text(program.name)
                        .font(VertFont.headline)
                        .foregroundStyle(.voltGreen)
                    Text(program.summary)
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(Spacing.md)
                .background(Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.lg))
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                recapRow(icon: sport.iconName, text: "Built for \(sport.displayName)")
                recapRow(icon: "target", text: "Goal: \(goal)")
            }

            Spacer(minLength: Spacing.lg)

            VStack(spacing: Spacing.sm) {
                Button(action: onMeasureNow) {
                    Text("Take Your First Measurement")
                        .font(VertFont.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                }
                .buttonStyle(.borderedProminent)
                .tint(.voltGreen)
                .foregroundStyle(.ink)

                Button("Explore My Program First", action: onExploreLater)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
        }
    }

    private func recapRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .foregroundStyle(.voltGreen)
                .frame(width: 24)
            Text(text)
                .font(VertFont.body(15))
                .foregroundStyle(.textPrimary)
            Spacer()
        }
        .padding(.horizontal, Spacing.xs)
    }
}

private struct InjuryCautionView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()
            VStack(spacing: Spacing.lg) {
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.stopRed)
                Text("Train Smart")
                    .font(VertFont.title)
                    .foregroundStyle(.textPrimary)
                Text("Vertmax isn't a substitute for medical advice. If you have current pain or a recent lower-body injury, please see a physical therapist or doctor before starting a jump training program. We'll route you to our most conservative program, but you should still get cleared before doing any plyometric work.")
                    .font(VertFont.bodyText)
                    .foregroundStyle(.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
                Spacer()
                Button("I Understand, Continue", action: onContinue)
                    .buttonStyle(.borderedProminent)
                    .tint(.voltGreen)
                    .foregroundStyle(.ink)
            }
            .padding(Spacing.lg)
        }
    }
}
