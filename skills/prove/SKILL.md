---
name: prove
description: >
  Verify a change against the real artifact the user will run, not a
  proxy. Use for /prove, "verify this", or when a kevbot playbook
  says to prove the work.
argument-hint: change or behavior to verify
---

# Prove

Apply **prove-on-the-artifact**. This skill is the procedure.

## Choose the scope

Inspect the actual diff before choosing a driver. Required repository
checks and verification the user explicitly requested still apply.

- **Wording only.** When an edit changes neither meaning nor behavior,
  inspect the edited document and run the applicable repository or
  document checks. Report those results without starting the app or
  launching extra verifiers. Stop here unless a requested check
  requires more.
- **Behavior or meaning changed.** Use the steps below for the affected
  behavior. Commands, runnable examples, configuration, public behavior
  claims, and skill instructions can change what users or agents do,
  even when the file is Markdown. File type is not a waiver.

For a follow-up to verified work, compare the whole diff since the
verified revision, including pending edits. Reuse evidence only when
its behavior, dependencies, inputs, and relevant setup remain unchanged.
Run required checks and a focused real check for affected behavior.
Broaden verification for new behavior, a redesign, a large diff, or
base/conflict changes that invalidate earlier evidence. A rebase alone
does not prove equivalence. Without reliable earlier evidence, use
the full applicable verification path below.

## Steps

1. Name the behavior you are proving, in the user's terms.
2. Choose the driver, in this order:
   1. A project `verify-*` skill. Locate it with the discovered
      **create-verification-skill** skill's `references/location.md`.
      Follow that skill's Launch, Doctor, Drive, Evidence, and
      Cleanup. Use the feature map when the behavior is listed.
   2. Otherwise the repo's existing harness (documented CLI, test
      that exercises the user path, Makefile target).
   3. Otherwise the narrowest real invocation that would have failed
      before the change.
   If (1) is missing and the surface is an app a later agent will
   need to drive again, offer `/create-verification-skill` once. Do
   not generate a verify skill as a side effect of prove.
3. Run that path. For a UI change, drive the UI. For a CLI change,
   run the binary. Capture the output.
4. Include one nearby case that would fail if the change was wrong
   (the old bug, the identity case, the byte-identical fallback).
5. Report: command or path, observed result, whether the behavior
   holds, and the revision or snapshot checked. Identify reused
   evidence by its original revision and explain why it still applies;
   do not present an earlier run as a fresh one. If a required check
   could not run, verification is incomplete, not a pass or a
   wording-only exception.

Do not declare done from compile-only, from tests you did not run, or
from a child's "all good".
