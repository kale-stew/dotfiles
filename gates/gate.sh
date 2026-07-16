#!/usr/bin/env bash
#
# dotfiles Class-A deterministic gates. $0, no model.
# Technique: github.com/acoyfellow/corrections-to-gates
#
# This repo is PUBLIC (github.com/kale-stew/dotfiles) and stows files into $HOME,
# so a leaked token is a real incident. Secrets live ONLY in ~/.localrc.
#
#   D1  no real secrets in staged/stowed content   (tokens belong in ~/.localrc)
#   D2  gitconfig sanity: no plaintext `helper = store`, no creds embedded in URLs
#   D3  never stage private artifacts (.localrc, mined corpus, tool-output)
#
# Usage:
#   gate.sh [--diff <file>] [--gitconfig <file>] [<file-or-dir> ...]
#   gate.sh --staged                # scan `git diff --cached` + staged gitconfigs
# Exit 1 on any violation (with evidence), 0 clean.
set -uo pipefail

DIFF=""; GITCONFIG=""; STAGED=0; declare -a PATHS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --diff)      DIFF="$2"; shift 2;;
    --gitconfig) GITCONFIG="$2"; shift 2;;
    --staged)    STAGED=1; shift;;
    -h|--help)   sed -n '2,18p' "$0"; exit 0;;
    *) PATHS+=("$1"); shift;;
  esac
done

fail=0
flag(){ echo "✗ $1"; echo "    evidence: $2"; fail=1; }

SECRET_PATTERNS=(
  'cfat_[A-Za-z0-9]{30,}'          # Cloudflare API tokens
  'ntn_[A-Za-z0-9]{40,}'           # Notion API keys
  'GOCSPX-[A-Za-z0-9]{20,}'        # Google OAuth secrets
  'sk-or-[A-Za-z0-9-]{40,}'        # OpenRouter keys
  'sk-[A-Za-z0-9]{40,}'            # OpenAI keys
  'ghp_[A-Za-z0-9]{36}'            # GitHub PATs
  'gho_[A-Za-z0-9]{36}'            # GitHub OAuth tokens
  'github_pat_[A-Za-z0-9_]{22,}'   # GitHub fine-grained PATs
  'glpat-[A-Za-z0-9_-]{20,}'       # GitLab personal access tokens
  'xox[baprs]-[A-Za-z0-9-]{20,}'   # Slack tokens
  'AIza[A-Za-z0-9_-]{35}'          # Google API keys
  'ya29\.[A-Za-z0-9_-]{50,}'       # Google OAuth access tokens
  'AKIA[A-Z0-9]{16}'               # AWS access key IDs
  '_authToken=[A-Za-z0-9_-]{20,}'  # npmrc auth tokens
)
SECRET_RE=$(IFS='|'; echo "${SECRET_PATTERNS[*]}")
FORBIDDEN_PATH_RE='(^|/)(\.mined/|corrections\.jsonl|tool-output/|\.localrc|opencode\.db($|-))'

# D2: plaintext credential store, or user:pass@ embedded in a URL.
GITCONFIG_STORE_RE='^[[:space:]]*helper[[:space:]]*=[[:space:]]*store([[:space:]]|$)'
GITCONFIG_URLCRED_RE='https?://[^/[:space:]:@]+:[^/[:space:]@]+@'

gate_secrets_files(){
  local f
  for f in "$@"; do
    [ -f "$f" ] || continue
    grep -nEo "$SECRET_RE" "$f" 2>/dev/null \
      | while read -r m; do flag "D1 real secret in file (tokens belong in ~/.localrc)" "$f:$m"; done
    grep -qE "$SECRET_RE" "$f" 2>/dev/null && fail=1
  done
}

# $1 = file to read, $2 = display name for evidence (defaults to $1).
gate_gitconfig(){
  local f="$1"; local disp="${2:-$1}"; [ -f "$f" ] || return 0
  grep -nE "$GITCONFIG_STORE_RE" "$f" \
    | while read -r m; do flag "D2 gitconfig uses plaintext credential 'helper = store'" "$disp:$m"; done
  grep -qE "$GITCONFIG_STORE_RE" "$f" && fail=1
  grep -nE "$GITCONFIG_URLCRED_RE" "$f" \
    | while read -r m; do flag "D2 credentials embedded in a git URL (user:pass@)" "$disp:$m"; done
  grep -qE "$GITCONFIG_URLCRED_RE" "$f" && fail=1
}

gate_diff(){
  local d="$1"; [ -f "$d" ] || return 0
  # Added content with the leading '+' stripped, so anchored regexes (^helper…)
  # match. Without the strip, D2's `^[[:space:]]*helper` never fires on a diff.
  local added; added="$(grep -E '^\+' "$d" | grep -vE '^\+\+\+' | sed 's/^+//')"
  printf '%s\n' "$added" | grep -nE "$SECRET_RE" \
    | while read -r m; do flag "D1 real secret in diff (tokens belong in ~/.localrc)" "$m"; done
  printf '%s\n' "$added" | grep -qE "$SECRET_RE" && fail=1
  printf '%s\n' "$added" | grep -nE "$GITCONFIG_STORE_RE|$GITCONFIG_URLCRED_RE" \
    | while read -r m; do flag "D2 gitconfig anti-pattern in diff (helper=store or url creds)" "$m"; done
  printf '%s\n' "$added" | grep -qE "$GITCONFIG_STORE_RE|$GITCONFIG_URLCRED_RE" && fail=1
  grep -E '^\+\+\+ b/' "$d" | sed 's#^+++ b/##' | grep -nE "$FORBIDDEN_PATH_RE" \
    | while read -r m; do flag "D3 private artifact staged (never commit .localrc/corpus/tool-output)" "$m"; done
  grep -E '^\+\+\+ b/' "$d" | sed 's#^+++ b/##' | grep -qE "$FORBIDDEN_PATH_RE" && fail=1
}

if [ "$STAGED" -eq 1 ]; then
  tmpd="$(mktemp)"; git diff --cached --diff-filter=ACMR -U0 > "$tmpd" 2>/dev/null || true
  gate_diff "$tmpd"; rm -f "$tmpd"
  # gitconfig sanity on the STAGED blob (not the working tree).
  while IFS= read -r f; do
    case "$(basename "$f")" in
      .gitconfig|gitconfig*|*.gitconfig|config)
        tmpf="$(mktemp)"; git show ":$f" > "$tmpf" 2>/dev/null && gate_gitconfig "$tmpf" "$f"; rm -f "$tmpf";;
    esac
  done < <(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null)
fi

[ -n "$DIFF" ]      && gate_diff "$DIFF"
[ -n "$GITCONFIG" ] && gate_gitconfig "$GITCONFIG"
if [ "${#PATHS[@]}" -gt 0 ]; then
  declare -a files=()
  for p in "${PATHS[@]}"; do
    if [ -d "$p" ]; then
      while IFS= read -r f; do
        echo "$f" | grep -qE "$FORBIDDEN_PATH_RE" && continue
        files+=("$f")
      done < <(find "$p" -type f 2>/dev/null)
    elif [ -f "$p" ]; then
      echo "$p" | grep -qE "$FORBIDDEN_PATH_RE" && continue
      files+=("$p")
    fi
  done
  if [ "${#files[@]}" -gt 0 ]; then
    gate_secrets_files "${files[@]}"
    for f in "${files[@]}"; do
      case "$(basename "$f")" in .gitconfig|gitconfig*|*.gitconfig|config) gate_gitconfig "$f";; esac
    done
  fi
fi

[ "$fail" -eq 0 ] && echo "✓ all dotfiles Class-A gates passed"
exit "$fail"
