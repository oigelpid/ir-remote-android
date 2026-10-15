---
title: IR Remote Android — UI Specification
status: approved
date: 2026-10-15
author: oigelpid
source: https://claude.ai/code/artifact/1f41645c-b1f4-40fc-b191-c79cf265cfea
---

# IR Remote Android — UI Specification

## Visual foundations

Sober interface resembling a physical remote, dark theme by default, platform resources (`Theme.DeviceDefault`), no Material Components.

### Color tokens

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `bg` | #F6F6F4 | #121314 | Background |
| `surface` | #FFFFFF | #1C1E20 | Cards, keypad |
| `key` | #ECEDEF | #2A2D30 | Keys |
| `key_pressed` | #D5D8DC | #3A3F44 | Pressed key |
| `text` | #1A1C1E | #ECEEF0 | Text |
| `text_muted` | #5F6368 | #9AA0A6 | Captions |
| `accent` | #1A5FD0 | #6FA3FF | Primary action |
| `power` | #C5221F | #F28B82 | Power only |
| `ok` | #137333 | #81C995 | Confirmations |
| `warn` | #8A4B00 | #FDD663 | Warnings |

All color/background pairs (bg, surface, key) ≥ 4.5:1 in both themes (WCAG 2.x); minimum 4.95:1.

### Typography and spacing
- System font. Title 22 sp, section 18, body 16, key 15 medium, caption 13.
- 4 dp grid; 16 dp margins; 12 dp spacing between keys.
- Keys ≥ 56 × 56 dp, 16 dp corners, D-pad 200 dp.

### Themes
- Light, dark, system. Own vector icons (~30). Edge-to-edge with `WindowInsets`.

## Navigation

Home is the only hub. S1 Welcome → S2 Home → S3 Add → S4 Guided test → S5 Remote. S2 → S5 with one tap on a card; S2 → S6 Settings; S5 → S7 Transmitters; Widget/tile → S5. System Back goes back one step (predictive back enabled).

## Screens (one Activity each, no Fragments)

### S1 · Welcome (first launch)
- One row per transmitter (built-in, audio, USB, network) with status: available / absent / to be configured.
- No IR: clear message + "Use an adapter" / "Explore anyway".
- Primary: "Add your first remote". No permission requested.

### S2 · Home
- Bar: title, active transmitter icon (→ S7), overflow.
- 2-column grid of cards (type icon, name, brand, favorite); favorites first.
- Long press: rename, duplicate, change transmitter, export, delete with undo.
- Round "+" button → S3. Empty state: "Find your remote".

### S3 · Add: type and brand
- Step 1: type grid (TV, Air conditioner, Set-top box, Projector, Audio, Fan, LED lights, Other).
- Step 2: brand search with suggestions, common brands on top.
- Secondary: "Import from file", "Enter code manually".
- Catalog missing: banner with size in MB and confirmation.

### S4 · Guided test
- "Brand Type · candidate N of M"; large key (Power, or Vol+ for devices that must not be turned off); "Point the phone and press".
- After sending: "It worked" / "Nothing, try the next one"; "Send again" link.
- On success: verify with a second key, suggested name, save → S5.
- Candidates exhausted: other brand/type, file import, report a missing brand.

### S5 · Remote
- Layout by role: Power/Input/Mute row, D-pad, Vol/Ch rocker, collapsible keypad, scrollable extras.
- Only keys present in the code.
- Feedback: short vibration + "IR" indicator.
- Repeat on Vol, Ch, arrows.
- Air conditioner: large temperature, +/−, mode and fan chips, Power; every change sends the full state.

### S6 · Settings
- Theme, vibration, Power confirmation (off), catalog update, sources (irdb with license warning), backup/restore, language.
- Privacy: "No data leaves the phone, except the catalog download".
- Info: version, GPL, attributions, source and SBOM links.

### S7 · Transmitters
- List with status and frequencies.
- Audio: mono/stereo, test, calibration.
- USB: device, permission.
- Network: add blaster (Tasmota, ESPHome, Broadlink, IP, name); `ACCESS_LOCAL_NETWORK` only here, with an explanation before the prompt.

## Custom View components

| Component | Class | Behavior | Accessibility |
| --- | --- | --- | --- |
| IR key | `IrKeyView` | Normal/pressed/disabled states; repeat after 300 ms, then ~110 ms | Spoken label, "press and hold" action |
| D-pad | `DpadView` | 4 sectors + OK, angular hit-test | 5 virtual nodes |
| Rocker | `RockerView` | Vertical pill +/− | 2 virtual nodes |
| Card | `RemoteCardView` | Icon, name, brand, star | Single reading |
| Action | `FabView` | 56 dp `accent` circle | Label required |
| Indicator | `TxIndicatorView` | 150 ms blink, red on error | Announced on error only |

Other: `TextView`, `EditText`, `ListView`/`GridView` (no RecyclerView), `Switch`, `SeekBar`, `PopupMenu`, `AlertDialog`.

## States, feedback, accessibility

| State | Where | What the user sees |
| --- | --- | --- |
| Empty | S2, S3 | Explanation + main action |
| Loading | S3, S4 | Progress with MB, cancelable |
| Offline | S3 | File import and manual code remain |
| Transmission error | S4, S5 | Red indicator + cause + action |
| Transmitter absent | S5 | `warn` banner with "Use phone IR" |
| Invalid catalog signature | S3 | "Update rejected for security reasons", previous version is used |

- `VIRTUAL_KEY` haptics if enabled; no sound by default.
- Targets ≥ 48 dp (main ones 56); text up to 200%; labels → icons above 130%.
- Ordered focus; no color-only information; left-handed mode; IT/EN strings.
