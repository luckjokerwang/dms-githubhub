#!/usr/bin/env bash
# GitHub Hub Contributions Fetcher (GraphQL Official API + Public Fallback)
set -eo pipefail

GITHUB_USERNAME="${1:-}"

if [ -z "$GITHUB_USERNAME" ]; then
    printf '{"contributions":[],"gridData":[],"total":0,"error":true,"errorMessage":"Username required"}\n'
    exit 0
fi

# ==============================================================================
# Method 1: GitHub CLI GraphQL (Zero Cache Lag, Official)
# ==============================================================================
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    query='query($userName: String!) {
      user(login: $userName) {
        contributionsCollection {
          contributionCalendar {
            totalContributions
            weeks {
              contributionDays {
                contributionCount
                date
                weekday
                contributionLevel
              }
            }
          }
        }
      }
    }'

    gh_res=$(timeout 6s gh api graphql -f query="$query" -f userName="$GITHUB_USERNAME" 2>/dev/null || echo "")

    if [ -n "$gh_res" ] && echo "$gh_res" | jq -e ".data.user.contributionsCollection.contributionCalendar.weeks" >/dev/null 2>&1; then
        echo "$gh_res" | jq -c '
          ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"] as $wnames |
          def lvl_num: if . == "FIRST_QUARTILE" then 1 elif . == "SECOND_QUARTILE" then 2 elif . == "THIRD_QUARTILE" then 3 elif . == "FOURTH_QUARTILE" then 4 else 0 end;
          
          .data.user.contributionsCollection.contributionCalendar.weeks[-8:] |
          map(
            .contributionDays | map({
              date: .date,
              weekday: .weekday,
              weekdayName: $wnames[.weekday],
              formattedDate: (.date[5:7] + "/" + .date[8:10]),
              count: .contributionCount,
              level: (.contributionLevel | lvl_num)
            })
          ) as $grid |
          ($grid | [.[][]]) as $all_days |
          {
            contributions: $all_days[-7:],
            gridData: $grid,
            total: ($all_days | map(.count) | add),
            error: false
          }
        '
        exit 0
    fi
fi

# ==============================================================================
# Method 2: Public API Fallback (jogruber.de, when unauthenticated)
# ==============================================================================
url="https://github-contributions-api.jogruber.de/v4/$GITHUB_USERNAME?y=last"
temp_response=$(mktemp)
http_code=$(curl -s --max-time 8 -w "%{http_code}" -o "$temp_response" "$url" || echo "000")

if [ "$http_code" != "200" ]; then
    rm -f "$temp_response"
    printf '{"contributions":[],"gridData":[],"total":0,"error":true,"errorMessage":"User not found or API error (HTTP %s)"}\n' "$http_code"
    exit 0
fi

jq -c '
  ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"] as $wnames |
  [.contributions[]? | select((.count | type == "number") and (.date | type == "string"))] as $all |
  if ($all | length) == 0 then
    {contributions: [], gridData: [], total: 0, error: true, errorMessage: "No contribution data found"}
  else
    ($all[-1].date | strptime("%Y-%m-%d") | strftime("%w") | tonumber) as $last_w |
    (49 + $last_w + 1) as $total_count |
    ($all[-$total_count:] | map(
      (.date | strptime("%Y-%m-%d")) as $tm |
      ($tm | strftime("%w") | tonumber) as $w |
      {
        date: .date,
        weekday: $w,
        weekdayName: $wnames[$w],
        formattedDate: (.date[5:7] + "/" + .date[8:10]),
        count: .count,
        level: (if .level >= 0 and .level <= 4 then .level else 0 end)
      }
    )) as $days |
    ([range(0; 49; 7) as $i | $days[$i:$i+7]] + (if ($days | length) > 49 then [$days[49:]] else [] end)) as $grid |
    {
      contributions: $days[-7:],
      gridData: $grid,
      total: ($days | map(.count) | add),
      error: false
    }
  end
' "$temp_response"

rm -f "$temp_response"
exit 0
