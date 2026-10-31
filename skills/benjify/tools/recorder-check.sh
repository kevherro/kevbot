#!/usr/bin/env bash
# Cross-check the in-process recorder against an outside capture: record
# the screen with `simctl io recordVideo` while the sweep lab plays, then
# find each mark's still in the video by where the bar is.
#   bash recorder-check.sh <udid> <out-dir>
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
udid=$1 out=$2
rm -rf "$out"; mkdir -p "$out/video"
xcrun simctl io "$udid" recordVideo --codec=h264 --force "$out/screen.mp4" 2>"$out/recordVideo.log" &
rec=$!
sleep 2
bash "$here/scene.sh" "$udid" lab-sweep "$out/rec" 6 >/dev/null
kill -INT "$rec"; wait "$rec" 2>/dev/null || true
read -r x y w h scale < <(python3 -c "import json;d=json.load(open('$out/rec/stage.json'));print(*(round(d[k]*d['scale']) if k!='scale' else d[k] for k in ['x','y','width','height','scale']))")
ffprobe -v error -select_streams v -show_entries frame=pts_time -of csv=p=0 "$out/screen.mp4" >"$out/video/times.txt"
ffmpeg -v error -i "$out/screen.mp4" -fps_mode passthrough -vf "crop=$w:$h:$x:$y" "$out/video/%06d.png"
swift "$here/analysis/sweep.swift" "$out/rec" "$out/video" "$scale"
