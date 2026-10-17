# Party mode decisions: epics.md coverage gaps

Format: team of 5 (Winston, Sally, John, Amelia, Vex), qualified majority 4/5, max 20 turns per agent per point. Dissent is recorded. Decisions are proposals for `epics.md`; not yet applied.

## P1 · UX-DR3 (theme, edge-to-edge, predictive back, own vector icons)

Result: CONSENSUS 5/5 (winston, sally, john, amelia, vex). No dissent. No separate foundation story.

Final text (Winston's P1.3, integrating Vex and Amelia):

**Story 2.1, new ACs**
- Given any Activity, When it is created, Then its theme parent is `android:Theme.DeviceDefault*` with light, dark and system variants (`values-night`), colors come only from the spec tokens, and no AndroidX, Material or Compose artifact is on the runtime classpath (CI dependency check).
- Given the manifest, Then `android:enableOnBackInvokedCallback="true"` is set, Back is handled with `OnBackInvokedCallback` one navigation step per press, and this story adds no permission.
- Given gesture or 3-button navigation, When a screen is shown edge-to-edge, Then WindowInsets (systemBars, displayCutout, IME) are applied and no control is hidden or smaller than 48 dp.
- Given the icons it uses, Then they are own XML VectorDrawables (24 dp, token tint), no icon library, no bitmap, provenance and licence stated, each with contentDescription or marked decorative.

**Stories 3.4, 3.5 and later screen stories**: AC "theme, WindowInsets and predictive back inherit from Story 2.1" (verification, not creation), plus own icons under the same rule.

**Story 5.1, new AC**: Given the release build, Then a CI/lint check finds no bitmap icon in `res/drawable`, the vector icon count is about 30, and each has a description or is decorative.

## P2 · UX-DR12 (RemoteCardView, FabView, TxIndicatorView not named)

Result: CONSENSUS 5/5 on P2.1 (sally, vex, amelia, winston, john). No dissent. No new stories. Each class is created in the first story that uses it. Note: the agents' closing texts differ only by additive details; the lead merged them below.

- **Story 3.4, +1 AC**: Given saved remotes, When Home is shown, Then each remote is a `RemoteCardView` (type icon, name, brand, favorite star; target at least 48 dp) read by TalkBack as a single item, and the add action is a `FabView` (56 dp accent circle, accessibility label required) that opens S3.
- **Story 2.3, +1 AC** (replaces the word "indicator" in its existing ACs; the class is created here): Given a transmission, When it starts or fails, Then it is signalled by `TxIndicatorView`: 150 ms blink, error color on failure, announced to TalkBack on error only, and the announced text contains no host or IP of a blaster (Rule zero).
- **Story 3.5**: the error AC and the tap AC name `TxIndicatorView` (from Story 2.3); `IrKeyView` is created here.
- **Story 3.6**: the first AC and the accessibility AC name `IrKeyView` (repeats after 300 ms, then about every 110 ms; the long-press action exposes repeat to TalkBack).

## P3 · UX-DR14 (left-handed mode, VIRTUAL_KEY haptics, labels to icons above 130%)

Result: CONSENSUS 5/5 on P3.1 (vex, sally, winston, amelia, john). No dissent. Sally first preferred "no setting, audit only"; she yielded. Facts: left-handed appears only in `ux-design-spec.md` line 113 (UX-DR14), not in the PRD, architecture or research; kept in v1 because it costs one switch. No new stories.

- **Story 3.8, +1 AC**: Given Settings (S6), Then a "Left-handed layout" switch (off by default) is offered, applies immediately and persists across restarts (local boolean, no permission).
- **Story 3.4, +1 AC**: Given left-handed layout on, Then `FabView` moves to the bottom-left.
- **Story 3.5, +1 AC (mirroring)**: Given left-handed layout on, When the Remote screen opens, Then the Volume and Channel rockers and the collapsible-keypad toggle swap sides, the D-pad stays centered, and every target is still at least 48 dp.
- **Story 3.5, +1 AC (haptics)**: Given vibration is enabled, When a key is pressed, Then `HapticFeedbackConstants.VIRTUAL_KEY` is performed once per press (not on each repeat in Story 3.6) and no sound is played.
- **Story 3.5, +1 AC (font scale)**: Given font scale above 130%, Then keys with a defined icon show the icon next to the label, and nothing is clipped up to 200%.
- **Story 5.1**: verifies all of this, including mirroring on the screens that define it.

## P4 · AR11 (manifest permissions in no AC)

Result: QUALIFIED MAJORITY on P4.1 (vex as proposer; formal CONSENSO from john, sally, winston, amelia). No dissent. No new stories. Each permission is declared by the first story that uses it (no dormant `INTERNET`). Consistent with P1 (Story 2.1 adds no permission).

- **Story 1.2, +1 AC**: Given a pull request, When CI runs, Then it checks the merged manifest against `tools/manifest-permissions.allowlist` (grep only, no dependency) and fails on any `uses-permission` not listed and on any `uses-feature` with `required=true`.
- **Story 2.3, +1 AC**: Given the manifest, Then it declares `TRANSMIT_IR` (normal permission, no runtime prompt) and the allowlist gains exactly that entry.
- **Story 4.3, +1 AC**: Given the manifest, Then it declares `INTERNET` and the allowlist gains exactly that entry; no other network permission, `ACCESS_NETWORK_STATE` included. Offline is detected from the request failure (5 s timeout), not from a pre-check.
- **Story 6.5**: `ACCESS_LOCAL_NETWORK` enters the allowlist there.
- **Story 5.6, +1 AC**: Given the release manifest, Then its permissions equal the allowlist and the Data safety answers are checked against it.
- Already covered, unchanged: Story 2.1 `uses-feature consumerir required=false`; Story 3.7 `dataExtractionRules`; Story 6.5 `ACCESS_LOCAL_NETWORK` at runtime. `allowBackup` is not mentioned in `architecture.md`; open note for the epics update.

## P5 · AR10 (Story 4.3 lacks network executor, 5 s timeout, cancellation)

Result: CONSENSUS 5/5 on P5.4 (= P5.3 of Vex, which includes Sally's UX AC, plus Winston's bounded queue in AC 1; reconfirmed by vex, sally, winston, john, amelia). No dissent. No new stories. `INTERNET` is already covered by P4.1. The id P5.2 was used twice during the discussion; resolved into P5.3, then P5.4.

**Story 4.3, new ACs**
1. Given any catalog request, Then it runs on the shared `netExecutor` (2 threads, bounded queue; a full queue yields a readable "busy, try again" error) created in the `app` composition root and injected as `java.util.concurrent.Executor` into `catalog` and `tx-net` (neither creates it), never on the main thread; results return via `Handler(Looper.getMainLooper())`.
2. Given an `HttpURLConnection`, Then connect and read timeouts are 5 s each (not a cap on total download time); a stalled download fails with a readable cause and a "Try again" action; the previous catalog stays in use.
3. Given a redirect, Then each hop must be https and on the allowlist, at most 3 hops, otherwise the download fails with a readable error.
4. Given a download, Then the body is streamed to a temp file in app-private storage with a hard size cap (declared size plus margin, abort beyond it), and signature and SHA-256 are verified before any parsing or renaming into the active catalog.
5. Given cancel or leaving the screen, Then the connection is closed within one read interval and the partial temp file is deleted.
6. Given the logs, Then no URL, header or response body is logged.
7. Given a download is running, Then S3 shows progress in MB with Cancel (UX-DR13); When it fails by network or timeout, Then the message states the cause, offers "Try again" plus import from file and manual code, is distinct from "Update rejected for security reasons", and no host or URL appears in shown text (UX-DR15).

**Story 6.5**: "uses the `netExecutor` injected from `app` (Story 4.3)". Same for other `tx-net` stories.

## P6 · UX-DR15 ("Code details" view in no story)

Result: CONSENSUS 5/5 (winston, sally, john, amelia, vex) on the 7-AC text (ids P6.2/P6.3/P6.4 in the discussion, identical content). No dissent. Facts: "Code details" is defined only by `ux-research.md` line 55 and UX-DR15; `ux-design-spec.md` does not say where it opens or what it shows. The data already exists (`IrCode` serialized per button; `remote` has source and hash). A new small story was preferred over an AC in 3.5 (new screen: key list plus dialog). It can be deferred if the budget tightens (Winston).

**New Story 3.9 "Code details"** (Epic 3, after 3.5, read-only)
1. Given S5, When I open the overflow menu and choose "Code details", Then per key I see: format or protocol name, address, command, toggle, carrier frequency, number of durations, total duration, and the catalog source name and license of the remote.
2. Given a key, When I choose "Copy code", Then only the Pronto/raw text is copied, only on that explicit action.
3. Given any other screen or error message, Then no protocol name, address or command appears. Exception: Story 2.2 manual entry and Story 3.3 import preview may show carrier, duration count and file format.
4. Given Code details, Then it renders only a fixed allowlist of `IrCode` fields plus the remote's source name and license; it never shows transmitter name, host, IP, credentials, session keys, file paths, hashes, catalog URL or signature (Rule zero), and works offline.
5. Given names or values from an imported file, Then they are plain text only (no HTML, no links) and truncated at a length limit.
6. Given an error, Then Code details is never opened automatically and its content is not logged.
7. Given the view, Then it meets the token, 48 dp, TalkBack and EN/IT criteria.

Out of v1: the optional "Code details" link from the S4 candidate (Story 4.6).

## P7 · UX-DR7 (S3 "Import from file" and "Enter code manually" only in the empty state)

Result: CONSENSUS 5/5 on P7.2v (= P7.1j of John + "loading" state from Sally + security AC from Vex; reconfirmed by john, winston, amelia, vex, sally). No dissent. No new stories. Only Story 4.4 changes. `ux-design-spec.md` lines 57-61 and 106 already require both entries in S3 in every state; S3 is born in Story 4.4, which owns the entries, while 2.2 and 3.3 own the flows. Before Epic 4 the entry stays the empty Home (Story 3.4).

**Story 4.4, +3 ACs**
1. Given the Add screen (S3), When it is shown in any state (catalog present, missing, offline, loading or no results), Then "Import from file" and "Enter code manually" are always visible as secondary actions below the brand search, each at least 48 dp with a spoken description.
2. Given I choose "Import from file" or "Enter code manually", Then the flow of Story 3.3 or Story 2.2 opens respectively, works with no catalog and no network, and Back returns to S3.
3. Given the import entry from S3, Then it uses the same system file picker, parser path and limits as Story 3.3 (no storage permission, file <= 256 KB, <= 500 signals, <= 1024 durations, 1..250000 us); S3 adds no second validation path and no permission.

The existing "no results" line stays, without duplicating the flows.

---

## Summary

All 7 points closed with 5/5 consensus; no dissent recorded. New story: 3.9 "Code details". No other new stories. Changes by story:
- 1.2: manifest allowlist CI check (P4).
- 2.1: theme, edge-to-edge, predictive back, icons (P1).
- 2.3: `TRANSMIT_IR` declaration; `TxIndicatorView` (P4, P2).
- 3.4: `RemoteCardView`, `FabView`; FAB bottom-left in left-handed mode (P2, P3).
- 3.5: `TxIndicatorView` reuse, `IrKeyView` creation; left-handed mirroring, `VIRTUAL_KEY` haptics, font scale above 130% (P2, P3).
- 3.6: `IrKeyView` repeat wording (P2).
- 3.8: left-handed switch (P3).
- 3.9: new "Code details" story (P6).
- 4.3: `INTERNET` declaration; `netExecutor`, timeouts, redirects, size cap, cancel, logs, UX (P4, P5).
- 4.4: S3 entries (P7).
- 5.1: icon CI/lint check; mirroring verification (P1, P3).
- 5.6: release manifest equals allowlist (P4).
- 6.5: reuses `netExecutor` (P5); `ACCESS_LOCAL_NETWORK` enters allowlist (P4).

Open notes for the epics update: confirm Winston's once-per-press haptic clause (P3); `allowBackup` is not mentioned in `architecture.md` (P4).
