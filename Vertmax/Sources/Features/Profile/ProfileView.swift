import SwiftUI
import SwiftData

struct ProfileView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteConfirmation = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountError: String?

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

                    Button("Delete Account", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .disabled(isDeletingAccount)
                }
                .padding(Spacing.lg)
            }
            .navigationTitle("Profile")
            .confirmationDialog(
                "Delete Your Account?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently deletes your account and all synced data — measurements, program history, and streaks. This can't be undone.")
            }
            .alert(
                "Couldn't Delete Account",
                isPresented: .constant(deleteAccountError != nil),
                presenting: deleteAccountError
            ) { _ in
                Button("OK") { deleteAccountError = nil }
            } message: { error in
                Text(error)
            }
        }
    }

    private func deleteAccount() async {
        isDeletingAccount = true
        defer { isDeletingAccount = false }
        do {
            try await supabase.deleteAccount()
            wipeLocalData()
        } catch {
            deleteAccountError = error.localizedDescription
        }
    }

    /// Deletion is server-authoritative — this only runs after
    /// `supabase.deleteAccount()` has confirmed the account (and, via
    /// cascade, every synced row) is gone. Also removes recorded jump
    /// videos, which never left the device in the first place.
    private func wipeLocalData() {
        let measurements = (try? modelContext.fetch(FetchDescriptor<JumpMeasurement>())) ?? []
        for measurement in measurements {
            if let filename = measurement.videoFilename {
                try? FileManager.default.removeItem(
                    at: PersistenceController.videosDirectory.appendingPathComponent(filename)
                )
            }
        }
        measurements.forEach(modelContext.delete)

        let profiles = (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []
        profiles.forEach(modelContext.delete)

        let completions = (try? modelContext.fetch(FetchDescriptor<SessionCompletion>())) ?? []
        completions.forEach(modelContext.delete)

        let customPrograms = (try? modelContext.fetch(FetchDescriptor<CustomProgram>())) ?? []
        customPrograms.forEach(modelContext.delete)

        try? modelContext.save()
    }
}
