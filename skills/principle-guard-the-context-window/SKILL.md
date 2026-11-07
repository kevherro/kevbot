---
name: principle-guard-the-context-window
description: Keep bulk out of the parent context. Used by kevbot when outputs, files, or fan-out would flood the session.
user-invocable: false
---

# Guard the context window

Tokens spent in this session do not come back. The parent keeps
findings and pointers, not raw dumps.

Route large reads and verbose output to children. Give them unique
output paths. Read the files they cite, not their essays. Skip
files you will not use. Keep the recipe the children must follow
in one skill they load, not restated in every prompt.

Spawns stay parent-owned. See `principle-parent-owns-fan-out`.
