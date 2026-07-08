import SwiftUI

struct SignInView: View {
    @StateObject private var supabase = SupabaseManager.shared

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Spacer()

                VStack(spacing: Spacing.md) {
                    VertmaxLogoMark()
                        .frame(width: 96, height: 96)
                    VStack(spacing: Spacing.xs) {
                        Text("VERTMAX")
                            .font(VertFont.display(34, weight: .heavy))
                            .foregroundStyle(.textPrimary)
                        Text("Measure it. Train for it. Prove it.")
                            .font(VertFont.bodyText)
                            .foregroundStyle(.textMuted)
                    }
                }

                Spacer()

                VStack(spacing: Spacing.md) {
                    Button {
                        Task { await supabase.signInWithGoogle() }
                    } label: {
                        HStack(spacing: Spacing.xs) {
                            if supabase.isAuthenticating {
                                ProgressView().tint(.ink)
                            } else {
                                Image(systemName: "g.circle.fill")
                            }
                            Text("Continue with Google")
                                .font(VertFont.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.sm)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.voltGreen)
                    .foregroundStyle(.ink)
                    .disabled(supabase.isAuthenticating)

                    if let error = supabase.authError {
                        Text(error)
                            .font(VertFont.caption)
                            .foregroundStyle(.stopRed)
                            .multilineTextAlignment(.center)
                    }

                    Text("By continuing you agree this app does not provide medical advice. Consult a professional before starting any training program.")
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
                .padding(.bottom, Spacing.xxl)
            }
            .padding(.horizontal, Spacing.lg)
        }
    }
}
