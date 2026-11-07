---
name: show-me-your-work
description: >
  Keep an append-only TSV decision log for long or unattended runs.
  Use for /show-me-your-work, or when leave-running or figure-it-out
  needs a trail.
disable-model-invocation: true
argument-hint: path of the log if not the default
---

# Show me your work

A human who was not in the room should reconstruct what was decided,
why, and on what evidence, without reading the whole transcript.

This skill owns the trail format. Other skills point here.

## Format

One TSV, one row per decision or checkpoint. Cells are single-line.
Evidence is a pointer, not a paragraph.

Columns: `ts`, `phase`, `decision`, `why`, `evidence`, `result`.

- **ts.** UTC ISO8601.
- **phase.** Workstream or unit.
- **decision.** What was chosen, one line.
- **why.** Plain reason. If a principle drove it, say so in words.
- **evidence.** Commit, `file:line`, command, screenshot path.
- **result.** What held: `verified`, `reverted`, `inconclusive`,
  `open`, or a measured outcome.

Default path: `.kevbot/decisions.tsv` in the worktree. Several
runs at once: `.kevbot/<task-slug>.tsv`. Local by default. Commit
only when a reviewer needs the trail to trust the result.

Append with this skill's `scripts/log.sh`, using its discovered
path. Run from the worktree so relative log paths stay there:

```text
bash <skill-dir>/scripts/log.sh <logfile> <phase> <decision> <why> <evidence> <result>
```

It stamps `ts`, writes the header on first use, strips tabs and
newlines, and quotes cells that would be spreadsheet formulas.

## Rules

- Append-only. A wrong call gets a new row. Never edit history.
- Log forks, landings, reverts, blockers, and one row per loop
  iteration. Skip the self-evident.
- Prefer evidence a committed script can reproduce.

## Several runs, one log

A run is one agent session, including its later turns. A pickup, a
replacement agent, or a new session is a new run.

A run joining a non-empty log opens with a phase `start` row. It
writes another `start` row whenever a different run has written
since its own last row. So check the tail of the log before
appending in a later turn. A `start` row's decision names the `ts`
range of earlier rows this run did not write; its evidence names
this run (session or agent id). Use phase `start` for nothing else.

## Before handoff

Walk this run's rows against this session's transcript (harness
adapter session path). This run's rows begin at its `start` rows, or
at the first row if it created the log, and end at the next `start`
row from another run.

Correct the log, not the story. Never edit or delete a row, even an
invented one. If a row records no real decision or action, or its
claim or evidence is wrong, append a row that supersedes it with what
happened and a pointer that resolves. Add rows for gaps that shaped
the work. Leave other runs' rows alone unless this run's work proves
one wrong; then supersede it the same way.

Then a second pair of eyes: one read-only child on a `reviewers`
slug if one is runnable and not the parent model; else the parent,
labeled `reviewed by parent`. Flag weak evidence, skipped proof,
and risky calls. End with **Attention**: reviewer identity, then
the flags. `No flags` is valid; omitting the identity is not.

**Reply:** path to the log, row count, attention flags.
