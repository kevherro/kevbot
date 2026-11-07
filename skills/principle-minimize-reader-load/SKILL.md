---
name: principle-minimize-reader-load
description: Cut layers and hidden state a reader must hold. Used by kevbot when code is hard to trace.
user-invocable: false
---

# Minimize reader load

A reader should answer "where does X come from?" and "what can
change X?" quickly. Count indirections to the answer, and mutable
context they must keep in their head. Cut whichever is high.

Inline one-caller wrappers and pass-through layers. Prefer returns
over mutation, locals over fields, derived values over synced
copies. A new layer has to reduce load somewhere else by at least
as much as it adds.
