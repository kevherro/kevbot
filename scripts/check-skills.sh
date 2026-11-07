#!/usr/bin/env bash
# Check skill directory names, frontmatter names, and required files.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
errors=0

fail() {
  printf 'error: %s\n' "$1" >&2
  errors=$((errors + 1))
}

name_ok() {
  local n="$1"
  [[ "$n" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] && [[ ${#n} -ge 2 && ${#n} -le 64 ]]
}

shopt -s nullglob
for skill_dir in "$ROOT"/skills/*/; do
  name="$(basename "$skill_dir")"
  skill_md="$skill_dir/SKILL.md"

  if [[ ! -f "$skill_md" ]]; then
    fail "$name: missing SKILL.md"
    continue
  fi

  if ! name_ok "$name"; then
    fail "$name: directory name is not a valid skill name"
  fi

  fm_name="$(awk '
    BEGIN { in_fm=0 }
    /^---[[:space:]]*$/ { if (in_fm) exit; in_fm=1; next }
    in_fm && $1=="name:" {
      sub(/^name:[[:space:]]*/, "")
      gsub(/[[:space:]]+$/, "")
      gsub(/^["'\'']|["'\'']$/, "")
      print
      exit
    }
  ' "$skill_md")"

  if [[ -z "$fm_name" ]]; then
    fail "$name: SKILL.md has no frontmatter name"
  elif [[ "$fm_name" != "$name" ]]; then
    fail "$name: frontmatter name '$fm_name' does not match directory"
  fi
done

if [[ ! -f "$ROOT/skills/kevbot/SKILL.md" ]]; then
  fail "missing entry skill skills/kevbot/SKILL.md"
fi

help_list="$ROOT/scripts/list-skills.sh"
if [[ ! -f "$help_list" ]]; then
  fail "missing scripts/list-skills.sh"
elif ! listing="$(bash "$help_list")"; then
  fail "scripts/list-skills.sh failed"
else
  catalog="$ROOT/skills/help/references/catalog.md"
  if [[ ! -f "$catalog" ]] || ! diff -u <(printf '%s\n' "$listing") "$catalog"; then
    fail "help catalog stale: bash scripts/list-skills.sh > skills/help/references/catalog.md"
  fi
  for skill_dir in "$ROOT"/skills/*/; do
    name="$(basename "$skill_dir")"
    if ! printf '%s\n' "$listing" | grep -F -q \
      -e "\`/${name}\`" -e "\`${name}\`"; then
      fail "help listing missing $name"
    fi
  done
fi

for pb in investigate fix build reshape leave-running; do
  if [[ ! -f "$ROOT/skills/kevbot/playbooks/$pb.md" ]]; then
    fail "missing playbook $pb.md"
  fi
done

for f in \
  skills/create-verification-skill/SKILL.md \
  skills/create-verification-skill/references/location.md \
  skills/create-verification-skill/references/generated-skill.md \
  skills/create-verification-skill/references/feature-map.md \
  skills/maintain-verification-skill/SKILL.md \
  skills/figure-it-out/SKILL.md \
  skills/show-me-your-work/SKILL.md \
  skills/show-me-your-work/scripts/log.sh \
  skills/interrogate/references/rubric.md \
  skills/interrogate/references/reviewer-brief.md \
  skills/unslop/references/tells.md
do
  if [[ ! -f "$ROOT/$f" ]]; then
    fail "missing $f"
  fi
done

while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  fail "cursor-only string in skill body: $line"
done < <(find "$ROOT/skills" -name '*.md' -exec \
  grep -n -E 'AskQuestion|\.mdc|pstack-models' {} + 2>/dev/null || true)

while IFS= read -r line; do
  [[ -n "$line" ]] || continue
  fail "harness primitive outside adapter references: $line"
done < <(find "$ROOT/skills" -name '*.md' \
  ! -path "$ROOT/skills/kevbot/references/*" -exec \
  grep -n -E 'spawn_subagent|get_command_or_subagent_output|run_terminal_command|scheduler_create|ask_user_question|`explore`|grok -p|Amp orb' {} + 2>/dev/null || true)

if ! bash "$ROOT/scripts/check-hosted-skills.sh"; then
  fail "hosted skill checks failed"
fi

if [[ "$errors" -gt 0 ]]; then
  printf '%s check(s) failed\n' "$errors" >&2
  exit 1
fi

printf 'ok\n'
