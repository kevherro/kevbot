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
  spawns one read-only child per entry. An empty list means no panel;
  the parent reviews.

## Resolution

1. If the file does not exist, inherit the parent for every role.
2. Use a role's line when present.
3. A slug this session cannot run falls through to its declared
   fallback. With no fallback left, it is a dropout for that lane. Do
   not substitute a model the file does not name.

Use only model identifiers documented as selectable in this session.
If selection is unavailable, inherit the parent for default work and
report explicit overrides as dropouts. Do not launch an external
vendor CLI to satisfy an unavailable override.

## Effort

When the session exposes a reasoning-effort or speed setting for
children, pick it per job. Start from the role's default. Raise one
step for the hardest or subtlest work, lower for routine work. Use a
fast mode only when someone is blocked on the result now. Change the
effort, not the model family, so a reviewer panel stays diverse. If
the adjusted setting is rejected, fall back to the role's default and
say so.
