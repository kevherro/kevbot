---
name: no-comments
description: >
  Delete comments that narrate code; keep or encode the ones that
  constrain. Use for /no-comments or "strip comments".
disable-model-invocation: true
argument-hint: files or diff to strip
---

# No comments

Comments that retell the next line are noise. Constraints belong in a
type, a test, or a lint (**encode-the-rule**).

The parent wrote many of these comments. Defer to a fresh child on
what to delete.

## Steps

1. Scope. Caller files or diff. Else the working tree against `main`.
2. Spawn one read-only child, per
   the discovered **kevbot** skill's `references/harness.md`.
   Pass the scope. Ask for each comment: `path:line`,
   text, verdict `delete` / `keep` / `encode`. A keep needs proof
   the comment is about something this repo cannot change (license,
   generated code, a third-party contract). An encode is a constraint
   the code does not enforce.
3. Parent reads the comments. Reject verdicts that edit application
   logic, escape the scope, or treat intentional code as guilty.
   If a keep is thin, delete it. If a delete is ambiguous, delete it.
4. Apply accepted deletes. Smallest in-scope fix when a comment was
   hiding a dead path or a fake parameter (**smallest-change**,
   **root-cause**). Do not widen the fence.
5. For each `encode`: offer the cheapest in-scope type, test, or
   lint. Wait for a yes. Unattended runs delete and report the
   constraint open unless the caller pre-approved encoding.

**Reply:** deletes, keeps, encodings offered, encodings landed,
constraints still open.
