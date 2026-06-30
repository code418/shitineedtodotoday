#!/usr/bin/env bash
# Regenerate the Android launcher icons from the in-app brand mark
# (lib/core/design/widgets/app_brand_mark.dart). Run from anywhere:
#
#   tool/generate_app_icon.sh
#
# Steps: render the mark to two 1024² PNGs (build/app_icon/) via a Flutter
# test, then downsample into res/mipmap-* with ImageMagick. Requires the
# `convert` (ImageMagick) CLI. The adaptive-icon XML + gradient background
# drawable in res/ are authored by hand and not regenerated here.
set -euo pipefail
cd "$(dirname "$0")/.."

command -v convert >/dev/null || { echo "ImageMagick 'convert' is required"; exit 1; }

flutter test tool/generate_app_icon.dart

SRC=build/app_icon
RES=android/app/src/main/res

# density : legacy ic_launcher size (48dp) : adaptive foreground size (108dp)
for spec in "mdpi:48:108" "hdpi:72:162" "xhdpi:96:216" "xxhdpi:144:324" "xxxhdpi:192:432"; do
  d=${spec%%:*}; rest=${spec#*:}; leg=${rest%%:*}; fg=${rest##*:}
  mkdir -p "$RES/mipmap-$d"
  convert "$SRC/icon_full.png"       -resize "${leg}x${leg}" -strip "$RES/mipmap-$d/ic_launcher.png"
  convert "$SRC/icon_foreground.png" -resize "${fg}x${fg}"   -strip "$RES/mipmap-$d/ic_launcher_foreground.png"
  echo "mipmap-$d: ic_launcher=${leg}px  foreground=${fg}px"
done

echo "Done — launcher icons regenerated under $RES/mipmap-*"
