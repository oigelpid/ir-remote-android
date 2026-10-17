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
| _bmad-output/planning-artifacts/epics.md | draft (8 epics, 51 stories); step 4 validation run: 7 checks open (see "In progress"); PR open |
| sprint-status.yaml | to create |

## Next BMAD workflow
Finish `bmad-create-epics-and-stories` (step 4, final validation), then readiness check → `bmad-sprint-planning` → for each story, in separate chats: create-story → dev-story → code-review.

## In progress
`bmad-create-epics-and-stories`: step 4 validation done, `epics.md` saved as draft with 7 checks open. FR coverage 18/18, no placeholders, every story has Given/When/Then ACs, no blocking forward dependency (3.4 uses a placeholder until 3.5; 4.1 only announces 4.2/4.3). Open requirement-coverage gaps:
1. UX-DR3: Theme.DeviceDefault, edge-to-edge with WindowInsets, predictive back and own vector icons are in no story AC.
2. UX-DR12: `RemoteCardView` and `FabView` are not named in Story 3.4.
3. UX-DR14: left-handed mode is only audited (Story 5.1), implemented nowhere; `VIRTUAL_KEY` haptics and labels-to-icons above 130% are not explicit.
4. AR11: manifest permissions (`TRANSMIT_IR`, `INTERNET`, `uses-feature consumerir required=false`) are in no AC.
5. AR10: Story 4.3 (index download) lacks the network executor, 5 s timeout and `INTERNET` criteria.
6. UX-DR15: the "Code details" view (the only place for technical terms) is in no story.
7. UX-DR7: S3 "Import from file" and "Enter code manually" entries are only in the empty state of Story 4.4.

## Open branches
- `claude/create-epics-and-stories`: `epics.md` and the party mode memory log.

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
| 2026-10-17 | Project documentation moved into the repo (`docs/`) | merged (PR 1); Project documents deleted |
| 2026-10-17 | `bmad-create-epics-and-stories` step 4 validation | draft saved, 7 checks open |
