#!/bin/bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_APP="$PROJECT_DIR/build/剪贴成文.app"
TARGET_APP="$HOME/Applications/剪贴成文.app"
if [[ ! -d "$SOURCE_APP" ]]; then "$PROJECT_DIR/scripts/build.sh"; fi
mkdir -p "$HOME/Applications"
if [[ -e "$TARGET_APP" ]]; then
    BACKUP_APP="$HOME/Applications/剪贴成文-backup-$(date +%Y%m%d-%H%M%S).app"
    mv "$TARGET_APP" "$BACKUP_APP"
    printf '旧版本已备份：%s\n' "$BACKUP_APP"
fi
ditto "$SOURCE_APP" "$TARGET_APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$TARGET_APP"
/usr/bin/pluginkit -a "$TARGET_APP/Contents/PlugIns/ClipboardFinder.appex"
/usr/bin/open "$TARGET_APP"
printf '已安装：%s\n请在系统设置中启用「剪贴成文」Finder 扩展。\n' "$TARGET_APP"
