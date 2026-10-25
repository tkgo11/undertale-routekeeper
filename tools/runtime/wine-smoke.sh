#!/bin/sh
# Run inside the isolated container with only the newly prepared lab mounted.
set -eu
: "${LAB:=/lab}"
test -f "$LAB/.routekeeper-disposable-runtime-lab"
export HOME="$LAB/home" WINEARCH=win32 WINELOADERNOEXEC=1
export WINESERVER=/usr/lib/wine/wineserver64 DISPLAY=:99 WINEDEBUG=-all
mkdir -p "$HOME" "$LAB/evidence/wine"
ulimit -c 0
Xvfb :99 -screen 0 1024x768x24 > "$LAB/evidence/wine/xvfb.log" 2>&1 &
xpid=$!
trap 'kill "$xpid" 2>/dev/null || true' EXIT
# Cloud kernels can reject ELF32. QEMU + the official Wine preloader reserve
# the low PE image address instead of mapping the ELF loader over 0x400000.
# No change to UNDERTALE.exe/steam_api.dll, and no fabricated Steam ownership.
for kind in original patched; do
    export WINEPREFIX="$LAB/wine-prefix-$kind"
    test ! -e "$WINEPREFIX" || { echo "Refusing an existing Wine profile; prepare a new lab." >&2; exit 2; }
    mkdir -p "$WINEPREFIX/drive_c/windows/system32"
    cp -asn /usr/lib/i386-linux-gnu/wine/i386-windows/. "$WINEPREFIX/drive_c/windows/system32/"
    (cd "$LAB/runs/$kind" && timeout 90 qemu-i386 /usr/lib/wine/wine-preloader /usr/lib/wine/wine UNDERTALE.exe) > "$LAB/evidence/wine/$kind.log" 2>&1 || true
    scrot "$LAB/evidence/wine/$kind.png"
done
python3 - "$LAB" <<'PY'
import json,sys,hashlib
from pathlib import Path
lab=Path(sys.argv[1]);results=[]
for kind in ['original','patched']:
 text=(lab/'evidence/wine'/f'{kind}.log').read_text(errors='replace')
 reason='SteamAPI_InitSafe failed; no authorized client session' if 'SteamAPI_InitSafe() failed' in text else 'Manual review/scenario assertions required; process survival is not a PASS'
 blocked=any(s in text for s in ['SteamAPI_InitSafe() failed','could not load','Unhandled','Failed to create mainwindow'])
 root=lab/'runs'/kind
 digest=lambda name:hashlib.file_digest((root/name).open('rb'),'sha256').hexdigest()
 results.append(dict(case=kind,result='BLOCKED' if blocked else 'NOT_RUN',execution='QEMU_USER_WINE_XVFB',reason=reason,runnerSha256=digest('UNDERTALE.exe'),dataSha256=digest('data.win')))
(lab/'evidence/wine/results.json').write_text(json.dumps(results,indent=2)+'\n')
PY
