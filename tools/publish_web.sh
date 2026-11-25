#!/bin/sh
# Maakt de webexport en zet hem in de portfoliosite (public/parkstad-racer/).
# index.wasm gaat er gecomprimeerd in (index.wasm.gz) vanwege de 25 MB-limiet van
# Cloudflare; de spelpagina pakt hem in de browser uit (zie html/head_include in
# export_presets.cfg). Met PWA: op de telefoon via Delen > Zet op beginscherm.
# Daarna zelf committen en pushen in de portfolio-repo.
set -e
cd "$(dirname "$0")/.."
GODOT="${GODOT:-/Users/cliff/Downloads/Godot.app/Contents/MacOS/Godot}"
SITE="${SITE:-$HOME/Documents/SourceCode/portfolio-website-cliffwings/public/parkstad-racer}"
mkdir -p build/web
"$GODOT" --headless --path . --export-release "Web" build/web/index.html
gzip -9 -n -k -f build/web/index.wasm
# Over het hele scherm, ook langs de Dynamic Island van de iPhone (anders zwarte balken
# links en rechts); het spel houdt de knoppen zelf binnen het veilige gebied.
sed -i '' 's/initial-scale=1\.0">/initial-scale=1.0, viewport-fit=cover">/' build/web/index.html
grep -q 'viewport-fit=cover' build/web/index.html
# PWA-aanpassingen voor de portfoliosite:
#  - de service worker bewaart de gecomprimeerde wasm (die vraagt de pagina op);
#  - Cloudflare stuurt index.html door naar ./ en geeft geen losse HTML-bestanden, dus
#    de pagina heet ./ (ook als start_url) en de offlinepagina gaat er niet in.
SW=build/web/index.service.worker.js
sed -i '' -e 's/"index\.wasm"/"index.wasm.gz"/' -e 's/"index\.html"/".\/"/' -e 's/"index\.offline\.html",//' "$SW"
sed -i '' 's/"start_url":"\.\/index\.html"/"start_url":".\/"/' build/web/index.manifest.json
grep -q '"index.wasm.gz"' "$SW" && grep -q 'CACHED_FILES = \["\./"' "$SW" && ! grep -q '"index.offline.html"' "$SW"
grep -q '"start_url":"\./"' build/web/index.manifest.json
# Android/Chrome wil voor "App installeren" ook een icoon van 192 px (Godot maakt 144, 180
# en 512); het installatiebalkje toont hem ook. Plus een korte naam onder het icoon.
sips -z 192 192 build/web/index.512x512.png --out build/web/index.192x192.png >/dev/null
python3 - build/web/index.manifest.json <<'PY'
import json, sys
p = sys.argv[1]
m = json.load(open(p))
if not any(i.get("sizes") == "192x192" for i in m["icons"]):
    m["icons"].append({"sizes": "192x192", "src": "index.192x192.png", "type": "image/png", "purpose": "any"})
m["short_name"] = "Parkstad Racer"
m["id"] = "./"
json.dump(m, open(p, "w"), separators=(",", ":"))
PY
grep -q '"192x192"' build/web/index.manifest.json
rm -f build/web/index.offline.html
mkdir -p "$SITE"
for f in build/web/*; do
	[ "$(basename "$f")" = "index.wasm" ] && continue
	cp "$f" "$SITE/"
done
ls -la "$SITE"
