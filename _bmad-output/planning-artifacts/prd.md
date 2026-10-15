---
title: IR Remote Android — PRD
status: approved
date: 2026-10-15
author: oigelpid
source: https://claude.ai/code/artifact/fa0ba6a7-e365-4189-ac51-8d6937cc0a0b
track: bmad-method (+ security/devops sections of the enterprise track)
---

# IR Remote Android — PRD

## Summary

An open source universal remote for Android that finds IR codes in open databases, sends them from the built-in transmitter or from an external one, and does so with a number of third-party dependencies close to zero, each of them vetted.

**Problem.** IR apps on the Play Store are largely closed source, full of ads and trackers, with proprietary databases. Open source alternatives exist, but they either do not search online databases or rely on frameworks with a large dependency tree.

**v1.0 goals**

1. A user with an IR-equipped phone controls their TV within 3 minutes of installing, without knowing anything about protocols.
2. Unified search across at least two open databases (Flipper-IRDB, irdb) with automatic format conversion.
3. Zero analytics, advertising, or crash reporting SDKs; no personal data leaves the phone.
4. Third-party runtime dependencies outside AOSP: target zero, hard cap of three, each with an evaluation sheet.
5. Publishable on Google Play (target API 36) and on F-Droid with a reproducible build.

## Baseline study

### Android IR API

- `ConsumerIrManager` requires the `FEATURE_CONSUMER_IR` feature and exposes `hasIrEmitter()`, `getCarrierFrequencies()`, and `transmit(frequency, pattern)`.
- `transmit` is synchronous and discards patterns longer than 2 seconds: "button held down" repetition must be built by the app as successive frames.
- The `TRANSMIT_IR` permission is a normal permission: no user prompt.
- Phones with built-in IR are mostly Xiaomi/Redmi/POCO, some Huawei/Honor, and various Chinese models; Samsung and Pixel do not have it.

### Open code databases

| Database | Format | License | Use on Play | Notes |
| --- | --- | --- | --- | --- |
| Flipper-IRDB | `.ir` file (parsed + raw) | CC0-1.0 contributions | Yes, including bundled | The most active; by type/brand/model |
| irdb (probonopd) | CSV protocol/device/subdevice/function | Custom license | Yes, with conditions | Notification issue before use + attribution notice |
| SmartIR codes | JSON (Broadlink base64, Pronto, raw) | MIT on the repo, data to be verified | Probable | Strong on air conditioners |
| LIRC remotes | `.conf` | to be verified | To be verified | Huge but dated |
| Global Caché | Hex/GC | Proprietary | No | Excluded |

Decision: Flipper-IRDB as primary, irdb as secondary with attribution and a notification issue before release, the others as manual import.

### External transmitters

- **Audio jack**: IR LED driven by PCM, mono or stereo in antiphase; volume at maximum.
- **USB dongles**: Tiqiaa/Tview (10C4:8468) and ElkSmart/Ocrustar (045C:02AA), with published reverse-engineered protocols.
- **Network blasters**: Broadlink RM (local UDP, AES-encrypted), ESP8266/ESP32 with Tasmota or ESPHome.

### Open source competitors

| App | Stack | Transmitters | Search | License |
| --- | --- | --- | --- | --- |
| IR Blaster (iodn) | Flutter | built-in, USB, audio | GitHub repo browser, Flipper/LIRC/IRPLUS import | GPL-3.0 |
| SupIR | Android | built-in | bundled irdb | GPL-3.0 |

Our space: the hardware scope of IR Blaster plus network blasters, brand-guided search, a native app with near-zero dependencies.

## Users and use cases

| Segment | Need | Typical hardware | Main use case |
| --- | --- | --- | --- |
| General user | Turn on TV/air conditioner without the remote | Xiaomi with IR | Search brand, try buttons, save |
| Privacy-conscious | Remote without ads or trackers | Phone with IR | F-Droid, offline |
| Maker / homelab | Multiple rooms, own codes | USB dongle, ESP Tasmota/ESPHome, Broadlink | Import `.ir`, send over network, learn codes |

Key use cases:

1. **Find my remote**: type → brand → guided trial → save.
2. **Daily use**: favorite remote, widget, tile.
3. **Button held down**: volume and channels repeat.
4. **Air conditioner**: full state in every command.
5. **Import/export**: Flipper `.ir`, Pronto, raw; JSON backup.
6. **Remote transmitter**: send to a blaster on the LAN.

## Functional requirements

P0 = v1.0, P1 = v1.x, P2 = later.

| ID | Requirement | Priority | Acceptance criterion |
| --- | --- | --- | --- |
| FR1 | Detect available transmitters and supported frequencies | P0 | On first launch the screen shows what is available and why |
| FR2 | Transmit a raw code from the built-in transmitter | P0 | Validated pattern: positive durations, even length, total < 2 s |
| FR3 | Encode NEC/NECx, Samsung32, Sony 12/15/20, RC5, RC6, Kaseikyo, JVC, Sharp, Denon | P0 | Vector tests against IrScrutinizer/Flipper for each protocol |
| FR4 | Pronto hex ↔ raw | P0 | Lossless round trip apart from carrier quantization |
| FR5 | Search by type and brand on Flipper-IRDB | P0 | Results within 2 s with cached index |
| FR6 | Guided trial of candidates | P0 | At most 3 taps per candidate |
| FR7 | Local library with favorites | P0 | Works offline after saving |
| FR8 | Repeat while button held, using repeat frames | P0 | NEC uses the repeat code |
| FR9 | Import Flipper `.ir`, Pronto, raw; JSON export/backup | P0 | Import of all of Flipper-IRDB without crashes (CI) |
| FR10 | Second source irdb with attribution | P1 | Notice visible in About and in the source sheet |
| FR11 | Audio jack transmitter | P1 | Test with a real adapter at 38 kHz |
| FR12 | Tiqiaa and ElkSmart USB dongles | P1 | Send verified; USB permission handled |
| FR13 | Tasmota, ESPHome, Broadlink network blasters | P1 | Manual add by IP; credentials only on device |
| FR14 | Air conditioner with state | P1 | SmartIR or Flipper profiles, state persisted |
| FR15 | Widget and quick settings tile | P1 | Button sent without opening the app |
| FR16 | Code learning (USB, Broadlink) | P2 | Captured, displayed, replayed, saved |
| FR17 | Layout editor | P2 | Move, rename, resize buttons |
| FR18 | Code contribution to Flipper-IRDB | P2 | `.ir` conforming to the repo conventions |

## Non-functional requirements

### NFR1 — Dependencies and supply chain
- Runtime: only the Android SDK and `kotlin-stdlib`. No AndroidX, networking libraries, external JSON libraries, or DI.
- Build: only AGP and the Kotlin Gradle Plugin, pinned and verified.
- `gradle/verification-metadata.xml` with SHA-256 and PGP signatures; the build fails on unregistered artifacts.
- Mandatory evaluation sheet for every new dependency (OpenSSF Scorecard criteria).
- Downloaded data treated as hostile input; content pinned by commit hash.

### NFR2 — Privacy and network
- No analytics, crash reporting, or advertising.
- Network only to allowlisted CDNs and user-added LAN blasters.
- Cleartext forbidden except for LAN addresses.
- `ACCESS_LOCAL_NETWORK` (Android 17, target 37) requested only when adding a blaster.

### NFR3 — Platform and distribution
- `minSdk` 26, `targetSdk` 36; plan for 37.
- Google Play (AAB, Play App Signing) + F-Droid (reproducible build).
- Data safety: no data collected or shared.

### NFR4 — License
GPL-3.0-or-later (alternative: Apache-2.0). irdb attribution in the app.

### NFR5 — Quality
- Cold start < 500 ms on a 2021 mid-range device; APK < 3 MB.
- Tap → transmission latency < 50 ms on the built-in transmitter.
- TalkBack on all buttons, 48 dp targets, WCAG AA contrast.
- v1 languages: Italian and English.

## Out of scope for v1

433 MHz RF, Broadlink/Tuya cloud, accounts, sync, iOS, proprietary databases, large-scale jamming or brute-forcing.

## Risks

| Risk | Prob. | Impact | Mitigation |
| --- | --- | --- | --- |
| Code does not work on the model | High | High | Multi-candidate guided trial; fallback to protocol + device code |
| Code repo compromised | Medium | Medium | Pinned commits, signed index, parser with limits |
| irdb terms not respected | Low | High | Notification issue before release; in-app notice |
| Play rejection for policy | Low | High | Contextual permissions; accurate Data safety |
| Bus factor = 1 | High | High | Docs, public CI, co-maintainer from v1.0 |
| USB/Broadlink protocols change | Medium | Medium | Optional, isolated modules |
| Declining number of phones with IR | Medium | Medium | USB and network early (P1) |

## Metrics (no telemetry)

Store reviews, `code-not-working` issues per brand, time to first button in tests (< 3 min), OpenSSF Scorecard of the repo (≥ 8).

## Roadmap

1. **M0 — Foundations**: ir-core with tests, built-in transmitter, CI with dependency verification. Exit: green vector tests on all P0 protocols.
2. **M1 — Alpha**: Flipper-IRDB search, guided trial, local library. Exit: 5 users find their TV without help.
3. **M2 — v1.0**: import/export, repeat, accessibility, F-Droid + Play. Exit: Data safety approved, reproducible build verified.
4. **M3 — v1.1**: audio, USB, network, irdb, air conditioners, widget.
5. **M4 — v1.2+**: learning, layout editor, upstream contribution.
