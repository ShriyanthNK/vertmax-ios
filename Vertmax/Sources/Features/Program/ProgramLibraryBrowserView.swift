import SwiftUI
import SwiftData

/// Lets a user switch their active program — the gap that made the Program
/// tab feel like a dead end once onboarding auto-assigned one.
struct ProgramLibraryBrowserView: View {
    let activeProgramID: String
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomProgram.createdAt, order: .reverse) private var customPrograms: [CustomProgram]
    @State private var showBuilder = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ink.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Button {
                            showBuilder = true
                        } label: {
                            Label("Create Your Own Program", systemImage: "plus.circle.fill")
                                .font(VertFont.headline)
                                .foregroundStyle(.ink)
                                .frame(maxWidth: .infinity)
                                .padding(Spacing.md)
                                .background(Color.voltGreen)
                                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
                        }

                        if !customPrograms.isEmpty {
                            sectionHeader("My Programs")
                            ForEach(customPrograms) { program in
                                programRow(id: program.referenceID, name: program.name, summary: program.summary)
                            }
                        }

                        sectionHeader("Prebuilt Programs")
                        ForEach(ProgramLibrary.all) { program in
                            programRow(id: program.id, name: program.name, summary: program.summary)
                        }
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("Switch Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showBuilder) {
                ProgramBuilderView(onSaved: { program in
                    onSelect(program.referenceID)
                    dismiss()
                })
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(VertFont.caption)
            .foregroundStyle(.textMuted)
            .padding(.top, Spacing.xs)
    }

    private func programRow(id: String, name: String, summary: String) -> some View {
        let isActive = id == activeProgramID
        return Button {
            onSelect(id)
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(name)
                        .font(VertFont.headline)
                        .foregroundStyle(.textPrimary)
                    Text(summary)
                        .font(VertFont.caption)
                        .foregroundStyle(.textMuted)
                        .lineLimit(2)
                }
                Spacer()
                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.voltGreen)
                }
            }
            .padding(Spacing.md)
            .background(isActive ? Color.voltGreen.opacity(0.12) : Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
        .buttonStyle(.plain)
    }
}
