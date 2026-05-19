#!/usr/bin/env bash
# uptime-badge — generate a shields.io-style SVG uptime badge for any URL.
# Self-hosted, no external services. Drop the SVG anywhere.
#
#   bash uptime-badge.sh https://example.com           # checks 5 times → svg to stdout
#   bash uptime-badge.sh https://example.com out.svg   # saves to file
#   bash uptime-badge.sh https://example.com out.svg --checks 10
#
set -u
VERSION="1.0.0"

URL="${1:-}"
OUT="${2:-/dev/stdout}"
CHECKS=5
while [ $# -gt 0 ]; do
    case "$1" in
        --checks) CHECKS="${2:-5}"; shift ;;
    esac
    shift
done

[ -z "$URL" ] && {
    cat <<USAGE
uptime-badge v$VERSION
  bash uptime-badge.sh <url> [out.svg] [--checks N]

Examples:
  bash uptime-badge.sh https://example.com
  bash uptime-badge.sh https://example.com badge.svg --checks 20
USAGE
    exit 1
}

# Run N checks, count successes
OK=0
TOTAL_MS=0
for i in $(seq 1 "$CHECKS"); do
    OUT_TIMING=$(curl -fsS -o /dev/null --max-time 6 \
                 -w '%{http_code} %{time_total}' "$URL" 2>/dev/null || echo "0 0")
    CODE=$(echo "$OUT_TIMING" | awk '{print $1}')
    T=$(echo "$OUT_TIMING"    | awk '{print $2}')
    if [ "${CODE:0:1}" = "2" ] || [ "${CODE:0:1}" = "3" ]; then
        OK=$((OK + 1))
        MS=$(awk -v t="$T" 'BEGIN{printf "%d", t*1000}')
        TOTAL_MS=$((TOTAL_MS + MS))
    fi
done

PCT=$(awk -v o="$OK" -v c="$CHECKS" 'BEGIN{printf "%.1f", (o/c)*100}')
if [ "$OK" -gt 0 ]; then
    AVG_MS=$((TOTAL_MS / OK))
else
    AVG_MS=0
fi

# Color thresholds
if (( $(awk -v p="$PCT" 'BEGIN{print (p>=99)}') )); then COL="#4c1"
elif (( $(awk -v p="$PCT" 'BEGIN{print (p>=95)}') )); then COL="#97CA00"
elif (( $(awk -v p="$PCT" 'BEGIN{print (p>=80)}') )); then COL="#dfb317"
elif (( $(awk -v p="$PCT" 'BEGIN{print (p>=50)}') )); then COL="#fe7d37"
else COL="#e05d44"; fi

LABEL="uptime"
VALUE="${PCT}%"

# Calculate widths (rough monospace approximation)
LABEL_W=$(( ${#LABEL} * 7 + 12 ))
VALUE_W=$(( ${#VALUE} * 7 + 12 ))
TOTAL_W=$(( LABEL_W + VALUE_W ))
LABEL_TX=$(( LABEL_W * 10 / 2 ))
VALUE_TX=$(( LABEL_W * 10 + VALUE_W * 10 / 2 ))

cat > "$OUT" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="$TOTAL_W" height="20" role="img" aria-label="$LABEL: $VALUE">
  <title>$LABEL: $VALUE</title>
  <linearGradient id="s" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <clipPath id="r"><rect width="$TOTAL_W" height="20" rx="3" fill="#fff"/></clipPath>
  <g clip-path="url(#r)">
    <rect width="$LABEL_W" height="20" fill="#555"/>
    <rect x="$LABEL_W" width="$VALUE_W" height="20" fill="$COL"/>
    <rect width="$TOTAL_W" height="20" fill="url(#s)"/>
  </g>
  <g fill="#fff" text-anchor="middle"
     font-family="Verdana,Geneva,DejaVu Sans,sans-serif"
     text-rendering="geometricPrecision" font-size="110">
    <text aria-hidden="true" x="$LABEL_TX" y="150" fill="#010101" fill-opacity=".3"
          transform="scale(.1)" textLength="$((LABEL_W*10 - 100))">$LABEL</text>
    <text x="$LABEL_TX" y="140" transform="scale(.1)" fill="#fff"
          textLength="$((LABEL_W*10 - 100))">$LABEL</text>
    <text aria-hidden="true" x="$VALUE_TX" y="150" fill="#010101" fill-opacity=".3"
          transform="scale(.1)" textLength="$((VALUE_W*10 - 100))">$VALUE</text>
    <text x="$VALUE_TX" y="140" transform="scale(.1)" fill="#fff"
          textLength="$((VALUE_W*10 - 100))">$VALUE</text>
  </g>
</svg>
SVG

if [ "$OUT" != "/dev/stdout" ]; then
    printf 'uptime-badge: %s — %s%% (%d/%d ok, avg %dms)  →  %s\n' \
        "$URL" "$PCT" "$OK" "$CHECKS" "$AVG_MS" "$OUT" >&2
fi
