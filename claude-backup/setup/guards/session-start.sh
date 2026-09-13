#!/usr/bin/env bash
# SessionStart guard — 원격 저장소 없는 폴더에서 작업이 시작되는 것을 잡아낸다.
# 2026-09 별점/별핑계 소실의 직접 원인이 "로컬에만 있던 저장소"였다.
set -uo pipefail

warn() { jq -n --arg m "$1" '{systemMessage:$m}'; exit 0; }

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  warn "⚠ 이 폴더는 git 저장소가 아닙니다. 코드를 만들기 전에 new-project.sh 로 저장소부터 만드세요."
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  warn "🔴 origin 원격이 없습니다. 이 상태로 작업하면 PC가 날아갈 때 코드도 같이 사라집니다 (2026-09 사고와 동일). 지금 바로: gh repo create <name> --private --source=. --remote=origin --push"
fi

# 원격은 있는데 한참 안 올린 경우
upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
if [ -z "$upstream" ]; then
  warn "⚠ 현재 브랜치에 upstream이 없습니다. git push -u origin \$(git branch --show-current) 로 연결하세요."
fi

ahead=$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
last_push_days=$(( ( $(date +%s) - $(git log -1 --format=%ct "$upstream" 2>/dev/null || date +%s) ) / 86400 ))

if [ "$ahead" -gt 0 ] || [ "$last_push_days" -gt 2 ]; then
  warn "⚠ 원격에 안 올라간 커밋 ${ahead}개 · 마지막 푸시 ${last_push_days}일 전. 작업 시작 전에 정리하세요."
fi

exit 0
