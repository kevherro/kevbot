"""Summarize slowdown.sh runs: frame intervals while the bar moves, hitches
(an interval over 1.5x the median of the no-stills runs), mark spacing,
and capture cost. Usage: python3 slowdown.py <out-dir> <runs>"""
import json, statistics, sys, os

out, runs = sys.argv[1], int(sys.argv[2])
base = None
for mode in ["nostills", "stills", "frames"]:
    ivs, gaps, caps, frames = [], [], [], 0
    for i in range(1, runs + 1):
        d = os.path.join(out, f"{mode}-{i}")
        marks = json.load(open(os.path.join(d, "marks.json")))
        t = {m["name"]: m["time"] for m in marks}
        stamps = json.load(open(os.path.join(d, "meter.json")))
        # Frames while the bar sweeps: from mark start to mark t3000, on the
        # meter's clock, aligned by the first stamp after launch is unknown,
        # so take the 3s window with the most frames after the first second.
        moving = [s for s in stamps if stamps[0] + 1.0 <= s]
        moving = [s for s in moving if s <= moving[0] + 3.0] if moving else []
        ivs += [(b - a) * 1000 for a, b in zip(moving, moving[1:])]
        names = [f"t{k * 500}" for k in range(1, 7)]
        gaps += [(t[b] - t[a]) * 1000 for a, b in zip(names, names[1:]) if a in t and b in t]
        p = os.path.join(d, "captures.json")
        if os.path.exists(p):
            c = json.load(open(p)); caps += [x * 1000 for x in c]; frames += len(c)
        p = os.path.join(d, "mark-captures.json")
        if mode == "stills" and os.path.exists(p):
            caps += [x * 1000 for x in json.load(open(p))]
    med = statistics.median(ivs)
    if base is None:
        base = med
    hitch = sum(1 for x in ivs if x > 1.5 * base) / max(1, len(ivs))
    def q(xs, p):
        xs = sorted(xs); return xs[min(len(xs) - 1, int(p * len(xs)))] if xs else float("nan")
    print(f"{mode:9s} runs={runs} frame interval median={med:.1f}ms p95={q(ivs, .95):.1f}ms "
          f"hitch(>1.5x {base:.1f}ms)={hitch * 100:.1f}% | mark gap (want 500) "
          f"median={statistics.median(gaps):.1f}ms max={max(gaps):.1f}ms"
          + (f" | capture median={statistics.median(caps):.1f}ms p95={q(caps, .95):.1f}ms n={len(caps)}" if caps else ""))
