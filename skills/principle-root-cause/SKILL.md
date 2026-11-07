---
name: principle-root-cause
description: Reproduce first and fix the cause, not the symptom. Used by kevbot while debugging.
user-invocable: false
---

# Root cause

Reproduce the symptom before editing. If you cannot reproduce it, you
cannot know you fixed it.

The symptom is where a bad state showed up. The cause is the
earliest point where the system either made a wrong move or dropped
a state it was meant to handle. Keep asking why until you land on a
wrong decision in code rather than a downstream effect. Stuck? Add
instrumentation and read the actual error and values. No guessing.

Then ask whether the triggering state is allowed. Allowed: the code
that choked on it is at fault, so teach that code to handle it. Not
allowed: a guard at the crash site only buries the bug, so go find the
code that created the state. Catches, retries, clamps, nil-checks, and
dropped state are the usual hiding places.

Failures that appear only after restarting point at saved state
first: config, caches, lock files, serialized data.

Fix the pattern, not the instance. Search for the same fault
elsewhere. A workaround that needs a paragraph of comment to justify
it means the code is wrong.

Two fixes on one belief failed the same check: stop and run
**attack-the-premise**.

Record the repro (command, input, observed output) next to the patch.
If the deciding fact took a deep dig, propose the cheap always-on
signal (a log line, a metric, an assertion) that would have shown it
at first look.
