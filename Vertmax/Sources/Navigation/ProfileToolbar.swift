import SwiftUI

private struct ProfileToolbarModifier: ViewModifier {
    @State private var showProfile = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showProfile = true
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .foregroundStyle(.textMuted)
                    }
                    .accessibilityLabel("Profile")
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
    }
}

extension View {
    /// Consistent settings/profile entry point, top-right on every tab.
    func profileToolbar() -> some View {
        modifier(ProfileToolbarModifier())
    }
}
