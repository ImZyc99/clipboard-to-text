#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_APP="$PROJECT_DIR/build/剪贴成文.app"
TARGET_APP="$HOME/Applications/剪贴成文.app"
if [[ ! -d "$SOURCE_APP" ]]; then "$PROJECT_DIR/scripts/build.sh"; fi
mkdir -p "$HOME/Applications"
if [[ -e "$TARGET_APP" ]]; then
    # Stop only this installed app and its extensions; leave Finder itself running.
    python3 - "$TARGET_APP" <<'PY'
import os, signal, subprocess, sys
prefix = sys.argv[1] + '/Contents/'
for line in subprocess.check_output(['ps', '-axo', 'pid=,comm='], text=True).splitlines():
    parts = line.strip().split(None, 1)
    if len(parts) == 2 and parts[1].startswith(prefix):
        try: os.kill(int(parts[0]), signal.SIGTERM)
        except ProcessLookupError: pass
PY
    mkdir -p "$PROJECT_DIR/build/backups"
    BACKUP_APP="$PROJECT_DIR/build/backups/剪贴成文-$(date +%Y%m%d-%H%M%S)-$$.zip"
    ditto -c -k --sequesterRsrc --keepParent "$TARGET_APP" "$BACKUP_APP"
    /usr/bin/pluginkit -r "$TARGET_APP/Contents/PlugIns/ClipboardFinder.appex" || true
    python3 - "$TARGET_APP" <<'PY'
import shutil, sys
shutil.rmtree(sys.argv[1])
PY
    printf '旧版本已归档备份：%s\n' "$BACKUP_APP"
fi
ditto "$SOURCE_APP" "$TARGET_APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$TARGET_APP"
/usr/bin/pluginkit -a "$TARGET_APP/Contents/PlugIns/ClipboardFinder.appex"
/usr/bin/open "$TARGET_APP"
printf '已安装：%s\n请在系统设置中启用「剪贴成文」Finder 扩展。\n' "$TARGET_APP"
