#!/usr/bin/env bash
# GitHub Heatmap Fetcher (GraphQL Official API + Public API Fallback)
set -eo pipefail

GITHUB_USERNAME="${1:-}"

if [ -z "$GITHUB_USERNAME" ]; then
    printf '{"contributions":[],"gridData":[],"total":0,"error":true,"errorMessage":"Username is empty"}\n'
    exit 0
fi

# ==============================================================================
# Method 1: GitHub Official GraphQL API (High priority, 100% Real-time, Zero-Cache)
# ==============================================================================
if command -v gh >/dev/null 2>&1; then
    query='query($userName:String!) {
      user(login: $userName){
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
          def lvl_col: if . == 1 then "#0e4429" elif . == 2 then "#006d32" elif . == 3 then "#26a641" elif . == 4 then "#39d353" else "#202329" end;
          
          .data.user.contributionsCollection.contributionCalendar.weeks[-8:] |
          map(
            .contributionDays | map({
              date: .date,
              weekday: .weekday,
              weekdayName: $wnames[.weekday],
              formattedDate: (.date[5:7] + "/" + .date[8:10]),
              count: .contributionCount,
              level: (.contributionLevel | lvl_num),
              color: ((.contributionLevel | lvl_num) | lvl_col)
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
# Method 2: Public API Fallback (jogruber.de, when not authenticated with gh)
# ==============================================================================
COLOR_0="#202329"
COLOR_1="#0e4429"
COLOR_2="#006d32"
COLOR_3="#26a641"
COLOR_4="#39d353"

today=$(date +%Y-%m-%d)
today_dow=$(date -d "$today" +%u)

if [ "$today_dow" = "7" ]; then
    current_sunday="$today"
else
    current_sunday=$(date -d "$today -$today_dow days" +%Y-%m-%d)
fi

start_date=$(date -d "$current_sunday -49 days" +%Y-%m-%d)
today_timestamp=$(date -d "$today" +%s)

url="https://github-contributions-api.jogruber.de/v4/$GITHUB_USERNAME?y=last"

temp_response=$(mktemp)
http_code=$(curl -s --max-time 8 -w "%{http_code}" -o "$temp_response" "$url" || echo "000")

if [ "$http_code" != "200" ]; then
    rm -f "$temp_response"
    printf '{"contributions":[],"gridData":[],"total":0,"error":true,"errorMessage":"User not found or API error (HTTP %s)"}\n' "$http_code"
    exit 0
fi

body=$(cat "$temp_response")
rm -f "$temp_response"

# Filter relevant days
relevant_days=$(echo "$body" | jq -c --arg start "$start_date" '.contributions[]? | select(.date >= $start)')

total_contributions=0
all_days=()

while IFS= read -r day_json; do
    if [ -z "$day_json" ]; then continue; fi

    date=$(echo "$day_json" | jq -r '.date')
    count=$(echo "$day_json" | jq -r '.count')
    level=$(echo "$day_json" | jq -r '.level')

    day_timestamp=$(date -d "$date" +%s)

    if [ "$day_timestamp" -le "$today_timestamp" ]; then
        case "$level" in
            0) color="$COLOR_0" ;;
            1) color="$COLOR_1" ;;
            2) color="$COLOR_2" ;;
            3) color="$COLOR_3" ;;
            4) color="$COLOR_4" ;;
            *) color="$COLOR_0" ;;
        esac

        total_contributions=$((total_contributions + count))
        weekday=$(date -d "$date" +%w)
        formatted_date=$(date -d "$date" +%m/%d)
        weekday_names=("Sun" "Mon" "Tue" "Wed" "Thu" "Fri" "Sat")
        weekday_name="${weekday_names[$weekday]}"

        all_days+=("$date|$weekday|$count|$color|$formatted_date|$weekday_name|$level")
    fi
done <<< "$relevant_days"

if [ ${#all_days[@]} -eq 0 ]; then
    printf '{"contributions":[],"gridData":[],"total":0,"error":true,"errorMessage":"No contribution data found"}\n'
    exit 0
fi

IFS=$'\n' sorted_days=($(sort <<<"${all_days[*]}"))
unset IFS

grid_json="["
current_week="["
first_week=1
first_day_in_week=1

for day_data in "${sorted_days[@]}"; do
    IFS='|' read -r date weekday count color formatted_date weekday_name level <<< "$day_data"

    if [ "$weekday" == "0" ] && [ "$first_day_in_week" == "0" ]; then
        current_week="$current_week]"
        if [ "$first_week" == "1" ]; then
            grid_json="$grid_json$current_week"
            first_week=0
        else
            grid_json="$grid_json,$current_week"
        fi
        current_week="["
        first_day_in_week=1
    fi

    day_obj="{\"date\":\"$date\",\"weekday\":$weekday,\"weekdayName\":\"$weekday_name\",\"formattedDate\":\"$formatted_date\",\"count\":$count,\"color\":\"$color\",\"level\":${level:-0}}"

    if [ "$first_day_in_week" == "1" ]; then
        current_week="$current_week$day_obj"
        first_day_in_week=0
    else
        current_week="$current_week,$day_obj"
    fi
done

current_week="$current_week]"
if [ "$first_week" == "1" ]; then
    grid_json="$grid_json$current_week"
else
    grid_json="$grid_json,$current_week"
fi
grid_json="$grid_json]"

# Build 7-day pill
day_count=${#sorted_days[@]}
pill_start=$((day_count - 7))
if [ $pill_start -lt 0 ]; then pill_start=0; fi

pill_json="["
pill_count=0

for (( i=pill_start; i<day_count; i++ )); do
    day_data="${sorted_days[$i]}"
    IFS='|' read -r date weekday count color formatted_date weekday_name level <<< "$day_data"

    if [ $pill_count -gt 0 ]; then
        pill_json="$pill_json,"
    fi
    pill_json="$pill_json{\"date\":\"$date\",\"weekday\":$weekday,\"weekdayName\":\"$weekday_name\",\"formattedDate\":\"$formatted_date\",\"count\":$count,\"color\":\"$color\",\"level\":${level:-0}}"
    pill_count=$((pill_count + 1))
done
pill_json="$pill_json]"

printf '{"contributions":%s,"gridData":%s,"total":%d,"error":false}\n' "$pill_json" "$grid_json" "$total_contributions"
