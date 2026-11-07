---
name: recall
description: >
  Rebuild recent working context from this harness's sessions and live
  git/gh state. Use for /recall, "catch me up", or "where did I leave
  off".
argument-hint: topic or "recent work"
---

# Recall

Before starting or resuming, rebuild where the work stands. Hand back
a short brief. Do not start the work in this skill.

Resolve session access and missing-history fallbacks through
the discovered **kevbot** skill's `references/harness.md`.

## Steps

1. Route. One named prior chat to continue is resume, not this. A
   full state capsule already in the prompt: use it and skip mining.
2. Lock scope. Window (default last 7 days), topic if named, this
   workspace. Say the scope. Do not quietly shrink "all".
3. Mine this harness's sessions in that window. One or two hits:
   read them yourself. More: parent spawns read-only slices, per
   the discovered **kevbot** skill's `references/harness.md`.
   Order by real modification time, not id. Skip the current session
   and obvious noise. Each slice returns: topic, goal, decisions,
   open threads, corrections, artifacts, with a session id.
4. Verify live. `git` and `gh` on the branches, PRs, and tickets the
   mining named. History is not current truth.
5. Write the brief. Stay on the named topic.

## Brief

- **Capsule.** At most 5 bullets. What this is and where it stands.
- **Threads.** One line each, with exactly one tag: `[merged #N]`,
  `[open PR #N]`, `[in flight <branch>]`, `[verified, uncommitted]`,
  `[reverted #N]`, `[planned, not started]`.
- **Problems.** At most 5. Recurring symptoms and reverted fixes.
- **Next.** One concrete action.

**Reply:** the brief.
