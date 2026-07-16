#!/usr/bin/env bash
# Every gate must FIRE on red and stay CLEAN on green (Jordan's L9).
# Red fixtures that carry secret/credential PATTERNS are synthesized at runtime so
# no token/credential literal is ever committed to this PUBLIC repo (and so the
# gates don't flag their own test data). Green fixtures are safe to commit.
set -uo pipefail
cd "$(dirname "$0")"
G=./gate.sh
pass=0; fail=0
chk(){ if eval "$2"; then echo "✓ $1"; pass=$((pass+1)); else echo "✗ $1"; fail=$((fail+1)); fi; }

# Guard: a deleted green fixture would make the green cases pass VACUOUSLY (gate.sh
# returns 0 on a missing file). Fail loudly instead of reporting a false clean.
chk "fixtures: committed green fixtures present" "[ -f fixtures/green/gitconfig ] && [ -f fixtures/green/clean.diff ]"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# --- D2 gitconfig sanity (file mode + diff mode). Diff mode regressed once: the
# anchored regex must still fire with the leading '+' on added lines. ---
printf '[credential]\n\thelper = store\n' > "$TMP/gitconfig-store"
# build the '@' from a separate arg so the credential-URL literal never appears in
# committed source (else the path-agnostic diff gate would flag this test file).
printf '[url "https://%s:%s%s%s/"]\n\tinsteadOf = gh:\n' 'kylie' 'supersecretpw' '@' 'github.com' > "$TMP/gitconfig-urlcreds"
{ echo 'diff --git a/home/.gitconfig b/home/.gitconfig'; echo '--- a/home/.gitconfig'; \
  echo '+++ b/home/.gitconfig'; echo '@@ -0,0 +1,2 @@'; echo '+[credential]'; \
  echo '+	helper = store'; } > "$TMP/gitconfig-store.diff"
chk "D2 red: helper=store (file) fires" "$G --gitconfig \"$TMP/gitconfig-store\" >/dev/null 2>&1; [ \$? -eq 1 ]"
chk "D2 red: url creds (file) fire"     "$G --gitconfig \"$TMP/gitconfig-urlcreds\" >/dev/null 2>&1; [ \$? -eq 1 ]"
chk "D2 red: helper=store (diff) fires" "$G --diff \"$TMP/gitconfig-store.diff\" >/dev/null 2>&1; [ \$? -eq 1 ]"
{ echo 'diff --git a/home/.gitconfig b/home/.gitconfig'; echo '--- a/home/.gitconfig'; \
  echo '+++ b/home/.gitconfig'; echo '@@ -0,0 +1 @@'; \
  printf '+[url "https://%s:%s%s%s/"]\n' 'kylie' 'supersecretpw' '@' 'github.com'; } > "$TMP/gitconfig-urlcreds.diff"
chk "D2 red: url creds (diff) fires"    "$G --diff \"$TMP/gitconfig-urlcreds.diff\" >/dev/null 2>&1; [ \$? -eq 1 ]"
chk "D2 green: osxkeychain passes"      "$G --gitconfig fixtures/green/gitconfig >/dev/null 2>&1"

# --- D3 private-artifact path (reuse committed green clean.diff for the negative) ---
chk "D3 green: normal diff passes"     "$G --diff fixtures/green/clean.diff >/dev/null 2>&1"

# --- D1 secrets (synthesized) ---
TOK="ghp_$(printf 'A%.0s' {1..36})"        # fake-but-pattern-valid GitHub PAT
{ echo 'diff --git a/x b/x'; echo '--- a/x'; echo '+++ b/x'; echo '@@ -0,0 +1 @@'; echo "+export TOKEN=$TOK"; } > "$TMP/secret.diff"
{ echo 'diff --git a/.localrc b/.localrc'; echo 'new file mode 100644'; echo '--- /dev/null'; echo '+++ b/.localrc'; echo '@@ -0,0 +1 @@'; echo '+x=1'; } > "$TMP/localrc.diff"
printf 'export TOKEN=%s\n' "$TOK" > "$TMP/leak.zsh"
printf 'export TOKEN="$SOME_ENV"\n' > "$TMP/clean.zsh"
chk "D1 red: secret in diff fires"     "$G --diff \"$TMP/secret.diff\" >/dev/null 2>&1; [ \$? -eq 1 ]"
chk "D1 red: secret in file fires"     "$G \"$TMP/leak.zsh\" >/dev/null 2>&1; [ \$? -eq 1 ]"
chk "D1 green: env-ref file passes"    "$G \"$TMP/clean.zsh\" >/dev/null 2>&1"
chk "D3 red: .localrc staged fires"    "$G --diff \"$TMP/localrc.diff\" >/dev/null 2>&1; [ \$? -eq 1 ]"

echo "---"; echo "pass=$pass fail=$fail"; [ "$fail" -eq 0 ]
