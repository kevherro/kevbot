---
name: principle-make-operations-idempotent
description: Retries must land on the same end state. Used by kevbot when designing commands, startup, or processing loops.
user-invocable: false
---

# Make operations idempotent

A crash, restart, or double-run must converge to the same result.
If the next run's outcome depends on leftover partial state, add
a reconciliation step.

Ask: what if this runs twice? What if it died at each step? If
the answer is "it depends what was left behind," the operation
is not done.
