#!/bin/sh
# Laatste probleemrapporten van het spel lezen (zie /report in server/src/index.js).
# Gebruik: tools/reports.sh [aantal]   (standaard 20)
# De leessleutel staat in server/.report_key (niet in git); op de server als geheim REPORT_KEY.
set -e
cd "$(dirname "$0")/.."
KEY=$(cat server/.report_key)
SERVER="${PARKSTAD_SERVER:-https://parkstad-racer-mp.cliffwings.workers.dev}"
curl -s -H "Authorization: Bearer $KEY" "$SERVER/reports?n=${1:-20}" | python3 -c '
import json, sys
rows = json.load(sys.stdin)
for r in reversed(rows):
    print("=" * 78)
    print("#%s  %s  %s  (%s)" % (r.get("id"), r.get("time", "")[:19].replace("T", " "), r.get("kind"), r.get("country", "")))
    if r.get("note"):
        print("  opmerking:", r["note"])
    print("  waar:     %s (al %ss), %ss na openen, versie %s" % (r.get("stage"), r.get("stage_s"), r.get("uptime_s"), r.get("version")))
    print("  apparaat: %s" % r.get("ua"))
    print("  chip:     %s | scherm %s (venster %s, x%s) | geheugen %s GB, %s kernen | beginscherm %s | %s fps" % (
        r.get("gpu"), r.get("screen"), r.get("window"), r.get("dpr"), r.get("memory_gb"), r.get("cores"), r.get("standalone"), r.get("fps")))
    for line in r.get("log", [])[-15:]:
        print("   ", line)
'
