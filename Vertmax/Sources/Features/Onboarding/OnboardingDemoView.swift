import SwiftUI

struct DemoDrill: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let sets: Int
    let reps: String
    let isPlyometric: Bool
}

/// Small curated pool pulled from the same exercises the real bundled
/// programs use (see Resources/Programs/*.json) — not invented names — so
/// what the user picks here reads exactly like a page from their real plan.
enum DemoDrillCatalog {
    static func drills(for equipment: EquipmentAccess) -> [DemoDrill] {
        switch equipment {
        case .bodyweight:
            return [
                DemoDrill(name: "Broad Jump", sets: 4, reps: "5", isPlyometric: true),
                DemoDrill(name: "Pogo Hops", sets: 2, reps: "12", isPlyometric: true),
                DemoDrill(name: "Bodyweight Squat", sets: 2, reps: "10", isPlyometric: false),
                DemoDrill(name: "Reverse Lunge", sets: 4, reps: "12/leg", isPlyometric: false),
                DemoDrill(name: "Calf Raise", sets: 3, reps: "20", isPlyometric: false),
                DemoDrill(name: "Wall Sit", sets: 3, reps: "45s", isPlyometric: false)
            ]
        case .basic:
            return [
                DemoDrill(name: "Broad Jump", sets: 4, reps: "5", isPlyometric: true),
                DemoDrill(name: "Single-Leg Pogo Hops", sets: 2, reps: "8/leg", isPlyometric: true),
                DemoDrill(name: "Goblet Squat", sets: 2, reps: "10", isPlyometric: false),
                DemoDrill(name: "Dumbbell Step-Up", sets: 4, reps: "10/leg", isPlyometric: false),
                DemoDrill(name: "Standing Calf Raise (Dumbbell)", sets: 4, reps: "18", isPlyometric: false),
                DemoDrill(name: "Banded Lateral Walk", sets: 2, reps: "10/side", isPlyometric: false)
            ]
        case .fullGym:
            return [
                DemoDrill(name: "Box Jump", sets: 2, reps: "4", isPlyometric: true),
                DemoDrill(name: "Trap Bar Jump", sets: 2, reps: "4", isPlyometric: true),
                DemoDrill(name: "Depth Drop to Stick", sets: 4, reps: "5", isPlyometric: true),
                DemoDrill(name: "Back Squat", sets: 2, reps: "5", isPlyometric: false),
                DemoDrill(name: "Bulgarian Split Squat", sets: 4, reps: "10/leg", isPlyometric: false),
                DemoDrill(name: "Weighted Calf Raise", sets: 4, reps: "12", isPlyometric: false)
            ]
        }
    }
}

/// Screen 11 (the framework's hardest screen): a real interactive mini
/// version of picking a session, using the same exercise names/sets/reps
/// the bundled programs use — not a tour, an actual choice with an output.
struct OnboardingDemoPickView: View {
    let equipment: EquipmentAccess
    @Binding var selected: Set<String>
    let onContinue: () -> Void

    private let targetCount = 3
    private var drills: [DemoDrill] { DemoDrillCatalog.drills(for: equipment) }

    private var remainingLabel: String {
        let remaining = targetCount - selected.count
        return remaining <= 0 ? "Done!" : "Pick \(remaining) more"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Pick 3 Drills for Your First Session")
                    .font(VertFont.screenTitle)
                    .foregroundStyle(.textPrimary)
                Text(remainingLabel)
                    .font(VertFont.caption)
                    .foregroundStyle(.voltGreen)
            }
            .padding(.top, Spacing.lg)

            ScrollView {
                VStack(spacing: Spacing.sm) {
                    ForEach(drills) { drill in
                        drillRow(drill)
                    }
                }
                .padding(.bottom, Spacing.sm)
            }
            // See the identical comment in OnboardingPainPointsView — without
            // this the list sizes to content and the bottom rows render past
            // the screen edge instead of scrolling into view.
            .frame(maxHeight: .infinity)

            Button("Continue", action: onContinue)
                .buttonStyle(VoltButtonStyle())
                .disabled(selected.count != targetCount)
        }
    }

    private func drillRow(_ drill: DemoDrill) -> some View {
        let isSelected = selected.contains(drill.name)
        return Button {
            if isSelected {
                selected.remove(drill.name)
            } else if selected.count < targetCount {
                selected.insert(drill.name)
            }
        } label: {
            HStack(spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    HStack(spacing: Spacing.xs) {
                        Text(drill.name)
                            .font(VertFont.headline)
                            .foregroundStyle(.textPrimary)
                        if drill.isPlyometric { PlyoBadge() }
                    }
                    Text("\(drill.sets) × \(drill.reps)")
                        .font(VertFont.dataCaption)
                        .foregroundStyle(.textMuted)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .voltGreen : .textMuted)
            }
            .padding(Spacing.md)
            .cardStyle(accent: isSelected ? .voltGreen : nil)
        }
        .pressableRow()
        .disabled(!isSelected && selected.count >= targetCount)
    }
}

/// Screen 12: the tangible output from the pick above, plus the share hook
/// (the framework's "viral moment"). Framed as a preview, not a promise —
/// the real Week 1 session (sport/goal/injury-aware) is assigned next, so
/// copy is careful not to claim these exact picks land in that plan.
struct OnboardingDemoOutputView: View {
    let selectedNames: Set<String>
    let equipment: EquipmentAccess
    let onContinue: () -> Void

    @State private var revealed = false
    @State private var shareImage: Image?
    @State private var shareURL: URL?

    private var drills: [DemoDrill] {
        DemoDrillCatalog.drills(for: equipment).filter { selectedNames.contains($0.name) }
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xxs) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.voltGreen)
                Text("Your Day 1 Could Look Like This")
                    .font(VertFont.screenTitle)
                    .foregroundStyle(.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Spacing.lg)
            .scaleEffect(revealed ? 1 : 0.85)
            .opacity(revealed ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: revealed)

            VStack(spacing: Spacing.sm) {
                ForEach(drills) { drill in
                    HStack(spacing: Spacing.sm) {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            HStack(spacing: Spacing.xs) {
                                Text(drill.name)
                                    .font(VertFont.headline)
                                    .foregroundStyle(.textPrimary)
                                if drill.isPlyometric { PlyoBadge() }
                            }
                            Text("\(drill.sets) × \(drill.reps)")
                                .font(VertFont.dataCaption)
                                .foregroundStyle(.textMuted)
                        }
                        Spacer()
                    }
                    .padding(Spacing.md)
                    .cardStyle()
                }
            }
            .reveal(revealed, delay: 0.15)

            Text("Your full Week 1 plan — built around your sport, goal, and any injury history — comes next.")
                .font(VertFont.caption)
                .foregroundStyle(.textMuted)
                .multilineTextAlignment(.center)
                .reveal(revealed, delay: 0.2)

            Spacer(minLength: Spacing.md)

            VStack(spacing: Spacing.sm) {
                if let shareURL {
                    ShareLink(
                        item: shareURL,
                        preview: SharePreview("My Vertmax Session", image: shareImage ?? Image(systemName: "photo"))
                    ) {
                        Label("Share My Session", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
                Button("Continue", action: onContinue)
                    .buttonStyle(VoltButtonStyle())
            }
            .reveal(revealed, delay: 0.25)
        }
        .padding(.horizontal, Spacing.lg)
        .onAppear {
            revealed = true
            renderShareCard()
        }
    }

    /// Renders off-screen to a PNG file, same pattern as `ShareCardView` on
    /// the real measurement result — a stable file URL is more reliable
    /// across share destinations than an in-memory image.
    private func renderShareCard() {
        let card = OnboardingSessionShareCard(drills: drills)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        guard let uiImage = renderer.uiImage, let data = uiImage.pngData() else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("vertmax-session-\(UUID().uuidString).png")
        do {
            try data.write(to: url)
            shareImage = Image(uiImage: uiImage)
            shareURL = url
        } catch {
            shareImage = nil
            shareURL = nil
        }
    }
}

/// Branded export card for the demo output share — mirrors `ShareCardView`'s
/// visual language (mono readout swapped for a session list) so a shared
/// onboarding session still reads as unmistakably Vertmax.
private struct OnboardingSessionShareCard: View {
    let drills: [DemoDrill]
    private let cardSize = CGSize(width: 400, height: 700)

    var body: some View {
        ZStack {
            Color.ink
            VStack(alignment: .leading, spacing: Spacing.xl) {
                HStack(spacing: Spacing.xs) {
                    VertmaxLogoMark().frame(width: 22, height: 22)
                    Text("VERTMAX")
                        .font(VertFont.wordmark)
                        .foregroundStyle(.textPrimary)
                        .eyebrowTracking()
                    Spacer()
                }
                Text("MY DAY 1 SESSION")
                    .font(VertFont.eyebrow)
                    .foregroundStyle(.voltGreen)
                    .eyebrowTracking()

                VStack(spacing: Spacing.md) {
                    ForEach(drills) { drill in
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(drill.name)
                                .font(VertFont.headline)
                                .foregroundStyle(.textPrimary)
                            Text("\(drill.sets) × \(drill.reps)")
                                .font(VertFont.dataLabel)
                                .foregroundStyle(.voltGreen)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Spacer()
            }
            .padding(Spacing.xl)
        }
        .frame(width: cardSize.width, height: cardSize.height)
    }
}
