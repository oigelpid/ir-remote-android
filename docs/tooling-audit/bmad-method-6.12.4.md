# Development tool audit: bmad-method 6.12.4

Date: 2026-10-15 · Scope: development tool, does not end up in the APK.

| Criterion | Result |
| --- | --- |
| Version | 6.12.4 (latest), published 2026-10-14, pinned with `--save-exact` |
| License | MIT |
| Repository | github.com/bmad-code-org/BMAD-METHOD |
| npm maintainers | 3 (bmadcode, muratkeremozcan, alex_verk) |
| Provenance | SLSA v1 attestation present on the npm registry; registry signatures present |
| Local signature verification | `npm audit signatures` not completed: key download blocked by the sandbox proxy. To be repeated on the development machine |
| Install scripts | No `preinstall`/`install`/`postinstall`; only `prepare` (husky, dev). Installed with `--ignore-scripts` anyway |
| Direct dependencies | 13; full tree ~196 lines of `npm ls --all` |
| Vulnerabilities | 2 moderate: `csv-parse` < 7.0.2 (GHSA-8cw4-87c7-c6xx, prototype replacement). Used only by the installer on the package's own internal CSVs: low risk. Upstream fix to be monitored |
| Generated files | `_bmad/` (196 KB), `.claude/skills/bmad-*` (29 skills, 2.3 MB, 27 Python/JS scripts) |
| Scripts in skills | No network calls; `subprocess` used only for `git log` (retrospective) and local resolvers (party mode, forge idea) |

Recommendation: **accepted** as a development tool, under these conditions:
1. Run the installer/updater only with a pinned version and `--ignore-scripts`, preferably in a container.
2. Repeat `npm audit signatures` on an unfiltered network before first local use.
3. Every update goes through `supply-chain-auditor`, and the diff of `_bmad/` and `.claude/skills/` must be reviewed.
4. BMAD v7 is in preview: do not adopt it until it is stable.
