---
name: reflect
description: >
  Mine this session for durable lessons and route them into skill
  edits. Use for /reflect.
disable-model-invocation: true
---

# Reflect

Turn this conversation into skill edits. One-offs are not lessons.
Skip if the session is trivial or already covered by a skill the
parent followed.

## Steps

1. Resolve transcript access through the discovered **kevbot**
   skill's `references/harness.md`. Match the opening user prompt.
   If no file resolves, write a short digest and use that. Do not
   read other workspaces.
2. Spawn two or three read-only children in one turn, per the
   **kevbot** skill's `references/harness.md`.
   Models from the `reviewers` list when present; otherwise inherit
   the parent. Dropouts stay named. Lenses:
   - **Judgment.** What should have been a rule, and where it lives.
   - **Tooling.** Missing checks, scripts, or harness gaps.
   - **Surprise.** Dead ends, user corrections, paths that generalized.
   Each returns findings with evidence (session moment or `path:line`).
   They must not write.
3. Parent synthesizes: **Accepted** / **Rejected** / **Backlog**.
   Spot-check citations. A lesson that a lint, test, or script would
   enforce better is Backlog, not a prose bullet
   (**encode-the-rule**).
4. Choose a durable destination for each Accepted item: a source
   checkout in scope, or a project/user skill directory that the
   current harness discovers. Resolve symlinks before choosing.
   Never edit a managed installed copy or plugin cache, including
   through a symlink. For a cached skill without a source checkout,
   plan to copy its whole folder so references and scripts survive.
   If the destination already exists, read it and reconcile the
   proposed edit there; do not overwrite it with the cached copy.
5. Show the three lists, each proposed edit, and its exact destination
   before approval. Wait. Skill edits change every later session;
   do not auto-apply. If no durable, discoverable destination is
   known, ask for that location before requesting approval.
6. Apply approved Accepted items in their approved destinations.
   Copy cached folders only after approval, then edit the copies.
   The parent makes both trivial and substantive edits. Do not
   invent a second generator. Run `./scripts/check-skills.sh` for
   changes in this pack. For a local override, confirm discovery
   selects it; if this requires a reload, report that pending step.

Do not infer publishing permission from a plugin's repository field.
Commits, pushes, and PRs follow the **kevbot** skill's action permissions.

**Reply:** applied edits and destination paths, new skills, discovery
status, backlog, dropped findings with the synthesizer's reason.
