# Iron rule: no secrets, no sensitive data

Applies to the repository, claude.ai Project documents, artifacts, commits, issues and pull requests, and CI logs. No exceptions, no "just temporarily".

## What never goes in
- Keys and keystores: APK/AAB signing keys (`*.jks`, `*.keystore`, `*.p12`, `*.pem`, `*.key`), the catalog's ECDSA private key, GPG/SSH keys.
- Credentials: GitHub/Google Play/API tokens, passwords, `service-account*.json`, `google-services.json`, `.env` files, `local.properties`, `keystore.properties`, cookies, authentication headers.
- Personal data: emails, phone numbers, addresses, real names of third parties, home network IPs or MACs, Wi-Fi SSIDs and passwords, Broadlink blaster keys, non-anonymized screenshots.
- Real test data: only fake values, documented as such (e.g. `192.0.2.10`, RFC 5737).

## Where they go instead
- CI secrets: GitHub Actions Secrets or runner environment variables, never printed in logs.
- Release signing and the catalog key: only on the user's machine or in hardware storage; never in Claude's sandbox, never passed to subagents.
- Local configuration: git-ignored files (`.gitignore`) with a value-free `*.example` template.

## Identity in commits
Commit author: GitHub username and GitHub `noreply` email (`<id>+<login>@users.noreply.github.com`), never personal emails.

## Checks
1. `bash tools/check-no-secrets.sh` before every commit and before every save to the Project (no dependencies: grep only).
2. On GitHub: secret scanning and push protection enabled.
3. The `code-reviewer` blocks any diff that violates this rule.

## If it happens
A secret that ended up in a commit, even if deleted right away, must be considered compromised: revoke and rotate it first, then clean up the history. Rewriting history alone is not enough.
