#!/usr/bin/env bash
set -eo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== 1. Testing fetch-contributions.sh ==="
test_user="${1:-torvalds}"
res_contrib=$("$DIR/scripts/fetch-contributions.sh" "$test_user")
echo "$res_contrib" | jq -e '.error == false and .total > 0 and (.contributions | length) == 7 and (.gridData | length) == 8' >/dev/null
echo "✓ Heatmap data parsed successfully (7-day pill + 8-week grid)"

echo "=== 2. Testing fetch-github-data.sh (Authenticated) ==="
res_gh=$("$DIR/scripts/fetch-github-data.sh")
echo "$res_gh" | jq -e '.authenticated == true and (.user.login | length) > 0' >/dev/null
echo "✓ GitHub user & activity data parsed successfully"

echo "=== 3. Testing fetch-github-data.sh (Graceful fallback) ==="
res_gh_fake=$(GH_CONFIG_DIR="/tmp/fakegh" "$DIR/scripts/fetch-github-data.sh")
echo "$res_gh_fake" | jq -e '.authenticated == false and .reason == "not_logged_in"' >/dev/null
echo "✓ Fallback mode returned valid unauthenticated payload"

echo "All backend tests passed!"
