# Models

Optional override file: `~/.agents/kevbot-models.md`.

`/setup-kevbot` writes it. A missing file, or a missing role line,
means inherit the parent session model.

## Shape

```text
# kevbot model overrides. Delete a line to inherit the parent.
code: inherit-parent
judgment: inherit-parent
reviewers:
```

- `inherit-parent` and `auto` mean: omit any child model field.
- `code` is mechanical implementation.
- `judgment` is design, prose, and synthesis.
- An entry may also name an agent type this session can spawn, when
  that definition pins model and effort. Spawn it by type and omit
  the model field.
- Any slug may name declared fallbacks with `>`: `fable > opus` runs
  `fable`, else `opus`. The first runnable slug wins; report which one
  ran and any skipped. None runnable is a dropout.
- `reviewers` is an optional comma-separated list. `/interrogate`
  spawns one child per entry under its workspace rules. An empty list
  means no panel; the parent reviews.

## Resolution

1. If the file does not exist, inherit the parent for every role.
2. Use a role's line when present.
3. Skip choices this session cannot run or has already rejected, per
   the record below, and try the next declared fallback. With none
   left, report a dropout for that lane. Do not substitute a model
   the file does not name, including the parent unless inheritance
   is declared.

Use only model identifiers documented as selectable in this session.
If selection is unavailable, inherit the parent for default work and
report explicit overrides as dropouts. Do not launch an external
vendor CLI to satisfy an unavailable override.

## Rejected choices

Keep a rejection record for this session and consult it across roles
before each spawn or retry. Record a choice when the tool identifies
it as invalid or unsupported, or returns a complete supported-model
list that excludes it. An incomplete list is not rejection evidence.

Record the model identifier when the model itself is rejected. If
only an effort or speed setting is unsupported, record that exact
combination instead; the model may still work at its default. Treat
agent types that pin a rejected choice the same way when the mapping
is known. Timeouts, rate limits, and failures inside a worker are not
evidence that its model is unsupported and do not advance the fallback
chain on their own. Follow the tool's retry guidance; after an ambiguous
dispatch failure, check whether a worker started before retrying.

Skip rejected choices even when another role or fallback names them.
Report the skipped choices and the fallback used, or the dropout.
Keep this record out of the model override file. A new session starts
fresh; within this session, reconsider a choice only when new
capability evidence explicitly shows it is supported.

## Effort

When the session exposes a reasoning-effort or speed setting for
children, pick it per job. Start from the role's default. Raise one
step for the hardest or subtlest work, lower for routine work. Use a
fast mode only when someone is blocked on the result now. Change the
effort, not the model family, so a reviewer panel stays diverse. After
one rejected adjustment, use the role's default only if the rejection
record permits it. If that choice was already rejected or is rejected
now, continue through Resolution to the declared fallbacks. Do not
cycle through more adjusted settings or retry an identical default.
