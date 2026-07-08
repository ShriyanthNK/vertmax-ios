import SwiftUI

struct ProfileView: View {
    @StateObject private var supabase = SupabaseManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ink.ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    VStack(spacing: Spacing.xxs) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.textMuted)
                        if let email = supabase.session?.user.email {
                            Text(email)
                                .font(VertFont.body(15))
                                .foregroundStyle(.textPrimary)
                        }
                    }
                    .padding(.top, Spacing.xl)

                    Spacer()

                    Button {
                        Task { await supabase.signOut() }
                    } label: {
                        Text("Sign Out")
                            .font(VertFont.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                    }
                    .buttonStyle(.bordered)
                    .tint(.stopRed)
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Profile")
        }
    }
}
