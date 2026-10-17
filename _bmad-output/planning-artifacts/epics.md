---
status: draft
stepsCompleted: [1, 2, 3, 4]
revisions:
  - "2026-10-17: applied party decisions for the 7 coverage gaps (new Story 3.9; ACs added to 1.2, 2.1, 2.3, 3.4, 3.5, 3.6, 3.8, 4.3, 4.4, 5.1, 5.6, 6.5); step 4 re-validation pending"
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/ux-design-spec.md
  - _bmad-output/planning-artifacts/ux-research.md
  - _bmad-output/project-context.md
---

# ir-remote-android - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for ir-remote-android, decomposing the requirements from the PRD, UX Design if it exists, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

Priority: P0 = v1.0, P1 = v1.x, P2 = later.

FR1 (P0): Detect available transmitters and supported frequencies. On first launch the screen shows what is available and why.
FR2 (P0): Transmit a raw code from the built-in transmitter. Validated pattern: positive durations, even length, total < 2 s.
FR3 (P0): Encode NEC/NECx, Samsung32, Sony 12/15/20, RC5, RC6, Kaseikyo, JVC, Sharp, Denon. Vector tests against IrScrutinizer/Flipper for each protocol.
FR4 (P0): Pronto hex <-> raw. Lossless round trip apart from carrier quantization.
FR5 (P0): Search by type and brand on Flipper-IRDB. Results within 2 s with cached index.
FR6 (P0): Guided trial of candidates. At most 3 taps per candidate.
FR7 (P0): Local library with favorites. Works offline after saving.
FR8 (P0): Repeat while button held, using repeat frames. NEC uses the repeat code.
FR9 (P0): Import Flipper `.ir`, Pronto, raw; JSON export/backup. Import of all of Flipper-IRDB without crashes (CI).
FR10 (P1): Second source irdb with attribution. Notice visible in About and in the source sheet.
FR11 (P1): Audio jack transmitter. Test with a real adapter at 38 kHz.
FR12 (P1): Tiqiaa and ElkSmart USB dongles. Send verified; USB permission handled.
FR13 (P1): Tasmota, ESPHome, Broadlink network blasters. Manual add by IP; credentials only on device.
FR14 (P1): Air conditioner with state. SmartIR or Flipper profiles, state persisted.
FR15 (P1): Widget and quick settings tile. Button sent without opening the app.
FR16 (P2): Code learning (USB, Broadlink). Captured, displayed, replayed, saved.
FR17 (P2): Layout editor. Move, rename, resize buttons.
FR18 (P2): Code contribution to Flipper-IRDB. `.ir` conforming to the repo conventions.

### NonFunctional Requirements

NFR1: Dependencies and supply chain. Runtime: only the Android SDK and `kotlin-stdlib` (no AndroidX, networking libraries, external JSON libraries, or DI). Build: only AGP and the Kotlin Gradle Plugin, pinned and verified. `gradle/verification-metadata.xml` with SHA-256 and PGP signatures; the build fails on unregistered artifacts. Mandatory evaluation sheet for every new dependency (OpenSSF Scorecard criteria). Downloaded data treated as hostile input; content pinned by commit hash.
NFR2: Privacy and network. No analytics, crash reporting, or advertising. Network only to allowlisted CDNs and user-added LAN blasters. Cleartext forbidden except for LAN addresses. `ACCESS_LOCAL_NETWORK` (Android 17, target 37) requested only when adding a blaster.
NFR3: Platform and distribution. `minSdk` 26, `targetSdk` 36 (plan for 37). Google Play (AAB, Play App Signing) + F-Droid (reproducible build). Data safety: no data collected or shared.
NFR4: License. GPL-3.0-or-later. irdb attribution in the app.
NFR5: Quality. Cold start < 500 ms on a 2021 mid-range device; APK < 3 MB. Tap -> transmission latency < 50 ms on the built-in transmitter. TalkBack on all buttons, 48 dp targets, WCAG AA contrast. v1 languages: Italian and English.

### Additional Requirements

No starter template: the project is a from-scratch multi-module Gradle build.

Project rules (`project-context.md`):
- Rule zero: no secrets or sensitive data anywhere; `bash tools/check-no-secrets.sh` before every commit.
- Rule one: English only for documents, code, comments, commits, issues, PRs; user strings in `values/strings.xml` (English) and `values-it/strings.xml` (Italian).
- No new dependency without an evaluation sheet approved by the user; `gradle/verification-metadata.xml` changes only in a dependency story.
- Every protocol encoder has test vectors with a documented source.
- Errors always carry a readable cause and a suggested action.
- No permission requested on first launch.
- Commits, pushes, tags, signing and publishing only with user confirmation.

Architecture:
- AR1: Gradle modules `ir-core` (pure JVM, no `android.*`), `ir-formats`, `catalog`, `tx-builtin`, `tx-audio`, `tx-usb`, `tx-net`, `app`; `tx-*` depend only on `ir-core`.
- AR2: Canonical model `IrSignal(carrierHz, intro, repeat, ending, dutyCycle)`, `IrCode` (Parsed/Raw/Pronto), `ProtocolEncoder.encode(code, toggle)`.
- AR3: RC5/RC6 toggle bit per button held by `TransmitService`; NEC repeat code; repeat every ~108 ms (NEC) while pressed; one single-thread executor per transmitter.
- AR4: Inputs: Flipper `.ir`, irdb CSV, Pronto (`0000`, `5000`, `6000`), textual raw, SmartIR JSON. Outputs: raw µs (built-in, audio, Tasmota), Pronto (ESPHome), Broadlink packet (time unit to be fixed with tests on RM4), RLE for USB dongles.
- AR5: Validation before every send: durations > 0 and < 250 ms, even length, total < 2 s on built-in, frequency within `getCarrierFrequencies()` ranges ±2 kHz.
- AR6: `IrTransmitter` interface (id, kind, capabilities, transmit(signal, repeats), close); automatic fallback to the next available transmitter.
- AR7: Transmitters: built-in (`ConsumerIrManager`), audio (`AudioTrack` PCM 16-bit 48 kHz, antiphase, manual calibration), USB (Tiqiaa 10C4:8468, ElkSmart 045C:02AA, bulk), network (Tasmota HTTP, ESPHome reference firmware with `web_server` + Pronto action, Broadlink UDP AES-128-CBC with in-memory session key; no automatic discovery in v1).
- AR8: Catalog pipeline: weekly CI snapshot (`ir-index` repo) at pinned commits of Flipper-IRDB and irdb; compressed JSON index with SHA-256 per file; ECDSA P-256 signature (offline key, protected CI job; public key + backup key in the APK; `java.security.Signature`); download from GitHub Releases or jsDelivr; per-file verification; cache in `filesDir`; manual or weekly update via `JobScheduler`; SQLite FTS4 search with synonyms; candidate ranking.
- AR9: Persistence in `SQLiteDatabase`: tables `remote`, `button`, `transmitter` (never session keys), `ac_state`, `index_*` (FTS4, rebuildable); versioned JSON backup; `dataExtractionRules` only for `remote`/`button`; import/export via Storage Access Framework.
- AR10: Threading: UI on main thread only; `dbExecutor` (1 thread); `netExecutor` (2 threads, 5 s timeout); results via `Handler(Looper.getMainLooper())`.
- AR11: Permissions: `TRANSMIT_IR` and `INTERNET` declared; `ACCESS_LOCAL_NETWORK` runtime only when adding a blaster; USB via system dialog; `uses-feature consumerir required="false"`.
- AR12: Parser limits: file <= 256 KB, <= 500 signals, <= 1024 durations, durations 1..250000 µs; names rendered as plain text.
- AR13: Supply chain: Gradle dependency verification (`verify-metadata`, `verify-signatures`, SHA-256); only `google()` and `mavenCentral()` with `includeGroup` routing; wrapper with `distributionSha256Sum`; GitHub Actions pinned by SHA, `permissions: read-all`, no `pull_request_target`; OSV-Scanner on every PR, weekly OpenSSF Scorecard, CycloneDX SBOM at release; evaluation sheet template for new dependencies.
- AR14: Test levels: JVM unit (encoders with vectors, Pronto round trip, parser fuzzing; every PR), corpus (entire Flipper-IRDB and irdb snapshot; weekly), instrumented bench with ESP verification receiver (pre-release), UI via platform instrumentation + scripted manual tests (no Espresso).
- AR15: Release: signed GPG tag -> reproducible build in container (`SOURCE_DATE_EPOCH`) -> AAB on Play / APK on GitHub -> F-Droid verifies reproducibility -> SBOM and checksums attached.
- AR16: Public-repo hygiene to be completed by the user on github.com: secret scanning, push protection, protection of `main`.

### UX Design Requirements

UX-DR1: Color tokens (`bg`, `surface`, `key`, `key_pressed`, `text`, `text_muted`, `accent`, `power`, `ok`, `warn`) for light and dark themes with exact values from the spec; all color/background pairs >= 4.5:1; colors used only from tokens.
UX-DR2: Typography and spacing tokens: system font; title 22 sp, section 18, body 16, key 15 medium, caption 13; 4 dp grid, 16 dp margins, 12 dp key spacing; keys >= 56x56 dp, 16 dp corners, D-pad 200 dp.
UX-DR3: Themes light/dark/system via `Theme.DeviceDefault` (no Material Components); ~30 own vector icons; edge-to-edge with `WindowInsets`; predictive back.
UX-DR4: Navigation: Home as the only hub; S1->S2->S3->S4->S5; S2->S5 in one tap on a card; S2->S6; S5->S7; widget/tile -> S5; Back goes one step.
UX-DR5: S1 Welcome: one row per transmitter with status (available/absent/to be configured); no-IR message with "Use an adapter" / "Explore anyway"; primary "Add your first remote"; no permission requested.
UX-DR6: S2 Home: bar with title, active transmitter icon (-> S7), overflow; 2-column card grid (favorites first); long-press menu (rename, duplicate, change transmitter, export, delete with undo); round "+" button; empty state "Find your remote".
UX-DR7: S3 Add: type grid (TV, Air conditioner, Set-top box, Projector, Audio, Fan, LED lights, Other); brand search with suggestions and common brands on top; "Import from file" and "Enter code manually"; missing-catalog banner with size in MB and confirmation.
UX-DR8: S4 Guided test: "Brand Type · candidate N of M"; large key (Power, or Vol+ for devices that must not be turned off); send-again link; "It worked" / "Nothing, try the next one"; second-key verification, suggested name, save -> S5; exhausted-candidates exits (other brand/type, file import, report missing brand via prefilled issue shown before sending).
UX-DR9: S5 Remote: layout by role (Power/Input/Mute row, D-pad, Vol/Ch rocker, collapsible keypad, scrollable extras); only keys present in the code; short vibration + "IR" indicator; repeat on Vol/Ch/arrows; air conditioner variant (large temperature, +/-, mode and fan chips, Power, full state on every change).
UX-DR10: S6 Settings: theme, vibration, Power confirmation (off), catalog update, sources (irdb with license warning), backup/restore, language; privacy statement; info (version, GPL, attributions, source and SBOM links).
UX-DR11: S7 Transmitters: list with status and frequencies; audio mono/stereo, test, calibration; USB device and permission; network add blaster (Tasmota, ESPHome, Broadlink, IP, name) with `ACCESS_LOCAL_NETWORK` explained before the prompt.
UX-DR12: Custom Views: `IrKeyView` (states, repeat after 300 ms then ~110 ms, spoken label, "press and hold" action), `DpadView` (4 sectors + OK, angular hit-test, 5 virtual nodes), `RockerView` (2 virtual nodes), `RemoteCardView`, `FabView` (56 dp, label required), `TxIndicatorView` (150 ms blink, red on error, announced on error only).
UX-DR13: State handling: empty (S2, S3), loading with MB and cancel (S3, S4), offline (S3), transmission error with cause and action (S4, S5), transmitter absent `warn` banner with "Use phone IR" (S5), invalid catalog signature ("Update rejected for security reasons", previous version used) (S3).
UX-DR14: Accessibility and feedback: `VIRTUAL_KEY` haptics if enabled, no sound by default; targets >= 48 dp (main 56); text to 200%; labels -> icons above 130%; ordered focus; no color-only information; left-handed mode; TalkBack on all controls; IT/EN strings.
UX-DR15: Plain-language principle: devices not protocols (technical terms only in "Code details"); every error states cause and way out; confirmation before Power remains an open decision (default off, to be tested).

### FR Coverage Map

FR1: Epic 2 - Detect transmitters and frequencies (S1 Welcome)
FR2: Epic 2 - Transmit a validated raw code from the built-in transmitter
FR3: Epic 1 - P0 protocol encoders with sourced test vectors
FR4: Epic 1 - Pronto hex <-> raw round trip
FR5: Epic 4 - Search by type and brand on the signed Flipper-IRDB index
FR6: Epic 4 - Guided trial of candidates
FR7: Epic 3 - Local library with favorites, offline
FR8: Epic 3 - Repeat while a key is held (repeat frames, toggle bit)
FR9: Epic 3 - Import Flipper `.ir`/Pronto/raw and JSON export/backup (the Flipper parser itself is built in Epic 3 and reused by Epic 4)
FR10: Epic 7 - Second source irdb with attribution
FR11: Epic 6 - Audio jack transmitter
FR12: Epic 6 - Tiqiaa and ElkSmart USB dongles
FR13: Epic 6 - Tasmota, ESPHome, Broadlink network blasters
FR14: Epic 7 - Air conditioner with persisted state
FR15: Epic 7 - Widget and quick settings tile
FR16: Epic 8 - Code learning
FR17: Epic 8 - Layout editor
FR18: Epic 8 - Contribution to Flipper-IRDB

NFR coverage: NFR1 and NFR2 are enforced from Epic 1 (CI, dependency verification, privacy rules); NFR5 budgets (APK size, latency) are checked from Epic 1 and on device in Epic 2; NFR3, NFR4 and the final NFR5 audits (TalkBack, 200% text, IT/EN) close in Epic 5. Every UI story carries its own accessibility, token and string acceptance criteria (project rule 8).

## Epic List

### Epic 1: IR engine and verified build
Foundations that make every later epic safe: multi-module Gradle build with dependency verification, CI with supply chain checks and an APK size budget, the `ir-core` signal model with validation, Pronto <-> raw, and the P0 protocol encoders in four family stories with sourced vectors. Pure JVM, no phone needed. Exit: green vector tests on all P0 protocols (M0, first half).
**FRs covered:** FR3, FR4

### Epic 2: First transmission on the phone
The engine meets real hardware: S1 Welcome with transmitter detection, sending a validated raw code from the built-in transmitter, and an on-device bench test against a receiver. Exit: measured timings match expectations on a real device (M0, second half).
**FRs covered:** FR1, FR2

### Epic 3: My remotes: library, remote screen, import/export
Users save, organize and use remotes: SQLite persistence, Home (S2), Remote (S5) with repeat while held, Flipper `.ir`/Pronto/raw import, JSON backup/restore, essential Settings (S6). Makers get value immediately from manual import.
**FRs covered:** FR7, FR8, FR9

### Epic 4: Find my remote from the catalog
Users find a working code without knowing protocols: catalog pipeline and signed index (first story, with user-side prerequisites: `ir-index` repo and offline signing key created by the user, never in the sandbox), FTS4 search by type and brand (S3), guided trial (S4) saving into the library. Exit: 5 users find their TV without help (M1).
**FRs covered:** FR5, FR6

### Epic 5: Release v1.0 (Play + F-Droid)
Verification and release only; accessibility, tokens and strings are acceptance criteria of every UI story. Covers the TalkBack and 200% text audit, IT/EN completeness, reproducible build, SBOM, Data safety, quality thresholds. Exit: Data safety approved, reproducible build verified (M2).
**FRs covered:** none new (NFR3, NFR4, NFR5)

### Epic 6: External transmitters (v1.1)
Users without a built-in emitter can still send codes: one independent, separately shippable story per transmitter (audio jack, USB Tiqiaa/ElkSmart, Tasmota, ESPHome, Broadlink) plus the S7 Transmitters screen. USB and Broadlink stories require real hardware to verify.
**FRs covered:** FR11, FR12, FR13

### Epic 7: Air conditioners, widget and second source (v1.1)
Air conditioner remotes with persisted state, home-screen widget and quick settings tile, irdb as a second catalog source with attribution and notification issue.
**FRs covered:** FR14, FR15, FR10

### Epic 8: Power-user tools (P2)
Code learning, layout editor and contribution of codes upstream to Flipper-IRDB.
**FRs covered:** FR16, FR17, FR18

## Epic 1: IR engine and verified build

Foundations that make every later epic safe: a multi-module Gradle build with dependency verification, CI with supply chain checks and an APK size budget, the `ir-core` signal model with strict validation, Pronto <-> raw conversion, and the P0 protocol encoders in four family stories with sourced test vectors. Pure JVM; no phone needed. User value: trust in the correctness of every signal the app will ever send.

### Story 1.1: Gradle skeleton and verified build

As a maintainer,
I want a multi-module Gradle build where every dependency is pinned and verified,
So that no unreviewed artifact can enter the project.

**Acceptance Criteria:**

**Given** a clean checkout
**When** I run `./gradlew build`
**Then** the modules `ir-core` (pure JVM, no `android.*`) and `app` (`minSdk` 26, `targetSdk` 36) build successfully
**And** the only plugins are AGP and the Kotlin Gradle Plugin, and the only runtime dependency is `kotlin-stdlib`.

**Given** the Gradle wrapper
**When** it is downloaded
**Then** `distributionSha256Sum` is set
**And** a checksum mismatch fails the build.

**Given** `gradle/verification-metadata.xml` with SHA-256 and PGP signatures
**When** a dependency is added without registering it
**Then** the build fails.

**Given** the repository configuration
**Then** only `google()` and `mavenCentral()` are declared, with `includeGroup` routing.

### Story 1.2: CI with supply chain checks

As a maintainer,
I want every pull request checked automatically for secrets, vulnerable dependencies and unsafe workflows,
So that regressions are caught before review.

**Acceptance Criteria:**

**Given** a pull request
**When** CI runs
**Then** it executes the JVM unit tests, `tools/check-no-secrets.sh` and OSV-Scanner
**And** it fails on any finding.

**Given** the workflow files
**Then** every GitHub Action is pinned by commit SHA, `permissions: read-all` is the default, and `pull_request_target` is not used.

**Given** a debug build of `app`
**When** its APK exceeds 3 MB
**Then** CI fails with the measured size in the message (NFR5).

**Given** the repository
**Then** a weekly OpenSSF Scorecard workflow exists.

**Given** a pull request
**When** CI runs
**Then** it checks the merged manifest against `tools/manifest-permissions.allowlist` (grep only, no dependency)
**And** it fails on any `uses-permission` not listed and on any `uses-feature` with `required="true"`.

### Story 1.3: Signal model and validation

As a maintainer,
I want a canonical `IrSignal` model with strict validation,
So that no malformed signal can ever reach a transmitter.

**Acceptance Criteria:**

**Given** `IrSignal(carrierHz, intro, repeat, ending, dutyCycle)` and `IrCode` (Parsed/Raw/Pronto)
**When** a signal is built
**Then** the model contains no `android.*` types.

**Given** a signal
**When** it is validated
**Then** it is rejected unless all durations are > 0 and < 250 ms, the number of durations is even, and the total duration is < 2 s.

**Given** a carrier frequency outside the supported ranges ±2 kHz
**When** it is validated
**Then** it is rejected.

**Given** any rejection
**Then** the error names the cause and a suggested action in plain language, without protocol jargon.

### Story 1.4: Pronto hex and raw conversion

As a maker,
I want to convert between Pronto hex and raw durations,
So that I can reuse codes from other tools.

**Acceptance Criteria:**

**Given** a Pronto code of type `0000`
**When** it is converted to raw and back
**Then** the result equals the original apart from carrier quantization (documented tolerance).

**Given** Pronto types `5000` and `6000`
**When** they are parsed
**Then** they are recognized or rejected with a readable error.

**Given** malformed input (odd word count, non-hex characters, length mismatch)
**When** it is parsed
**Then** it is rejected and no exception escapes the module.

**Given** the test suite
**Then** it includes vectors with a documented source.

### Story 1.5: NEC family, Samsung32 and JVC encoders

As a user with a TV or set-top box using these protocols,
I want correct encoding of NEC, NEC2, NECx, Samsung32 and JVC,
So that my commands do what I expect.

**Acceptance Criteria:**

**Given** an address and a command
**When** they are encoded as NEC
**Then** the durations match the reference vectors from IrScrutinizer or Flipper, with the source documented.

**Given** a held key
**When** repeats are requested
**Then** NEC emits the repeat code, not the full frame.

**Given** invalid parameters (address or command out of range)
**When** encoding
**Then** a readable error is returned.

**Given** the protocol set
**Then** each variant has at least one vector test and a round trip to Pronto and back.

### Story 1.6: Sony SIRC encoders

As a user with a Sony device,
I want 12, 15 and 20-bit SIRC encoding,
So that my commands are recognized.

**Acceptance Criteria:**

**Given** a command
**When** it is encoded as SIRC 12, 15 or 20
**Then** the durations match the reference vectors, with the source documented.

**Given** a held key is simulated
**Then** the frame repeats as the protocol requires (three sends, spacing per spec).

**Given** an out-of-range address or command
**When** encoding
**Then** a readable error is returned.

### Story 1.7: RC5 and RC6 encoders with toggle bit

As a user with a device using Philips-family protocols,
I want RC5 and RC6 mode 0 encoding with the toggle bit,
So that repeated presses of the same key are recognized as separate presses.

**Acceptance Criteria:**

**Given** a command
**When** it is encoded as RC5 or RC6 mode 0
**Then** the durations match the reference vectors, with the source documented.

**Given** `ProtocolEncoder.encode(code, toggle)`
**When** it is called with `toggle` true and then false
**Then** only the toggle bit differs.

**Given** a held key
**Then** the toggle bit stays constant across repeats and flips on the next press.

### Story 1.8: Kaseikyo, Sharp and Denon encoders

As a user with a Panasonic, Sharp or Denon device,
I want these protocols encoded correctly,
So that the P0 protocol set is complete.

**Acceptance Criteria:**

**Given** a command
**When** it is encoded as Kaseikyo, Sharp or Denon
**Then** the durations match the reference vectors, with the source documented, including the Kaseikyo vendor and parity bytes.

**Given** the complete P0 set
**Then** all encoders pass a single vector suite in CI, with the vectors listed in a README table with their source.

**Given** the end of the epic
**Then** the M0 first-half exit criterion is met: green vector tests on all P0 protocols.

## Epic 2: First transmission on the phone

The engine meets real hardware: transmitter detection with the S1 Welcome screen, a reusable manual code entry screen with validation preview, sending a validated code from the built-in transmitter, and an on-device bench test against a receiver. User value: the first time the app actually controls a device, with honest feedback when it cannot.

### Story 2.1: Welcome screen with transmitter detection

As a new user,
I want to see which transmitters my phone has and why,
So that I know immediately whether I can control devices.

**Acceptance Criteria:**

**Given** the app is launched for the first time
**When** the Welcome screen (S1) is shown
**Then** it lists one row per transmitter kind with status (available / absent / to be configured)
**And** the built-in row shows the supported carrier frequencies read from the system
**And** no permission is requested.

**Given** the phone has no IR emitter
**When** S1 is shown
**Then** a plain-language message offers "Use an adapter" and "Explore anyway".

**Given** the `tx-builtin` module
**Then** it implements the `IrTransmitter` interface (id, kind, capabilities) and `ir-core` does not depend on it
**And** the manifest declares `uses-feature consumerir` with `required="false"`.

**Given** the screen
**Then** it uses the color, typography and spacing tokens in light and dark themes, touch targets of at least 48 dp, a spoken description for each row, and English plus Italian strings.

**Given** any Activity of the app (this story creates the foundation for all screens)
**When** it is created
**Then** its theme parent is `android:Theme.DeviceDefault*` with light, dark and system variants (`values-night`), colors come only from the spec tokens, and no AndroidX, Material or Compose artifact is on the runtime classpath (CI dependency check).

**Given** the manifest
**Then** `android:enableOnBackInvokedCallback="true"` is set, Back is handled with `OnBackInvokedCallback` one navigation step per press, and this story adds no permission.

**Given** gesture or 3-button navigation
**When** a screen is shown edge-to-edge
**Then** WindowInsets (systemBars, displayCutout, IME) are applied and no control is hidden or smaller than 48 dp.

**Given** the icons this story uses
**Then** they are own XML VectorDrawables (24 dp, token tint), with no icon library and no bitmap, provenance and licence stated, each with a contentDescription or marked decorative
**And** every later UI story adds the icons it needs under the same rule.

### Story 2.2: Manual code entry with validation preview

As a maker,
I want to type or paste a raw or Pronto code and see whether it is valid,
So that I can check a code before sending it.

**Acceptance Criteria:**

**Given** the manual entry screen
**When** I paste a valid raw or Pronto code
**Then** the screen shows that it is valid, the number of durations, the carrier frequency and the total duration.

**Given** an invalid code (odd number of durations, a duration out of range, total over 2 s, non-hex Pronto)
**When** I submit it
**Then** the screen shows the cause and a suggested action in plain language, with no stack trace or protocol jargon.

**Given** empty input
**Then** the submit action is disabled and a hint is shown.

**Given** the screen
**Then** it is a self-contained component that other flows can open and receive the parsed `IrCode` from (reused as "Enter code manually" in Epic 3)
**And** it meets the same token, 48 dp, spoken-description and EN/IT string criteria as Story 2.1.

### Story 2.3: Send a validated code from the built-in transmitter

As a user,
I want to send the code I entered from my phone's IR emitter,
So that I can see my device react.

**Acceptance Criteria:**

**Given** a valid code and an available built-in transmitter
**When** I tap Send
**Then** the signal is transmitted on a dedicated single-thread executor, not on the main thread
**And** the transmission is signalled by `TxIndicatorView` (created in this story): a 150 ms blink.

**Given** an invalid signal or an absent transmitter
**When** I tap Send
**Then** nothing is transmitted, the `TxIndicatorView` turns to the error color, and the message gives the cause and an action (for example "Use an adapter")
**And** the error is announced to TalkBack on error only, and the announced text contains no host or IP of a blaster.

**Given** the manifest
**Then** it declares `TRANSMIT_IR` (normal permission, no runtime prompt) and `tools/manifest-permissions.allowlist` gains exactly that entry.

**Given** the built-in transmitter
**When** the signal frequency is not within the supported ranges ±2 kHz
**Then** it is rejected before reaching the system service.

**Given** a mid-range device
**When** latency from tap to the start of transmission is measured with the documented method
**Then** it is below 50 ms (NFR5).

### Story 2.4: On-device bench test against a receiver

As a maintainer,
I want to compare what the phone really transmits with what the encoders intend,
So that timing errors are caught before any user sees them.

**Acceptance Criteria:**

**Given** a debug-only tool (not included in the release APK)
**When** it is run with a connected receiver
**Then** it transmits one vector for each P0 protocol family from Epic 1.

**Given** the receiver capture
**When** the measured timings are compared with the expected ones
**Then** each vector passes or fails against a documented tolerance
**And** the result is written to a report file in the repository.

**Given** the receiver hardware is not available
**Then** this story is marked non-blocking for the closure of Epic 2
**And** it is a mandatory gate before the first alpha release.

**Given** the procedure
**Then** it documents the receiver options (ESP with TSOP/VS1838, Flipper Zero, or a learning dongle) and the steps to reproduce.

## Epic 3: My remotes: library, remote screen, import/export

Users save, organize and use remotes: SQLite persistence, the Flipper `.ir` parser, import from a file, the Home screen (S2), the Remote screen (S5), repeat while a key is held, JSON backup and restore, essential Settings (S6), and the read-only "Code details" view. Makers get value immediately from manual import. User value: a personal, offline library of working remotes that survives a phone change.

### Story 3.1: Local library storage

As a user,
I want my remotes and their buttons stored on the phone,
So that they are available at any time without a network.

**Acceptance Criteria:**

**Given** a fresh install
**When** the library is first opened
**Then** the tables `remote` and `button` exist, and no other tables are created by this story.

**Given** a remote with buttons
**When** it is saved and read back
**Then** every field, including the favorite flag and the transmitter assignment, round-trips unchanged.

**Given** any database access
**Then** it runs on a dedicated single-thread executor (`dbExecutor`) and never on the main thread.

**Given** a schema version change
**When** the app is upgraded
**Then** a versioned migration preserves existing remotes, and a migration test covers each version step.

**Given** the library
**Then** it works with no network permission being used (airplane mode).

### Story 3.2: Flipper `.ir` parser

As a maker,
I want a safe parser for Flipper `.ir` files,
So that I can import codes from the community database.

**Acceptance Criteria:**

**Given** a valid `.ir` file with parsed and raw signals
**When** it is parsed
**Then** the result is a list of named `IrCode` values matching the file.

**Given** a file larger than 256 KB, with more than 500 signals, with more than 1024 durations in one signal, or with a duration outside 1 to 250000 µs
**When** it is parsed
**Then** it is rejected with a readable error.

**Given** signal names containing markup or control characters
**Then** they are kept as plain text and never interpreted.

**Given** malformed or truncated input
**When** it is parsed
**Then** no exception escapes the module and the error states where the problem is.

**Given** the test suite
**Then** it includes parser fuzzing and a corpus test over a pinned snapshot of Flipper-IRDB with no crashes.

### Story 3.3: Import a remote from a file

As a maker,
I want to import a remote from a file I choose,
So that I can use codes I already have.

**Acceptance Criteria:**

**Given** the import action
**When** I pick a file with the system file picker
**Then** the app reads only that file and requests no storage permission.

**Given** a Flipper `.ir`, a Pronto text file or a raw text file
**When** it is read
**Then** a preview lists the detected buttons and the format, before anything is saved.

**Given** the preview
**When** I confirm
**Then** the remote is saved in the library and I can name it.

**Given** an unreadable or invalid file
**Then** the message gives the cause and a suggested action, with no stack trace.

**Given** a single code to add
**Then** the manual entry screen from Epic 2 can be opened from the import flow.

### Story 3.4: Home screen

As a user,
I want a Home screen showing my remotes,
So that I can open the one I need quickly.

**Acceptance Criteria:**

**Given** saved remotes
**When** Home (S2) is shown
**Then** they appear as cards in a two-column grid with favorites first
**And** each remote is a `RemoteCardView` (type icon, name, brand, favorite star; target at least 48 dp) read by TalkBack as a single item
**And** the add action is a `FabView` (56 dp accent circle, accessibility label required) that opens S3, or the import and manual entry flows until Story 4.4 delivers S3.

**Given** left-handed layout is on (Story 3.8)
**Then** the `FabView` moves to the bottom-left.

**Given** an empty library
**Then** the empty state "Find your remote" is shown with the actions to add or import a remote.

**Given** a card
**When** I long-press it
**Then** a menu offers rename, duplicate, change transmitter, export and delete.

**Given** I delete a remote
**Then** it disappears immediately and an undo action restores it for a limited time.

**Given** a card tap
**Then** it opens the Remote screen, or a placeholder until Story 3.5 is delivered.

**Given** airplane mode
**Then** Home works fully.

**Given** the screen
**Then** it meets the token, 48 dp, spoken-description and EN/IT string criteria.

### Story 3.5: Remote screen

As a user,
I want a remote screen that sends the commands of my device,
So that I can control it like a physical remote.

**Acceptance Criteria:**

**Given** a saved remote
**When** the Remote screen (S5) opens
**Then** keys are laid out by role (Power/Input/Mute row, D-pad, Volume and Channel rockers, collapsible keypad, scrollable extras)
**And** only keys present in the saved code are shown.

**Given** a key
**When** I tap it
**Then** the signal is sent through the active transmitter, with a short vibration if enabled and the `TxIndicatorView` (from Story 2.3) shown.

**Given** a transmitter error
**Then** the message gives the cause and an action, and the `TxIndicatorView` (from Story 2.3) turns to the error color.

**Given** the custom views `IrKeyView` (created in this story), `DpadView` and `RockerView`
**Then** each exposes spoken descriptions and virtual nodes for TalkBack (five for the D-pad, two for the rocker)
**And** every target is at least 48 dp (56 dp for main keys).

**Given** vibration is enabled
**When** a key is pressed
**Then** `HapticFeedbackConstants.VIRTUAL_KEY` is performed once per press (not on each repeat in Story 3.6) and no sound is played.

**Given** font scale above 130%
**Then** keys with a defined icon show the icon next to the label, and nothing is clipped up to 200%.

**Given** left-handed layout is on (Story 3.8)
**When** the Remote screen opens
**Then** the Volume and Channel rockers and the collapsible-keypad toggle swap sides, the D-pad stays centered, and every target is still at least 48 dp.

**Given** the screen
**Then** it supports light, dark and system themes and EN/IT strings
**And** the theme, WindowInsets and predictive back are inherited from Story 2.1 (verification, not creation).

### Story 3.6: Repeat while a key is held

As a user,
I want volume and channel keys to repeat while I hold them,
So that I can adjust quickly like on a real remote.

**Acceptance Criteria:**

**Given** a repeatable key (`IrKeyView`)
**When** I hold it
**Then** the first signal is sent at once and repeats start after 300 ms, then every about 110 ms.

**Given** a NEC signal
**When** repeating
**Then** the NEC repeat code is sent instead of the full frame.

**Given** an RC5 or RC6 signal
**Then** the toggle bit is held by `TransmitService`, stays constant for the repeats of one press and flips on the next press.

**Given** I release the key
**Then** repeating stops within one repeat interval, and a lifecycle change (screen off, app in background) also stops it.

**Given** a long-press accessibility action
**Then** `IrKeyView` exposes repeat (after 300 ms, then about every 110 ms) as a spoken action for TalkBack.

### Story 3.7: JSON backup and restore

As a user,
I want to export and restore my library,
So that I do not lose my remotes when I change phone.

**Acceptance Criteria:**

**Given** the export action
**When** I choose a location with the system file picker
**Then** a versioned JSON backup of remotes and buttons is written there.

**Given** a backup file
**When** I restore it
**Then** remotes are added without overwriting existing ones silently, and I see a summary of what was restored.

**Given** a backup with an unknown or newer version, or invalid content
**Then** it is rejected with a readable error and the library is unchanged.

**Given** system backup rules
**Then** `dataExtractionRules` include only `remote` and `button` data and never transmitter credentials or session keys.

**Given** the test suite
**Then** a round trip export, restore, compare passes for the current and the previous backup version.

### Story 3.8: Essential Settings

As a user,
I want a Settings screen for the basics,
So that the app behaves the way I prefer.

**Acceptance Criteria:**

**Given** Settings (S6)
**Then** it offers theme (light, dark, system), vibration, Power confirmation (off by default), language and links to backup and restore.

**Given** the information section
**Then** it shows the version, the GPL license, the privacy statement (no analytics, no tracking), and links to the source and the SBOM.

**Given** Settings (S6)
**Then** a "Left-handed layout" switch (off by default) is offered, applies immediately and persists across restarts (a local boolean; no permission).

**Given** a setting change
**Then** it applies immediately and persists across restarts.

**Given** the screen
**Then** it meets the token, 48 dp, spoken-description and EN/IT string criteria.

### Story 3.9: Code details

As a maker or an advanced user,
I want to see the technical data of each key in one place,
So that I can report a bug or check a code that does not work, while the rest of the app stays free of jargon.

**Acceptance Criteria:**

**Given** the Remote screen (S5)
**When** I open the overflow menu and choose "Code details"
**Then** for each key I see, read-only: the format or protocol name (or Raw/Pronto), address, command, toggle, carrier frequency, number of durations, total duration
**And** the catalog source name and license of the remote.

**Given** a key
**When** I choose "Copy code"
**Then** only the Pronto/raw code text is copied, only on that explicit action.

**Given** any other screen or error message
**Then** no protocol name, address or command appears
**And** the exception is the maker flows: Story 2.2 manual entry and Story 3.3 import preview may show carrier, number of durations and file format.

**Given** Code details
**Then** it renders only a fixed allowlist of `IrCode` fields plus the source name and license
**And** it never shows transmitter name, host, IP, credentials, session keys, file paths, hashes, catalog URL or signature (Rule zero)
**And** it works offline.

**Given** names or values from an imported file
**Then** they are shown as plain text only (no HTML, no links) and truncated at a length limit.

**Given** an error
**Then** Code details is never opened automatically and its content is not logged.

**Given** the screen
**Then** it meets the token, 48 dp, spoken-description and EN/IT string criteria.

## Epic 4: Find my remote from the catalog

Users find a working code without knowing protocols: the signed catalog index (user-side setup, CI pipeline, in-app download and verification), search by type and brand (S3), candidate ranking, the guided trial (S4) saving into the library, and exits when nothing matches. User value: pick a brand, try a few codes, and end up with a working remote. Exit: five users find their TV without help (M1).

### Story 4.1: Catalog setup checklist (maintainer actions)

As a maintainer,
I want a checklist of the steps only I can perform for the catalog,
So that the signing trust anchor never passes through the sandbox.

**Acceptance Criteria:**

**Given** the checklist document in the repository
**Then** it lists the maintainer-only steps: create the public `ir-index` repository, enable secret scanning and push protection on it, generate the ECDSA P-256 signing key pair and a backup pair offline, and record the two public keys for the APK.

**Given** the signing private keys
**Then** they are never stored in any repository, the Project, artifacts, CI logs or this sandbox (rule zero)
**And** the checklist states how they are stored and backed up by the maintainer.

**Given** the steps are completed
**Then** the maintainer records the public keys and the `ir-index` repository location in the repository documentation, and the story is closed by the maintainer.

**Given** this story is not yet completed
**Then** Stories 4.2 and 4.3 can proceed with a dummy development key (see Story 4.2).

### Story 4.2: Catalog pipeline and signed index

As a maintainer,
I want a CI pipeline that builds a signed catalog index from pinned upstream commits,
So that the app can trust what it downloads.

**Acceptance Criteria:**

**Given** pinned commits of Flipper-IRDB
**When** the weekly pipeline runs in the `ir-index` repository
**Then** it produces a compressed JSON index with a SHA-256 for each file and an ECDSA P-256 signature over the index.

**Given** upstream content
**Then** it is treated as hostile input: parsed with the limits from Story 3.2, with names kept as plain text, and a file that fails parsing is excluded and reported in the build log.

**Given** a development environment without the real key
**When** a test index is needed
**Then** the test harness generates a throwaway key pair at test time, signs a test index with it, and the dummy private key is never committed.

**Given** a release build
**Then** it rejects any index signed with a development key
**And** a CI check fails if a development public key is present in release resources.

**Given** the pipeline definition
**Then** every action is pinned by SHA and runs with minimal permissions.

### Story 4.3: Index download, verification and manual update

As a user,
I want the app to download and verify the catalog, and let me update it,
So that I get the codes safely and can refresh them when I want.

**Acceptance Criteria:**

**Given** the first search without a local catalog
**When** I accept the download
**Then** the app shows the size in MB and a cancel action before downloading
**And** it requires no permission other than network access.

**Given** a downloaded index
**When** it is verified
**Then** the signature is checked with the public keys in the APK (primary and backup) and each file is checked against its SHA-256 before use.

**Given** a signature or hash that does not verify
**Then** the update is rejected with the message "Update rejected for security reasons"
**And** the previous catalog stays in use.

**Given** a verified index
**Then** it is stored in the app-private storage and works offline afterwards
**And** a manual "Update catalog" action in Settings repeats the same download and verification path.

**Given** no network
**Then** a clear offline message offers the options that still work (local library, import)
**And** offline is detected from the failure of the request (5 s timeout), not from a pre-check.

**Given** the network requests
**Then** only the allowlisted catalog hosts are contacted and cleartext traffic is refused.

**Given** the manifest
**Then** it declares `INTERNET` and `tools/manifest-permissions.allowlist` gains exactly that entry
**And** no other network permission (`ACCESS_NETWORK_STATE` included) is added.

**Given** any catalog request
**Then** it runs on the shared `netExecutor` (2 threads, bounded queue; a full queue yields a readable "busy, try again" error), created in the `app` composition root and injected as `java.util.concurrent.Executor` into `catalog` and `tx-net` (neither creates it), never on the main thread
**And** results return via `Handler(Looper.getMainLooper())`.

**Given** an `HttpURLConnection`
**Then** connect and read timeouts are 5 s each (not a cap on total download time)
**And** a stalled download fails with a readable cause and a "Try again" action, and the previous catalog stays in use.

**Given** a redirect
**Then** each hop must be https and on the allowlist, at most 3 hops, otherwise the download fails with a readable error.

**Given** a download
**Then** the body is streamed to a temp file in app-private storage with a hard size cap (declared size plus margin; abort beyond it)
**And** the signature and SHA-256 are verified before any parsing or renaming into the active catalog.

**Given** cancel, leaving the screen or an error
**Then** the connection is closed within one read interval and the partial temp file is deleted.

**Given** the logs
**Then** no URL, header or response body is logged.

**Given** a download is running
**Then** S3 shows progress in MB with Cancel
**And** when it fails by network or timeout the message states the cause, offers "Try again" plus import from file and manual code, is distinct from "Update rejected for security reasons", and no host or URL appears in shown text.

### Story 4.4: Search by type and brand

As a user,
I want to search the catalog by device type and brand,
So that I find candidates for my device.

**Acceptance Criteria:**

**Given** the Add screen (S3)
**Then** it shows a grid of device types (TV, Air conditioner, Set-top box, Projector, Audio, Fan, LED lights, Other), a brand search box with suggestions, and common brands first.

**Given** a type and a brand, or a partial brand name
**When** I search
**Then** results appear within 2 s using the local full-text index (SQLite FTS4) with brand synonyms.

**Given** the catalog is missing
**Then** a banner states the size in MB and offers the download from Story 4.3.

**Given** no results
**Then** the empty state offers other brand or type, import from a file and manual entry.

**Given** the Add screen (S3)
**When** it is shown in any state (catalog present, missing, loading, offline or no results)
**Then** "Import from file" and "Enter code manually" are always visible as secondary actions below the brand search, each at least 48 dp with a spoken description.

**Given** I choose "Import from file" or "Enter code manually"
**Then** the flow of Story 3.3 or Story 2.2 opens respectively, works with no catalog and no network, and Back returns to S3.

**Given** the import entry from S3
**Then** it uses the same system file picker, parser path and limits as Story 3.3 (no storage permission, file <= 256 KB, <= 500 signals, <= 1024 durations, 1..250000 µs)
**And** S3 adds no second validation path and no permission.

**Given** the screen
**Then** it meets the token, 48 dp, spoken-description and EN/IT string criteria.

### Story 4.5: Candidate ranking

As a user,
I want the most likely codes tried first,
So that I find my remote with as few attempts as possible.

**Acceptance Criteria:**

**Given** a set of matching remotes for a type and brand
**When** candidates are ranked
**Then** the order is deterministic and documented (for example by protocol popularity and model-name match)
**And** duplicates with identical signals are merged into one candidate.

**Given** the ranking logic
**Then** it is pure code with its own fixtures and ordering tests, independent of the user interface.

**Given** a corpus snapshot
**Then** a test verifies that the known popular models for a sample of brands appear within the first candidates.

### Story 4.6: Guided trial

As a user,
I want to try candidates one by one with a single large key,
So that I can find the right code without knowing anything technical.

**Acceptance Criteria:**

**Given** a ranked list
**When** the guided trial (S4) starts
**Then** it shows "Brand Type · candidate N of M", a large test key (Power, or Volume up for devices that must not be turned off) and a send-again link.

**Given** a candidate
**When** I tap "It worked"
**Then** a second key is tried to confirm, a name is suggested, and the remote is saved to the library and opened on S5.

**Given** a candidate
**When** I tap "Nothing, try the next one"
**Then** the next candidate is loaded in at most three taps per candidate in total.

**Given** a transmitter error or absent transmitter
**Then** the message gives the cause and an action, and no candidate is skipped silently.

**Given** the screen
**Then** it meets the token, 48 dp, spoken-description and EN/IT string criteria.

### Story 4.7: Exits when no candidate works

As a user,
I want clear options when nothing worked,
So that I am not stuck.

**Acceptance Criteria:**

**Given** the candidates are exhausted
**Then** the screen offers: try another brand or type, import from a file, and report a missing brand.

**Given** I choose to report a missing brand
**Then** a prefilled issue is shown in full before anything is sent
**And** nothing is sent without my explicit confirmation
**And** it contains no personal or device identifying data.

**Given** the options
**Then** each leads to an existing flow (Story 4.4, Story 3.3) without a dead end.

## Epic 5: Release v1.0 (Play + F-Droid)

Verification and release only: accessibility, tokens and strings are already acceptance criteria of every UI story. This epic proves them on a real device, measures the quality thresholds, makes the build reproducible and prepares the release artifacts and store compliance. Real signing, tagging and publishing are done by the maintainer and never by the sandbox or by agents. Exit: Data safety approved, reproducible build verified (M2).

### Story 5.1: Accessibility audit

As a user who relies on accessibility features,
I want every screen verified with TalkBack, large text and sufficient contrast,
So that the app is usable by everyone.

**Acceptance Criteria:**

**Given** every screen (S1 to S7 that exist at this point)
**When** it is navigated with TalkBack
**Then** every control has a spoken label, focus order is logical, and custom views expose their virtual nodes and actions.

**Given** system text size set to 200%
**Then** no text is clipped and no action becomes unreachable
**And** above 130% labels are accompanied by icons where specified.

**Given** the color tokens in light and dark themes
**Then** every text and background pair reaches at least 4.5:1 contrast
**And** no information is conveyed by color alone.

**Given** left-handed mode
**Then** the layouts mirror correctly on the screens that define it (Story 3.4 `FabView`, Story 3.5 rockers and keypad toggle).

**Given** the release build
**Then** a CI/lint check finds no bitmap icon in `res/drawable`, the vector icon count is about 30, and every icon has a description or is marked decorative.

**Given** the audit
**Then** its findings are recorded in a report in the repository, with each finding fixed or tracked.

### Story 5.2: Translation completeness check

As a maintainer,
I want an automated check that all strings exist in English and Italian,
So that no release ships with missing or hardcoded text.

**Acceptance Criteria:**

**Given** `values/strings.xml` and `values-it/strings.xml`
**When** CI runs the check
**Then** it fails if any string exists in one file and not the other.

**Given** the layouts and code
**Then** the check fails on user-visible hardcoded strings.

**Given** a placeholder or plural in a string
**Then** the check verifies that the Italian version uses the same placeholders.

**Given** a release candidate
**Then** a manual pass confirms the Italian text reads naturally and is recorded in the audit report.

### Story 5.3: Quality thresholds measured

As a maintainer,
I want the performance thresholds measured on a real device,
So that the release meets its promises.

**Acceptance Criteria:**

**Given** a mid-range 2021 device or equivalent
**When** the app is cold-started with the documented protocol
**Then** the median start time over a stated number of runs is below 500 ms.

**Given** the release APK
**Then** its size is below 3 MB, enforced by the CI check from Story 1.2.

**Given** the built-in transmitter
**When** tap-to-transmit latency is measured with the protocol from Story 2.3
**Then** it is below 50 ms.

**Given** a measurement misses its threshold
**Then** the result is recorded with the device model and a tracked issue, and the release is not tagged until resolved or the threshold is formally revised.

### Story 5.4: Reproducible build

As a maintainer,
I want the same source to produce the same APK every time,
So that anyone, including F-Droid, can verify the published binary.

**Acceptance Criteria:**

**Given** a tagged commit
**When** it is built twice in a clean container with a pinned toolchain and `SOURCE_DATE_EPOCH`
**Then** the two APKs are byte-identical before signing.

**Given** the build container definition
**Then** the base image and tools are pinned by digest or checksum.

**Given** the comparison
**Then** a script reports the first differing entry when the builds differ, and the release is blocked until fixed.

**Given** the build documentation
**Then** it describes how an outside party reproduces the build.

### Story 5.5: Release artifacts

As a maintainer,
I want the release artifacts prepared consistently,
So that I can sign and publish with confidence.

**Acceptance Criteria:**

**Given** a successful reproducible build
**Then** a CycloneDX SBOM and SHA-256 checksums for every artifact are generated.

**Given** the release notes
**Then** they are written in English and list user-visible changes and known issues.

**Given** signing and tagging
**Then** the story delivers step-by-step instructions for the maintainer (GPG-signed tag, Play App Signing upload, APK signing) and performs none of them itself.

**Given** the release workflow
**Then** it runs with minimal permissions, uses pinned actions and has no access to signing keys.

### Story 5.6: Store compliance

As a maintainer,
I want the store metadata and privacy declarations ready,
So that the app is accepted on Google Play and F-Droid.

**Acceptance Criteria:**

**Given** the Play Data safety form
**Then** the prepared answers state that no data is collected or shared, consistent with the manifest permissions and the code.

**Given** the release manifest
**Then** its permissions equal `tools/manifest-permissions.allowlist`
**And** the Data safety answers are checked against that allowlist.

**Given** F-Droid
**Then** fastlane metadata (descriptions, changelog, screenshots list) is in the repository, and the build is declared reproducible.

**Given** the privacy statement
**Then** it is available in the app (Settings) and in the repository, in English and Italian.

**Given** the license information
**Then** the GPL-3.0-or-later notice and the irdb or Flipper-IRDB attributions required by the catalog sources are present in the About section.

## Epic 6: External transmitters (v1.1)

Users without a built-in emitter, or who prefer another one, can still send codes: the Transmitters screen (S7) with selection and fallback, then one independent, separately shippable story per transmitter (audio jack, each USB dongle, and the network blasters on top of a shared add flow). USB and Broadlink stories require real hardware to verify. User value: the remote works on any phone, with or without an IR emitter.

### Story 6.1: Transmitters screen, selection and fallback

As a user,
I want to see my transmitters and choose which one each remote uses,
So that commands always go through a working path.

**Acceptance Criteria:**

**Given** the Transmitters screen (S7)
**Then** it lists every transmitter with its status and, where relevant, its frequencies.

**Given** a remote
**When** I change its transmitter
**Then** the choice is saved for that remote.

**Given** the chosen transmitter is unavailable
**When** I send a key
**Then** the app falls back to the next available transmitter and tells me which one was used, or shows a banner with "Use phone IR" when none works.

**Given** the `transmitter` table
**Then** it stores configuration only and never session keys or passwords in clear text.

**Given** the screen
**Then** it meets the token, 48 dp, spoken-description and EN/IT string criteria.

### Story 6.2: Audio jack transmitter

As a user with an IR audio-jack adapter,
I want to send codes through the headphone output,
So that I can control devices without a built-in emitter.

**Acceptance Criteria:**

**Given** the audio transmitter module (`tx-audio`, depending only on `ir-core`)
**When** a signal is sent
**Then** it is rendered as 16-bit PCM at 48 kHz in antiphase on the two channels.

**Given** the audio settings in S7
**Then** I can choose mono or stereo, run a test signal and calibrate the volume manually.

**Given** no headset connected
**Then** the message says so and suggests the adapter.

**Given** a real adapter
**Then** a 38 kHz carrier is verified with the bench procedure from Story 2.4, and the result is recorded.

### Story 6.3: Tiqiaa USB dongle

As a user with a Tiqiaa dongle,
I want to send codes through it,
So that I can control devices from my phone.

**Acceptance Criteria:**

**Given** a Tiqiaa dongle (10C4:8468) is connected
**When** I grant access in the system USB dialog
**Then** the app detects it and shows it in S7.

**Given** a signal
**When** it is sent
**Then** it is converted to the dongle's format and written over bulk transfer on a dedicated executor, with failures reported with a cause and an action.

**Given** the dongle is unplugged during use
**Then** the transmitter becomes unavailable and fallback applies.

**Given** the story
**Then** it is marked "verify on real hardware" and records the verification result.

### Story 6.4: ElkSmart USB dongle

As a user with an ElkSmart dongle,
I want to send codes through it,
So that I can control devices from my phone.

**Acceptance Criteria:**

**Given** an ElkSmart dongle (045C:02AA) is connected
**When** I grant access in the system USB dialog
**Then** the app detects it and shows it in S7.

**Given** a signal
**When** it is sent
**Then** it is converted to the dongle's format and written over bulk transfer, with failures reported with a cause and an action.

**Given** the dongle is unplugged during use
**Then** fallback applies.

**Given** the story
**Then** it is independent of Story 6.3 and records its own real-hardware verification.

### Story 6.5: Add a network blaster

As a user,
I want to add a network IR blaster by its address,
So that the app can control it from my phone.

**Acceptance Criteria:**

**Given** the add flow in S7
**When** I choose to add a blaster
**Then** I enter type, name and IP address, and the address is validated as a local network address.

**Given** the local network permission (`ACCESS_LOCAL_NETWORK`)
**Then** it is requested only at this moment, after a screen explaining why, and never at launch
**And** the permission enters `tools/manifest-permissions.allowlist` in this story.

**Given** credentials
**Then** they are stored only on the device, are never included in backups and never appear in logs.

**Given** a connection test
**When** I run it
**Then** it uses the `netExecutor` injected from `app` (Story 4.3) with the 5 s connect and read timeouts, and reports success or a readable error.

**Given** cleartext traffic
**Then** it is allowed only to local network addresses.

### Story 6.6: Tasmota blaster

As a user with a Tasmota IR blaster,
I want to send codes through it,
So that I can control devices from anywhere in my home network.

**Acceptance Criteria:**

**Given** a blaster added with Story 6.5
**When** a signal is sent
**Then** it is sent as raw durations over HTTP, within the timeout, and the result is shown.

**Given** a network error or an unexpected reply
**Then** the message gives the cause and an action, and fallback applies.

**Given** the story
**Then** it is marked "verify on real hardware" and records the verification result.

### Story 6.7: ESPHome blaster

As a user with an ESPHome IR blaster,
I want to send codes through it,
So that I can reuse my existing setup.

**Acceptance Criteria:**

**Given** a blaster added with Story 6.5
**When** a signal is sent
**Then** it is sent as Pronto to the documented `web_server` action of the reference firmware.

**Given** the reference firmware
**Then** a sample configuration is documented in the repository.

**Given** a network error or an unexpected reply
**Then** the message gives the cause and an action.

### Story 6.8: Broadlink blaster

As a user with a Broadlink blaster,
I want to send codes through it,
So that I can control devices without extra hardware.

**Acceptance Criteria:**

**Given** a blaster added with Story 6.5
**When** it is first used
**Then** the app authenticates over UDP and keeps the session key in memory only, never persisted.

**Given** a signal
**When** it is sent
**Then** it is converted to a Broadlink packet with AES-128-CBC encryption, and the time unit is fixed by tests on a real RM4.

**Given** discovery
**Then** there is no automatic discovery in v1: devices are added manually.

**Given** the story
**Then** it is marked "verify on real hardware" and records the verification result.

## Epic 7: Air conditioners, widget and second source (v1.1)

Air conditioner remotes with persisted state, a home-screen widget and a quick settings tile, a second catalog source (irdb) with attribution, and the weekly automatic catalog update deferred from Epic 4. User value: control stateful devices, send a key without opening the app, and find more remotes.

### Story 7.1: Second catalog source (irdb)

As a user,
I want a second source of remotes,
So that I find devices missing from the first catalog.

**Acceptance Criteria:**

**Given** the catalog pipeline from Story 4.2
**When** the irdb source is added
**Then** its CSV data is parsed with the same hostile-input limits and included in the signed index with its own source marker.

**Given** the source selection in Settings
**Then** irdb is optional, shows its license warning, and can be turned off.

**Given** irdb content in the app
**Then** an attribution notice is visible in About and in the source sheet.

**Given** a search
**Then** results show their source and duplicates across sources are merged.

### Story 7.2: Air conditioner state model and profiles

As a user with an air conditioner,
I want the app to understand AC profiles and remember the state,
So that each command carries the complete state the unit expects.

**Acceptance Criteria:**

**Given** a SmartIR JSON or Flipper AC profile
**When** it is parsed
**Then** the app builds a model of modes, fan speeds, temperature range and the matching signals.

**Given** a state change (power, mode, fan, temperature)
**Then** the full state is encoded into the signal and saved in the `ac_state` table.

**Given** an invalid or unsupported profile
**Then** it is rejected with a readable error and no exception escapes.

**Given** the module
**Then** it is pure JVM logic with fixtures and tests, independent of the user interface.

### Story 7.3: Air conditioner remote screen

As a user with an air conditioner,
I want a screen that shows temperature, mode and fan,
So that I can control it as I would the physical remote.

**Acceptance Criteria:**

**Given** a remote with an AC profile
**When** S5 opens
**Then** the AC variant shows a large temperature, plus and minus controls, mode and fan chips and a Power key.

**Given** any change
**Then** the full state is sent and the display reflects the saved state after a restart.

**Given** a transmission error
**Then** the message gives the cause and an action, and the displayed state is not changed.

**Given** the screen
**Then** it meets the token, 48 dp, spoken-description and EN/IT string criteria.

### Story 7.4: Home-screen widget

As a user,
I want a widget that sends a key from my home screen,
So that I do not have to open the app.

**Acceptance Criteria:**

**Given** a saved remote
**When** I add the widget and choose a remote and a key
**Then** tapping it sends the key through the remote's transmitter without opening the app.

**Given** the remote or key no longer exists
**Then** the widget shows a clear state and does nothing when tapped.

**Given** the widget
**Then** it has a spoken description, a 48 dp minimum target and EN/IT labels.

### Story 7.5: Quick settings tile

As a user,
I want a quick settings tile that sends a key,
So that I can use it from the notification shade.

**Acceptance Criteria:**

**Given** the tile is added
**When** I choose a remote and a key
**Then** tapping the tile sends the key without opening the app.

**Given** an error
**Then** the tile shows an error state and a tap opens the Remote screen.

**Given** the tile
**Then** it has a spoken label and EN/IT strings.

### Story 7.6: Weekly automatic catalog update

As a user,
I want the catalog to refresh itself,
So that I do not use stale remotes.

**Acceptance Criteria:**

**Given** the setting is enabled
**Then** a weekly job (JobScheduler) runs only on an unmetered network and uses the same download and verification path as Story 4.3.

**Given** a failed verification
**Then** the previous catalog stays in use and the failure is shown the next time I open the catalog settings.

**Given** the setting is disabled
**Then** no background work is scheduled.

**Given** the job
**Then** it has its own tests for scheduling and failure behavior.

## Epic 8: Power-user tools (P2)

Code learning from remotes the catalog does not know, a layout editor to arrange buttons, and a way to contribute codes upstream. User value: full control for makers and a way to give back to the community catalog.

### Story 8.1: Learn a code with a USB dongle

As a maker,
I want to capture a code from my physical remote with a USB dongle,
So that I can use devices missing from the catalog.

**Acceptance Criteria:**

**Given** a supported dongle with learning capability
**When** I start learning and press a key on the physical remote
**Then** the captured signal is displayed with its durations and carrier frequency.

**Given** a captured signal
**Then** I can replay it, name it and save it to a remote.

**Given** no signal is received within a timeout
**Then** the message says so and suggests a retry.

**Given** the story
**Then** it records real-hardware verification.

### Story 8.2: Learn a code with Broadlink

As a maker,
I want to capture a code through a Broadlink device,
So that I can use devices missing from the catalog.

**Acceptance Criteria:**

**Given** a Broadlink blaster added in Epic 6
**When** I start learning and press a key on the physical remote
**Then** the captured signal is decoded and displayed.

**Given** a captured signal
**Then** I can replay it, name it and save it.

**Given** a timeout or an error
**Then** the message gives the cause and an action, and the session key stays in memory only.

**Given** the story
**Then** it records real-hardware verification.

### Story 8.3: Layout editor

As a user,
I want to arrange, rename and resize the buttons of a remote,
So that it looks the way I use it.

**Acceptance Criteria:**

**Given** a remote
**When** I enter edit mode
**Then** I can move, rename and resize buttons, and add or remove buttons for saved codes.

**Given** an edit
**When** I leave edit mode
**Then** the layout is saved and shown the same after a restart.

**Given** a destructive change (removing a button)
**Then** an undo action is available.

**Given** the editor
**Then** every action is available to TalkBack users, targets are at least 48 dp and strings exist in EN and IT.

### Story 8.4: Export a remote for contribution

As a maker,
I want to export my remote as a file the community catalog accepts,
So that I can contribute it upstream.

**Acceptance Criteria:**

**Given** a saved remote
**When** I choose to export for contribution
**Then** a `.ir` file is produced following the conventions of the Flipper-IRDB repository.

**Given** the file
**Then** it contains no personal data and only the device and codes.

**Given** the export
**Then** nothing is uploaded automatically: I get the file and the instructions to open a pull request.

