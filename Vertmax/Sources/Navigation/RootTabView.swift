import SwiftUI
import SwiftData

/// Top-level switch: onboarding runs before any auth check — a new user
/// answers the questionnaire and sees their program before we ever ask them
/// to create an account, since asking cold with nothing delivered yet is
/// the surest way to lose them. Sign-in becomes a soft gate only once
/// onboarding is done and there's a program worth saving.
struct RootTabView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var profiles: [UserProfile]
    @State private var isOnboardingActive: Bool?

    private var isSignedIn: Bool {
        supabase.session != nil
    }

    /// Locked in once via `onAppear` rather than recomputed live from
    /// `profiles.isEmpty` — onboarding inserts the `UserProfile` right after
    /// the injury step, well before the flow actually ends (building →
    /// widgetPromo → reveal). If this stayed reactive, the moment
    /// that row landed `profiles.isEmpty` would flip to false and this view
    /// would swap `OnboardingFlowView` out from under the in-progress flow,
    /// dumping the user onto the sign-in screen mid-onboarding.
    private var showOnboarding: Bool {
        isOnboardingActive ?? profiles.isEmpty
    }

    var body: some View {
        Group {
            if showOnboarding {
                OnboardingFlowView(onComplete: { isOnboardingActive = false })
            } else if isSignedIn {
                MainTabView()
            } else {
                SignInView()
            }
        }
        .onAppear {
            if isOnboardingActive == nil {
                isOnboardingActive = profiles.isEmpty
            }
        }
        .onChange(of: isSignedIn) { _, signedIn in
            if signedIn {
                Task { await SyncEngine.reconcile(context: modelContext) }
            }
        }
        // Deleting the account wipes the local `UserProfile` row (see
        // `ProfileView.wipeLocalData`); only reset the onboarding lock when
        // that happens post-onboarding (`isOnboardingActive == false`), not
        // during onboarding itself where `profiles` is transiently empty
        // before the injury step inserts the row.
        .onChange(of: profiles.isEmpty) { _, isEmpty in
            if isEmpty, isOnboardingActive == false {
                isOnboardingActive = nil
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isSignedIn {
                Task { await SyncEngine.reconcile(context: modelContext) }
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            ProgramTabView()
                .tabItem { Label("Program", systemImage: "list.bullet.clipboard.fill") }

            MeasurementFlowView()
                .tabItem { Label("Measure", systemImage: "camera.fill") }

            ProgressDashboardView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            CoachView()
                .tabItem { Label("Coach", systemImage: "bubble.left.and.bubble.right.fill") }
        }
        .tint(.voltGreen)
    }
}
