---
name: principle-named-shape
description: Name the data and its invariant before writing logic. Used by kevbot before implementation.
user-invocable: false
---

# Named shape

Before code, state:

1. The values that exist (and the ones that must not).
2. The invariant that must hold after every operation.
3. The structure that enforces it (type, struct, enum, table, state
   machine, queue). Not a pile of conditionals that hope to.

Illegal states should be unrepresentable when the language can do
that. Parse untrusted input at the boundary; trust the internal type.

If you cannot name the shape in a few sentences, you are not ready to
write the feature.
