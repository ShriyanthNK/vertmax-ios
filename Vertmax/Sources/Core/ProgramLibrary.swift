import Foundation

/// Loads every bundled program JSON once at first access. Filenames are
/// listed explicitly rather than enumerated, since Xcode copies loose
/// resource files to the bundle root (no subdirectory) by default.
enum ProgramLibrary {
    private static let filenames = [
        "beginner-bodyweight",
        "beginner-gym",
        "intermediate-gym",
        "approach-jump-focus",
        "in-season-maintenance",
    ]

    static let all: [Program] = {
        let decoder = JSONDecoder()
        return filenames.compactMap { name -> Program? in
            guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                return nil
            }
            return try? decoder.decode(Program.self, from: data)
        }
    }()

    static func program(withID id: String) -> Program? {
        all.first { $0.id == id }
    }
}
