import SwiftUI
import SwiftData

/// Top-level switch: signed-out users see the auth gate, signed-in users
/// without a profile see onboarding, everyone else lands in the tab bar.
struct RootTabView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @Query private var profiles: [UserProfile]
    @State private var justFinishedOnboarding = false

    var body: some View {
        Group {
            if supabase.session != nil {
                if profiles.isEmpty && !justFinishedOnboarding {
                    OnboardingFlowView(onComplete: { justFinishedOnboarding = true })
                } else {
                    MainTabView()
                }
            } else {
                SignInView()
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
