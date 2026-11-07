# Why kevbot is shaped this way

Kevbot is one skill tree that different agent harnesses load. Skills
are procedures. This file is the argument for the load-bearing
choices. If a rule and this memo disagree, the skill that owns the
rule wins; fix this file.

Thesis: an agent that writes code without a checkable finish
condition, and that nests work inside children that cannot nest,
produces output you cannot trust. The tree below exists to make those
two failures illegal.

## The failure that names the design

You ask:

```text
/kevbot the export writes duplicate rows when a retry lands mid-run.
repro first, then fix and verify. text output stays byte-identical
when --json is off.
```

Three things have to happen: someone must understand export, someone
must change it, someone must run the real binary.

If the parent spawns a fixer, and the fixer spawns a reviewer, Grok
Build rejects the inner spawn. Depth is one: only the top-level
session may call `spawn_subagent`; a child that calls it gets a
depth-limit error (`~/.grok/docs/user-guide/16-subagents.md`). The
review becomes the child's own summary. That summary is untrusted.

If nobody encodes how to start and drive export, `/prove` invents a
path (`cargo test`, a helper the user does not run). The next session
does not have that path. The `--json` flag is "done" in chat and
wrong on the binary.

Those two failures are the whole design space. Parent-owned fan-out
fixes the first. A project `verify-*` skill fixes the second.

## Invariants

1. **One skill tree, any capable harness.** Sessions load the same
   `SKILL.md` files. Harness tool names live only in
   `skills/kevbot/references/`.
2. **The parent owns every spawn.** Children never spawn. Writers do
   not share a writable path.
3. **One home per fact.** A search path, a playbook step, a model
   role, or a feature recipe exists in one file. Everyone else links.
4. **Done means the real artifact moved.** Compile-only, unread tests,
   and child self-reports are not proof.
5. **Creating a skill is not shipping it.** No commit, PR, or
   generated `verify-*` as a side effect of a fix unless the user
   asked.

Amp and Grok were the original installation targets, as recorded in
the first commit. The nested-spawn failure above motivated a portable
ownership rule. It does not require restricting the skill pack to
those harnesses. Parent-owned synthesis remains useful even where
nested delegation is supported.

## Mechanism

### Dispatcher

`/kevbot` matches a playbook and copies its steps into the todo
list. Principles are leaves; the dispatcher only indexes them. If
the work is "understand / change / prove" on the export bug, the
playbook is `fix`: reproduce on the binary, patch the cause, prove
on the binary. The parent may spawn read-only explorers for `how`.
It does not hand the whole task to a child and wait for "looks good."

### Adapters

A mandatory Amp-or-Grok choice made an otherwise portable procedure
undefined in a third harness. `references/harness.md` now owns a
capability contract, with optional adapters for known integrations.
A new harness can use its documented tools without a new adapter.
Missing tools reduce what can be done or proved; they do not justify
inventing a tool call or treating a parent review as an independent one.

The existing installer remains a convenience for its original targets.
Loading a skill tree and executing its procedures are separate concerns;
a harness can load the same files from its own discovery path.

### Project `verify-*`

`/prove` is the bar, not the recipe. Export's launch command, ready
signal, and "duplicate rows" observation belong to the app repo.

`/create-verification-skill` interviews the checkout and writes:

```text
<repo>/.agents/skills/verify-<app>/SKILL.md
<repo>/.agents/skills/verify-<app>/features/
```

The original targets shared `.agents/skills/` discovery. Keeping one
canonical location avoids drift when a new harness uses a different
search path. Discovery can be configured or the file loaded explicitly;
it does not need a second copy of the verification recipe.

Create must run launch → doctor → one mapped feature → evidence →
cleanup before handoff. A skill whose Drive section was never
executed teaches the next agent a guess. Cleanup that deletes
evidence makes the run un-auditable; evidence has a named location
that survives teardown.

`/prove` then prefers that skill, then an existing repo harness, then
a one-off invocation. It offers create once. Generating `verify-export`
in the same turn as the `--json` patch mixes product work with
harness work and usually skips the "run it once" gate.

`/maintain-verification-skill` only edits the verify skill. Source
explorers are parent-spawned and read-only. The parent drives every
feature live. A map line that describes behavior the app no longer
does is either doc drift (fix the map) or a product bug (report it).
Outcomes are `clean`, `changed`, or `blocked`.

## Alternatives

**Vendor pstack or open-pstack.** pstack is MIT; copying is legal.
Its skill bodies name Cursor `Task`, sticky mode, cloud agents, and
`~/.cursor/rules/*.mdc`. Those strings do not resolve here. A
mechanical substitute table is a second product to sync. kevbot
keeps the problem (throughput without a checkable finish condition)
and keeps harness-specific primitives in optional adapters. The cost
is less playbook coverage (no arena or
Graphite autopilot in v0.2). `/interrogate` exists; it runs the
`reviewers` list on this parent, not a vendor mix.

Ideas still flow one way, rewritten rather than copied. The last
review covered pstack in `cursor/plugins` through `4ec7ffa`
(2026-10-22). Not taken from that pass: `statechart` (a large
TLA+-to-Mermaid toolkit; revisit if formal checks become routine
here) and `poteto-help` (`/help` and `/setup-kevbot` cover it). The
next sync starts from that commit:
`git log 4ec7ffa..origin/main -- pstack`.

**Let children spawn.** That matches "a fixer with its own
reviewer." On Grok it does not run. On Amp it still puts the
synthesis in a context that has not seen the user's constraints.
The parent already has the goal and the finish condition; it is the
cheaper place to read diffs.

**Prove with whatever is handy, never write `verify-*`.** Fine for a
one-off CLI flag in a repo you will not open again. The second
session pays the interview cost again, and the invented path is not
in git. Create is the encode-the-rule step for a repo that will see
more than one prove.

**Write new verify skills under `.grok/skills/` too.** Grok would
still find them. Amp would not, unless you also teach Amp that path.
The overlapping discovery directory is `.agents/skills/`. A second
write is a second home.

## Limits

There is no eval in this repo that kevbot reduces defect rate or
token cost against a bare session. The claim is narrower: the
illegal states above cannot be produced while the skills are
followed.

v0.2 `/interrogate` is the panel. A `reviewers:` line that names a
slug this session cannot run is a dropout, not a silent substitute
(`references/models.md`). Arena-style bakeoffs are parent-owned
spawns with unique worktrees, not a named playbook yet.

The Grok restriction above records the original design motivation,
not a current compatibility guarantee. No cross-harness execution suite
exists here. The capability contract describes how to adapt; it does
not establish that every harness discovers skills or follows them.

## Conclusion

Load kevbot as skills. Run `/kevbot` for non-trivial work. Put
app-specific drive recipes in the app repo under
`.agents/skills/verify-<app>/`. Keep arguments in this file and
orders in `SKILL.md`.

What you can rely on: fan-out is flat; verify skills have one write
path; prove will not invent a generator as a side effect of a patch.

What you cannot: that this tree is complete, or that following it
is empirically better than a careful session without it. Those are
open.
