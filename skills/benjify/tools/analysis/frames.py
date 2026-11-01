"""Summarize frames.sh: over the window from the first mark to the last
mark + 3s, the display-frame intervals (a hitch is an interval over 1.5x
the 16.7ms budget of the simulator's 60Hz display) and main-thread busy
time per frame (busy spans clipped to each frame interval).
Usage: python3 frames.py <out-dir> <runs>"""
import json, os, statistics, sys

out, runs = sys.argv[1], int(sys.argv[2])
ivs, per_frame = [], []
for i in range(1, runs + 1):
    d = os.path.join(out, f"run-{i}")
    stamps = json.load(open(os.path.join(d, "meter.json")))
    busy = json.load(open(os.path.join(d, "busy.json")))
    # The meter and the stage clock differ; the scene plays from launch,
    # so use 0.5s after the first frame to the end of the recording.
    start, end = stamps[0] + 0.5, stamps[-1]
    frames = [s for s in stamps if start <= s <= end]
    ivs += [(b - a) * 1000 for a, b in zip(frames, frames[1:])]
    bi = 0
    for a, b in zip(frames, frames[1:]):
        t = 0.0
        for s, e in busy:
            if e <= a: continue
            if s >= b: break
            t += min(e, b) - max(s, a)
        per_frame.append(t * 1000)
q = lambda xs, p: sorted(xs)[min(len(xs) - 1, int(p * len(xs)))]
hitch = sum(1 for x in ivs if x > 25) / len(ivs)
print(f"runs={runs} frames={len(ivs)} interval median {statistics.median(ivs):.1f}ms p95 {q(ivs, .95):.1f}ms max {max(ivs):.1f}ms; "
      f"hitch ratio (>25ms) {hitch * 100:.2f}%; main thread per frame median {statistics.median(per_frame):.2f}ms "
      f"p95 {q(per_frame, .95):.2f}ms max {max(per_frame):.2f}ms")
