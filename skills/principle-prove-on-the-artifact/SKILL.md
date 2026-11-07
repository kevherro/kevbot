---
name: principle-prove-on-the-artifact
description: Verify against the real running artifact, not a proxy. Used by kevbot before declaring done.
user-invocable: false
---

# Prove on the artifact

Done means you exercised the thing the user will use.

Run the command, click the path, read the value the system persisted,
inspect the diff. Compiling, generating a test you did not run, or
stating that it should work is not proof.

Prefer the project's existing harness. If none exists, run the
narrowest real invocation that would have failed before the change.

The **prove** skill owns the procedure. This principle is the bar.
