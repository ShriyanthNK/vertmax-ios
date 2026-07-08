import Foundation

/// Loads the bundled exercise database once at first access.
enum ExerciseLibrary {
    static let all: [Exercise] = {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        return (try? JSONDecoder().decode([Exercise].self, from: data)) ?? []
    }()
}
