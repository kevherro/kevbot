---
name: principle-sequence-verifiable-units
description: End each small unit in a check before starting the next. Used by kevbot for sweeps, migrations, and commit order.
user-invocable: false
---

# Sequence verifiable units

Break the work into units that each end in a known-good state.
Check the current unit before starting the next. A batch of edits
with one test at the end hides the break.

Order delivery the same way: the sequence should prove itself.
Failing check then fix. Subtraction then reshape. Scaffold then
feature. The **prove** skill owns how each check is run.
