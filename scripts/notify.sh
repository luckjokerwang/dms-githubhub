#!/usr/bin/env bash
# Desktop Notification Helper for GitHub Hub (DMS Native + Freedesktop Fallback)
set -eo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TITLE="${1:-GitHub Hub}"
MSG="${2:-}"
URGENCY="${3:-normal}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dms-githubhub"
AVATAR="$CACHE_DIR/avatar.png"
ICON_PNG="$DIR/../assets/icon.png"
GITHUB_SVG="$DIR/../assets/github.svg"

APP_ICON="$GITHUB_SVG"
if [ -s "$ICON_PNG" ]; then
    APP_ICON="$ICON_PNG"
fi

if [ -s "$AVATAR" ]; then
    CONTENT_IMG="$AVATAR"
else
    CONTENT_IMG="$APP_ICON"
fi

if command -v dms >/dev/null 2>&1; then
    dms notify \
        -a "GitHub Hub" \
        -n "$APP_ICON" \
        -i "$CONTENT_IMG" \
        -u "$URGENCY" \
        -t 4000 \
        "$TITLE" \
        "$MSG"
elif command -v notify-send >/dev/null 2>&1; then
    notify-send \
        -a "GitHub Hub" \
        -i "$APP_ICON" \
        -u "$URGENCY" \
        -t 4000 \
        -h string:x-canonical-private-synchronous:github-hub-sync \
        "$TITLE" \
        "$MSG"
fi
