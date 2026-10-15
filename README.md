# IR Remote Android

An open source universal IR remote for Android. It finds IR codes in open databases (Flipper-IRDB, irdb), sends them from the phone's built-in IR transmitter or from external ones (audio jack, USB dongles, network blasters), and keeps third-party dependencies close to zero, each of them vetted.

**Status:** planning (BMAD Solutioning phase). No application code yet.

## Goals

- Control a TV within 3 minutes of installing, without knowing anything about IR protocols.
- No analytics, advertising or crash reporting; no personal data leaves the phone.
- Runtime dependencies: only `kotlin-stdlib` (no AndroidX).
- Verified supply chain: Gradle dependency verification, pinned CI actions, SBOM, reproducible builds.
- Distribution on Google Play and F-Droid.

## Documents

- PRD: `_bmad-output/planning-artifacts/prd.md`
- Architecture: `_bmad-output/planning-artifacts/architecture.md`
- UI specification: `_bmad-output/planning-artifacts/ux-design-spec.md`
- UX research: `_bmad-output/planning-artifacts/ux-research.md`
- Project rules: `_bmad-output/project-context.md`
- Secrets policy: `docs/policy/secrets.md`

## Contributing

Run `bash tools/check-no-secrets.sh` before every commit. Everything in this repository is written in English.

## License

GPL-3.0-or-later. See `LICENSE`.
