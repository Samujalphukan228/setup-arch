#!/usr/bin/env bash
# setup-arch test suite — no root, no network, no pacman required.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

PASS=0
FAIL=0
FAILED=()

pass() { PASS=$((PASS + 1)); printf '  \033[1;32m✓\033[0m %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); FAILED+=("$1"); printf '  \033[1;31m✗\033[0m %s\n' "$1"; }

check() { # description command...
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then pass "$desc"; else fail "$desc"; fi
}

section() { printf '\n\033[1;37m%s\033[0m\n' "$1"; }

no_crlf() { ! grep -q $'\r' "$1"; }
no_duplicates() { ! sort "$1" | uniq -d | grep -q .; }
no_comments() { ! grep -qE '^[[:space:]]*#' "$1"; }

section "Shell syntax"
while IFS= read -r f; do
    check "bash -n $f" bash -n "$f"
done < <(find bin lib test dotfiles -type f \( -name '*.sh' -o -path 'bin/setup-arch' \) | sort)

section "ShellCheck"
if command -v shellcheck >/dev/null 2>&1; then
    while IFS= read -r f; do
        check "shellcheck $f" shellcheck "$f"
    done < <(find bin lib test dotfiles -type f \( -name '*.sh' -o -path 'bin/setup-arch' \) | sort)
else
    printf '  \033[1;33m!\033[0m shellcheck not installed — skipped\n'
fi

section "package.json"
check "valid JSON" node -e "JSON.parse(require('fs').readFileSync('package.json','utf8'))"
check "name is setup-arch" node -e "if(require('./package.json').name!=='setup-arch')process.exit(1)"
check "bin exists" test -x bin/setup-arch
check "bin is executable" test -x bin/setup-arch
check "license file exists" test -f LICENSE
check "README exists" test -f README.md
check "no trailing CRLF in package.json" no_crlf package.json

section "Package lists"
for list in packages/pacman.txt packages/aur.txt packages/services.txt; do
    check "$list exists" test -s "$list"
    check "$list has no duplicates" no_duplicates "$list"
    check "$list has no comments" no_comments "$list"
    check "$list has no CRLF" no_crlf "$list"
done
check "services.txt has docker.service" grep -qx "docker.service" packages/services.txt

section "Dotfiles"
for f in \
    dotfiles/hypr/hyprland.lua \
    dotfiles/hypr/hypridle.conf \
    dotfiles/hypr/hyprlock.conf \
    dotfiles/hypr/scripts/system-switcher.sh \
    dotfiles/waybar/config.jsonc \
    dotfiles/waybar/style.css \
    dotfiles/waybar/scripts/wifimenu.sh \
    dotfiles/waybar/scripts/powermenu.sh \
    dotfiles/wofi/config \
    dotfiles/wofi/style.css \
    dotfiles/kitty/kitty.conf \
    dotfiles/.bashrc \
    dotfiles/.bash_profile \
    dotfiles/.gitconfig
do
    check "$f" test -s "$f"
done
check "system-switcher is executable" test -x dotfiles/hypr/scripts/system-switcher.sh
check "wifimenu is executable" test -x dotfiles/waybar/scripts/wifimenu.sh
check "powermenu is executable" test -x dotfiles/waybar/scripts/powermenu.sh

section "No secrets committed"
if grep -rqE 'ghp_[A-Za-z0-9]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|BEGIN [A-Z ]*PRIVATE KEY' dotfiles bin lib packages 2>/dev/null; then
    fail "no secrets in dotfiles/scripts"
else
    pass "no secrets in dotfiles/scripts"
fi

section "CLI"
check "--help exits 0" bash -c "'$ROOT/bin/setup-arch' --help"
check "--help prints usage" bash -c "'$ROOT/bin/setup-arch' --help | grep -q 'Usage: setup-arch'"
check "--version prints version" bash -c "'$ROOT/bin/setup-arch' --version | grep -q 'setup-arch '"
check "unknown flag exits 2" bash -c "'$ROOT/bin/setup-arch' --bogus >/dev/null 2>&1; [ \$? -eq 2 ]"

section "Dry run"
tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT
check "dry-run succeeds" env HOME="$tmp_home" "$ROOT/bin/setup-arch" --dry-run --no-packages --no-services
check "dry-run writes nothing" bash -c "[ ! -e '$tmp_home/.config' ]"
check "dry-run reports completion" bash -c "env HOME='$tmp_home' '$ROOT/bin/setup-arch' --dry-run --no-packages --no-services --no-dotfiles | grep -q 'Dry run complete'"

section "npm package contents"
if command -v npm >/dev/null 2>&1; then
    files="$(npm pack --dry-run --ignore-scripts --json 2>/dev/null | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{const j=JSON.parse(d);const p=Array.isArray(j)?j[0]:Object.values(j)[0];console.log(p.files.map(f=>f.path).join('\n'))})")"
    for f in bin/setup-arch lib/install.sh packages/pacman.txt packages/aur.txt dotfiles/hypr/hyprland.lua LICENSE README.md; do
        check "tarball contains $f" grep -qx "$f" <<<"$files"
    done
else
    printf '  \033[1;33m!\033[0m npm not installed — skipped\n'
fi

section "Result"
printf '  %d passed, %d failed\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    printf '\n  Failed:\n'
    for t in "${FAILED[@]}"; do printf '    - %s\n' "$t"; done
    exit 1
fi
printf '  \033[1;32mAll tests passed.\033[0m\n'
