---
name: principle-smallest-change
description: Bias toward deletion and the smallest diff that solves the problem. Used by kevbot when sizing a change.
user-invocable: false
---

# Smallest change

Prefer the patch a reviewer can hold in their head.

Delete dead code, unused flags, and one-caller wrappers before adding
anything. If two designs both work, take the one with fewer new names
and fewer new files.

Do not add an abstraction for a single call site. Do not "clean up"
neighbors in the same diff as a behavior change unless they block it.

The test: if you removed the new helper, would the remaining patch
still be obvious? If yes, remove the helper.
