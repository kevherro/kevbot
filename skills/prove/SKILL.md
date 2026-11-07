---
name: prove
description: >
  Verify a change against the real artifact the user will run, not a
  proxy. Use for /prove, "verify this", or when a kevbot playbook
  says to prove the work.
argument-hint: behavior to prove
---

# Prove

Apply **prove-on-the-artifact**. This skill is the procedure.

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
   holds. If you could not run it, that is a failed prove, not a
   skip.

Do not declare done from compile-only, from tests you did not run, or
from a child's "all good".
