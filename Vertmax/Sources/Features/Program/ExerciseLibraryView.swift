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

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        List(filtered) { exercise in
                            exerciseRow(exercise)
                                .listRowBackground(Color.surface)
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.plain)
                    }
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

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundStyle(.textMuted)
            Text("No exercises found")
                .font(VertFont.headline)
                .foregroundStyle(.textPrimary)
            Text("Try a different search term or filter.")
                .font(VertFont.caption)
                .foregroundStyle(.textMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                ChipToggle(title: "All", isSelected: categoryFilter == nil) { categoryFilter = nil }
                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    ChipToggle(title: category.displayName, isSelected: categoryFilter == category) {
                        categoryFilter = categoryFilter == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
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
                        PlyoBadge()
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
