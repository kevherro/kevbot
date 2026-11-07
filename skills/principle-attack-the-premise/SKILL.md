---
name: principle-attack-the-premise
description: Two fixes on one belief failed the same check; test the belief before a third. Used by kevbot when retries stop converging.
user-invocable: false
---

# Attack the premise

Two failed fixes that rest on the same belief are evidence against
that belief. A third fix on it spends more effort where the evidence
already points away.

Write the belief as one sentence. Every failed attempt assumed it.

Before the next fix, find a measurement whose result depends on
whether the belief is true, and take it. Look at which cases fail,
not only how badly. Make that observation a script you can rerun
(**build-the-lever**).

If it refutes the belief, look for what the failing cases share that
the belief did not predict. If it confirms the belief, keep asking
why (**root-cause**). The earlier fixes probably treated a
consequence.

Remove the condition that puts a case on the losing side. A cleanup
step after the fact leaves the cause in place and runs forever.

This is not **redesign-from-first-principles**. That rebuilds around
a new requirement. This questions a fact the current design assumes.
