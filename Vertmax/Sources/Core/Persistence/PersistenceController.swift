import SwiftData
import Foundation

/// Local on-device store for measurements. v1 is local-only; Supabase sync
/// (per PRD backend decision) is layered on top once the project/schema exists.
struct PersistenceController {
    static let shared = PersistenceController()

    let container: ModelContainer

    init() {
        let schema = Schema([JumpMeasurement.self, UserProfile.self, SessionCompletion.self, CustomProgram.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// Directory where recorded jump videos are stored on-device.
    static var videosDirectory: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("JumpVideos", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
}
