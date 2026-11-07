---
name: principle-outcome-oriented-execution
description: Converge on the target design, not throwaway in-between states. Used by kevbot during planned rewrites and migrations.
user-invocable: false
---

# Outcome-oriented execution

Optimize for the intended end state. Smooth intermediate
compatibility that you plan to delete often stays.

Scoped, reversible breakage is allowed when the phase says so.
Prove the target at the phase boundary. Do not invent a second
architecture that exists only to keep CI green on a shape you
are leaving.
