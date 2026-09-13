#!/usr/bin/env bash
# 일일 백업 — 하루 끝에 한 번 돌린다. cron/작업스케줄러 등록 권장.
#
#   1. 모든 프로젝트의 미푸시 커밋을 원격에 올린다
#   2. 커밋조차 안 된 변경은 경고한다 (임의 커밋하지 않음)
#   3. Claude Code 대화 기록(~/.claude/projects/*.jsonl)을 클라우드 동기화 폴더에 보존
#
# 3번이 중요한 이유: 2026-09 사고 때 로컬 트랜스크립트가 PC와 함께 사라져
# 대화에 남아있던 코드를 되찾을 방법이 없었다.
set -uo pipefail

ROOT="${PROJECTS_ROOT:-$HOME/projects}"
# Windows+WSL이면 OneDrive/Google Drive 동기화 폴더를 가리키게 한다
ARCHIVE="${CLAUDE_ARCHIVE_DIR:-$HOME/cloud-sync/claude-archive}"
TODAY=$(date +%Y-%m-%d)

mkdir -p "$ARCHIVE"

echo "════ 일일 백업 $TODAY ════"
dirty_repos=()
pushed=0

# ── 1·2. 프로젝트 푸시 ──
while IFS= read -r gitdir; do
  repo=$(dirname "$gitdir")
  name=$(basename "$repo")
  cd "$repo" || continue

  if ! git remote get-url origin >/dev/null 2>&1; then
    echo "🔴 $name — origin 없음! 지금 만드세요: gh repo create $name --private --source=. --remote=origin --push"
    continue
  fi

  if [ -n "$(git status --porcelain)" ]; then
    dirty_repos+=("$name")
  fi

  branch=$(git branch --show-current 2>/dev/null || echo "")
  [ -z "$branch" ] && continue

  if ! git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    git push -u origin "$branch" >/dev/null 2>&1 && { echo "⬆ $name ($branch) upstream 연결+푸시"; pushed=$((pushed+1)); }
    continue
  fi

  ahead=$(git rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
  if [ "$ahead" -gt 0 ]; then
    if git push >/dev/null 2>&1; then
      echo "⬆ $name ($branch) 커밋 ${ahead}개 푸시"
      pushed=$((pushed+1))
    else
      echo "✗ $name 푸시 실패 — 수동 확인 필요"
    fi
  fi
done < <(find "$ROOT" -maxdepth 3 -name .git -type d 2>/dev/null)

echo "── 푸시된 저장소: ${pushed}개"

if [ ${#dirty_repos[@]} -gt 0 ]; then
  echo "⚠ 커밋 안 된 변경이 남은 저장소: ${dirty_repos[*]}"
  echo "  (자동 커밋하지 않습니다. 직접 확인 후 커밋하세요.)"
fi

# ── 3. Claude Code 자산 보존 ──
if [ -d "$HOME/.claude" ]; then
  tar czf "$ARCHIVE/claude-home-$TODAY.tar.gz" \
    -C "$HOME" \
    --exclude='.claude/plugins/cache' \
    --exclude='.claude/*.old' \
    .claude 2>/dev/null
  echo "💾 ~/.claude 보존: $ARCHIVE/claude-home-$TODAY.tar.gz ($(du -h "$ARCHIVE/claude-home-$TODAY.tar.gz" | cut -f1))"
fi

# 30일 넘은 아카이브 정리 (클라우드 용량 보호)
find "$ARCHIVE" -name 'claude-home-*.tar.gz' -mtime +30 -delete 2>/dev/null

echo "════ 완료 ════"
