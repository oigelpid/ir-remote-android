---
title: IR Remote Android — UX Research
status: approved
date: 2026-10-15
author: oigelpid
source: https://claude.ai/code/artifact/4097266c-a3b9-4571-bd4d-366723e5c995
evidence: desk study, hypotheses to validate
---

# IR Remote Android — UX Research

## Goals and method

The decisive moment is the first one: finding a code that works. Desk study: personas and journeys are hypotheses, to be validated with the plan at the end.

Questions: who uses an IR remote on a phone and when; where users are lost before the first successful key; which choices reduce failed attempts; how to communicate hardware limits without looking like a broken app.

## Personas

| | Marta, 58 | Luca, 34 | Paolo, 41 |
| --- | --- | --- | --- |
| Situation | Air conditioner remote at the beach house is lost | New phone, wants an ad-free app | Homelab, TV and amp across several rooms |
| Phone | Redmi with IR | Xiaomi with IR | Pixel without IR + ESP32 Tasmota |
| Skill | Low | Medium | High (NEC, Pronto, LIRC) |
| Goal | Turn on and adjust today | Clean, offline TV remote | Own codes, sending over the network |
| Frustrations | Model lists, too many steps | Unnecessary permissions, trackers | Closed formats, no control |
| Convinced by | "It worked" in a few taps | No permissions, F-Droid | `.ir`/Pronto import, network, source |
| Drop-off | After 3–4 failed candidates | At the first sign of data collection | If their hardware is missing |

## Journey and friction

| Phase | Friction | Response |
| --- | --- | --- |
| Discovery | "Doesn't work" reviews from phones without IR | Explicit store listing; warning in S1 |
| First launch | Doesn't know if they have IR | S1 detects and explains |
| Search | Doesn't know the model; brand spelled differently | Search by brand; synonyms |
| Download | Waiting, privacy doubt | Explicit size, confirmation, "none of your data" |
| Test | Aiming; fatigue | Instruction, "Send again", ranking, counter |
| Confirmation | Power works, other keys don't | Second verification before saving |
| Daily use | Finding the right remote | Favorites, widget, tile |
| Failure | Abandonment | Other brand, import, prefilled report |

## Critical flows

**Find my remote**: Choose type and brand → Send to the candidate → "Did it work?" → no: next candidate (retry) / exhausted: ways out → yes: try a 2nd key → yes: save and open / no: next candidate.

**First launch**: S1 → "Add your first remote" → flow above. Goal < 3 min, zero permissions.

**Daily use**: widget/tile → key; or app → card → S5. Max two taps.

## Principles and decisions

| Principle | Decision |
| --- | --- |
| Devices, not protocols | Technical terms only in "Code details" |
| The phone doesn't know if it worked | Explicit question and double verification |
| Never a dead key | Only keys present in the code |
| Network and permissions only when needed | Catalog on confirmation; LAN permission only for blasters |
| Errors with cause and way out | Every error says why and what to do |
| The remote is the screen | S5 minimal, dark, large keys, one hand |
| The power user doesn't struggle | Import, manual code, transmitter choice one menu away |

Open decisions:
- [ ] Confirmation before Power (default off, to be tested).
- [ ] Candidate order: heuristic, no telemetry.
- [ ] Direct opening of the last remote only with a single favorite.

## Validation plan

- M1: 5 participants with IR (≥ 3 Marta-type), 2 real devices; measures: time to first key (< 3 min), candidates tried, errors, SUS (≥ 75); think-aloud.
- M3: 3 power users: Flipper import, Tasmota blaster, sending from S5 without documentation.
- Accessibility: TalkBack and 200% text on S2, S4, S5; contrasts verified.
- Continuous feedback: prefilled GitHub issue, shown before sending; `code-not-working` label per brand.
- v1.0 exit: 4 out of 5 reach the first key without help; no TalkBack blockers.
