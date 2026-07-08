import Foundation
import SwiftData

enum JumpType: String, Codable, CaseIterable {
    case standing
    case approach
}

/// Source of the measurement — camera-derived numbers are the credible,
/// shareable ones; manual entry is the fallback for users who can't film.
enum MeasurementSource: String, Codable {
    case cameraFlightTime
    case manualEntry
}

@Model
final class JumpMeasurement {
    var id: UUID
    var date: Date
    var jumpType: JumpType
    var heightInches: Double
    var source: MeasurementSource

    // Populated for camera-derived measurements so the result screen can
    // show "verified by video" — the credibility requirement in PRD §5.2.
    var videoFilename: String?
    var takeoffFrameIndex: Int?
    var landingFrameIndex: Int?
    var frameRate: Double?

    init(
        id: UUID = UUID(),
        date: Date = .now,
        jumpType: JumpType,
        heightInches: Double,
        source: MeasurementSource,
        videoFilename: String? = nil,
        takeoffFrameIndex: Int? = nil,
        landingFrameIndex: Int? = nil,
        frameRate: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.jumpType = jumpType
        self.heightInches = heightInches
        self.source = source
        self.videoFilename = videoFilename
        self.takeoffFrameIndex = takeoffFrameIndex
        self.landingFrameIndex = landingFrameIndex
        self.frameRate = frameRate
    }

    /// Flight time in seconds, when derived from video.
    var flightTimeSeconds: Double? {
        guard let takeoffFrameIndex, let landingFrameIndex, let frameRate, frameRate > 0 else {
            return nil
        }
        return Double(landingFrameIndex - takeoffFrameIndex) / frameRate
    }
}
