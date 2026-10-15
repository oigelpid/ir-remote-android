#!/usr/bin/env bash
# Secret and sensitive data check with no external dependencies (grep only).
# Usage: bash tools/check-no-secrets.sh [directory]   -> exit 1 if anything is found
set -uo pipefail
DIR="${1:-.}"
EXCL=(--exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.gradle --exclude-dir=build
      --exclude=check-no-secrets.sh --exclude=secrets.md --exclude=package-lock.json)
FOUND=0

# 1. Files that must not exist
BADFILES=$(find "$DIR" \( -name .git -o -name node_modules \) -prune -o -type f \( \
  -name '*.jks' -o -name '*.keystore' -o -name '*.p12' -o -name '*.pfx' -o -name '*.pem' -o -name '*.key' \
  -o -name '.env' -o -name '.env.*' -o -name 'local.properties' -o -name 'keystore.properties' \
  -o -name 'google-services.json' -o -name 'service-account*.json' -o -name 'id_rsa*' -o -name 'id_ed25519*' \
  \) -print | grep -v '\.example$' || true)
if [ -n "$BADFILES" ]; then echo "Forbidden files:"; echo "$BADFILES"; FOUND=1; fi

# 2. Suspicious content
check() {
  local label="$1" pattern="$2" out
  out=$(grep -rInE "${EXCL[@]}" "$pattern" "$DIR" 2>/dev/null || true)
  if [ -n "$out" ]; then echo "== $label"; echo "$out" | cut -c1-200; FOUND=1; fi
}
check "Private key"            '-----BEGIN ([A-Z]+ )?PRIVATE KEY-----'
check "GitHub token"           '(ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}'
check "Google API key"         'AIza[0-9A-Za-z_-]{35}'
check "AWS key"                'AKIA[0-9A-Z]{16}'
check "Slack token"            'xox[abprs]-[A-Za-z0-9-]{10,}'
check "Anthropic/OpenAI key" 'sk-(ant-)?[A-Za-z0-9_-]{20,}'
check "Plaintext password"     '(password|passwd|storePassword|keyPassword|secret|api[_-]?key|token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'$<{[:space:]]{8,}["'"'"']'
check "Email"                 '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'

# GitHub noreply emails and example addresses are allowed: review any other hits by hand.
if [ "$FOUND" -eq 0 ]; then echo "OK: no secrets or sensitive data found in $DIR"; fi
exit "$FOUND"
