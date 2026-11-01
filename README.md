# mestack

Harness-agnostic engineering skills. Load the same Markdown procedures
in an agent that can read instructions and use tools. Optional adapters
cover Amp and Grok Build; other harnesses use the capability contract in
[references/harness.md](skills/mestack/references/harness.md).

```text
/mestack <goal, and how you will know it is done>
```

`/mestack` picks a playbook, applies the principles that change a
decision, and keeps subagent fan-out in the parent. Why that shape:
[docs/why.md](docs/why.md).

## Install

Point your harness's skill search path at this repo's `skills/`, or
symlink its skill directories into a location your harness discovers.
Without skill discovery, ask the agent to read
`skills/mestack/SKILL.md` by absolute path and follow its linked files.
Slash commands depend on the harness. Delegation, model selection,
transcript access, and unattended continuation are optional capabilities;
the capability contract defines fallbacks and blocked cases.

The convenience installer targets the Amp, Grok, and Claude Code
directories:

```bash
./install.sh
```

Symlinks `skills/*` into `~/.agents/skills/`, `~/.grok/skills/`, and
`~/.claude/skills/`, `agents/mestack-agent.md` into
`~/.grok/agents/` and `~/.claude/agents/`, and the Claude-only
reviewers in `agents/claude/` into `~/.claude/agents/`. Honors
`CLAUDE_CONFIG_DIR` and `GROK_HOME`. Skips any destination that
exists and is not a symlink. Does not edit `config.toml`,
`settings.json`, `AGENTS.md`, or `CLAUDE.md`. Re-run after new
skills appear.

Grok, as a plugin instead of (or besides) the links:

```bash
grok plugin install /Users/kevin/src/mestack --trust
```

Amp on this machine: the `~/.agents/skills` links, or add
`~/src/mestack/skills` to its skill path.

For Amp orbs and other machines, ask Amp:

```text
Publish this mestack skill pack to my Amp personal skills repository.
```

Copy all `skills/*` directories to that repository's top level, not
just the dispatcher: it calls the other skills and their resources.
Run `./scripts/check-skills.sh` before publishing; it also checks a
versioned, non-executable hosted layout. Amp asks before pushing.
New threads load the published skills automatically; reload skills
in existing threads. Local skills with the same names take precedence.
See [Amp's skills documentation](https://ampcode.com/docs/customize/skills).

## Setup

```text
/setup-mestack
```

Writes `~/.agents/mestack-models.md` if you want per-role model
overrides. Offers a project `verify-*` skill when the current repo
has a runnable app and none exists. Optional always-on routing:

```text
Non-trivial engineering work (bug, feature, refactor, investigation):
read and follow the mestack skill before acting. Casual questions stay
ordinary chat. The user can opt out for a turn by saying so.
```

Put that in a user or project instructions file your harness loads.

## Commands

| Command | When |
| --- | --- |
| `/mestack` | Non-trivial engineering work |
| `/help` | List mestack skills |
| `/how` | Walk a subsystem, read-only |
| `/prove` | Exercise the real artifact |
| `/figure-it-out` | No narrower playbook fits |
| `/interrogate` | Adversarial review of a change |
| `/recall` | Catch up on recent work |
| `/teach` | Explain so a person understands |
| `/tdd` | Failing check before production code |
| `/bro` | Restate the last message plainly |
| `/unslop` | Cut AI tells from prose |
| `/no-comments` | Strip narrative comments |
| `/reflect` | Mine this session into skill edits |
| `/show-me-your-work` | Decision log for long runs |
| `/make-bot-ui` | Local page that wakes agent work |
| `/nudge` | Nudge every N minutes; Yes writes a team update |
| `/create-verification-skill` | Repo has an app and no `verify-*` yet |
| `/maintain-verification-skill` | That skill or its map drifted |
| `/setup-mestack` | Install check and model sheet |
| `/ketchup` | Catch up on this chat; list your pending calls |
| `/in-your-own-words` | Play back the goal before work |
| `/sharpen` | Rewrite a prompt to ask for a deeper task |
| `/correct` | Make a repeated agent mistake impossible |
| `/benchmark-checklist` | Vet a measured speedup or regression |
| `/create-formal-verification-skill` | Model-check or prove one risky promise |
| `/maintain-formal-verification-skill` | That formal check drifted from the code |
| `/benjify` | Animated product-UI scene in an iPhone app (SwiftUI) |

Playbooks behind `/mestack`: `investigate`, `fix`, `build`,
`reshape`, `leave-running`.

`/prove` prefers `<repo>/.agents/skills/verify-<app>/`, then an
existing harness, then a one-off invocation. Create writes that
skill (launch, doctor, drive, evidence, feature map) and runs one
feature before handoff. Details: [docs/why.md](docs/why.md).

## Layout

```text
skills/mestack/                            dispatcher, playbooks, adapters
skills/principle-*/                        one rule each; slash-hidden
skills/how prove setup-mestack help
skills/<name>/                             situational; /help lists them
skills/create-verification-skill/          owns verify-* contract
skills/maintain-verification-skill/
skills/create-formal-verification-skill/   owns formal-* contract
skills/maintain-formal-verification-skill/
skills/benjify/                            skill + StageshowKit Swift package (iOS 27)
agents/mestack-agent.md                    Grok child; no nested spawn
agents/claude/                             Claude-only reviewer agents
docs/why.md                                design argument
```

Harness tool names live only in `skills/mestack/references/`.

## Status

v0.2. No arena or Graphite autopilot. `/interrogate` runs the
`reviewers` list on this parent; an empty list means the parent
reviews. Competing designs: parent spawns isolated writers and
reads them.
