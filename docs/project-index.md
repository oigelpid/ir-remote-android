# IR Remote Android — project document index

Last updated: 2026-10-17

## Iron rules (override everything else)
1. **Rule zero — no secrets or sensitive data**: no keys, keystores, tokens, passwords, credentials, real names or other sensitive information in the repository, artifacts, commits, issues or logs. Run `bash tools/check-no-secrets.sh .` before every commit. Policy: [docs/policy/secrets.md](policy/secrets.md). The user is identified only by their GitHub username.
2. **Rule one — English only**: every document, all code, comments, commit messages, issues and PR text are in English, regardless of the chat language. App UI strings: English default, Italian translation.

## Repository
- Source of truth: https://github.com/oigelpid/ir-remote-android (public, license GPL-3.0-or-later). Work on `claude/...` branches with pull requests; merges, tags and signing by the user.

## Documents
- PRD: [_bmad-output/planning-artifacts/prd.md](../_bmad-output/planning-artifacts/prd.md)
- Architecture: [_bmad-output/planning-artifacts/architecture.md](../_bmad-output/planning-artifacts/architecture.md)
- UI Specification: [_bmad-output/planning-artifacts/ux-design-spec.md](../_bmad-output/planning-artifacts/ux-design-spec.md)
- UX Research: [_bmad-output/planning-artifacts/ux-research.md](../_bmad-output/planning-artifacts/ux-research.md)
- Epics and stories: `_bmad-output/planning-artifacts/epics.md` (once merged)
- Project rules for every story: [_bmad-output/project-context.md](../_bmad-output/project-context.md)
- Agents and orchestration (instructions for Claude): [docs/agents-and-orchestration.md](agents-and-orchestration.md)
- BMAD across sessions (instructions for Claude): [docs/bmad-sessions.md](bmad-sessions.md)
- Current BMAD status and pending work: [docs/STATUS.md](STATUS.md)
- Tool audit: [docs/tooling-audit/bmad-method-6.12.4.md](tooling-audit/bmad-method-6.12.4.md)

## Decisions
- UI with classic platform Views, no AndroidX; the only runtime dependency is kotlin-stdlib.
- Transmitters: built-in IR (v1.0), then audio jack, USB dongles (Tiqiaa, ElkSmart), network blasters (Tasmota, ESPHome, Broadlink).
- Distribution: Google Play (target API 36) + F-Droid with reproducible build. License: GPL-3.0-or-later.
- Code databases: Flipper-IRDB (CC0) primary; irdb secondary with notification issue and attribution notice.
- Catalog shipped as a signed index (ECDSA P-256) generated in CI from pinned commits.
- Supply chain: Gradle dependency verification (sha256 + pgp), per-group repository routing, Actions pinned by SHA, OSV-Scanner, OpenSSF Scorecard, CycloneDX SBOM.
- Subagent use: governed by [docs/agents-and-orchestration.md](agents-and-orchestration.md) (S/M/L/XL scale, max 4 in parallel, mandatory independent review on critical parts, signing and publishing only with user confirmation).
- Secrets and sensitive data: rule zero; commits use the GitHub noreply address; secret scanning and push protection on GitHub (to be enabled by the user, see [docs/STATUS.md](STATUS.md)).
- Epic and story structure decisions are taken with the BMAD party mode round table by qualified majority (4 of 5); a deadlock keeps the draft and is flagged to the user.

## BMAD method
- BMAD Method v6.12.4, bmm module, BMad Method track; documents in English, chat in Italian.
- Use across sessions: the repo is the source of truth; BMAD is installed with `tools/bmad/session.sh` (checks integrity and the fingerprint of the audited dependency tree). Protocol in [docs/bmad-sessions.md](bmad-sessions.md).
