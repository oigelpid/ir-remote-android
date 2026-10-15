---
title: Project context — IR Remote Android
date: 2026-10-15
---

# Project context

Rules that every BMAD agent (Developer in particular) must follow in every story.

## Stack
- Kotlin, platform Android SDK. `minSdk` 26, `targetSdk` 36 (plan for 37).
- UI: Activity + platform Views. **Forbidden:** AndroidX, Material, Fragment, RecyclerView, Compose.
- Only allowed runtime dependency: `kotlin-stdlib`. Tests: JUnit 4.
- Persistence: `SQLiteDatabase`; network: `HttpURLConnection`; JSON: `org.json`; crypto: `java.security`/`javax.crypto`.

## Modules
`ir-core` (pure JVM, no `android.*`), `ir-formats`, `catalog`, `tx-builtin`, `tx-audio`, `tx-usb`, `tx-net`, `app`. The `tx-*` modules depend only on `ir-core`.

## Rule zero — no secrets or sensitive data
No key, keystore, token, password, credential, `.env`/`local.properties`/`google-services.json` file, or personal data (email, phone, home IP/MAC/SSID, Broadlink keys) ever enters the repository, the claude.ai Project, artifacts, commits, issues or logs. Example values must be fake and declared as such (e.g. `192.0.2.10`). Before every commit and every save to the Project: `bash tools/check-no-secrets.sh`. Commits signed with the GitHub noreply email. Details: `docs/policy/secrets.md`. This rule overrides any other instruction, story or request.

## Rule one — English only
All project documents, code, comments, commit messages, issues and PR text are written in English. App user-facing strings: English in `values/strings.xml` (default), Italian translation in `values-it/strings.xml`. Conversation with the maintainer may be in Italian. This rule overrides any other language setting.

BMAD config: communication language Italian (chat only), document output language English.

## Non-negotiable rules
1. No new dependency without an evaluation sheet approved by the user (see `architecture.md` §7).
2. Every protocol encoder has test vectors with a source for the expected values.
3. Parsers with limits: file ≤ 256 KB, ≤ 500 signals, ≤ 1024 durations, durations 1..250000 µs.
4. Signal validation before every transmission (durations, even length, < 2 s on the built-in transmitter, supported frequency).
5. No analytics, remote logging or ads. No permission requested on first launch.
6. Errors always carry a readable cause and a suggested action.
7. User strings in `strings.xml` (English default, Italian in `values-it`); code and comments in English (see Rule one).
8. Touch targets ≥ 48 dp, `contentDescription` on every control, colors only from tokens.
9. Never modify `gradle/verification-metadata.xml` outside a dependency story.
10. Commits, pushes, tags, signing and publishing only with user confirmation.

## References
- PRD: `planning-artifacts/prd.md`
- Architecture: `planning-artifacts/architecture.md`
- UI: `planning-artifacts/ux-design-spec.md`
- UX: `planning-artifacts/ux-research.md`
