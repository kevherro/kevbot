---
name: principle-separate-before-serializing-shared-state
description: Give concurrent writers their own state before adding locks. Used by kevbot when two actors might mutate the same file, branch, or object.
user-invocable: false
---

# Separate before serializing

If two actors write the same mutable thing, first ask whether they
need one object. Usually they do not. Give each an owned file,
key, or worktree and merge at the read boundary.

Two workers editing fields in one `state.json` is still shared
mutation. Instructions to "take turns" are not control. A lock
is for the rare case where one writer is a real invariant.

For agent fan-out, `principle-parent-owns-fan-out` owns the spawn
rule.
