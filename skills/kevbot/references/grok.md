# Grok Build

## Spawn

Use `spawn_subagent`.

| Field | Value |
| --- | --- |
| `subagent_type` | `kevbot-agent` for work that must follow kevbot. `explore` for read-only search. `general-purpose` only when the child must edit and kevbot-agent is unavailable. |
| `background` | `true` for fan-out. Drain with `get_command_or_subagent_output`. |
| `isolation` | `worktree` for any writer. `none` for read-only. |
| `model` | Only a slug from [models.md](models.md) that this session can actually run. Omit to inherit the parent. |

Grok children cannot spawn. If you are already a child, do the work
yourself.

## Tools

- Shell: `run_terminal_command`. Long jobs: `background: true`.
- Overnight wake: Grok `/loop` and the scheduler. Pair with the
  leave-running playbook.
- Project rules: `AGENTS.md` and `~/.grok/rules/*.md`.
- Model sheet: follow [models.md](models.md).

## Current-session schedule

Harness capability. Use `scheduler_create` with `foreground: true`.
Default scheduled tasks and `/loop` run as a background subagent:
they do not see this transcript, and they cannot ask a blocking
question (`ask_user_question` is parent-only).

- `interval`: `Ns` / `Nm` / `Nh` / `Nd`. Minimum 60 seconds.
- `durable`: `false` unless the caller asked to persist.
- `fire_immediately`: `false` unless the caller asked.
- Recurring tasks expire after 7 days. At most 50 at once.
- Replace: `scheduler_list`, then `scheduler_delete` for rows whose
  prompt matches the caller's tag.

## Sessions

On-disk log: `$GROK_HOME/sessions/<encoded-cwd>/<session-id>/`
(`GROK_HOME` defaults to `~/.grok`). `updates.jsonl` is the
conversation. `summary.json` is the index. List with
`grok sessions list`. Search with `grok sessions search`. Stay inside
the encoded cwd for this workspace unless the user named another.

## Do not use

Cursor `Task`, Amp orb APIs, or nested `spawn_subagent` from a child.

## External wake

For a local bot server, check the installed CLI help before using
`grok -p` with a prompt file, `--cwd`, and `--output-format json`.
Only use flags supported by that installation.
