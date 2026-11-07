---
name: principle-migrate-callers-then-delete-legacy-apis
description: Migrate callers and delete the old API in one wave. Used by kevbot when replacing an internal interface.
user-invocable: false
---

# Migrate callers, then delete

When a new internal API is the design, move every in-tree caller
and delete the old one in the same wave. Dual paths are not a
compatibility strategy for code you own.

Time-box an adapter only when an external user still needs the
old surface. Update tests to the new contract. Delete tests that
only protected the previous shape.
