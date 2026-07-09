# Handoff — Vertmax iOS

## What you're trying to do

Vertmax is a SwiftUI iOS app (SwiftData local storage, Supabase for Google
auth) for measuring and training vertical jump. Across this session the work
was, in order:

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

Both commits are pushed to `origin/master`. Build verified clean via
`xcodebuild` after every batch of changes, not just assumed from reading
code. Visual verification done via temporary debug-seed-data +
debug-auto-bypass hacks in `VertmaxApp.swift`/`RootTabView.swift` (see
"How to continue" below) — always reverted before committing.

## What's NOT done (real gaps, not yet started)

- **Supabase sync** — auth works, but SwiftData is 100% local-only. No
  cloud backup/sync. Flagged to the user as the biggest remaining gap; they
  just installed the Supabase skill/plugin, so this is likely next.
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

## Exactly how to continue

1. `cd ~/developer/vertmax-ios && git log --oneline -5` — confirm `HEAD` is
   `e07bea7` or later, working tree clean.
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
4. **Next most valuable work**, in the priority order discussed with the
   user: (a) Supabase data sync — likely what they want next, given they
   just added the Supabase skill; (b) build out the Coach tab; (c) add
   automated tests (currently zero); (d) verify `JumpAnalyzer`'s real Vision
   pipeline on an actual device, not just the Simulator fallback.
5. If doing another review pass, re-run `code-review` at high effort against
   the actual diff in scope (`git diff HEAD~1...HEAD` or whatever range is
   relevant) — this session's review was thorough but scoped specifically to
   the redesign commit, not the whole codebase.
