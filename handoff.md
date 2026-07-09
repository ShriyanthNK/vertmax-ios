# Handoff — Vertmax iOS

## What you're trying to do

Vertmax is a SwiftUI iOS app (SwiftData local storage, Supabase for Google
auth + data sync) for measuring and training vertical jump. Work so far,
across two sessions, in order:

1. Redesign the entire UI to look professional/distinctive (custom
   typography, a real design system, motion) instead of the placeholder
   system-font look it shipped with.
2. Add four features the user picked from a brainstorm: consistency streaks,
   adaptive program progression, a shareable "vert card," and a home-screen
   widget.
3. An open-ended overnight pass: "look through the whole app, optimize
   everything possible, fix any bugs, use any of the skills you have" — a
   full code review + security review + accessibility sweep + manual audit,
   then fix everything found.
4. Supabase cloud sync (session 2) — the biggest gap flagged at the end of
   session 1. Metadata-only (no video upload — see "Key decisions").

## What's done

**Redesign** (commit `9049908`): embedded Archivo Black + IBM Plex Mono
fonts (OFL-licensed, files + licenses in `Vertmax/Resources/Fonts/`), built
a shared design-system layer (`Vertmax/Sources/DesignSystem/`: `Chrome.swift`
has card/button chrome + shared badges, `TrajectoryArc.swift` is the
signature jump-arc motif, `Motion.swift` has the entrance-reveal helper),
applied across all ~15 screens.

**Features** (commit `9049908`):
- `StreakCalculator.swift` — consistency streak, shown on Home
- `ProgramProgression.swift` — bumps next week's volume after a fully
  completed week, surfaced via a `BoostBadge` on Home/Program tab/full
  schedule
- `ShareCardView.swift` + share flow on `MeasurementResultView`
- `Vertmax/WidgetExtension/` — a real WidgetKit extension (small/medium),
  synced via an App-Group-shared snapshot (`Sources/Shared/WidgetSnapshot.swift`,
  `Sources/Core/WidgetSnapshotRefresher.swift`)
- An onboarding step showing users how to add the widget (iOS has no API to
  add it programmatically)
- `#if DEBUG` sign-in bypass button (compiled out of Release) and a
  `#if targetEnvironment(simulator)` fallback in `JumpAnalyzer.swift`
  (Vision's body-pose detector needs the Neural Engine, which the Simulator
  doesn't have, so real measurement always fails there)

**Overnight audit + fixes** (commit `e07bea7`): ran a full 8-angle code
review, a security review, and a manual audit of every file the redesign
hadn't touched, then fixed everything CONFIRMED/PLAUSIBLE:
- Real bugs: a share link that could point at a file that failed to write;
  a duplicate-`SessionCompletion`-insert race on fast double-tap; completion
  matching that never filtered by `programID` (latent cross-program
  collision risk); an active-program row that lost its highlight tint in
  the redesign; a disabled button that only dimmed its background, not its
  label; a widget that showed fabricated numbers to real users with zero
  measurements instead of an honest empty state
- Performance: `HomeView`/`ProgramTabView` were recomputing the whole
  program-progression pipeline 3–5x per render; widget refresh was blocking
  the completion-tap animation
- Accessibility: added VoiceOver labels to all 9 icon-only buttons in the
  app (there were none); added an empty state to exercise search
- Dedup: extracted `CredibilityBadge`, `FrameThumbnail`, `BoostBadge` (each
  was hand-copied 2–3x); consolidated "days since last measurement" into
  `StreakCalculator.daysSince`

**Supabase cloud sync** (session 2, uncommitted at time of writing — see
"Exactly how to continue"):
- 4 Postgres tables in the `Vert GPT` Supabase project (`dnrzagutlpqoixqrjtpt`):
  `user_profiles`, `jump_measurements`, `session_completions`,
  `custom_programs`. Each has owner-scoped RLS (`auth.uid() = user_id` on
  select/insert/update/delete) — confirmed clean via the security advisor.
  Applied directly through the Supabase MCP (`apply_migration`), not the
  Supabase CLI (not installed in this environment).
- `Vertmax/Sources/Core/Sync/SyncEngine.swift` — the whole sync layer:
  private snake_case `Codable` DTOs per table, `push(...)` functions
  (fire-and-forget, best-effort, called right after a local
  insert/delete — same convention as `WidgetSnapshotRefresher`, the only
  precedent for "call this after a mutation" in the codebase), and a
  `reconcile(context:)` that pushes every local row (idempotent upsert,
  catches anything a best-effort push missed while offline) then pulls the
  user's full remote state and inserts whatever's missing locally.
- Wired into the 6 places the 4 synced models are actually created/deleted:
  `OnboardingFlowView` (profile), `HomeView.completeSession` +
  `ProgramView.toggleCompletion` (both insert *and* delete branches of the
  latter), `ManualEntryView`/`MeasurementResultView` (measurements),
  `ProgramBuilderView` (custom programs).
- `reconcile(context:)` runs from `RootTabView` on two triggers: the
  signed-in transition (`.onChange(of: isSignedIn)`) and app foreground
  (`.onChange(of: scenePhase)`, `== .active`) — both live in `RootTabView`
  rather than `VertmaxApp` deliberately, to avoid relying on `Scene`'s
  `onChange` (uncertain API surface) when `View.onChange` is the
  well-established pattern and `RootTabView` already had `modelContext`.
- **Verified live**, not just build-checked: signed in with a real Google
  account on the simulator, walked through onboarding, logged a manual
  measurement, checked off a program session, and built a custom program —
  then queried the 4 Supabase tables directly and confirmed all 4 rows
  landed with correct field values (including the `custom_programs.sessions`
  jsonb array decoding to the right session count).

Both session-1 commits are pushed to `origin/master`. Build verified clean
via `xcodebuild` after every batch of changes, not just assumed from
reading code. Visual verification done via temporary debug-seed-data +
debug-auto-bypass hacks in `VertmaxApp.swift`/`RootTabView.swift` (see
"How to continue" below) — always reverted before committing.

## What's NOT done (real gaps, not yet started)

- **Video sync** — deliberate scope cut, not an oversight. Cloud sync
  covers all 4 SwiftData models' structured data, but `JumpMeasurement`'s
  recorded video file never leaves the device (`videoFilename` isn't even
  a synced column). Reinstalling/switching devices recovers all your
  numbers and history but not old video clips. Revisit only if a
  video-history UI ever gets built — there isn't one today, even locally
  (see the pre-existing sharing gap below).
- **Session-completion delete-propagation is implemented but not verified
  live** — `SyncEngine.reconcileCompletions` is supposed to delete a local
  completion if it disappeared remotely (e.g. unchecked on another device),
  but only when this round's push is confirmed to have succeeded first (to
  avoid misreading "offline, never pushed" as "deleted elsewhere"). Only
  the push/insert paths were exercised this session; the cross-device
  delete path wasn't.
- **Coach tab** — still a placeholder (`CoachView.swift`), per the app's own
  PRD §5.4.
- **Zero automated tests** anywhere in the project.
- **Real-device verification** — `JumpAnalyzer`'s actual Vision-based CV
  pipeline has never been exercised on real hardware this session, only the
  Simulator fallback path. Numbers it produces on-device are unverified.
- Sharing only works from the fresh camera-verified result screen, not from
  Progress-dashboard history or manual entries.
- Two duplication findings from the code review were deliberately left
  alone (judgment calls, not bugs): `ProgramView`/`ExerciseLibraryView`
  exercise-row rendering (different contexts — full schedule vs. library
  picker), and the onboarding widget mock hand-duplicating the real widget's
  layout (can't literally share the view across targets given the widget's
  curated source list — see project.yml).
- `CameraService.swift`'s `recordingContinuation` (set inside `sessionQueue`,
  cleared from an `AVCaptureFileOutputRecordingDelegate` callback that may
  run on a different queue) looked like a possible pre-existing race during
  the audit. **Not touched or fixed** — it predates this session, and
  confirming it would need real-device testing under load. Worth a look if
  you're ever debugging a dropped/duplicate recording completion.

## What failed / mistakes to avoid

- **Swift compiler crash**: naming a local `let` the same as a method it
  calls inside its own initializer closure —
  `let todaySession = x.flatMap { todaySession(in: $0) }` — crashes the
  compiler with "failed to produce diagnostic for expression." Fixed by
  renaming the methods (`resolveTodaySession`, `resolveUpNext`). Watch for
  this pattern in any future "hoist a computed property to a local `let`"
  refactor.
- **Can't automate simulator taps here** — `osascript`/System Events has no
  Accessibility permission in this environment and it isn't grantable
  non-interactively. Every UI verification went through a temporary
  `#if DEBUG` pattern instead: flip `RootTabView.debugBypassAuth`'s default
  to `true`, and/or add a `seedDemoDataIfRequested` block to
  `VertmaxApp.init()` gated on an env var, screenshot via
  `xcrun simctl io <udid> screenshot`, then **revert both before
  committing**. Don't skip the revert — shipping `debugBypassAuth = true` as
  the default would make every debug build auto-skip sign-in.
- **`simctl install` does not wipe existing app data** — only
  `simctl uninstall` does. Reusing a stale install skewed one verification
  pass (a leftover profile with no measurements). Always
  `xcrun simctl uninstall <udid> com.vertmax.app` before a from-scratch
  verification.
- Only Xcode **Command Line Tools** were present at the start of the
  session — `xcodebuild`/`simctl` were unavailable until the user separately
  installed full Xcode partway through. If `xcodebuild` fails oddly, check
  `xcode-select -p` points at `/Applications/Xcode.app`, not the CLT.
- `VNDetectHumanBodyPoseRequest` (Vision) does not run in the iOS
  Simulator — always returns zero results regardless of the input video.
  That's a hardware limitation (no Neural Engine), not a bug — it's why the
  `#if targetEnvironment(simulator)` fallback exists in `JumpAnalyzer.swift`.
- **Still can't automate simulator taps** (session 2 confirmed this is
  still true) — but real OAuth sign-in can't be scripted around anyway
  (Google's consent screen needs an actual account + browser interaction),
  so for anything gated behind sign-in the only path is asking the user to
  tap through the flow themselves, then verifying server-side via SQL
  afterward. That turned out to be a *better* verification method than the
  debug-bypass/seed-data tricks from session 1 for this specific feature —
  it exercises the real auth + network path instead of a local fixture.
- **The Supabase MCP's `execute_sql`/`get_logs` are auto-mode-gated against
  reading `auth.users` (or auth service logs) without the user having
  specifically asked for that data** — a plain "does Google sign-in work"
  question isn't authorization to pull real emails/PII. Once the user
  explicitly said "how do I check in supabase," querying `auth.users` (and
  the app's own tables, scoped to that one `user_id`) was fine. Ask first
  or wait for an explicit "check X" before querying tables with real user
  data, even read-only.

## Key decisions and rationale

- **Archivo Black + IBM Plex Mono**, not a single bold rounded numeral font.
  Mono is used for *every measured number* app-wide — a deliberate
  "instrument readout" signature tying to the app's actual value prop
  (camera-measured precision), not just a stylistic choice. Archivo Black is
  used sparingly (wordmark, screen titles, eyebrows) per "spend your
  boldness in one place." Both OFL-licensed; downloaded from
  `github.com/google/fonts` with license files kept alongside in
  `Vertmax/Resources/Fonts/`.
- **TrajectoryArc** (a single rising parabolic arc shape) is the one
  signature background motif, echoing the logo mark's jump arc. Used
  sparingly — hero cards, sign-in, the measuring-loading state — not
  sprinkled everywhere.
- **Widget syncs via a shared UserDefaults snapshot** (`WidgetSnapshotStore`
  in an App Group), not a shared SwiftData store. Deliberately simpler and
  lower-risk than giving the widget extension direct model access — the
  widget extension has zero SwiftData dependency (see its curated source
  list in `project.yml`).
- **Auto-progression is deliberately conservative**: +1 rep (if numeric) or
  +1 set (if not, capped at 6), only when the immediately preceding
  non-deload week was 100% completed, never compounding across multiple
  weeks, never touching deload weeks. There's no weight/RPE tracking in the
  app to inform real periodization, so this only ever nudges, never
  replaces authored programming.
- **`boostedWeeks` is threaded as a separate value** alongside `Program`
  (via `ProgramProgression.Result`) rather than embedding a flag on
  `Program`/`ProgramWeek` themselves. The code review flagged this as an
  altitude tradeoff (state that could arguably live on the model), but it
  was left as-is — only 3 call sites, all correctly wired, and changing it
  would mean touching the `Codable` shapes used for bundled-JSON program
  decoding.
- **Sign Out uses `OutlineButtonStyle`, not `.stopRed`** — `Colors.swift`
  documents `stopRed`/`cautionAmber` as reserved for injury/safety flows
  only; Sign Out isn't one. This was a real bug in the original code,
  fixed during the redesign.
- Both debug escape hatches (`#if DEBUG` bypass, `#if targetEnvironment(simulator)`
  fallback) were confirmed — via `project.pbxproj` inspection and a
  dedicated security-review pass — to compile out of Release builds
  entirely. Not just assumed.
- **Sync is insert/delete-only per model, deliberately no field-level
  conflict resolution (no `updatedAt`, no last-write-wins merge).**
  Checked every mutation site in the codebase first: `UserProfile` and
  `CustomProgram` are create-once (never edited after creation anywhere in
  the app), `JumpMeasurement` is append-only, and `SessionCompletion` is
  the only model ever deleted locally (unchecking a session). Since
  nothing is ever field-edited post-creation, a plain idempotent upsert
  keyed by the model's own UUID is sufficient — no CRDT/timestamp-merge
  machinery needed. If a future feature adds editing (e.g. an "edit
  profile" screen), this assumption breaks and `reconcile` would need a
  real conflict-resolution strategy.
- **Video (`JumpMeasurement.videoFilename`) deliberately excluded from the
  synced columns** — confirmed via full-codebase grep that no view ever
  reads a *saved* video back from `PersistenceController.videosDirectory`
  (only the pre-save temp recording, at save time, for thumbnails/share).
  Syncing video would mean standing up Supabase Storage + upload/download
  plumbing for a feature with no UI to consume it on a second device.
  Confirmed with the user before building rather than assumed.
- **`reconcile(context:)` triggers live in `RootTabView`, not
  `VertmaxApp`** — both sign-in (`.onChange(of: isSignedIn)`) and
  foreground (`.onChange(of: scenePhase)`) needed a `ModelContext`, which
  `RootTabView` already reads via `@Environment(\.modelContext)`.
  Deliberately did not add `.onChange` directly on the `WindowGroup`
  `Scene` in `VertmaxApp` to avoid depending on `Scene.onChange` API
  specifics when the plain `View.onChange` pattern was already
  well-established and sufficient.

## Exactly how to continue

1. `cd ~/developer/vertmax-ios && git log --oneline -5` — confirm `HEAD` is
   the Supabase-sync commit (message mentions "sync") or later, working
   tree clean.
2. **To build/run**: simulator is `8E3AA816-4745-4565-A8C8-48801C38DB06`
   (iPhone 17 Pro).
   ```
   cd Vertmax && xcodegen generate && \
   xcodebuild -project Vertmax.xcodeproj -scheme Vertmax \
     -destination "id=8E3AA816-4745-4565-A8C8-48801C38DB06" \
     -configuration Debug build
   ```
   Then find the `.app` under
   `~/Library/Developer/Xcode/DerivedData/Vertmax-*/Build/Products/Debug-iphonesimulator`,
   `xcrun simctl install <udid> <path>`, `xcrun simctl launch <udid> com.vertmax.app`.
3. **To verify UI changes without manual taps**: temporarily set
   `RootTabView.swift`'s `debugBypassAuth` default to `true`, screenshot via
   `xcrun simctl io <udid> screenshot out.png`, then **revert before
   committing**. For screens needing real data, temporarily re-add a
   `seedDemoDataIfRequested(into:)` block to `VertmaxApp.init()` gated on
   `ProcessInfo.processInfo.environment["VERTMAX_SEED_DEMO_DATA"]`, launch
   with `SIMCTL_CHILD_VERTMAX_SEED_DEMO_DATA=1 xcrun simctl launch ...`, and
   again **revert before committing**. `git diff` before every commit to
   confirm no debug scaffolding leaked in.
   Note: this trick doesn't work for anything gated behind real Supabase
   auth (sync, in particular) — `debugBypassAuth` skips Supabase sign-in
   entirely, so there's no `session`/`user_id` and every `SyncEngine` call
   no-ops. Verifying sync requires the user to actually sign in with a real
   Google account and use the app, then checking Supabase directly (`open
   -a Simulator` to bring the window forward for them, then
   `execute_sql`/MCP against project `dnrzagutlpqoixqrjtpt` once they
   confirm they've acted — see "What failed" above on asking first).
4. **Next most valuable work**, in priority order: (a) build out the Coach
   tab (still `CoachView.swift` placeholder); (b) add automated tests
   (currently zero); (c) verify `JumpAnalyzer`'s real Vision pipeline on an
   actual device, not just the Simulator fallback; (d) verify the
   session-completion delete-propagation path in sync (uncheck a session,
   confirm the row actually disappears from `session_completions`, ideally
   simulating a second device by deleting it directly in Supabase and
   confirming the next `reconcile()` removes it locally too).
5. If doing another review pass, re-run `code-review` at high effort against
   the actual diff in scope (`git diff HEAD~1...HEAD` or whatever range is
   relevant) — each session's review was thorough but scoped to that
   session's own diff, not the whole codebase.
