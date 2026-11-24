#!/usr/bin/env python3
"""Print the UDID of an App Store screenshot simulator, creating one if needed.
Usage: pick_screenshot_simulator.py iphone|ipad
iphone: iPhone 17/16 Pro Max (6.9-inch, 1320x2868), else any Pro Max (1290x2796).
ipad:   iPad Pro 13-inch (2064x2752), else iPad Pro 12.9-inch (2048x2732)."""
import json, re, subprocess, sys

kind = sys.argv[1]
PATTERNS = {
    "iphone": [(100, r"^iPhone 16 Pro Max$"), (99, r"^iPhone 17 Pro Max$"), (90, r"^iPhone \d+ Pro Max$")],
    "ipad": [(100, r"^iPad Pro 13-inch \(M\d\)"), (90, r"^iPad Pro \(12\.9-inch\) \(6th generation\)"), (80, r"^iPad Pro \(12\.9-inch\)")],
}[kind]

def score(name):
    for s, p in PATTERNS:
        if re.search(p, name):
            return s
    return 0

def runtimes():
    data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "runtimes", "available", "-j"]))
    out = []
    for r in data.get("runtimes", []):
        m = re.search(r"iOS-(\d+)-(\d+)", r.get("identifier", ""))
        if m and int(m.group(1)) >= 17 and r.get("isAvailable", True):
            out.append(((int(m.group(1)), int(m.group(2))), r["identifier"], r))
    return sorted(out, reverse=True)

devs = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"]))["devices"]
best = None
for runtime, items in devs.items():
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not m or int(m.group(1)) < 17:
        continue
    for d in items:
        s = score(d["name"])
        if s:
            key = (s, (int(m.group(1)), int(m.group(2))))
            if best is None or key > best[0]:
                best = (key, d["udid"], d["name"])
if best:
    print(f"Using {best[2]}", file=sys.stderr)
    print(best[1])
    sys.exit(0)

types = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devicetypes", "-j"]))["devicetypes"]
for version, rid, r in runtimes():
    supported = {t["identifier"] for t in r.get("supportedDeviceTypes", [])} or {t["identifier"] for t in types}
    cands = sorted(((score(t["name"]), t["name"], t["identifier"]) for t in types if score(t["name"]) and t["identifier"] in supported), reverse=True)
    if cands:
        _, name, tid = cands[0]
        print(f"Creating {name} on {rid}", file=sys.stderr)
        print(subprocess.check_output(["xcrun", "simctl", "create", f"Screenshots {kind}", tid, rid], text=True).strip())
        sys.exit(0)
sys.exit(f"No {kind} screenshot simulator available")
