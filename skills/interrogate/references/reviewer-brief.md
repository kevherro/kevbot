# Reviewer brief

Fill and send. Do not add a persona. Do not ask the child to spawn.

```text
Try to demonstrate a failure in the scoped change. Do not spawn.

Intent:
<one paragraph>

Scope (read these; the diff is the change):
<paths or git diff command>

Workspace:
<absolute path to this reviewer's isolated worktree or copy>

Keep the reviewed source unchanged. You may add repro scripts or
tests and run commands in this workspace. Do not apply fixes or
write to another reviewer's workspace or the user's checkout.

For a design, exercise a small prototype or probe the current code.
A finding needs a run showing behavior that contradicts the intent.
Omit opinions about style and claims you have not exercised.

Return only:
- findings: title, exact command, working directory, prerequisites,
  actual output, expected output, intent violated, evidence paths
- artifacts: paths to any repros needed for the parent's rerun
- coverage: what you exercised and what you could not check
- no demonstrated failures when none were found
```
