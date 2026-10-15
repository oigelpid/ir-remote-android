#!/usr/bin/env bash
# BMAD for the IR Remote Android project in a fresh sandbox.
#   bash bmad-session.sh setup    -> installs verified BMAD 6.12.4 in $ROOT
#   bash bmad-session.sh changed  -> modified state files to re-save to the Project
set -euo pipefail
ROOT="${BMAD_ROOT:-/home/claude/ir-remote-android}"
TOOL="$ROOT/tools/bmad"
STAMP="$ROOT/.bmad-session-stamp"
VER="6.12.4"
SRI="sha512-DBVws7H1NxpSOhv2DHvLEHTceQGCv9c+gBx/1cnVF38WhlN70854SnHUUCHkTuLIalu6hq/7LRVtAWCNHmnFEw=="
TREE="77e43b320d99e1eab50bfe2be032aa5a5e95d3580f1789bb8abcea62114fd439"
# Name shown by the BMAD agents: the GitHub username, never the real name
BMAD_USER="${BMAD_USER:-$(gh api user --jq .login 2>/dev/null || true)}"
[ -n "$BMAD_USER" ] || BMAD_USER="maintainer"

case "${1:-setup}" in
  setup)
    mkdir -p "$TOOL" && cd "$TOOL"
    [ -f package.json ] || printf '{ "private": true, "name": "ir-remote-bmad-tooling" }\n' > package.json
    npm install --ignore-scripts --save-exact --no-audit --no-fund --loglevel=error "bmad-method@$VER"
    GOT="$(node -p "require('./package-lock.json').packages['node_modules/bmad-method'].integrity")"
    [ "$GOT" = "$SRI" ] || { echo "ERROR: bmad-method integrity differs from the audited one" >&2; exit 1; }
    FP="$(npm ls --all --json 2>/dev/null | python3 -c "
import json,sys,hashlib
d=json.load(sys.stdin); s=set()
def w(n):
  for k,v in (n.get('dependencies') or {}).items():
    s.add(k+'@'+v.get('version','?')); w(v)
w(d); print(hashlib.sha256('\n'.join(sorted(s)).encode()).hexdigest())")"
    if [ "$FP" = "$TREE" ]; then
      echo "Dependency tree identical to the audited one"
    else
      echo "WARNING: transitive tree changed since the audit (fingerprint $FP)."
      echo "A new audit with supply-chain-auditor is needed before trusting the installation."
      npm audit --omit=dev 2>/dev/null | tail -4 || true
    fi
    cd "$ROOT"
    if [ ! -f _bmad/bmm/config.yaml ]; then
      "$TOOL/node_modules/.bin/bmad-method" install --directory "$ROOT" \
        --modules bmm --tools claude-code --user-name "$BMAD_USER" \
        --communication-language Italian --document-output-language English \
        --yes >/dev/null
    fi
    mkdir -p _bmad-output/planning-artifacts _bmad-output/implementation-artifacts
    touch "$STAMP"
    echo "BMAD $VER ready in $ROOT ($(ls -d .claude/skills/bmad-* | wc -l) skill)"
    ;;
  changed)
    cd "$ROOT"
    find _bmad-output -type f -newer "$STAMP" | sort
    ;;
  *) echo "usage: $0 setup|changed" >&2; exit 2;;
esac
