# kevbot

Personal agent skill pack. Markdown and a few shell scripts. No
build, no tests beyond `scripts/check-skills.sh`, no dependencies.

## Content model

| Path | Owns |
| --- | --- |
| `skills/kevbot/SKILL.md` | Dispatcher: playbook match, principle index, reply shape. |
| `skills/kevbot/playbooks/` | Numbered steps copied into the todo list verbatim. |
| `skills/kevbot/references/` | Harness and model translation. The only place Amp/Grok tool names live. |
| `skills/principle-*/SKILL.md` | One rule per directory. |
| `skills/help` | Catalog of current kevbot skills. |
| `skills/how`, `prove`, `setup-kevbot` | Situational skills the dispatcher calls. |
| other `skills/*` | User-invocable procedures. `/help` lists them. Dispatcher names the ones it routes to. |
| `skills/create-verification-skill/` | Generator for a project-local `verify-<app>` skill. Owns location, generated-skill contract, and feature-map shape. |
| `skills/maintain-verification-skill/` | Upkeep loop for that project skill. Points at create's references. |
| `skills/create-formal-verification-skill/` | Generator for a project-local `formal-<area>` skill. Owns its location and contract. |
| `skills/maintain-formal-verification-skill/` | Upkeep loop for that skill. Points at create. |
| `docs/why.md` | Design argument (parent-owned fan-out, verify-* path, rejected alternatives). Not a second copy of skill rules. |
| `README.md` | Install, commands, layout. Points at `docs/why.md` for why. |

One home per fact. If a playbook needs a rule, it names the principle
skill. It does not restate the rule. Do not put procedures in
`docs/why.md` or arguments in `SKILL.md`.

## Rules for edits

- Agent Skills spec: each skill is `skills/<name>/SKILL.md` with
  `name` matching the directory. Lowercase, digits, hyphens.
- Principle skills set `user-invocable: false`.
- Do not copy pstack, open-pstack, or cursor-team-kit skill text.
- Do not mention Cursor tools (`Task`, `AskQuestion`, `.mdc` rules,
  cloud `environment`) in skill bodies.
- Keep `SKILL.md` bodies actionable. Move long tables into
  `references/`.
- Wrap prose near 80 columns. Do not reflow playbook step lists for
  cosmetics.
- `./install.sh` is the user-level install. Do not run it as a test;
  it mutates `~/.agents/skills`, `~/.grok/skills`, and
  `~/.claude/skills`.
- Check with `./scripts/check-skills.sh` after adding or renaming a
  skill.

## Verification

```sh
./scripts/check-skills.sh
```
