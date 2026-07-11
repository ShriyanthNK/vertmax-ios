import AuthenticationServices
import SwiftUI

struct SignInView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var appeared = false
    @State private var currentAppleNonce: String?
    #if DEBUG
    var onDebugBypass: (() -> Void)?
    #endif

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()

            GeometryReader { geo in
                TrajectoryArc(liftoff: 0.1)
                    .stroke(Color.voltGreen.opacity(0.12), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: geo.size.width * 1.3, height: geo.size.height * 0.6)
                    .offset(x: -geo.size.width * 0.15, y: geo.size.height * 0.08)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: Spacing.xl) {
                Spacer()

                VStack(spacing: Spacing.md) {
                    VertmaxLogoMark()
                        .frame(width: 96, height: 96)
                        .reveal(appeared)
                    VStack(spacing: Spacing.xs) {
                        Text("Save Your Program")
                            .font(VertFont.display(32))
                            .foregroundStyle(.textPrimary)
                            .multilineTextAlignment(.center)
                        Text("Create a free account so your program and progress sync across devices.")
                            .font(VertFont.bodyText)
                            .foregroundStyle(.textMuted)
                            .multilineTextAlignment(.center)
                    }
                    .reveal(appeared, delay: 0.1)
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
                        }
                    }
                    .buttonStyle(VoltButtonStyle())
                    .disabled(supabase.isAuthenticating)

                    SignInWithAppleButton(.continue) { request in
                        let nonce = AppleNonce.random()
                        currentAppleNonce = nonce
                        request.requestedScopes = [.email, .fullName]
                        request.nonce = AppleNonce.sha256(nonce)
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            guard
                                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                                let tokenData = credential.identityToken,
                                let idToken = String(data: tokenData, encoding: .utf8),
                                let nonce = currentAppleNonce
                            else {
                                supabase.authError = "Apple sign-in didn't return a valid credential."
                                return
                            }
                            Task { await supabase.signInWithApple(idToken: idToken, nonce: nonce) }
                        case .failure(let error):
                            // The system cancel button surfaces as ASAuthorizationError.canceled —
                            // not a real failure, so don't show an error for it.
                            if (error as? ASAuthorizationError)?.code != .canceled {
                                supabase.authError = error.localizedDescription
                            }
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
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

                    #if DEBUG
                    if let onDebugBypass {
                        Button("Skip Sign-In (Debug Build)", action: onDebugBypass)
                            .font(VertFont.caption)
                            .foregroundStyle(.voltGreen)
                            .padding(.top, Spacing.xs)
                    }
                    #endif
                }
                .padding(.bottom, Spacing.xxl)
                .reveal(appeared, delay: 0.2)
            }
            .padding(.horizontal, Spacing.lg)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { appeared = true }
        }
    }
}
