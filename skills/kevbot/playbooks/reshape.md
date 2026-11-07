# Reshape

Behavior-preserving restructure: rename, extract, inline, move, dedupe.

## Steps

1. State the behavior that must not change, and how you will know
   (tests, a command, a UI path).
2. Run **how** on the current shape. Name the boundary you are moving.
3. Apply **smallest-change** and **one-home**. Prefer delete and
   inline over a new wrapper. One owner for the fact you are moving.
4. Make the structural change with no behavior change in the same
   diff if you can. If you cannot, split: behavior lock first, then
   move.
5. Run the **prove** skill on the stated behavior. A green compile is
   not enough.
