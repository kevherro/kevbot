---
name: principle-explain-the-number
description: >
  Plan the decision a measurement will inform, then check its limiter
  and alternative explanations. Used by kevbot before measuring or
  reporting speedups, regressions, latency, and eval results.
user-invocable: false
---

# Explain the number

A measured number is a claim about work. Check that the work
happened and that you know what limited it.

Before collecting results, record the decision, the smallest effect
that would change it, the expected noise floor, and how you will
estimate variation. If noise is unknown, calibrate first. If the
measurement cannot resolve the target effect, improve the experiment
before comparing options.

After a comparison, if run-to-run spread exceeds the measured
effect, stop and report no measured difference. Improve the
experiment before another comparison.

Name the limiter. Which core, lock, disk, network link, or load
generator kept the number from being twice as good? Get it from a
profile or counters taken during a run, then point at the source
that owns it. Reading code and guessing does not name a limiter.

Rule out the other readings, each with evidence: errors counted as
fast responses, cached or skipped work, a path that never ran, one
side left on default settings, noise larger than the gap, a piece
too small to move the end-to-end result.

Keep the run count, the spread, and the limiter next to the number,
in the notes or a linked file.

For performance numbers, run **benchmark-checklist**. For an eval,
ask whether every trial did the task and whether the gap holds
across trials and models.

Signs this was skipped: measuring without a decision or threshold,
or reporting without a run count, spread, or limiter. Or a claimed
saving that exceeds the whole cost of the part you changed.

**prove-on-the-artifact** checks that an output is real. This checks
that a measurement means what you say.
