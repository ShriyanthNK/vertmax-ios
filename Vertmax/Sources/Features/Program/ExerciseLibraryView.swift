import SwiftUI

/// Browses the exercise database. When `onPick` is set, tapping an exercise
/// calls it and dismisses (picker mode, used by ProgramBuilderView);
/// otherwise it's a read-only reference browser reachable from the Program tab.
struct ExerciseLibraryView: View {
    var onPick: ((Exercise) -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var categoryFilter: ExerciseCategory?
    @State private var equipmentFilter: EquipmentAccess?

    private var filtered: [Exercise] {
        ExerciseLibrary.all.filter { exercise in
            (searchText.isEmpty || exercise.name.localizedCaseInsensitiveContains(searchText))
                && (categoryFilter == nil || exercise.category == categoryFilter)
                && (equipmentFilter == nil || exercise.equipmentLevel == equipmentFilter)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ink.ignoresSafeArea()

                VStack(spacing: 0) {
                    filterBar

                    List(filtered) { exercise in
                        exerciseRow(exercise)
                            .listRowBackground(Color.surface)
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Exercise Library")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                filterChip("All", isSelected: categoryFilter == nil) { categoryFilter = nil }
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    filterChip(category.displayName, isSelected: categoryFilter == category) {
                        categoryFilter = categoryFilter == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
    }

    private func filterChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(VertFont.body(13, weight: .semibold))
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(isSelected ? Color.voltGreen : Color.surface)
                .foregroundStyle(isSelected ? .ink : .textPrimary)
                .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func exerciseRow(_ exercise: Exercise) -> some View {
        if let onPick {
            Button {
                onPick(exercise)
                dismiss()
            } label: {
                exerciseRowLabel(exercise, showsAddIcon: true)
            }
            .buttonStyle(.plain)
        } else {
            exerciseRowLabel(exercise, showsAddIcon: false)
        }
    }

    private func exerciseRowLabel(_ exercise: Exercise, showsAddIcon: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: exercise.category.iconName)
                .foregroundStyle(.voltGreen)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xxs) {
                    Text(exercise.name)
                        .font(VertFont.body(16, weight: .medium))
                        .foregroundStyle(.textPrimary)
                    if exercise.isPlyometric {
                        Text("PLYO")
                            .font(VertFont.body(9, weight: .bold))
                            .foregroundStyle(.ink)
                            .padding(.horizontal, Spacing.xxs)
                            .padding(.vertical, 2)
                            .background(Color.voltGreen)
                            .clipShape(Capsule())
                    }
                }
                Text("\(exercise.equipmentLevel.displayName) · \(exercise.difficulty.displayName)")
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
                Text(exercise.instructions)
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
                    .lineLimit(2)
            }
            Spacer()
            if showsAddIcon {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.voltGreen)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }
}
