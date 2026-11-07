| Skill | Description |
| --- | --- |
| `/benchmark-checklist` | Plan and vet a performance measurement before running or reporting it: limiter, tuning, physical limits, errors, repeatability, relevance, and whether the work ran. |
| `/benjify` | Build miniature, animated product-UI scenes inside an iPhone app with SwiftUI: onboarding, feature explainers, empty states. |
| `/bro` | Restate the last assistant message in plain language. |
| `/correct` | Turn the mistakes agents repeat in this repo into ones they cannot make, preferring the strongest enforcement that fits. |
| `/create-formal-verification-skill` | Write a repo-local formal-<area> skill that machine-checks one high-stakes promise tests rarely exercise, using the verifier that fits the question. |
| `/create-verification-skill` | Generate a project-local verify-<app> skill that drives this repo's real app the way a user does. |
| `/figure-it-out` | Design and run an auditable playbook when no narrower kevbot playbook fits. |
| `/help` | Print a table of the current kevbot skills and a short description of each. |
| `/how` | Walk through how a subsystem works now, with runtime flow, types, and the non-obvious parts. |
| `/in-your-own-words` | Play back the user's goal and the problem behind it before any work. |
| `/interrogate` | Adversarial review with reproduced failures, one child per configured reviewer. |
| `/ketchup` | Bring the user current on this chat since they last wrote, plainly, then lay out each pending call of theirs with what they need to make it without clicking through. |
| `/kevbot` | Kevin's harness-agnostic engineering dispatcher. |
| `/maintain-formal-verification-skill` | Re-sync a repo's formal-* checks with code that moved since their last confirmation: read those commits, update the model from the code, rerun, and classify each failure as drift or bug. |
| `/maintain-verification-skill` | Keep a project's verify-* skill and feature map honest: source pass per feature, one live drive of every feature, proven corrections only. |
| `/make-bot-ui` | Build a local page whose buttons start agent work through an available CLI or API, keeping secrets on the server. |
| `/no-comments` | Delete comments that narrate code; keep or encode the ones that constrain. |
| `/nudge` | Recurring check-in in this session: ask whether to write a paste-ready team update. |
| `principle-attack-the-premise` | Two fixes on one belief failed the same check; test the belief before a third. |
| `principle-boundary-discipline` | Validate at the edge and trust internal types. |
| `principle-build-the-lever` | Build a rerunnable tool for non-trivial work. |
| `principle-encode-the-rule` | Encode a repeated instruction as a check, not more prose. |
| `principle-exhaust-the-design-space` | Try two or three real alternatives when there is no precedent. |
| `principle-experience-first` | Choose the consumer's result over implementation convenience. |
| `principle-explain-the-number` | Plan the decision a measurement will inform, then check its limiter and alternative explanations. |
| `principle-guard-the-context-window` | Keep bulk out of the parent context. |
| `principle-make-operations-idempotent` | Retries must land on the same end state. |
| `principle-migrate-callers-then-delete-legacy-apis` | Migrate callers and delete the old API in one wave. |
| `principle-minimize-reader-load` | Cut layers and hidden state a reader must hold. |
| `principle-named-shape` | Name the data and its invariant before writing logic. |
| `principle-one-home` | Each fact has one owner. |
| `principle-outcome-oriented-execution` | Converge on the target design, not throwaway in-between states. |
| `principle-parent-owns-fan-out` | Only the parent session spawns workers. |
| `principle-prove-on-the-artifact` | Verify against the real running artifact, not a proxy. |
| `principle-redesign-from-first-principles` | Integrate a requirement as if it had been there on day one. |
| `principle-reversible-without-asking` | Do reversible work, then show the result. |
| `principle-root-cause` | Reproduce first and fix the cause, not the symptom. |
| `principle-separate-before-serializing-shared-state` | Give concurrent writers their own state before adding locks. |
| `principle-sequence-verifiable-units` | End each small unit in a check before starting the next. |
| `principle-smallest-change` | Bias toward deletion and the smallest diff that solves the problem. |
| `principle-test-behavior` | A test asserts what callers can observe; it fails when behavior breaks and survives a refactor. |
| `principle-type-system-discipline` | Make illegal states unrepresentable and refuse to lie to the compiler. |
| `/prove` | Verify a change against the real artifact the user will run, not a proxy. |
| `/recall` | Rebuild recent working context from this harness's sessions and live git/gh state. |
| `/reflect` | Mine this session for durable lessons and route them into skill edits. |
| `/setup-kevbot` | Configure kevbot for this machine: check the install, write optional model overrides, and show how to make /kevbot the default. |
| `/sharpen` | Make a task deeper rather than larger, then return a rewritten prompt. |
| `/show-me-your-work` | Keep an append-only TSV decision log for long or unattended runs. |
| `/tdd` | Write a failing check before production code when the user asked for TDD or a cheap local test exists. |
| `/teach` | Explain a subsystem or change so a person understands it, using how plus git and docs for motivation. |
| `/unslop` | Cut AI tells from prose the user will read. |
