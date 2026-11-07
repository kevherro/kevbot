---
name: interrogate
description: >
  Adversarial review of a change by one child per configured reviewer.
  Use for /interrogate, "tear this apart", or "multi-model review".
disable-model-invocation: true
argument-hint: diff, files, or branch to review
---

# Interrogate

Stress a change with independent read-only reviewers. The parent
judges. Do not auto-apply.

The `reviewers` list in the discovered **kevbot** skill's
`references/models.md` is the panel. Empty list: the parent reviews
once, labeled `parent`.
A slug this session cannot run uses its declared fallback, else it is
a dropout. Do not substitute an undeclared model.

## Steps

1. Scope. User-named files or diff if given. Else
   `git diff <base>...HEAD` including the working tree. Base is
   `main` unless the repo says otherwise.
2. Intent. One paragraph: what this change is for. User message,
   commits, PR body, then the diff. Reviewers challenge fit to
   intent, not the intent itself. If intent is unclear, ask.
3. Spawn. Parent launches one read-only child per remaining reviewer
   in one turn, per the **kevbot** skill's `references/harness.md`.
   Read-only reviewers may share a checkout; they must not write.
   Same brief for every child: intent, scope, and
   [references/rubric.md](references/rubric.md). Fill
   [references/reviewer-brief.md](references/reviewer-brief.md).
4. Parent reads the diff again. Child summaries are untrusted.
5. Judge. You have the goal and the constraints. Bucket every
   finding:
   - **Act on.** Would block a real merge.
   - **Consider.** Real, cost unclear.
   - **Noted.** Valid, not actionable now.
   - **Dismissed.** Wrong, nit, or missing context. Say why.
   Consensus (2+ children, same issue) is high-confidence. A lone
   finding still appears, with its model.

**Reply:**

### Intent
> the paragraph from step 2

### Reviewers
one bullet each: label, slug or `parent`, finding count, dropouts

### Act on / Consider / Noted / Dismissed
each finding: what, evidence, who raised it, why this bucket

### Agreement
where they agreed, where they split
