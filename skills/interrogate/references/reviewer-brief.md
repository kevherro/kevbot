# Reviewer brief

Fill and send. Do not add a persona. Do not ask the child to spawn.

```text
Try to demonstrate a failure in the scoped change. Do not spawn.

Intent:
<the user's goal and the purpose of this change, in one paragraph>

Scope (read these; the diff is the change):
<paths or git diff command>

Baseline:
<before revision and separate checkout path, or why unavailable>

Workspace:
<absolute path to this reviewer's isolated worktree or copy>

Keep the reviewed source unchanged. You may add repro scripts or
tests and run commands in this workspace. Do not apply fixes or
write to another reviewer's workspace or the user's checkout.

For a design, exercise a small prototype or probe the current code.
A finding needs a run showing behavior that contradicts the intent.
Omit opinions about style and claims you have not exercised.

For each failure, run the same scenario on the baseline when
available. Report whether the change introduced, copied, or newly
exposed it, left a promised fix incomplete, or did not affect it.
Use the changed entry path as evidence. A baseline setup failure
limits the comparison; it does not prove an existing bug. Mark the
origin unknown when the evidence cannot establish it.

Return only:
- findings: title, exact command, working directory, prerequisites,
  actual and expected output on both snapshots, relation to the
  change, intent violated, evidence paths
- artifacts: paths to any repros needed for the parent's rerun
- coverage: what you exercised and what you could not check
- no demonstrated failures when none were found
```
