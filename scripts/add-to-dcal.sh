#!/usr/bin/env bash
# Add an issue or PR to dcal tasks
set -eo pipefail

SUMMARY="${1:-}"
URL="${2:-}"

if [ -z "$SUMMARY" ]; then
    echo "Summary is required"
    exit 1
fi

notify() {
    local title="$1"
    local msg="$2"
    local urg="${3:-normal}"
    if command -v dms >/dev/null 2>&1; then
        dms notify -a "GitHub Hub" -u "$urg" -t 3000 "$title" "$msg"
    elif command -v notify-send >/dev/null 2>&1; then
        notify-send -a "GitHub Hub" -u "$urg" -t 3000 "$title" "$msg"
    fi
}

if ! command -v dcal >/dev/null 2>&1; then
    notify "添加失败" "未找到 dcal 命令行工具" "low"
    exit 1
fi

# Find the default task calendar ID
cal_id=$(dcal ipc calendars.list 2>/dev/null | jq -r '[.[] | select(.holdsTasks == true)][0].id // ""')

if [ -z "$cal_id" ]; then
    notify "添加失败" "未找到支持任务的日历" "low"
    exit 1
fi

dcal ipc tasks.create \
  calendarId="$cal_id" \
  summary="$SUMMARY" \
  description="来源: $URL" \
  status="needs_action" >/dev/null 2>&1

notify "已加入待办" "$SUMMARY" "normal"
echo "ok"
