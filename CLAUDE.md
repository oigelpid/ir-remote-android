# IR Remote Android

Open source IR remote for Android, near-zero dependencies, verified supply chain.

## Method: BMAD v6.12.4 (BMad Method track)

- Configuration: `_bmad/bmm/config.yaml` (user = the maintainer's GitHub username; communication language Italian (chat only), document output language English).
- Artifacts: `_bmad-output/planning-artifacts/` (prd, architecture, ux-design-spec, ux-research), `_bmad-output/project-context.md` (mandatory rules for every story).
- BMAD skills in `.claude/skills/bmad-*`. When in doubt: `bmad-help` skill.
- Current phase: 3 Solutioning, next steps `bmad-create-epics-and-stories` → readiness check → `bmad-sprint-planning`.
- One BMAD workflow per new chat, as the method recommends.

## BMAD roles and subagents

BMAD roles drive the process; the subagents in `.claude/agents/` do the work inside a story.

| BMAD role / workflow | Subagent to use |
| --- | --- |
| Analyst, research | `general-purpose` in fan-out |
| Architect, readiness check | `Plan` (opus) + `code-reviewer` as adversary |
| Developer, dev-story on ir-core/ir-formats | `ir-core-engineer` |
| Developer, dev-story on tx-* | `transmitter-engineer` |
| Developer, dev-story on app | `android-ui-engineer` |
| Developer, story touching dependencies or CI | `supply-chain-auditor` before implementing |
| Test and QA (`bmad-qa-generate-e2e-tests`) | `test-engineer` |
| Code review (`bmad-code-review`) | `code-reviewer` with clean context, a different model from the author |
| Release | `release-engineer` (prepares, does not sign or publish) |

Full rules on complexity scale, orchestration patterns and guardrails: `docs/agents-and-orchestration.md`. Session protocol: `docs/bmad-sessions.md`. Current status and pending work: `docs/STATUS.md`. Document index: `docs/project-index.md`.

## Quick rules
- **Rule zero: no secrets or sensitive data** in the repo, the Project, artifacts, commits, issues or logs (keys, keystores, tokens, passwords, `.env`, `local.properties`, `google-services.json`, emails, home network data). Mandatory check `bash tools/check-no-secrets.sh` before every commit and every save to the Project; commit author uses the GitHub noreply email. Policy: `docs/policy/secrets.md`. Overrides everything.
- **Rule one: English only.** All project documents, code, comments, commit messages, issues and PR text are written in English. App user-facing strings: English in `values/strings.xml` (default), Italian translation in `values-it/strings.xml`. Conversation with the maintainer may be in Italian. This rule overrides any other language setting.
- Read `_bmad-output/project-context.md` before every story.
- Never add new dependencies without an audit; never push, tag, sign or upload without confirmation.
- Development tools (including BMAD) follow the same policy: pinned version and audit.
