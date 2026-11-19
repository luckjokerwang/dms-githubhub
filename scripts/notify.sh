#!/usr/bin/env bash
# Desktop Notification Helper for GitHub Hub (Freedesktop Standard)
set -eo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TITLE="${1:-GitHub Hub}"
MSG="${2:-}"
URGENCY="${3:-normal}"

AVATAR="$DIR/../assets/avatar.png"
GITHUB_SVG="$DIR/../assets/github.svg"

# Priority 1: User GitHub Avatar; Priority 2: GitHub SVG Icon; Priority 3: System 'github' Icon
if [ -s "$AVATAR" ]; then
    ICON="$AVATAR"
elif [ -s "$GITHUB_SVG" ]; then
    ICON="$GITHUB_SVG"
else
    ICON="github"
fi

notify-send \
    -a "GitHub Hub" \
    -i "$ICON" \
    -u "$URGENCY" \
    -t 4000 \
    -h string:x-canonical-private-synchronous:github-hub-sync \
    "$TITLE" \
    "$MSG"
