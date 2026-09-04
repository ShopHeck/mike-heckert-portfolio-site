#!/usr/bin/env bash
# Regenerate responsive AVIF + WebP variants for every raster asset.
# Requires ImageMagick with libwebp + AVIF delegates (`identify -list format`).
set -euo pipefail
cd "$(dirname "$0")/.."
OUT=assets/gen
mkdir -p "$OUT"

# name|variant widths (space separated), capped at source width by the loop
IMAGES="
fight-clearwater-punch.jpg|480 720 1000 1400
fight-clearwater-raised-hand.jpg|480 720 1000 1400
fight-clearwater-victory.jpg|480 720 1000 1400
fight-clearwater-walkout.jpg|480 720 1000 1400
media-bkfc-clearwater4-poster.png|480 720 1000 1400
media-cfn-walkout.jpg|480 720 1000 1400
media-fight-night-key-art.jpg|480 720 1000 1400
media-king-killer-arena.jpg|480 720 1000 1400
media-king-killers-portrait.jpg|480 720 1000 1400
media-sponsor-shirt.jpg|480 720 1000 1400
sponsor-1tom-plumber.png|120 240
sponsor-bluefitmd.png|120 240
sponsor-ufc-gym.png|120 240
sponsor-vitality-wellness.png|120 240
"

echo "$IMAGES" | while IFS='|' read -r src widths; do
  [ -z "$src" ] && continue
  base="${src%.*}"
  sw=$(identify -format '%w' "assets/$src")
  for w in $widths; do
    [ "$w" -gt "$sw" ] && continue
    convert "assets/$src" -resize "${w}x" -quality 80 -define webp:method=6 \
      "$OUT/$base-${w}w.webp"
    convert "assets/$src" -resize "${w}x" -quality 60 \
      "$OUT/$base-${w}w.avif"
  done
  echo "  $src -> $base-{..}w.{avif,webp}"
done
