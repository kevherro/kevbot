---
name: principle-build-the-lever
description: Build a rerunnable tool for non-trivial work. Used by kevbot when hand-applying a recipe would be the artifact.
user-invocable: false
---

# Build the lever

If the work is not a couple of obvious edits, the deliverable is a
script, codemod, generator, or skill a reviewer can rerun.

Do the first unit by hand to learn the recipe. Then encode it.
Prove the lever by rerunning it on that unit. Prefer one
deterministic pass over fanning the same edit to children.

Citing this principle with no tool in the diff is a miss.
