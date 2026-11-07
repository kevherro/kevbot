---
name: tdd
description: >
  Write a failing check before production code when the user asked for
  TDD or a cheap local test exists. Use for /tdd, "failing test
  first", or "regression test".
disable-model-invocation: true
argument-hint: behavior to lock in
---

# TDD

Make the broken behavior executable before changing production code.
Skip a new test when the path is expensive, integration-heavy, or
not requested, and say so.

A kevbot **fix** still starts with a repro on the real surface.
This skill is the loop when that repro is a cheap test.

## Steps

1. Name intended vs current behavior and the smallest observation.
2. Pick the narrowest check this repo already uses for that path.
   If none is cheap, do not invent a heavy harness to satisfy TDD.
3. Write the failing test first. It encodes intended behavior, not
   the current implementation (**test-behavior**).
4. Run it. It must fail for the intended reason. If it passes, or
   fails for a different reason, fix the test before production code.
5. Smallest production change that makes the intent hold
   (**smallest-change**, **root-cause**).
6. Run the same test. It must pass.
7. Run nearby tests. Then **prove** on the real artifact when that
   artifact is not this test.

## If a failing test is not practical

Say why. Use the closest executable check (script, command, UI
drive). Prefer no new test over a mock-heavy or timing-dependent
one.

Do not weaken assertions to match a wrong implementation.

**Reply:** failing-before command and output, passing-after command
and output, nearby checks. If failing-before was impossible, why
and what you ran instead.
