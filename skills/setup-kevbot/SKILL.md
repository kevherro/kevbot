---
name: setup-kevbot
description: >
  Configure kevbot for this machine: check the install, write optional
  model overrides, and show how to make /kevbot the default. Use for
  /setup-kevbot or "configure kevbot".
---

# Setup kevbot

## 1. Check the install

Resolve the current session's capabilities through the discovered
**kevbot** skill's `references/harness.md`. Confirm the dispatcher
can read its bundled playbooks and references. A source checkout,
symlink, directly loaded file, or managed copy is valid; it need not
point at this repo's `skills/` tree.

If discovery is missing, use the installation options in the repo's
README. Configure a supported skill search path, link the skill tree,
or load the entry file explicitly. Do not assume every harness scans
the same directories. Do not run `install.sh` unless the user asks.

## 2. Models

Read `~/.agents/kevbot-models.md` if it exists. Otherwise start from
the default shape in
the **kevbot** skill's `references/models.md`.

Show the current mapping (`code`, `judgment`, `reviewers`). Ask
whether to keep inherit-parent for everything or set specific slugs
this session can actually run. Never write a slug you have not seen
in this session's model list.

Write `~/.agents/kevbot-models.md` in the shape from
the **kevbot** skill's `references/models.md`.
Overwrite the whole file so reruns stay idempotent.

## 3. Optional default routing

If they want kevbot on every non-trivial task, show this block and
ask where to put it in a rules file the current harness actually loads.
Do not write it without a yes:

```text
Non-trivial engineering work (bug, feature, refactor, investigation):
read and follow the kevbot skill before acting. Casual questions stay
ordinary chat. The user can opt out for a turn by saying so.
```

## 4. Project verification skill

If this session is inside a git repo, search for a `verify-*` skill
using the discovered **create-verification-skill** skill's
`references/location.md`.

- Found: name the path. Mention `/maintain-verification-skill` when
  the map may have drifted.
- Missing, and the repo has a runnable app: offer once to run
  `/create-verification-skill`. Do not generate it without a yes.
- Missing, no runnable surface: skip. Do not push a verify skill on
  a docs-only or library-only tree.

## 5. Confirm

Tell them `/help` lists the pack. Slash-menu discovery depends on
the harness; skills can also be loaded by path. `/interrogate` spawns
one child per `reviewers` entry. A slug this session cannot run
falls through to its `>` fallback, else it is a dropout.
