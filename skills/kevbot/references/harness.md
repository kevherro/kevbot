# Harness

Resolve capabilities once per task from the current session's tool
instructions. A harness name is not a prerequisite. Read an optional
adapter only when the session identifies itself as [Amp](amp.md) or
[Grok Build](grok.md). Current tool instructions take precedence over
adapter examples. Environment variables alone do not identify a harness.

## Capabilities

For each capability needed by the chosen playbook, establish whether it
is available, unavailable, or unknown. Use only documented tools exposed
in this session; unknown is not permission to guess a tool or command.

- **Read, edit, execute.** Use the available file and command tools. If
  a required operation is missing, report the blocked step and continue
  independent work. Do not claim verification without executing it.
- **Skills and resources.** Resolve another skill by name through the
  harness's current discovery. Read its resources relative to that
  skill's reported directory, not a guessed sibling path. Managed copies
  may have versioned directory names. Invoke bundled shell scripts with
  `bash`; distribution may not preserve executable modes.
- **Todo list.** Use the session's planning tool, or a Markdown checklist
  in the conversation when none exists.
- **Delegation.** Use native child sessions when available and permitted.
  Otherwise perform ordinary slices serially in the parent and report
  reduced coverage. If independent reviewers or specific models were
  requested, report their absence as dropouts; a parent pass does not
  satisfy that requirement.
- **Isolation.** Give writers separate worktrees or output directories.
  If isolation is unavailable, keep writes in the parent, serially.
- **Models.** Follow [models.md](models.md). Do not infer that model
  selection exists merely because delegation exists.
- **Sessions.** Use this session's exposed transcript or documented log
  location. If unavailable, use visible conversation and live repo state,
  and name the missing history. Do not guess another harness's paths or
  read another workspace unless the user named it.
- **External wake.** For a bot UI, use a documented CLI or API callable
  from its server. An in-session delegation tool alone is not a server
  integration. If none is available, report the bot UI as blocked.
- **Continuation.** Use a documented wake mechanism if available. Without
  one, work within the active session and report unfinished work at its
  limit. Do not promise unattended continuation after the session ends.
- **Current-session schedule.** Recurring prompt in this conversation,
  with this transcript and a blocking yes/no. A background child or
  overnight orb is not this. If unavailable, say so and stop. Do not
  fake it with a child.

These fallbacks apply wherever a skill calls for the capability.

## Shared contract

1. The parent session owns every spawn. Children never spawn.
2. Each writer gets its own worktree or output directory. Shared
   writable paths across siblings are forbidden.
3. A child prompt is self-contained: goal, scope, how to verify, where
   to write, what to report. File pointers, not pasted dumps.
4. Review the child's diff yourself. Do not pass through its summary.
5. A missing model, failed child, or dropped worker is a named dropout.
   Use only fallbacks declared in [models.md](models.md), and name them
   when used. Do not silently substitute another model.
6. Model overrides follow [models.md](models.md).
7. New work goes to a fresh child with consolidated scope: the
   original brief, every later directive, the prior child's report
   and branch. That covers fix rounds, retries, and follow-ups.
   Continue an existing child only when the work needs state that is
   costly to move: its checkout, uncommitted changes, or a process it
   still runs. Resumed children drop directives silently.

## Overnight

Finish condition, isolated worktree, decision log, stop rule. The
leave-running playbook names them. A wake mechanism keeps work active;
it does not replace the finish condition.
