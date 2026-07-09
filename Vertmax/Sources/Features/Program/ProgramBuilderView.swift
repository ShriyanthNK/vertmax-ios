import SwiftUI
import SwiftData

/// Build a custom program from the exercise database. Kept to a single
/// repeating week (see CustomProgram.swift) so the builder stays simple:
/// name it, add sessions, fill each with exercises, save.
struct ProgramBuilderView: View {
    let onSaved: (CustomProgram) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var summary = ""
    @State private var sessions: [ProgramSession] = []
    @State private var pickerTargetSessionIndex: Int?

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !sessions.isEmpty
            && sessions.contains { !$0.exercises.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ink.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        detailsSection

                        ForEach(Array(sessions.enumerated()), id: \.offset) { index, _ in
                            sessionCard(at: index)
                        }

                        Button {
                            sessions.append(
                                ProgramSession(
                                    id: UUID().uuidString,
                                    dayLabel: "Day \(sessions.count + 1)",
                                    name: "",
                                    exercises: []
                                )
                            )
                        } label: {
                            Label("Add Session", systemImage: "plus")
                                .font(VertFont.headline)
                                .foregroundStyle(.voltGreen)
                                .frame(maxWidth: .infinity)
                                .padding(Spacing.md)
                                .cardStyle()
                        }
                        .pressableRow()
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("Create Program")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .sheet(item: $pickerTargetSessionIndex.asIdentifiableIndex) { wrapper in
                ExerciseLibraryView(onPick: { exercise in
                    sessions[wrapper.index].exercises.append(exercise.asProgramExercise())
                })
            }
        }
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            field(label: "Program Name", text: $name, placeholder: "e.g. My Vert Plan")
            field(label: "Summary (optional)", text: $summary, placeholder: "One line about what this program is for")
        }
    }

    private func field(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(label)
                .font(VertFont.caption)
                .foregroundStyle(.textMuted)
            TextField(placeholder, text: text)
                .font(VertFont.body(16, weight: .medium))
                .foregroundStyle(.textPrimary)
                .padding(Spacing.sm)
                .background(Color.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.sm, style: .continuous))
        }
    }

    private func sessionCard(at index: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                TextField("Session name (e.g. Legs)", text: Binding(
                    get: { sessions[index].name },
                    set: { sessions[index].name = $0 }
                ))
                .font(VertFont.headline)
                .foregroundStyle(.textPrimary)
                Spacer()
                Button {
                    sessions.remove(at: index)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.stopRed)
                }
                .accessibilityLabel("Delete session")
            }

            ForEach(Array(sessions[index].exercises.enumerated()), id: \.offset) { exIndex, exercise in
                exerciseEditRow(sessionIndex: index, exerciseIndex: exIndex, exercise: exercise)
            }

            Button {
                pickerTargetSessionIndex = index
            } label: {
                Label("Add Exercise", systemImage: "plus.circle")
                    .font(VertFont.caption)
                    .foregroundStyle(.voltGreen)
            }
        }
        .padding(Spacing.md)
        .cardStyle()
    }

    private func exerciseEditRow(sessionIndex: Int, exerciseIndex: Int, exercise: ProgramExercise) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(exercise.name)
                    .font(VertFont.body(15, weight: .medium))
                    .foregroundStyle(.textPrimary)
                HStack(spacing: Spacing.xs) {
                    Stepper(
                        "\(exercise.sets) sets",
                        value: Binding(
                            get: { sessions[sessionIndex].exercises[exerciseIndex].sets },
                            set: { sessions[sessionIndex].exercises[exerciseIndex].sets = $0 }
                        ),
                        in: 1...8
                    )
                    .font(VertFont.dataCaption)
                    .foregroundStyle(.textMuted)
                    .fixedSize()

                    TextField("reps", text: Binding(
                        get: { sessions[sessionIndex].exercises[exerciseIndex].reps },
                        set: { sessions[sessionIndex].exercises[exerciseIndex].reps = $0 }
                    ))
                    .font(VertFont.dataCaption)
                    .foregroundStyle(.textPrimary)
                    .frame(width: 50)
                    .padding(.horizontal, Spacing.xxs)
                    .padding(.vertical, 2)
                    .background(Color.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            Spacer()
            Button {
                sessions[sessionIndex].exercises.remove(at: exerciseIndex)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.textMuted)
            }
            .accessibilityLabel("Remove exercise")
        }
        .padding(.vertical, Spacing.xxs)
    }

    private func save() {
        let program = CustomProgram(name: name, summary: summary.isEmpty ? "A custom program." : summary, sessions: sessions)
        modelContext.insert(program)
        try? modelContext.save()
        onSaved(program)
        dismiss()
    }
}

/// Lets `Int?` drive `.sheet(item:)` so the picker sheet is tied to a
/// specific session index without a separate `isPresented` bool to keep in sync.
private struct IdentifiableIndex: Identifiable {
    let index: Int
    var id: Int { index }
}

private extension Binding where Value == Int? {
    var asIdentifiableIndex: Binding<IdentifiableIndex?> {
        Binding<IdentifiableIndex?>(
            get: { wrappedValue.map(IdentifiableIndex.init) },
            set: { wrappedValue = $0?.index }
        )
    }
}
