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
4. Show the three lists. Wait. Skill edits change every later
   session; do not auto-apply.
5. For each approved Accepted item, follow its routing:
   - Trivial edit to an existing skill: parent, in that skill's home.
   - Substantive edit or new skill: still the parent, in the pack or
     the current repo's skill dir. Do not invent a second generator.
   Run `./scripts/check-skills.sh` when the edit is in this pack.

**Reply:** applied edits, new skills, backlog, dropped findings with
the synthesizer's reason.
