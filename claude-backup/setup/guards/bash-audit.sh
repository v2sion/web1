#!/usr/bin/env bash
# PreToolUse(Bash) 감사 로그 — 사고 발생 시 "무슨 명령이 언제 돌았는가"를 남긴다.
# Windows 그룹정책 로깅(가이드 5번)의 WSL 쪽 대응물.
set -uo pipefail

LOG="${HOME}/.claude/bash-audit.log"
mkdir -p "$(dirname "$LOG")"

payload=$(cat)
printf '%s' "$payload" | jq -r '
  [ (now | strftime("%Y-%m-%dT%H:%M:%S")),
    (.session_id // "-"),
    (.cwd // "-"),
    (.tool_input.command // "-" | gsub("\n"; " ⏎ "))
  ] | @tsv
' >> "$LOG" 2>/dev/null || true

# 로그가 50MB를 넘으면 회전
if [ -f "$LOG" ] && [ "$(wc -c < "$LOG")" -gt 52428800 ]; then
  mv "$LOG" "${LOG}.$(date +%Y%m%d).old"
fi

exit 0
