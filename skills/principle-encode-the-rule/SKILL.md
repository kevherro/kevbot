---
name: principle-encode-the-rule
description: Encode a repeated instruction as a check, not more prose. Used by kevbot when a lesson would otherwise stay in chat.
user-invocable: false
---

# Encode the rule

The second time you write the same instruction, stop. Put it in a
lint, a test, a type, a schema, a script, or a skill the next agent
will actually load.

Comments that narrate what the next line does are not encoding. The
assertion, the type, or the command is the encoding.

Pick the highest level that works: structure that removes the wrong
path, then a type, then a lint that tells the reader what to do
instead, then a test. Prose is last, for judgment calls only. When a
rule must stay prose, put it where the agent will read it and show the
failure it prevents. The **correct** skill runs this ladder over a
repo.

If the rule is kevbot-wide, it belongs in a principle or playbook,
in one place.
