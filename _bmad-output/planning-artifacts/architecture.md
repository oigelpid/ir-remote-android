---
title: IR Remote Android — Architecture
status: approved
date: 2026-10-15
author: oigelpid
source: https://claude.ai/code/artifact/d86332e6-8c8e-48a3-b075-de6adacb5ec4
---

# IR Remote Android — Architecture

## 1. Principles and constraints

Native Kotlin app split into Gradle modules; the IR core is pure JVM and testable, and everything that touches hardware or the network sits behind replaceable interfaces.

- **Zero runtime dependencies beyond `kotlin-stdlib`**: `Activity` + platform Views, `java.util.concurrent`, `HttpURLConnection`, `org.json`, `SQLiteDatabase`.
- **Pure core**: `ir-core` does not import `android.*`; tests run on the JVM.
- **External data = hostile input**: parsers with explicit limits.
- **Offline first** after the first save.
- **Explainable errors**: every error has a human-readable cause.

## 2. Modules and data flow

```
app  (Activity, View, library, guided trial, TransmitService)
 ├─> catalog     (signed index from CDN, cache, FTS4 search) ──> ir-formats
 ├─> ir-formats  (Flipper .ir, irdb CSV, Pronto, raw, SmartIR) ──> ir-core
 └─> tx-builtin | tx-audio | tx-usb | tx-net ──> ir-core
ir-core (IrSignal, encoder, validation — pure JVM)
```

One button press: `app` → `TransmitService` → signal from `ir-core` → chosen transmitter. Search goes through `catalog`, which uses `ir-formats`.

## 3. Canonical IR model

```kotlin
data class IrSignal(
    val carrierHz: Int,          // 0 = unmodulated
    val intro: IntArray,         // µs, alternating mark/space, starts with mark
    val repeat: IntArray,        // frames while button held (may be empty)
    val ending: IntArray = IntArray(0),
    val dutyCycle: Float? = null
)

sealed interface IrCode {
    data class Parsed(val protocol: Protocol, val address: Long, val command: Long, val subdevice: Long? = null) : IrCode
    data class Raw(val signal: IrSignal) : IrCode
    data class Pronto(val hex: String) : IrCode
}

interface ProtocolEncoder { fun encode(code: IrCode.Parsed, toggle: Boolean): IrSignal }
```

- P0 protocols: NEC/NEC1/NEC2/NECx, Samsung32, Sony 12/15/20, RC5, RC6 mode 0, Kaseikyo, JVC, Sharp, Denon. Pure functions with vector tests (IrScrutinizer, Flipper files).
- Intro/repeat/ending as in IRP; NEC sends the repeat code.
- RC5/RC6 toggle bit per button, held by `TransmitService`.
- Input: Flipper `.ir`, irdb CSV, Pronto (`0000`, `5000`, `6000`), textual raw, SmartIR JSON.
- Output: raw µs (built-in, audio, Tasmota), Pronto (ESPHome), Broadlink packet (time unit ~30–33 µs, to be fixed with tests on RM4), RLE for USB dongles.
- Validation before every send: durations > 0 and < 250 ms, even length, total < 2 s on the built-in transmitter, frequency within the ranges from `getCarrierFrequencies()` ±2 kHz.

## 4. Transmitters

```kotlin
interface IrTransmitter {
    val id: String
    val kind: Kind              // BUILTIN, AUDIO, USB, NETWORK
    fun capabilities(): Capabilities
    fun transmit(signal: IrSignal, repeats: Int): Result
    fun close()
}
```

| Implementation | Module | Mechanism | Permissions | Limits |
| --- | --- | --- | --- | --- |
| Built-in | `tx-builtin` | `ConsumerIrManager.transmit()` | `TRANSMIT_IR` (normal) | Blocking, max 2 s |
| Audio | `tx-audio` | `AudioTrack` PCM 16-bit 48 kHz, mark = sine wave at half the carrier in antiphase | none | Max volume, no confirmation |
| USB | `tx-usb` | `UsbManager` bulk; Tiqiaa driver 10C4:8468, ElkSmart 045C:02AA | per-device USB permission | Reverse-engineered protocols |
| Network | `tx-net` | Tasmota `GET /cm?cmnd=IRsend`; ESPHome with reference firmware; Broadlink UDP AES-128-CBC | `INTERNET`, `ACCESS_LOCAL_NETWORK` (target 37) | Cleartext LAN, no automatic discovery in v1 |

- One single-thread executor per transmitter; repeat every ~108 ms (NEC) while pressed.
- Audio: perceived frequency is doubled with an antiphase LED (38 kHz → generates 19 kHz); manual calibration.
- ESPHome: native API (protobuf + Noise) excluded; reference firmware with `web_server` and a Pronto action over HTTP.
- Broadlink: `javax.crypto`; session key in memory only.
- Automatic fallback to the next available transmitter.

## 5. Code database pipeline

1. Weekly snapshot in CI (`ir-index` repo) at pinned commits of Flipper-IRDB and irdb; same parsers as `ir-core`; invalid files discarded.
2. Compressed JSON index: source, type, brand, model, normalized buttons, protocol, path, SHA-256.
3. ECDSA P-256 signature (offline key, protected CI job); public key + backup key in the APK; verification with `java.security.Signature`.
4. Download from GitHub Releases or jsDelivr; individual files from the pinned commit verified against the SHA-256 in the index.
5. Cache in `filesDir`; manual or weekly update with `JobScheduler`.
6. SQLite FTS4 search with synonyms.
7. Candidate ranking: standard buttons present, most frequent protocol for the brand, then the rest.

## 6. Persistence, threading, permissions

| Table | Content |
| --- | --- |
| `remote` | id, name, type, brand, layout, preferred transmitter, source + hash |
| `button` | id, remote_id, label, standard role, serialized `IrCode`, position |
| `transmitter` | registered blasters and dongles (never session keys) |
| `ac_state` | air conditioner state |
| `index_*` | FTS4, rebuildable |

Versioned JSON backup; `dataExtractionRules` only for `remote`/`button`.

Threading: main thread for UI only; `dbExecutor` (1 thread); `netExecutor` (2 threads, 5 s timeout); one executor per transmitter; results returned via `Handler(Looper.getMainLooper())`.

| Permission | Type | When |
| --- | --- | --- |
| `TRANSMIT_IR` | normal | declared |
| `INTERNET` | normal | declared |
| `ACCESS_LOCAL_NETWORK` | runtime (A17, target 37) | adding a blaster |
| USB | system dialog | dongle connection |
| `uses-feature consumerir` | `required="false"` | always |

Import/export via the Storage Access Framework.

## 7. Supply chain

| Artifact | Role | In the APK |
| --- | --- | --- |
| `kotlin-stdlib` | runtime | Yes |
| Android Gradle Plugin | build | No |
| Kotlin Gradle Plugin | build | No |
| JUnit 4 | test | No |

- Gradle dependency verification (`verify-metadata`, `verify-signatures`, SHA-256); regenerate only with `--write-verification-metadata sha256,pgp` and code review of the diff.
- Only `google()` and `mavenCentral()` with `content { includeGroup… }`.
- Wrapper with `distributionSha256Sum` and jar verification.
- Actions pinned by SHA, `permissions: read-all`, no `pull_request_target`.
- OSV-Scanner on every PR, weekly OpenSSF Scorecard, CycloneDX SBOM at release.

Evaluation sheet for a new dependency:

| Criterion | Threshold |
| --- | --- |
| Necessity | Not replicable in < ~300 lines |
| Maintenance | Commits in the last 90 days |
| Bus factor | ≥ 2 active maintainers, ideally from different organizations |
| Code review | Majority of changes reviewed |
| Releases | PGP-signed or SLSA provenance |
| Vulnerabilities | No open high CVE (OSV) |
| Transitive | Zero or already in inventory |
| License | GPL-3.0 compatible |

Data: signed index, per-file hash, limits (file ≤ 256 KB, ≤ 500 signals, ≤ 1024 durations), names rendered as plain text.

## 8. Build, CI, test, release

Modules: `ir-core`, `ir-formats`, `tx-builtin`, `tx-audio`, `tx-usb`, `tx-net`, `catalog`, `app`.

| Level | Covers | Where |
| --- | --- | --- |
| JVM unit | Encoders with vectors, Pronto↔raw round trip, parser fuzzing | CI, every PR |
| Corpus | Entire Flipper-IRDB and irdb snapshot | CI, weekly |
| Instrumented | Built-in transmitter on device with an ESP verification receiver | Manual bench, pre-release |
| UI | Platform instrumentation + scripted manual tests (no Espresso) | Pre-release |

Release: signed GPG tag → reproducible build in container (`SOURCE_DATE_EPOCH`) → AAB on Play / APK on GitHub → F-Droid verifies reproducibility → SBOM and checksums attached.
