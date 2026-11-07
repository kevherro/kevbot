---
name: benchmark-checklist
description: >
  Plan and vet a performance measurement before running or reporting it:
  limiter, tuning, physical limits, errors, repeatability, relevance,
  and whether the work ran. Use for /benchmark-checklist, before a
  performance comparison, or when reviewing a speedup or slowdown.
disable-model-invocation: true
argument-hint: the claim or the benchmark command
---

# Benchmark checklist

This is the procedure behind **principle-explain-the-number** for performance.
Answer each question from a run, not from reading code.

A quick ballpark the user asked for needs one run plus questions 4
and 7, labeled as one run. It still needs the preflight below.
Choosing between options is never a ballpark.

## Before running

- Apply **principle-explain-the-number** to plan the measurement.
- Specify the metric, dataset, percentile, and comparison, such as
  p95 import time on the 100k-row fixture, baseline versus candidate.
- Read the benchmark script. Note what it times and what it skips.
- Check machine load (`uptime`) and core count. If something else is
  busy and you cannot stop it, interleave the sides and say so.

## Questions

1. **What limits it?** Name the resource that stops it being twice
   as fast. Profile in a separate run you do not report, since
   profilers add cost. Use per-process CPU, a language profiler,
   I/O wait, and syscall counts, then trace the hottest frame to
   code. Check the client driving load too; if it maxes out first,
   the result describes the client. A change that left the number
   flat is explained by the limiter, so find it before giving up.
2. **Was each side tuned?** Release builds, production flags, pool
   and batch sizes, cache temperature, same versions, same data. A
   side on defaults turns the comparison into a config comparison.
   A limiter that is a setting (debug build, per-row commit, missing
   index) means retune and rerun before naming a winner.
3. **Is it physically possible?** Compare throughput with disk and
   network bandwidth and with core count. Deleting a step worth 10%
   of runtime cannot speed things up by much more than 11%. A result
   beyond such a ceiling came from caching, skipped work, or a bug.
4. **Did anything fail?** Count errors and non-success responses.
   Check outputs are correct, not just present. Fast rejections and
   slow retries both distort the number. Add the count if the script
   lacks one.
5. **Does it reproduce?** At least five runs per side, alternating
   A, B, A, B. Report median and range. A gap inside run-to-run
   spread is no measured difference.
6. **Does it matter end to end?** Next to a micro result, measure
   the path a user waits on, at realistic size and concurrency. Give
   the micro piece's share of the whole.
7. **Did the work happen?** Confirm inside the timed region that the
   request arrived, the rows landed, the bytes were read, and the
   result was used. Unawaited promises, uniterated generators,
   dead-code elimination, and timeouts all produce fast numbers.

## Report

Lead with the verdict: faster, slower, no measured difference, or
inconclusive. Then the number with unit, run count, range, and
limiter, for example "p95 120 ms to 96 ms, median of 6 alternating
runs each, after-range 92 to 99 ms, limited by one core doing gzip".

The verdict is inconclusive when the limiter is unnamed, a side was
untuned, or question 4 or 7 went unchecked. Name the gap.

A PR body carries one headline number. Runs and evidence go in a
linked file.
