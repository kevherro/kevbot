"""Main-thread time per frame from an xctrace recording (Time Profiler and
Core Animation Commits), for the window a scene plays in.

  python3 trace.py <tp.xml> <ca.xml> <from-s> <to-s>

tp.xml and ca.xml are `xctrace export --xpath` dumps of the time-profile and
coreanimation-commit-interval tables. xctrace writes a value once with an
id and later as ref=id; refs are resolved here. Frames are 60Hz (the
simulator's display); a sample is 1ms of a running thread."""
import sys, statistics, xml.etree.ElementTree as ET

def rows(path):
    root = ET.parse(path).getroot()
    seen = {}
    def val(e):
        if "ref" in e.attrib:
            return seen[e.attrib["ref"]]
        if "id" in e.attrib:
            seen[e.attrib["id"]] = e
        for c in e:  # register nested ids too
            val(c)
        return e
    for r in root.iter("row"):
        yield [val(c) for c in r]

tp, ca, t0, t1 = sys.argv[1], sys.argv[2], float(sys.argv[3]), float(sys.argv[4])
main_ms, bins = 0.0, {}
for r in rows(tp):
    t = int(r[0].text) / 1e9
    thread = r[1].attrib.get("fmt", "")
    state = r[4].attrib.get("fmt", "")
    if not (t0 <= t < t1) or not thread.startswith("Main Thread") or state != "Running":
        continue
    w = int(r[5].text) / 1e6
    main_ms += w
    bins[int(t * 10)] = bins.get(int(t * 10), 0) + w
frames = (t1 - t0) * 60
commits = [int(r[1].text) / 1e6 for r in rows(ca) if t0 <= int(r[0].text) / 1e9 < t1]
peak = max(bins.values()) if bins else 0
print(f"window {t0:.1f}-{t1:.1f}s: main thread running {main_ms:.0f}ms = {main_ms / frames:.2f}ms per 60Hz frame "
      f"(budget 16.7ms); busiest 100ms bin {peak:.0f}ms")
if commits:
    q = sorted(commits)
    print(f"CA commits: {len(commits)}, median {statistics.median(q):.2f}ms, p95 {q[int(.95 * len(q))]:.2f}ms, max {q[-1]:.2f}ms, "
          f"over 16.7ms: {sum(1 for c in q if c > 16.7)}")
