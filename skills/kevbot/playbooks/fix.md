# Fix

A reported defect. Reproduce, find the cause, change as little as
possible, prove it.

## Steps

1. Reproduce on the real surface (command, UI, failing test). Capture
   the symptom. No repro, no fix. If you cannot reproduce, stop with
   what you tried.
2. Apply **root-cause**. Trace the symptom to the code that is wrong.
   Do not add a nil-check that hides it.
3. Apply **named-shape** if the bug is a missing invariant. Name the
   invariant before the patch.
4. Apply **smallest-change**. Patch the cause. Do not refactor
   neighbors unless they block the fix.
5. Run the **prove** skill against the original symptom and one nearby
   case. Done means the repro is gone on the real surface.
