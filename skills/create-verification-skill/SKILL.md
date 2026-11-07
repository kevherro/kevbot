---
name: create-verification-skill
description: >
  Generate a project-local verify-<app> skill that drives this repo's
  real app the way a user does. Use for /create-verification-skill,
  "make a verify skill for this repo", or when /prove has no scripted
  way to exercise the product.
disable-model-invocation: true
argument-hint: app or repo to verify
---

# Create a verification skill

A `verify-<slug>` skill is how later agents prove behavior on **this**
app. Write it for a cold agent mid-task. Apply **encode-the-rule**:
the skill is the encoding, not a chat note.

Do not copy kevbot into the generated skill. Point at Launch / Drive
in the generated file.

## 1. Locate

Follow
[references/location.md](references/location.md). If a `verify-*`
skill already exists, stop. Offer
`/maintain-verification-skill` instead of writing a second one.

## 2. Interview the repo

Answer from the checkout. Ask the user only what you cannot observe.

- **Surface.** What a user touches: web UI, CLI/TUI, desktop, API,
  mobile, library. A repo can have several. Pick the primary one and
  name the rest.
- **Run.** How it starts locally. Prefer the repo's own documented
  command (package scripts, Makefile, README). Ports, env, seed, auth.
- **Drive.** How an agent can operate it. Existing harness first.
  Generic recipe only if none exists.
- **Observe.** Screenshots, transcripts, response bodies, logs, exit
  codes, DB state.
- **Isolate.** Can two instances run at once? If not, the generated
  skill must refuse to hijack the user's session.

If the checkout does not build or start, fix that first (or report it
precisely). Do not generate steps against a broken base.

A library with no runnable surface: stop. Say so. Do not invent a UI.

## 3. Write the skill

Create `<repo>/.agents/skills/verify-<slug>/SKILL.md` that satisfies
[references/generated-skill.md](references/generated-skill.md). Fill
every section from the interview. No template leftovers.

If an irrelevant missing asset blocks startup (empty static dir, sample
config the API never serves), the skill may create it, marked as
verification scaffolding, and remove it in cleanup.

## 4. Seed the feature map

Create `features/` next to that SKILL.md, following
[references/feature-map.md](references/feature-map.md). Top 3–5 real
user-facing features only.

## 5. Run it once

Follow the generated skill end to end: launch, doctor, drive **one**
mapped feature, capture evidence, clean up. After cleanup, confirm the
evidence is still at the named location.

Fix failures and rerun cleanup after every failed attempt so ports and
processes do not leak. A skill you have not executed is a draft. Do
not hand over a draft.

If the proof ran on a substitute (a container standing in for a
fresh VM, a local stack for a hosted one), name each setup step the
substitute supplied for free that the real target will not. Treat
those as unproven until something runs on the real target.

## 6. Hand off

Tell the user the skill path, which feature you proved, and where the
evidence is. Point at `/maintain-verification-skill` for map upkeep.

Commit the new skill only if they asked. Creating it does not mean
opening a PR.
