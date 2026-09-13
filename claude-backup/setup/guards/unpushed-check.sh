#!/usr/bin/env bash
# Stop 훅 — 턴이 끝날 때마다 "아직 원격에 없는 작업"을 알려준다.
# 일일 푸시를 기억에 의존하지 않게 만드는 장치.
set -uo pipefail

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

dirty=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
ahead=$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)

[ "$dirty" -eq 0 ] && [ "$ahead" -eq 0 ] && exit 0

msg="📌 원격에 없는 작업: 미커밋 ${dirty}개 파일"
[ "$ahead" -gt 0 ] && msg="${msg} · 미푸시 커밋 ${ahead}개"
msg="${msg} — 자리 뜨기 전에 git push 하세요."

jq -n --arg m "$msg" '{systemMessage:$m}'
exit 0
