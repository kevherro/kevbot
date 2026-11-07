#!/usr/bin/env bash
# Link kevbot skills into the Agent Skills locations Amp, Grok, and
# Claude Code scan. Does not edit config.toml, settings.json, AGENTS.md,
# or CLAUDE.md.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
AGENTS_SKILLS="${KEVBOT_AGENTS_SKILLS:-$HOME/.agents/skills}"
GROK_HOME="${GROK_HOME:-$HOME/.grok}"
GROK_SKILLS="$GROK_HOME/skills"
GROK_AGENTS="$GROK_HOME/agents"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CLAUDE_SKILLS="$CLAUDE_HOME/skills"
CLAUDE_AGENTS="$CLAUDE_HOME/agents"

mkdir -p "$AGENTS_SKILLS" "$GROK_SKILLS" "$GROK_AGENTS" \
  "$CLAUDE_SKILLS" "$CLAUDE_AGENTS"

link_dir() {
  local src="$1"
  local dest="$2"
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    printf 'skipped %s (exists and is not a symlink)\n' "$dest" >&2
    return
  fi
  ln -sfn "$src" "$dest"
  printf 'linked %s -> %s\n' "$dest" "$src"
}

for d in "$ROOT"/skills/*/; do
  name="$(basename "$d")"
  link_dir "$d" "$AGENTS_SKILLS/$name"
  link_dir "$d" "$GROK_SKILLS/$name"
  link_dir "$d" "$CLAUDE_SKILLS/$name"
done

if [[ -d "$ROOT/agents" ]]; then
  for a in "$ROOT"/agents/*.md; do
    [[ -e "$a" ]] || continue
    link_dir "$a" "$GROK_AGENTS/$(basename "$a")"
    link_dir "$a" "$CLAUDE_AGENTS/$(basename "$a")"
  done
  # Claude Code agent files pin Claude models; Grok cannot run them.
  for a in "$ROOT"/agents/claude/*.md; do
    [[ -e "$a" ]] || continue
    link_dir "$a" "$CLAUDE_AGENTS/$(basename "$a")"
  done
fi

printf '\nkevbot installed for this user.\n'
printf 'Amp:    %s\n' "$AGENTS_SKILLS"
printf 'Grok:   %s and %s\n' "$GROK_SKILLS" "$GROK_AGENTS"
printf 'Claude: %s and %s\n' "$CLAUDE_SKILLS" "$CLAUDE_AGENTS"
printf 'Next: open a session and run /setup-kevbot\n'
