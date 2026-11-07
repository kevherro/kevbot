# Build

New or changed behavior.

## Steps

1. Run **how** on the existing path this behavior will join. If the
   path is missing, say that and sketch only the seam you will add.
2. Apply **named-shape**. Write the data and the invariant first
   (type, struct, table, state machine). Code comes after.
3. Apply **smallest-change**. Ship the smallest complete behavior that
   honors the invariant. No speculative helpers.
4. Apply **encode-the-rule** if a constraint would otherwise live in a
   comment or a chat note.
5. Run the **prove** skill on the new behavior, including the case
   that would have been wrong if the shape was wrong.
6. Commit or open a PR only if the user asked.
