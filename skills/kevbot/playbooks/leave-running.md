# Leave running

The user is stepping away. Drive to a checkable finish condition.

## Steps

1. Write a contract in the todo list: goal, finish condition,
   permissions already granted, stop rule (stuck after N failed
   checks, or a named blocker).
2. Work in an isolated worktree or dedicated checkout. Do not leave half-edits
   in the user's dirty tree unless they asked to.
3. Keep a decision log via **show-me-your-work**. Default path
   `.kevbot/decisions.tsv` in the worktree. That skill owns the
   columns. Commit the trail if the user wants an audit; otherwise
   leave it in the worktree.
4. Apply **reversible-without-asking** inside the contract. Still
   pause for the irreversible list in kevbot SKILL.md. A call the
   contract covers: decide, act, log it. A call only the user can
   make: take a default, log it with the reason, and say in plain
   words what they could tell you to do instead.
5. Loop: do the next verifiable unit, **prove** it, then the next.
   Use an available wake mechanism only to re-check the finish
   condition, per [harness.md](../references/harness.md).
6. Stop when the finish condition holds, or when the stop rule
   fires. Write what is done, what is not, and why you stopped.
