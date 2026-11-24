#!/bin/bash
# Launch the Mac app with a screenshot scene and save 1280x800 PNGs.
# Usage: macos_screenshots.sh /path/to/VoiceOverMastery.app /path/to/output-dir
set -euo pipefail

APP="${1:?app path required}"
OUT="${2:?output directory required}"
BIN="$APP/Contents/MacOS/VoiceOverMastery"

if [ ! -x "$BIN" ]; then
  echo "No executable at $BIN" >&2
  exit 1
fi

mkdir -p "$OUT"

capture() {
  local scene="$1"
  local name="$2"
  local dest="$OUT/${name}.png"
  rm -f "$dest"
  echo "Capturing $scene -> $dest"
  "$BIN" -VoiceOverMasteryScreenshot "$scene" -VoiceOverMasteryScreenshotPath "$dest" &
  local pid=$!
  local i
  for i in $(seq 1 60); do
    if [ -s "$dest" ]; then
      break
    fi
    if ! kill -0 "$pid" 2>/dev/null; then
      break
    fi
    sleep 0.5
  done
  wait "$pid" || true
  if [ ! -s "$dest" ]; then
    echo "Failed to write $dest" >&2
    exit 1
  fi
  sips -g pixelWidth -g pixelHeight "$dest"
}

capture welcome 01-welcome
capture orientation 02-orientation
capture browse 03-browse
capture chapter 04-chapter-31
capture search 05-search
capture practice 06-practice
capture more 07-more

echo "Wrote screenshots to $OUT"
ls -la "$OUT"
