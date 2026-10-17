# BMAD across sessions — protocol for Claude

Applies to every chat where the user asks for a BMAD workflow (epics, stories, sprint, dev-story, code review, retrospective, "bmad help", "what do I do next" on the project).

## Rule zero
No secrets or sensitive data in the repo, artifacts, commits, issues, pull requests or logs (policy: `docs/policy/secrets.md`). Before every commit: `bash tools/check-no-secrets.sh .`. If it finds anything, do not commit: tell the user.

## Rule one
Everything written to the repo is in English, whatever language the chat is in. BMAD document output language: English; communication language: Italian (chat only).

## Principle
The sandbox resets every chat; the GitHub repository does not.
- **Source of truth**: this repository (`https://github.com/oigelpid/ir-remote-android`). Planning artifacts live in `_bmad-output/`, project rules in `CLAUDE.md` and `_bmad-output/project-context.md`, current status and pending work in `docs/STATUS.md`.
- **The claude.ai Project holds only a short bootstrap note** (repo URL, how to clone, how to enable BMAD). No project state is kept there.
- **Tool**: BMAD 6.12.4 is installed by `tools/bmad/session.sh setup` (checks the package sha512 integrity and the fingerprint of the audited dependency tree). Generated `_bmad/` and `.claude/skills/bmad-*` are committed in the repo.
- The Claude Docs artifacts (PRD, Architecture, UI, UX) are presentation copies; when a planning document changes, update the file in the repo first and then, if needed, the artifact.

## Session start
1. Attach the repo with `add_repo` (`oigelpid/ir-remote-android`, `access: "push"`) and clone it ONCE to `/home/claude/ir-remote-android` (`git clone --depth 1`, generous timeout). Set the git identity: name `oigelpid`, email the account's GitHub noreply address.
2. Read `docs/STATUS.md`: current phase, pending work, next workflow, any session marked "in progress".
   - If another session is marked in progress, ask the user before proceeding.
3. Run `bash tools/bmad/session.sh setup`.
   - If it reports "transitive tree changed" or an integrity mismatch, stop: an audit (`supply-chain-auditor`) is needed before using BMAD.
   - The `bmad-*` skills become available in the Skill tool.
4. Create a branch `claude/<workflow-or-story>`.
5. Record the workflow and date under "In progress" in `docs/STATUS.md` as part of the branch.

## During
- One BMAD workflow per chat, as the method recommends.
- Launch the matching BMAD skill and follow it. For technical work inside a story, use subagents as described in `docs/agents-and-orchestration.md` and the table in `CLAUDE.md`.
- Chat with the user in Italian; every file in English.

## Session end
1. `bash tools/check-no-secrets.sh .` must print OK.
2. Update `docs/STATUS.md`: phase, next workflow, clear "In progress", add a log line.
3. Commit on the `claude/...` branch (English message, noreply identity, required trailers), push, open a pull request. Never push to `main`; merges, tags and signing are done by the user.
4. Tell the user in one line what was saved and the next workflow.

## Limits
- The sandbox cannot create repositories or change repository settings (branch protection, secret scanning): the user does those on github.com.
- Pushing needs the Claude GitHub App installed on the account with access to the repository.
- The local tracking reference of a pushed branch can be lost when the sandbox is restored; `git ls-remote --heads origin <branch>` shows the real remote state.
