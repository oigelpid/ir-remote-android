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
4. After the documentation migration is merged: delete the old documents from the claude.ai Project (kept as a fallback until then), keep only a short bootstrap note, and point the Project instructions to it.
5. Epic 4 Story 4.1 (catalog setup) and Epic 5 Story 5.5 (release signing) are maintainer-only actions; no key ever passes through the sandbox.

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
| _bmad-output/planning-artifacts/epics.md | drafted on branch `claude/create-epics-and-stories` (8 epics, 51 stories); step 4 final validation pending; not yet merged |
| sprint-status.yaml | to create |

## Next BMAD workflow
Finish `bmad-create-epics-and-stories` (step 4, final validation), then readiness check → `bmad-sprint-planning` → for each story, in separate chats: create-story → dev-story → code-review.

## In progress
`bmad-create-epics-and-stories`: steps 1 to 3 done on branch `claude/create-epics-and-stories`; step 4 pending.

## Open branches
- `claude/create-epics-and-stories`: `epics.md` and the party mode memory log.
- `claude/move-project-docs`: moves the project documents from the claude.ai Project into `docs/`.

## Decisions taken in this workflow
- Epic structure approved: 8 epics (engine, first transmission, library, catalog, release, external transmitters, AC/widget/second source, power-user tools).
- Story structure decided by the BMAD party mode table by qualified majority (4 of 5). Deadlock on Epic 7 widget and quick settings tile (3 to 2): kept as two stories.
- Weekly automatic catalog update moved from Epic 4 to Epic 7 (Story 7.6).
- Story 2.4 (bench test) is non-blocking for Epic 2 but mandatory before the first alpha.

## Log
| Date | Activity | Result |
| --- | --- | --- |
| 2026-10-15 | BMAD 6.12.4 installed + documents imported | done |
| 2026-10-15 | Rule zero on secrets and sensitive data + automated check | done |
| 2026-10-16 | Identity = GitHub login; rule one English only | done |
| 2026-10-16 | GitHub migration: repo created, skeleton pushed to `main` | done; repo security settings left to the user |
| 2026-10-17 | `bmad-create-epics-and-stories` steps 1 to 3 | done on branch; step 4 pending |
| 2026-10-17 | Project documentation moved into the repo (`docs/`) | PR open |
