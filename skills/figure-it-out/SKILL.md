---
name: figure-it-out
description: >
  Design and run an auditable playbook when no narrower kevbot
  playbook fits. Use for /figure-it-out, a large migration, or work a
  human will review after stepping away.
disable-model-invocation: true
argument-hint: goal and how you will know it is done
---

# Figure it out

When investigate, fix, build, reshape, and leave-running do not fit,
design the playbook first. The deliverable before code is a sequence
of units that each end in a check.

A focused bug, feature, or refactor still belongs on those playbooks.
This skill is for the large or cross-cutting case, or for work the
user will audit after stepping away.

If they are leaving, run **leave-running** with this playbook as the
work. Do not invent a second overnight contract.

## Steps

1. Read the Principles index in the **kevbot** skill. Name each
   principle that changes a decision.
2. Frame, then stop long enough to say it:
   - Done as a falsifiable predicate (**prove-on-the-artifact**).
   - Scope in rough units, plus blockers already visible.
   - Rigor as gates and artifacts, biased high for one-way doors.
     Reversible steps stay small (**smallest-change**).
3. Decompose into independently landable units. Riskiest unknown
   first. Harness and baseline before features. Fan-out only on real
   seams, unique worktrees, parent-owned
   (**parent-owns-fan-out**). Write the unit list into the todo list.
4. For each unit: state the hypothesis, make the smallest change,
   **prove** it on the real artifact. Keep it if the predicate moved.
   Revert it if it did not. Inconclusive is not a pass.
5. Log every decision and unit through **show-me-your-work**. Do not
   invent a second trail format.
6. Prove the whole against the step-2 predicate. Encode a recurring
   miss as a check (**encode-the-rule**).

**Reply:** the playbook, the rigor level and why, the trail path,
what the predicate showed, what is still open.
