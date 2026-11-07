---
name: interrogate
description: >
  Adversarial review with reproduced failures, one child per configured
  reviewer.
  Use for /interrogate, "tear this apart", or "multi-model review".
disable-model-invocation: true
argument-hint: diff, files, or branch to review
---

# Interrogate

Find failures in a change or design. The parent reruns the evidence
before accepting a finding. Do not apply fixes.

The `reviewers` list in the discovered **kevbot** skill's
`references/models.md` is the panel. Empty list: the parent reviews
once, labeled `parent`.
A slug this session cannot run uses its declared fallback, else it is
a dropout. Do not substitute an undeclared model.

## Steps

1. Scope. Use the files, diff, or design the user names. Otherwise
   review from the merge base with the target branch through the
   working tree. Include relevant staged, unstaged, and untracked
   files; a branch diff alone omits pending work. Record the before
   revision for this scope and the reviewed revision or worktree
   snapshot. For a PR, use its merge base with the target branch;
   a stacked PR targets its parent's branch. For a named diff, use
   its before-state. If no baseline is available, say so.
2. Intent. One paragraph: what this change is for. User message,
   commits, PR body, then the diff. Reviewers challenge fit to
   intent, not the intent itself. If intent is unclear, ask.
3. Isolate. Give each reviewer a separate worktree or copy containing
   the same scoped code and pending edits, plus a separate baseline
   checkout when available. Follow the **kevbot**
   skill's `references/harness.md` for isolation and its fallback.
   Keep the reviewed source unchanged. Repro scripts, tests, and
   generated output belong in the reviewer's assigned workspace.
4. Spawn. Parent launches one child per remaining reviewer in one
   turn. Fill [references/reviewer-brief.md](references/reviewer-brief.md)
   with the intent, scope, baseline, and that child's workspace. Keep these
   workspaces until verification finishes. A parent-only review uses
   the same evidence requirements.
5. Reproduce. Read each proposed repro and inspect the reviewer's
   changes before running it against the unchanged scoped source.
   Rerun its command and compare the observed result with the intent.
   A command that was not rerun, or a failure caused by a reviewer's
   source edit, is not a verified finding. Record unavailable tools
   or prerequisites as verification limits.
6. Attribute. Reproduce the same scenario on the baseline, using
   equivalent inputs and setup. Inspect the path changed by the
   patch, not just whether an old helper also fails. When entry
   points differ, use an equivalent before-state path or show where
   the patch adds or copies the failing path. Missing tools or
   prerequisites are not proof of a baseline defect. If the evidence
   cannot establish attribution, keep the reproduced failure visible
   with its origin marked unknown; do not call it new or pre-existing.
7. Judge. Retain verified failures introduced, copied, or newly
   exposed by the change, and failures the change promised to fix
   but still leaves broken. Report other reproduced baseline
   defects separately as nonblocking follow-ups. Merge duplicates
   by root cause and credit their reviewers.
   Agreement between reviewers does not replace a reproduction.
   Drop style preferences, untested claims, and risks that depend on
   a hypothetical future change.

**Reply:**

### Intent
> the paragraph from step 2

### Reviewers
one bullet each: label, slug or `parent`, verified count, dropouts

### Verified change findings
each finding: command and working directory, actual and expected
output on the reviewed snapshot and baseline, how it relates to
the change and breaks the intent, evidence paths, who found it

### Existing defects
reproduced baseline failures outside this change's responsibility,
with evidence and suggested follow-up

### Dropped / Limits
counts and reasons per reviewer; anything that could not be checked,
including failures whose origin is unknown. Say "no verified change
findings" when none qualify, alongside existing defects and limits.
Unresolved attribution does not establish a clean review.
