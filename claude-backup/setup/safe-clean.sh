#!/usr/bin/env bash
# 안전한 빌드 산출물 정리 — rm -rf 대신 이걸 쓴다.
#
#   사용법: safe-clean.sh [경로...]      (기본값: dist build .vercel/output)
#
# 규칙 3개:
#   1. 현재 git 저장소 안에 있는 경로만 지운다 (작업폴더 탈출 차단)
#   2. 허용된 이름(dist/build/node_modules/...)만 지운다
#   3. 지우기 전에 무엇을 지우는지 출력한다
set -euo pipefail

ALLOWED='^(dist|build|out|coverage|node_modules|\.next|\.turbo|\.vercel/output|node_modules/\.vite)$'
TARGETS=("$@")
[ ${#TARGETS[@]} -eq 0 ] && TARGETS=(dist build .vercel/output)

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "✗ git 저장소 안에서만 실행할 수 있습니다." >&2; exit 1; }

for t in "${TARGETS[@]}"; do
  # 빈 값 방어 — 사고 유형 1위
  [ -z "$t" ] && { echo "✗ 빈 경로는 건너뜁니다." >&2; continue; }

  rel="${t#./}"
  if ! printf '%s' "$rel" | grep -Eq "$ALLOWED"; then
    echo "✗ 허용 목록에 없는 이름입니다: $rel (허용: dist build out coverage node_modules .next .turbo .vercel/output)" >&2
    continue
  fi

  abs=$(cd "$(dirname "$REPO_ROOT/$rel")" 2>/dev/null && pwd)/$(basename "$rel") || {
    echo "· 없음: $rel"; continue; }

  # 저장소 밖이면 거부
  case "$abs" in
    "$REPO_ROOT"/*) ;;
    *) echo "✗ 저장소 밖 경로입니다: $abs" >&2; continue ;;
  esac

  [ -e "$abs" ] || { echo "· 없음: $rel"; continue; }

  size=$(du -sh "$abs" 2>/dev/null | cut -f1)
  echo "🗑 삭제: $abs ($size)"
  rm -rf "$abs"
done

echo "완료."
