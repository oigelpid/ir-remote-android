# BMAD status — IR Remote Android

Updated: 2026-10-17

## Rule zero
No keys, keystores, tokens, passwords, credentials or sensitive data (real names included) in the repository, artifacts, commits, issues or logs. Run `bash tools/check-no-secrets.sh .` before every commit. Policy: `docs/policy/secrets.md`.

## Rule one
Every document, all code, comments, commit messages, issues and PR text are in English, regardless of the chat language. BMAD: documents in English, chat in Italian.

## Identity
The user is referred to everywhere only by their GitHub username (the login in `github.com/<login>`, never the display name): `oigelpid`. Commit identity: name `oigelpid`, email the account's GitHub noreply address.

## Pending work for the user
1. On github.com, Settings > Code security: enable Secret scanning and Push protection.
2. On github.com, Settings > Branches: protect `main` (require a pull request, block force pushes and deletions). Add required CI checks once CI exists.
3. Review and merge the open pull requests (see "Open branches").
4. Epic 4 Story 4.1 (catalog setup) and Epic 5 Story 5.5 (release signing) are maintainer-only actions; no key ever passes through the sandbox.

From now on: work only on `claude/...` branches with pull requests; merges, tags and signing are done by the user. Pushing needs the Claude GitHub App installed with access to the repo.

## Current phase
3 · Solutioning (BMad Method track)

## Artifacts
| File | Status |
| --- | --- |
| _bmad-output/planning-artifacts/prd.md | approved |
| _bmad-output/planning-artifacts/architecture.md | approved |
| _bmad-output/planning-artifacts/ux-design-spec.md | approved |
| _bmad-output/planning-artifacts/ux-research.md | approved |
| _bmad-output/project-context.md | approved (rule zero, rule one) |
| _bmad-output/planning-artifacts/epics.md | draft (8 epics, 52 stories); the 7 coverage gaps are closed on branch `claude/apply-party-decisions-to-epics`; step 4 re-validation pending |
| _bmad-output/party-mode/decisions-epics-gaps.md | decision log of the agent-team party (7 points, 5/5 consensus each) |
| sprint-status.yaml | to create |

## Next BMAD workflow
Finish `bmad-create-epics-and-stories` (step 4, final validation), then readiness check → `bmad-sprint-planning` → for each story, in separate chats: create-story → dev-story → code-review.

## In progress
`bmad-create-epics-and-stories`: the 7 requirement-coverage gaps found by the step 4 validation were resolved by an agent-team party (Winston, Sally, John, Amelia, Vex; qualified majority 4 of 5; every point closed 5/5, no dissent) and applied to `epics.md` (see `_bmad-output/party-mode/decisions-epics-gaps.md`). Remaining: re-run the step 4 validation on the updated file, then the readiness check and `bmad-sprint-planning`. Open notes from the party:
1. Winston's haptics clause (`VIRTUAL_KEY` once per press, not on each repeat) was applied; confirm it.
2. `allowBackup` is not mentioned in `architecture.md`; decide whether to add it.
3. New story 3.9 "Code details" can be deferred if the budget tightens.

## Open branches
- `claude/apply-party-decisions-to-epics`: epics.md updated with the party decisions, decision log, STATUS update. Not pushed.

## Decisions taken in this workflow
- Epic structure approved: 8 epics (engine, first transmission, library, catalog, release, external transmitters, AC/widget/second source, power-user tools).
- Story structure decided by the BMAD party mode table by qualified majority (4 of 5). Deadlock on Epic 7 widget and quick settings tile (3 to 2): kept as two stories.
- Weekly automatic catalog update moved from Epic 4 to Epic 7 (Story 7.6).
- Epics gaps resolved by the agent-team party (2026-10-17): one new story (3.9 Code details); theme, insets, predictive back and icons in Story 2.1; permissions declared by the first story that uses them with a CI manifest allowlist (Story 1.2); network rules in Story 4.3; left-handed layout kept in v1 (Story 3.8).
- Story 2.4 (bench test) is non-blocking for Epic 2 but mandatory before the first alpha.

## Log
| Date | Activity | Result |
| --- | --- | --- |
| 2026-10-15 | BMAD 6.12.4 installed + documents imported | done |
| 2026-10-15 | Rule zero on secrets and sensitive data + automated check | done |
| 2026-10-16 | Identity = GitHub login; rule one English only | done |
| 2026-10-16 | GitHub migration: repo created, skeleton pushed to `main` | done; repo security settings left to the user |
| 2026-10-17 | `bmad-create-epics-and-stories` steps 1 to 3 | done on branch; step 4 pending |
| 2026-10-17 | Project documentation moved into the repo (`docs/`) | merged (PR 1); Project documents deleted |
| 2026-10-17 | `bmad-create-epics-and-stories` step 4 validation | draft saved, 7 checks open |
| 2026-10-17 | Party (agent team) on the 7 epics.md gaps | done, 5/5 consensus each; applied to epics.md on branch |
