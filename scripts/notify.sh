#!/usr/bin/env bash
# Desktop Notification Helper for GitHub Hub (DMS Native + Freedesktop Fallback)
set -eo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TITLE="${1:-GitHub Hub}"
MSG="${2:-}"
URGENCY="${3:-normal}"

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dms-githubhub"
AVATAR="$CACHE_DIR/avatar.png"
GITHUB_SVG="$DIR/../assets/github.svg"

# Priority 1: User GitHub Avatar (from cache); Priority 2: GitHub SVG Icon; Priority 3: System 'github' Icon
if [ -s "$AVATAR" ]; then
    ICON="$AVATAR"
elif [ -s "$GITHUB_SVG" ]; then
    ICON="$GITHUB_SVG"
else
    ICON="github"
fi

if command -v dms >/dev/null 2>&1; then
    dms notify \
        -a "GitHub Hub" \
        -n "github" \
        -i "$ICON" \
        -u "$URGENCY" \
        -t 4000 \
        "$TITLE" \
        "$MSG"
elif command -v notify-send >/dev/null 2>&1; then
    notify-send \
        -a "GitHub Hub" \
        -i "$ICON" \
        -u "$URGENCY" \
        -t 4000 \
        -h string:x-canonical-private-synchronous:github-hub-sync \
        "$TITLE" \
        "$MSG"
fi
