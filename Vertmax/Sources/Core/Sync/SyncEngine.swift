import Foundation
import SwiftData
import Supabase

/// Mirrors the local SwiftData store to Supabase Postgres so a signed-in
/// user's data survives a reinstall or shows up on a second device. Videos
/// stay device-local (`JumpMeasurement.videoFilename` is never synced) —
/// there's no video-history UI today, so only the structured data below
/// makes the trip.
///
/// Push calls are fire-and-forget best-effort: call right after a local
/// insert/delete, same convention as `WidgetSnapshotRefresher`. If the
/// device is offline the call just fails silently — the next
/// `reconcile(context:)` pass (on sign-in / app foreground) re-pushes
/// everything, since every push is an idempotent upsert keyed by the
/// model's own UUID.
enum SyncEngine {

    // MARK: - Push (fire-and-forget, call right after a local mutation)

    @MainActor
    static func push(profile: UserProfile) {
        guard let userID = SupabaseManager.shared.session?.user.id else { return }
        let client = SupabaseManager.shared.client
        let dto = UserProfileDTO(profile, userID: userID)
        Task.detached(priority: .utility) {
            do {
                try await client.from("user_profiles").upsert(dto).execute()
            } catch {
                print("SyncEngine: profile push failed: \(error)")
            }
        }
    }

    @MainActor
    static func push(measurement: JumpMeasurement) {
        guard let userID = SupabaseManager.shared.session?.user.id else { return }
        let client = SupabaseManager.shared.client
        let dto = JumpMeasurementDTO(measurement, userID: userID)
        Task.detached(priority: .utility) {
            do {
                try await client.from("jump_measurements").upsert(dto).execute()
            } catch {
                print("SyncEngine: measurement push failed: \(error)")
            }
        }
    }

    @MainActor
    static func push(completion: SessionCompletion) {
        guard let userID = SupabaseManager.shared.session?.user.id else { return }
        let client = SupabaseManager.shared.client
        let dto = SessionCompletionDTO(completion, userID: userID)
        Task.detached(priority: .utility) {
            do {
                try await client.from("session_completions").upsert(dto).execute()
            } catch {
                print("SyncEngine: completion push failed: \(error)")
            }
        }
    }

    /// Call right after locally deleting a `SessionCompletion` (the one
    /// model in the app that ever gets deleted post-creation).
    @MainActor
    static func pushDelete(completionID: UUID) {
        guard SupabaseManager.shared.session != nil else { return }
        let client = SupabaseManager.shared.client
        Task.detached(priority: .utility) {
            do {
                try await client.from("session_completions").delete().eq("id", value: completionID).execute()
            } catch {
                print("SyncEngine: completion delete push failed: \(error)")
            }
        }
    }

    @MainActor
    static func push(program: CustomProgram) {
        guard let userID = SupabaseManager.shared.session?.user.id else { return }
        let client = SupabaseManager.shared.client
        let dto = CustomProgramDTO(program, userID: userID)
        Task.detached(priority: .utility) {
            do {
                try await client.from("custom_programs").upsert(dto).execute()
            } catch {
                print("SyncEngine: program push failed: \(error)")
            }
        }
    }

    // MARK: - Reconcile (full two-way sync: call on sign-in and app foreground)

    /// Pushes every local row (idempotent upsert, catches anything a
    /// best-effort push above missed while offline) then pulls the user's
    /// full remote state and inserts whatever's missing locally — the
    /// "new device" / "reinstalled the app" case. For `SessionCompletion`
    /// (the only model with a local delete path) also removes local rows
    /// that disappeared remotely, but only once we've confirmed this
    /// round's push actually reached the server — otherwise an offline
    /// push could look like a remote delete and erase unsynced local data.
    @MainActor
    static func reconcile(context: ModelContext) async {
        guard let userID = SupabaseManager.shared.session?.user.id else { return }
        let client = SupabaseManager.shared.client

        await reconcileProfiles(context: context, client: client, userID: userID)
        await reconcileMeasurements(context: context, client: client, userID: userID)
        await reconcileCompletions(context: context, client: client, userID: userID)
        await reconcilePrograms(context: context, client: client, userID: userID)

        WidgetSnapshotRefresher.refresh(context: context)
    }

    @MainActor
    private static func reconcileProfiles(context: ModelContext, client: SupabaseClient, userID: UUID) async {
        let local = (try? context.fetch(FetchDescriptor<UserProfile>())) ?? []
        let localIDs = Set(local.map(\.id))

        do {
            let dtos = local.map { UserProfileDTO($0, userID: userID) }
            if !dtos.isEmpty {
                try await client.from("user_profiles").upsert(dtos).execute()
            }
        } catch {
            print("SyncEngine: profile reconcile push failed: \(error)")
        }

        do {
            let remote: [UserProfileDTO] = try await client
                .from("user_profiles")
                .select()
                .eq("user_id", value: userID)
                .execute()
                .value
            for dto in remote where !localIDs.contains(dto.id) {
                context.insert(dto.asModel())
            }
            try? context.save()
        } catch {
            print("SyncEngine: profile reconcile pull failed: \(error)")
        }
    }

    @MainActor
    private static func reconcileMeasurements(context: ModelContext, client: SupabaseClient, userID: UUID) async {
        let local = (try? context.fetch(FetchDescriptor<JumpMeasurement>())) ?? []
        let localIDs = Set(local.map(\.id))

        do {
            let dtos = local.map { JumpMeasurementDTO($0, userID: userID) }
            if !dtos.isEmpty {
                try await client.from("jump_measurements").upsert(dtos).execute()
            }
        } catch {
            print("SyncEngine: measurement reconcile push failed: \(error)")
        }

        do {
            let remote: [JumpMeasurementDTO] = try await client
                .from("jump_measurements")
                .select()
                .eq("user_id", value: userID)
                .execute()
                .value
            for dto in remote where !localIDs.contains(dto.id) {
                context.insert(dto.asModel())
            }
            try? context.save()
        } catch {
            print("SyncEngine: measurement reconcile pull failed: \(error)")
        }
    }

    @MainActor
    private static func reconcileCompletions(context: ModelContext, client: SupabaseClient, userID: UUID) async {
        let local = (try? context.fetch(FetchDescriptor<SessionCompletion>())) ?? []
        let localIDs = Set(local.map(\.id))

        var pushSucceeded = true
        do {
            let dtos = local.map { SessionCompletionDTO($0, userID: userID) }
            if !dtos.isEmpty {
                try await client.from("session_completions").upsert(dtos).execute()
            }
        } catch {
            pushSucceeded = false
            print("SyncEngine: completion reconcile push failed: \(error)")
        }

        do {
            let remote: [SessionCompletionDTO] = try await client
                .from("session_completions")
                .select()
                .eq("user_id", value: userID)
                .execute()
                .value
            let remoteIDs = Set(remote.map(\.id))
            for dto in remote where !localIDs.contains(dto.id) {
                context.insert(dto.asModel())
            }
            if pushSucceeded {
                for completion in local where !remoteIDs.contains(completion.id) {
                    context.delete(completion)
                }
            }
            try? context.save()
        } catch {
            print("SyncEngine: completion reconcile pull failed: \(error)")
        }
    }

    @MainActor
    private static func reconcilePrograms(context: ModelContext, client: SupabaseClient, userID: UUID) async {
        let local = (try? context.fetch(FetchDescriptor<CustomProgram>())) ?? []
        let localIDs = Set(local.map(\.id))

        do {
            let dtos = local.map { CustomProgramDTO($0, userID: userID) }
            if !dtos.isEmpty {
                try await client.from("custom_programs").upsert(dtos).execute()
            }
        } catch {
            print("SyncEngine: program reconcile push failed: \(error)")
        }

        do {
            let remote: [CustomProgramDTO] = try await client
                .from("custom_programs")
                .select()
                .eq("user_id", value: userID)
                .execute()
                .value
            for dto in remote where !localIDs.contains(dto.id) {
                context.insert(dto.asModel())
            }
            try? context.save()
        } catch {
            print("SyncEngine: program reconcile pull failed: \(error)")
        }
    }
}

// MARK: - DTOs (snake_case columns, mirror the Postgres schema in `create_sync_tables`)

private struct UserProfileDTO: Codable {
    let id: UUID
    let userId: UUID
    let sport: String
    let jumpTypePreference: String
    let goal: String
    let equipment: String
    let experience: String
    let hasInjury: Bool
    let assignedProgramId: String
    let onboardingCompletedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, sport, goal, equipment, experience
        case userId = "user_id"
        case jumpTypePreference = "jump_type_preference"
        case hasInjury = "has_injury"
        case assignedProgramId = "assigned_program_id"
        case onboardingCompletedAt = "onboarding_completed_at"
    }

    init(_ model: UserProfile, userID: UUID) {
        id = model.id
        userId = userID
        sport = model.sport.rawValue
        jumpTypePreference = model.jumpTypePreference.rawValue
        goal = model.goal
        equipment = model.equipment.rawValue
        experience = model.experience.rawValue
        hasInjury = model.hasInjury
        assignedProgramId = model.assignedProgramID
        onboardingCompletedAt = model.onboardingCompletedAt
    }

    func asModel() -> UserProfile {
        UserProfile(
            id: id,
            sport: Sport(rawValue: sport) ?? .general,
            jumpTypePreference: JumpType(rawValue: jumpTypePreference) ?? .standing,
            goal: goal,
            equipment: EquipmentAccess(rawValue: equipment) ?? .bodyweight,
            experience: ExperienceLevel(rawValue: experience) ?? .new,
            hasInjury: hasInjury,
            assignedProgramID: assignedProgramId,
            onboardingCompletedAt: onboardingCompletedAt
        )
    }
}

private struct JumpMeasurementDTO: Codable {
    let id: UUID
    let userId: UUID
    let date: Date
    let jumpType: String
    let heightInches: Double
    let source: String
    let takeoffFrameIndex: Int?
    let landingFrameIndex: Int?
    let frameRate: Double?

    enum CodingKeys: String, CodingKey {
        case id, date, source
        case userId = "user_id"
        case jumpType = "jump_type"
        case heightInches = "height_inches"
        case takeoffFrameIndex = "takeoff_frame_index"
        case landingFrameIndex = "landing_frame_index"
        case frameRate = "frame_rate"
    }

    init(_ model: JumpMeasurement, userID: UUID) {
        id = model.id
        userId = userID
        date = model.date
        jumpType = model.jumpType.rawValue
        heightInches = model.heightInches
        source = model.source.rawValue
        takeoffFrameIndex = model.takeoffFrameIndex
        landingFrameIndex = model.landingFrameIndex
        frameRate = model.frameRate
    }

    func asModel() -> JumpMeasurement {
        JumpMeasurement(
            id: id,
            date: date,
            jumpType: JumpType(rawValue: jumpType) ?? .standing,
            heightInches: heightInches,
            source: MeasurementSource(rawValue: source) ?? .manualEntry,
            videoFilename: nil,
            takeoffFrameIndex: takeoffFrameIndex,
            landingFrameIndex: landingFrameIndex,
            frameRate: frameRate
        )
    }
}

private struct SessionCompletionDTO: Codable {
    let id: UUID
    let userId: UUID
    let programId: String
    let weekNumber: Int
    let sessionId: String
    let completedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case programId = "program_id"
        case weekNumber = "week_number"
        case sessionId = "session_id"
        case completedAt = "completed_at"
    }

    init(_ model: SessionCompletion, userID: UUID) {
        id = model.id
        userId = userID
        programId = model.programID
        weekNumber = model.weekNumber
        sessionId = model.sessionID
        completedAt = model.completedAt
    }

    func asModel() -> SessionCompletion {
        SessionCompletion(id: id, programID: programId, weekNumber: weekNumber, sessionID: sessionId, completedAt: completedAt)
    }
}

private struct CustomProgramDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let summary: String
    let sessions: [ProgramSession]
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, summary, sessions
        case userId = "user_id"
        case createdAt = "created_at"
    }

    init(_ model: CustomProgram, userID: UUID) {
        id = model.id
        userId = userID
        name = model.name
        summary = model.summary
        sessions = model.sessions
        createdAt = model.createdAt
    }

    func asModel() -> CustomProgram {
        CustomProgram(id: id, name: name, summary: summary, sessions: sessions, createdAt: createdAt)
    }
}
