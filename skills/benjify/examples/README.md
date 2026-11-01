# Examples

Ports of upstream's gold examples, at their compact (phone column) size.
Copy the closest one as the starting point for a new scene.

| File | Upstream | What to learn |
| --- | --- | --- |
| [PayoutFlow.swift](PayoutFlow.swift) | `payout-flow` (compact, 358 × 610) | Choreography with no cursor: slow overlapping arrivals, a connector, a payoff that holds |
| [FormError.swift](FormError.swift) | `form-error` (compact, 358 × 420), without its `Window` | A form with a touch: an error on the field that caused it, fixed, then the button confirms on itself |

Both are scenes in `tools/Runner` (`-scene payout-flow`, `-scene form-error`).
Their parity with the upstream originals is in
[verification](../references/verification.md).
