"""Compare mark dumps from two sides (web and SwiftUI, or a side and itself).

Each input is a JSON list of runs; a run is a list of marks
{name, time, rects{name: {x, y, width, height}}}. A SwiftUI marks.json (one
run, rects as [[x, y], [w, h]]) is accepted too, as are several files.

Checks, in order: the same marks in order; the same target names at each
mark (a zero-size rect counts as absent, as display:none measures); every
rect within the rect tolerance; every mark time (from the first mark)
within the time tolerance. Each side's noise is the largest distance of
any of its runs from that side's per-value median. The rect tolerance is
1.5x the larger side's noise plus 0.5pt (Chrome lays out at 1/64px,
SwiftUI at 1/3pt on a 3x screen); the time tolerance is 1.5x the larger
noise plus one 60Hz frame (16.7ms), since both sides land marks on frames.

  python3 compare.py A.json[,A2.json...] B.json[,B2...] [--rect R] [--time T]
  python3 compare.py --self-test A.json[,...]
"""
import json, statistics, sys

def load(paths):
    runs = []
    for p in paths.split(","):
        d = json.load(open(p))
        if d and isinstance(d[0], dict):  # a SwiftUI marks.json: one run
            d = [d]
        for run in d:
            out = []
            for m in run:
                rects = {}
                for k, v in m["rects"].items():
                    if isinstance(v, list):
                        v = {"x": v[0][0], "y": v[0][1], "width": v[1][0], "height": v[1][1]}
                    if v["width"] > 0 or v["height"] > 0:
                        rects[k] = v
                out.append({"name": m["name"], "time": m["time"], "rects": rects})
            t0 = out[0]["time"] if out else 0
            for m in out:
                m["time"] -= t0
            runs.append(out)
    return runs

KEYS = ["x", "y", "width", "height"]

def median_run(runs):
    base = runs[0]
    med = []
    for i, m in enumerate(base):
        rects = {}
        for k in m["rects"]:
            vals = [r[i]["rects"][k] for r in runs if i < len(r) and k in r[i]["rects"]]
            rects[k] = {c: statistics.median(v[c] for v in vals) for c in KEYS}
        med.append({"name": m["name"], "time": statistics.median(r[i]["time"] for r in runs if i < len(r)), "rects": rects})
    return med

def noise(runs):
    med = median_run(runs)
    nr = nt = 0.0
    for r in runs:
        for i, m in enumerate(r):
            if i >= len(med):
                continue
            nt = max(nt, abs(m["time"] - med[i]["time"]))
            for k, v in m["rects"].items():
                if k in med[i]["rects"]:
                    nr = max(nr, max(abs(v[c] - med[i]["rects"][k][c]) for c in KEYS))
    return nr, nt

def compare(a, b, rect_tol, time_tol, label=""):
    ma, mb = median_run(a), median_run(b)
    fails = []
    na, nb = [m["name"] for m in ma], [m["name"] for m in mb]
    if na != nb:
        return [f"marks differ: {na} vs {nb}"], 0, 0
    worst_r = worst_t = 0.0
    for x, y in zip(ma, mb):
        ka, kb = set(x["rects"]), set(y["rects"])
        if ka != kb:
            fails.append(f"{x['name']}: targets differ: only A {sorted(ka - kb)}, only B {sorted(kb - ka)}")
        for k in sorted(ka & kb):
            d = max(abs(x["rects"][k][c] - y["rects"][k][c]) for c in KEYS)
            worst_r = max(worst_r, d)
            if d > rect_tol:
                fails.append(f"{x['name']}: {k} off by {d:.1f}pt (A {fmt(x['rects'][k])} B {fmt(y['rects'][k])})")
        dt = abs(x["time"] - y["time"])
        worst_t = max(worst_t, dt)
        if dt > time_tol:
            fails.append(f"{x['name']}: time off by {dt * 1000:.0f}ms (A {x['time']:.3f}s B {y['time']:.3f}s)")
    return fails, worst_r, worst_t

def fmt(r):
    return "(" + ", ".join(f"{r[c]:.1f}" for c in KEYS) + ")"

def tolerances(rect_noise, time_noise):
    return 1.5 * rect_noise + 0.5, 1.5 * time_noise + 1 / 60

def main():
    args = sys.argv[1:]
    if args[0] == "--self-test":
        runs = load(args[1])
        nr, nt = noise(runs)
        rt, tt = tolerances(nr, nt)
        half = max(1, len(runs) // 2)
        f, wr, wt = compare(runs[:half], runs[half:] or runs, rt, tt)
        print(f"self: noise rect {nr:.2f}pt time {nt * 1000:.1f}ms -> tolerance {rt:.2f}pt {tt * 1000:.0f}ms; worst {wr:.2f}pt {wt * 1000:.1f}ms: {'PASS' if not f else 'FAIL'}")
        for x in f: print("  " + x)
        moved = json.loads(json.dumps(runs))
        m = next(m for m in moved[0] if m["rects"])
        k = sorted(m["rects"])[0]
        for r in moved:
            for mm in r:
                if mm["name"] == m["name"] and k in mm["rects"]:
                    mm["rects"][k]["x"] += 5
        f2, wr2, _ = compare(runs, moved, rt, tt)
        print(f"self, {k} moved 5pt at {m['name']}: worst {wr2:.2f}pt: {'PASS (should have failed)' if not f2 else 'FAIL as it should'}")
        for x in f2: print("  " + x)
        sys.exit(0 if not f and f2 else 1)
    a, b = load(args[0]), load(args[1])
    na, nb = noise(a), noise(b)
    rt, tt = tolerances(max(na[0], nb[0]), max(na[1], nb[1]))
    if "--rect" in args: rt = float(args[args.index("--rect") + 1])
    if "--time" in args: tt = float(args[args.index("--time") + 1]) / 1000
    f, wr, wt = compare(a, b, rt, tt)
    print(f"A runs={len(a)} noise rect {na[0]:.2f}pt time {na[1] * 1000:.1f}ms | B runs={len(b)} noise rect {nb[0]:.2f}pt time {nb[1] * 1000:.1f}ms")
    print(f"tolerance rect {rt:.2f}pt time {tt * 1000:.0f}ms; worst rect {wr:.2f}pt time {wt * 1000:.1f}ms: {'PASS' if not f else 'FAIL'}")
    for x in f: print("  " + x)
    sys.exit(0 if not f else 1)

main()
