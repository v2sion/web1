#!/usr/bin/env bash
# Git에 안 올라가는 설정·시크릿을 암호화해서 클라우드에 보존한다.
#
#   secrets-backup.sh          백업 생성
#   secrets-backup.sh restore <파일.gpg>   복원
#
# 대상: 각 프로젝트의 .env* / ~/.gitconfig / ~/.ssh / ~/.claude/settings.json 등
# 암호는 비밀번호 관리자에 따로 보관할 것. 암호를 잃으면 복호화가 불가능하다.
set -euo pipefail

ROOT="${PROJECTS_ROOT:-$HOME/projects}"
ARCHIVE="${CLAUDE_ARCHIVE_DIR:-$HOME/cloud-sync/claude-archive}"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT

command -v gpg >/dev/null 2>&1 || { echo "✗ gpg가 필요합니다: sudo apt-get install -y gnupg" >&2; exit 1; }

# ── 복원 모드 ──
if [ "${1:-}" = "restore" ]; then
  SRC="${2:?복원할 .gpg 파일 경로를 지정하세요}"
  OUT="$HOME/secrets-restored-$(date +%Y%m%d%H%M%S)"
  mkdir -p "$OUT"
  gpg --decrypt "$SRC" | tar xz -C "$OUT"
  echo "✓ 복원 위치: $OUT"
  echo "  내용을 확인한 뒤 직접 제자리에 옮기세요 (자동으로 덮어쓰지 않습니다)."
  exit 0
fi

# ── 백업 모드 ──
mkdir -p "$ARCHIVE" "$STAGE/env" "$STAGE/home"

echo "수집 중…"

# 1. 프로젝트별 .env
count=0
while IFS= read -r f; do
  repo=$(basename "$(dirname "$f")")
  mkdir -p "$STAGE/env/$repo"
  cp "$f" "$STAGE/env/$repo/$(basename "$f")"
  count=$((count+1))
done < <(find "$ROOT" -maxdepth 3 -name '.env' -o -maxdepth 3 -name '.env.*' 2>/dev/null | grep -v '\.env\.example$')
echo "  .env 계열: ${count}개"

# 2. 홈 설정
for p in .gitconfig .npmrc .claude/settings.json .config/gh/hosts.yml; do
  [ -f "$HOME/$p" ] || continue
  mkdir -p "$STAGE/home/$(dirname "$p")"
  cp "$HOME/$p" "$STAGE/home/$p"
  echo "  $p"
done

# 3. SSH 키
if [ -d "$HOME/.ssh" ]; then
  cp -r "$HOME/.ssh" "$STAGE/home/.ssh"
  echo "  .ssh/ (키 $(find "$HOME/.ssh" -name 'id_*' ! -name '*.pub' 2>/dev/null | wc -l | tr -d ' ')개)"
fi

# 4. Vercel 프로젝트 연결 정보 (재배포 시 필요)
while IFS= read -r f; do
  repo=$(basename "$(dirname "$(dirname "$f")")")
  mkdir -p "$STAGE/env/$repo"
  cp "$f" "$STAGE/env/$repo/vercel-project.json"
done < <(find "$ROOT" -maxdepth 4 -path '*/.vercel/project.json' 2>/dev/null)

OUT="$ARCHIVE/secrets-$(date +%Y-%m-%d).tar.gz.gpg"
tar cz -C "$STAGE" . | gpg --symmetric --cipher-algo AES256 --output "$OUT"

chmod 600 "$OUT"
echo
echo "✓ 암호화 백업: $OUT ($(du -h "$OUT" | cut -f1))"
echo "  암호를 비밀번호 관리자에 저장하세요. 잃어버리면 복호화할 수 없습니다."
echo "  복원: secrets-backup.sh restore \"$OUT\""
