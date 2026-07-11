import Foundation
import Supabase

/// Wraps the Supabase client for auth (Google sign-in) and, later, data sync.
///
/// SETUP REQUIRED before this compiles into a working auth flow:
/// 1. Create a project at supabase.com, copy its URL + anon key into
///    `projectURL` / `anonKey` below (move to an untracked xcconfig once real).
/// 2. In Supabase Dashboard → Authentication → Providers, enable Google and
///    supply its OAuth client ID/secret (from Google Cloud Console).
/// 3. In Google Cloud Console, add `https://<project-ref>.supabase.co/auth/v1/callback`
///    as an authorized redirect URI on the OAuth client.
/// 4. The `vertmax://` URL scheme is already registered in project.yml
///    (CFBundleURLTypes) — that's what brings the OAuth callback back into the app.
///    NOTE: this scheme changed from `vertgpt://` during the app rename — the
///    Supabase Dashboard's Authentication → URL Configuration → Redirect URLs
///    list must include `vertmax://login-callback` or Google sign-in will fail.
@MainActor
final class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    private static let projectURL = URL(string: "https://dnrzagutlpqoixqrjtpt.supabase.co")!
    private static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRucnphZ3V0bHBxb2l4cXJqdHB0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0MzU5OTAsImV4cCI6MjA5OTAxMTk5MH0.Z5U4HvcgXu4mAZV4xBqxTG3KMuy1t6Zma34JEY-yGvU"
    private static let redirectURL = URL(string: "vertmax://login-callback")!

    let client: SupabaseClient

    @Published var session: Session?
    @Published var isAuthenticating = false
    @Published var authError: String?

    private var authStateTask: Task<Void, Never>?

    private init() {
        client = SupabaseClient(supabaseURL: Self.projectURL, supabaseKey: Self.anonKey)
        session = client.auth.currentSession
        authStateTask = Task { [weak self] in
            guard let self else { return }
            for await (_, session) in client.auth.authStateChanges {
                self.session = session
            }
        }
    }

    func signInWithGoogle() async {
        isAuthenticating = true
        authError = nil
        defer { isAuthenticating = false }
        do {
            session = try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: Self.redirectURL
            )
        } catch {
            authError = error.localizedDescription
        }
    }

    func signOut() async {
        try? await client.auth.signOut()
        session = nil
    }

    /// Permanently deletes the signed-in user's account server-side via the
    /// `delete_user_account` RPC (a SECURITY DEFINER Postgres function scoped
    /// to `auth.uid()`) — this cascades to every synced table (profile,
    /// measurements, completions, custom programs) via their `ON DELETE
    /// CASCADE` foreign keys. Throws (rather than swallowing errors like
    /// `signOut`) so the caller can surface a failure instead of wiping local
    /// data under the false assumption the server side succeeded.
    func deleteAccount() async throws {
        _ = try await client.rpc("delete_user_account").execute()
        try? await client.auth.signOut()
        session = nil
    }

    /// Call from `.onOpenURL` so the OAuth callback completes the sign-in.
    func handle(url: URL) {
        Task { try? await client.auth.session(from: url) }
    }
}
