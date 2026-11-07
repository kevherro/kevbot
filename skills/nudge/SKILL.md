---
name: nudge
description: >
  Recurring check-in in this session: ask whether to write a paste-ready
  team update. Use for /nudge, "$nudge every 25m", or "nudge me every
  N minutes".
argument-hint: every 25m | stop
---

# Nudge

A timer in this conversation. Each fire asks. Yes writes a paste-ready
update. No ends the fire. Not a background child. Not an overnight
orb.

## Steps

1. Parse the argument.
   - `stop`, `off`, `cancel`, or `clear`: cancel tagged nudge
     schedules in this session. Say if none. Stop.
   - An interval (`25m`, `every 25 minutes`, `1h`): continue.
   - Missing or unparseable: ask once. Do not invent a default.

2. Resolve **current-session schedule** through
   the discovered **kevbot** skill's `references/harness.md`.
   Need a recurring prompt in this transcript, plus a blocking
   yes/no. A background child is not this. If unavailable, say so
   and stop.

3. Cancel any existing schedule whose prompt starts with `[nudge]`.
   Then create one recurring current-session turn at the interval.
   Do not persist across sessions. Do not fire immediately.

4. Fire prompt, with `<interval>` filled in:

   ```text
   [nudge] Check-in. Do not write or edit code.

   1. If a short local alert exists, play one chime. Ignore failure.
   2. Ask one blocking question: "It has been <interval>. Time for
      a team update?" Yes = paste-ready update. No = skip.
   3. No, dismiss, timeout, or no answer: stop. No recap. No tools.
   4. Yes: Slack-ready update of this session since the last nudge
      Yes, or since session start. Decisions, files, blockers, next.
      Fence it for copy. Tools only if git status/diff is needed to
      name files. Then stop.
   ```

5. Reply with the interval and that `/nudge stop` cancels it.
   Do not summarize now.
