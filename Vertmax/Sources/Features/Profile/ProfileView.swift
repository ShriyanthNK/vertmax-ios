import SwiftUI

struct ProfileView: View {
    @StateObject private var supabase = SupabaseManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ink.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.textMuted)
                            .padding(Spacing.xs)
                            .background(Circle().fill(Color.surface))
                        if let email = supabase.session?.user.email {
                            Text(email)
                                .font(VertFont.body(15))
                                .foregroundStyle(.textPrimary)
                        }
                    }
                    .padding(.top, Spacing.xl)

                    Spacer()

                    Button("Sign Out") {
                        Task { await supabase.signOut() }
                    }
                    .buttonStyle(OutlineButtonStyle())
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Profile")
        }
    }
}
