import Foundation

/// Resolves a `UserProfile.assignedProgramID` into a renderable `Program`,
/// regardless of whether it points at a bundled JSON program or a
/// user-built `CustomProgram` (prefixed "custom:").
enum ProgramResolver {
    static let customPrefix = "custom:"

    static func resolve(id: String, customPrograms: [CustomProgram]) -> Program? {
        if id.hasPrefix(customPrefix) {
            return customPrograms.first { $0.referenceID == id }?.asProgram()
        }
        return ProgramLibrary.program(withID: id)
    }
}
