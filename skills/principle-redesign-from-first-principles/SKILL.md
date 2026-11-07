---
name: principle-redesign-from-first-principles
description: Integrate a requirement as if it had been there on day one. Used by kevbot when bolting on would warp the design.
user-invocable: false
---

# Redesign from first principles

Do not hang a new requirement off the side of the current shape.
Ask what you would build if this had always been true. Then move
the existing code toward that.

Read the affected files as one design. Propagate types, tests,
and docs. Think the redesign whole; land it in verifiable units.
