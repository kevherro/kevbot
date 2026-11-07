# Where a project verification skill lives

Search the current repo, first match wins:

1. `<repo>/.agents/skills/verify-*/SKILL.md`
2. Project skill locations exposed by the current session, including
   the legacy `<repo>/.grok/skills/verify-*/SKILL.md` location.
   Deduplicate symlinks to the same skill.

Several matches: pick the one whose surface matches the behavior
under test, or ask which. None: there is no project verification
skill yet.

Write a **new** skill only at:

```text
<repo>/.agents/skills/verify-<slug>/
```

This is the canonical project location. If the current harness does
not discover it automatically, load its `SKILL.md` by path or configure
the harness to discover that directory. Do not create a second copy.
Maintain an existing skill at its current location.

`<slug>` is a valid skill name: lowercase letters, digits, hyphens,
2–64 characters, matching the directory and the frontmatter `name`.
Prefer the app or binary name (`verify-limen`, `verify-kevbot`).
