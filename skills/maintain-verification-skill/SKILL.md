---
name: maintain-verification-skill
description: >
  Keep a project's verify-* skill and feature map honest: source pass
  per feature, one live drive of every feature, proven corrections
  only. Use for /maintain-verification-skill, "audit the verify
  skill", or when the map has drifted from the app.
disable-model-invocation: true
argument-hint: verify skill to audit
---

# Maintain a verification skill

Upkeep for a skill written by `/create-verification-skill` (or any
project-local `verify-*` with a feature map). The unit is the
feature, not every sentence.

Apply **one-home** and **parent-owns-fan-out**. Edit only the verify
skill's directory. Never edit product code in this run: a map that
describes behavior the app no longer does is either doc drift (fix
the map) or a product regression (report it).

The generated-skill contract and map shape live in the discovered
**create-verification-skill** skill's `references/generated-skill.md`
and `references/feature-map.md`.

## Outcome

Pick one and say it:

- **clean** — every feature had source and live coverage; nothing to
  ship.
- **changed** — the verify skill (map, harness, helpers) has proven
  corrections. Offer a PR; do not open one unless asked.
- **blocked** — coverage could not finish, or a fix could not ship
  safely. Name the blocker.

## Pass

0. **Locate.** Follow the **create-verification-skill** skill's
   `references/location.md`.
   None → stop and point at `/create-verification-skill`.

1. **Index.** Read `features/README.md` and glob sibling files. Fix
   missing, extra, duplicate, or dead entries. Lightweight.

2. **Source wave.** Parent spawns one read-only explorer per feature
   file, per the discovered **kevbot** skill's `references/harness.md`.
   Each returns: how the feature works in source, likely drift with
   citations, one live-drive recipe. Children never drive the app and
   never edit. Parent reads the cited code.

3. **Reconcile.** Every feature file has a result. Merge overlapping
   recipes. Spot-check cited drift. Sweep recent user-facing surfaces
   missing from the map; require a source path before calling one
   missing.

4. **Live pass.** Required even when source looks clean. The parent
   drives, following the verify skill's Launch model (one long-lived
   instance for a server/UI, or a fresh process per drive for a
   short-lived CLI). Exercise every feature at least once.

   Hold for the whole pass:

   - Doctor before the first drive, after any failed drive, and on
     each fresh process. A wedged UI on a healthy process: reset or
     relaunch, do not keep clicking.
   - Evidence captured so far survives every cleanup. Check the named
     location.
   - Nothing a drive started outlives that drive. Clean residue from
     failed attempts. For a shared instance, clean residue, not the
     instance.

   A doctor failure caused by skill drift is drift: fix it inside the
   verify skill and retry once. A feature you cannot reach is
   `verified-unreachable` only with the concrete prerequisite and the
   route you tried. If the map omitted that prerequisite, that is
   drift.

5. **Triage.** Wrong user-facing description → fix the map. Working
   behavior the harness cannot drive → fix the harness, then re-drive
   it live before calling it done. App actually broken → product gap,
   report it, keep it out of the verify-skill diff.

6. **Stop.** For **changed**: show the diff of the verify skill only,
   re-read every file you touched, offer a commit/PR if they want one.
   For **clean** or **blocked**: no product-adjacent PR. Report
   coverage honestly (features covered, unreachable prerequisites,
   confirmed drift).

Do not commit run notes. Scratch only.
