# Amp

## Spawn

Start an independent thread for each child (an orb when the child
needs its own machine, checkout, or overnight budget). The parent
keeps working.

Each child gets a complete brief, the files it needs, a unique output
path, and an instruction to report back. Uncommitted parent files are
not visible unless you send them.

Fan-out is several threads at once, then the parent synthesizes. Do
not serialize independent slices without a reason.

A second opinion, when Amp exposes an oracle or equivalent, is one
extra read-only thread with the same rubric. It does not apply
changes.

## Overnight

An orb plus a finish condition from the leave-running playbook. The
orb is the machine. The playbook is the contract.

## Model sheet

Read `~/.agents/kevbot-models.md` when present. Amp-native models run
in-process. A role that names a model this Amp session cannot run is a
dropout.

## Sessions

Use the thread or transcript this Amp session exposes. If you cannot
find it, say unknown. Do not guess a Cursor path. Do not read another
workspace unless the user named it.

## Do not use

Grok `spawn_subagent` or Cursor `Task`.

## Current-session schedule

Not the overnight orb. If this Amp session exposes a recurring prompt
in the current thread with a blocking question, use that. Otherwise
the capability is unavailable.
