---
name: how
description: >
  Walk through how a subsystem works now, with runtime flow, types, and
  the non-obvious parts. Use for /how, "how does this work", or when
  kevbot needs to understand a path before editing.
argument-hint: subsystem or question
---

# How

Read-only understanding. No edits.

## Steps

1. Restate the question and the subsystem boundary.
2. If the area is large (several packages or an unclear entrypoint),
   spawn two to four read-only explorers from the parent, per
   the discovered **kevbot** skill's `references/harness.md`.
   Partition by entrypoint or package. Each explorer returns paths,
   types, and a flow in a few paragraphs. The parent reads the code
   they cite.
3. If the area is small, read it yourself. Do not spawn.
4. Answer with:
   - the runtime flow (who calls whom)
   - the data shape that actually moves
   - the surprising part (hidden state, retries, caches, implicit
     ordering)
   - open questions
5. Stay read-only. If the user also asked for a change, return to
   kevbot and pick `fix`, `build`, or `reshape`.
