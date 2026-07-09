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
    @State private var justFinishedOnboarding = false
    #if DEBUG
    @State private var debugBypassAuth = false
    #endif

    private var isSignedIn: Bool {
        #if DEBUG
        supabase.session != nil || debugBypassAuth
        #else
        supabase.session != nil
        #endif
    }

    var body: some View {
        Group {
            if profiles.isEmpty && !justFinishedOnboarding {
                OnboardingFlowView(onComplete: { justFinishedOnboarding = true })
            } else if isSignedIn {
                MainTabView()
            } else {
                #if DEBUG
                SignInView(onDebugBypass: { debugBypassAuth = true })
                #else
                SignInView()
                #endif
            }
        }
        .onChange(of: isSignedIn) { _, signedIn in
            if signedIn {
                Task { await SyncEngine.reconcile(context: modelContext) }
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
