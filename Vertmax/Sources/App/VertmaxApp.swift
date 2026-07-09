import SwiftUI
import SwiftData

@main
struct VertmaxApp: App {
    let modelContainer = PersistenceController.shared.container

    init() {
        Self.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
                .tint(.voltGreen)
                .onOpenURL { url in
                    SupabaseManager.shared.handle(url: url)
                }
        }
        .modelContainer(modelContainer)
    }

    /// One place to make every screen's system chrome (nav bar, tab bar)
    /// agree with the design system — cheaper and more consistent than
    /// styling each NavigationStack individually. The nav title font is
    /// the one spot Archivo Black shows up on almost every screen, which
    /// is exactly the restraint the display face calls for.
    private static func configureAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.ink)
        navAppearance.shadowColor = UIColor(Color.white.opacity(0.08))
        let titleFont = UIFont(name: "ArchivoBlack-Regular", size: 17) ?? .systemFont(ofSize: 17, weight: .bold)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.textPrimary), .font: titleFont]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(Color.voltGreen)

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color.ink)
        tabAppearance.shadowColor = UIColor(Color.white.opacity(0.08))
        for itemAppearance in [tabAppearance.stackedLayoutAppearance, tabAppearance.inlineLayoutAppearance, tabAppearance.compactInlineLayoutAppearance] {
            itemAppearance.normal.iconColor = UIColor(Color.textMuted)
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textMuted)]
            itemAppearance.selected.iconColor = UIColor(Color.voltGreen)
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.voltGreen)]
        }
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
}
