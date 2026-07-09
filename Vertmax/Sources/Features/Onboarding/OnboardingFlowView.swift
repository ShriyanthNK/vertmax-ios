import SwiftUI
import SwiftData

private enum OnboardingStepKind: Hashable {
    case sport, jumpType, goal, equipment, experience, injury, building, widgetPromo, reveal
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
        s.append(contentsOf: [.goal, .equipment, .experience, .injury, .building, .widgetPromo, .reveal])
        return s
    }

    private var currentKind: OnboardingStepKind { steps[stepIndex] }
    private var showsBackChevron: Bool {
        stepIndex > 0 && currentKind != .building && currentKind != .widgetPromo && currentKind != .reveal
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
                    case .widgetPromo:
                        WidgetPromoView(onContinue: advance)
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
                    .font(VertFont.screenTitle)
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
            .cardStyle()
        }
        .pressableRow()
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
                .font(VertFont.screenTitle)
                .foregroundStyle(.textPrimary)
                .padding(.top, Spacing.lg)

            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(items.indices, id: \.self) { i in
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: i < checkedCount ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .foregroundStyle(i < checkedCount ? .voltGreen : .textMuted)
                            .scaleEffect(i == checkedCount - 1 ? 1.15 : 1)
                            .animation(.spring(response: 0.35, dampingFraction: 0.5), value: checkedCount)
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

/// iOS has no API for an app to add its own widget — the best any app can
/// do is show the user how. Placed after the anticipation beat and before
/// the reveal so it doesn't interrupt the payoff moment, but still lands
/// while attention is high. Skippable: nothing here is required to use the
/// app, and nagging about it later would just be annoying.
private struct WidgetPromoView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            Spacer(minLength: Spacing.md)

            widgetMock
                .frame(width: 170)

            VStack(spacing: Spacing.xs) {
                Text("Add Vertmax to Your Home Screen")
                    .font(VertFont.screenTitle)
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)
                Text("See your best vert and streak at a glance — no need to open the app.")
                    .font(VertFont.bodyText)
                    .foregroundStyle(.textMuted)
                    .multilineTextAlignment(.center)
            }

            instructionsCard

            Spacer(minLength: Spacing.md)

            VStack(spacing: Spacing.sm) {
                Button("Got It", action: onContinue)
                    .buttonStyle(VoltButtonStyle())

                Button("Maybe Later", action: onContinue)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
        }
        .padding(.top, Spacing.lg)
    }

    /// A mockup, not the live widget — this runs in the main app target,
    /// not the widget extension, so it's illustrative rather than driven by
    /// real WidgetKit data. Uses the same tokens as the real widget so it
    /// still reads as an accurate preview.
    private var widgetMock: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("BEST VERT")
                .font(VertFont.eyebrow)
                .foregroundStyle(.textMuted)
                .eyebrowTracking()
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("28.5")
                    .font(VertFont.numeric(28, weight: .semibold))
                    .foregroundStyle(.voltGreen)
                Text("in")
                    .font(VertFont.numeric(12, weight: .medium))
                    .foregroundStyle(.textMuted)
            }
            Spacer(minLength: Spacing.xxs)
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                Text("4 day streak")
                    .font(VertFont.caption)
            }
            .foregroundStyle(.voltGreen)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 155)
        .cardStyle()
    }

    private var instructionsCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            instructionRow(number: "1", text: "Long-press your Home Screen")
            instructionRow(number: "2", text: "Tap the + in the top corner")
            instructionRow(number: "3", text: "Search \"Vertmax\" and add the widget")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .cardStyle()
    }

    private func instructionRow(number: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Text(number)
                .font(VertFont.numeric(13, weight: .semibold))
                .foregroundStyle(.voltGreen)
                .frame(width: 20)
            Text(text)
                .font(VertFont.caption)
                .foregroundStyle(.textPrimary)
            Spacer(minLength: 0)
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
                    .font(VertFont.screenTitle)
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
                .cardStyle(accent: .voltGreen)
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                recapRow(icon: sport.iconName, text: "Built for \(sport.displayName)")
                recapRow(icon: "target", text: "Goal: \(goal)")
            }

            Spacer(minLength: Spacing.lg)

            VStack(spacing: Spacing.sm) {
                Button("Take Your First Measurement", action: onMeasureNow)
                    .buttonStyle(VoltButtonStyle())

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
                    .font(VertFont.screenTitle)
                    .foregroundStyle(.textPrimary)
                Text("Vertmax isn't a substitute for medical advice. If you have current pain or a recent lower-body injury, please see a physical therapist or doctor before starting a jump training program. We'll route you to our most conservative program, but you should still get cleared before doing any plyometric work.")
                    .font(VertFont.bodyText)
                    .foregroundStyle(.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.md)
                Spacer()
                Button("I Understand, Continue", action: onContinue)
                    .buttonStyle(VoltButtonStyle())
            }
            .padding(Spacing.lg)
        }
    }
}
