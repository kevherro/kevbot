#!/usr/bin/env bash
# Exercise the pack with versioned directories and non-executable assets.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/kevbot-hosted.XXXXXX")"
trap 'rm -r "$fixture"' EXIT
errors=0

fail() {
  printf 'error: %s\n' "$1" >&2
  errors=$((errors + 1))
}

mkdir -p "$fixture/skills" "$fixture/worktree"
for skill_dir in "$ROOT"/skills/*/; do
  name="$(basename "$skill_dir")"
  cp -R "$skill_dir" "$fixture/skills/$name@fixture"
done
find "$fixture/skills" -type f -exec chmod 644 {} +

mkdir -p "$fixture/skills/help@stale" "$fixture/skills/unrelated@fixture"
printf '%s\n' --- 'name: help' 'description: Old help description.' --- \
  >"$fixture/skills/help@stale/SKILL.md"
printf '%s\n' --- 'name: unrelated' 'description: An unrelated skill.' --- \
  >"$fixture/skills/unrelated@fixture/SKILL.md"

while IFS= read -r file; do
  while IFS= read -r target; do
    case "$target" in
      *://* | mailto:* | \#* | *'<'*) continue ;;
    esac
    target="${target%%#*}"
    if [[ ! -f "$(dirname "$file")/$target" ]]; then
      fail "${file#"$fixture/"}: unresolved resource $target"
    fi
  done < <(grep -oE '\]\([^)]*\)' "$file" | sed 's/^](//; s/)$//' || true)
done < <(find "$fixture/skills" -name '*.md' -type f)

help_dir="$fixture/skills/help@fixture"
log_dir="$fixture/skills/show-me-your-work@fixture"
if ! grep -Fq '[references/catalog.md](references/catalog.md)' "$help_dir/SKILL.md"; then
  fail 'help: instructions must read the bundled catalog'
fi
if ! grep -Eq 'bash .*scripts/log\.sh' "$log_dir/SKILL.md"; then
  fail 'show-me-your-work: instructions must invoke the bundled script with bash'
fi

if ! bash "$ROOT/scripts/list-skills.sh" >"$fixture/expected.md"; then
  fail 'source help catalog failed'
fi
if ! cat "$help_dir/references/catalog.md" >"$fixture/actual.md"; then
  fail 'hosted help catalog failed'
elif ! diff -u "$fixture/expected.md" "$fixture/actual.md"; then
  fail 'hosted help catalog differs from source'
fi

if ! (cd "$fixture/worktree" && bash "$log_dir/scripts/log.sh" \
  .kevbot/decisions.tsv verify decision why evidence verified); then
  fail 'hosted decision log failed'
elif ! awk -F '\t' 'NF != 6 { exit 1 } END { if (NR != 2) exit 1 }' \
  "$fixture/worktree/.kevbot/decisions.tsv"; then
  fail 'hosted decision log did not write a header and six-column record'
fi

if [[ "$errors" -gt 0 ]]; then
  printf '%s hosted check(s) failed\n' "$errors" >&2
  exit 1
fi

printf 'hosted skills ok\n'
