---
status: draft
stepsCompleted: [1, 2]
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

<!-- Repeat for each epic in epics_list (N = 1, 2, 3...) -->

## Epic {{N}}: {{epic_title_N}}

{{epic_goal_N}}

<!-- Repeat for each story (M = 1, 2, 3...) within epic N -->

### Story {{N}}.{{M}}: {{story_title_N_M}}

As a {{user_type}},
I want {{capability}},
So that {{value_benefit}}.

**Acceptance Criteria:**

<!-- for each AC on this story -->

**Given** {{precondition}}
**When** {{action}}
**Then** {{expected_outcome}}
**And** {{additional_criteria}}

<!-- End story repeat -->
