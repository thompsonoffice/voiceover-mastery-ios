#!/usr/bin/env python3
"""Reads `xcrun simctl list devices available -j` on stdin and prints the UDID of an iPhone
simulator on the newest iOS runtime (iOS 17 or later), preferring a standard iPhone model."""
import json, re, sys

devices = json.load(sys.stdin)["devices"]
best = None
for runtime, items in devices.items():
    m = re.search(r"iOS-(\d+)-(\d+)", runtime)
    if not m or int(m.group(1)) < 17:
        continue
    version = (int(m.group(1)), int(m.group(2)))
    for d in items:
        name = d["name"]
        if not name.startswith("iPhone"):
            continue
        plain = 1 if re.fullmatch(r"iPhone \d+( Pro)?", name) else 0
        key = (version, plain, name)
        if best is None or key > best[0]:
            best = (key, d["udid"])
if best is None:
    sys.exit("No iOS 17+ iPhone simulator found")
print(best[1])
