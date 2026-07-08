import SwiftUI
import SwiftData

@main
struct VertmaxApp: App {
    let modelContainer = PersistenceController.shared.container

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
}
