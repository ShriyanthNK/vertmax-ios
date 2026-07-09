import SwiftUI
import SwiftData

/// Top-level switch: signed-out users see the auth gate, signed-in users
/// without a profile see onboarding, everyone else lands in the tab bar.
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
            if isSignedIn {
                if profiles.isEmpty && !justFinishedOnboarding {
                    OnboardingFlowView(onComplete: { justFinishedOnboarding = true })
                } else {
                    MainTabView()
                }
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
