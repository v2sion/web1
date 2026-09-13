#!/usr/bin/env bash
# WSL2(Ubuntu) 안에서 1회 실행 — Claude Code 작업 환경을 통째로 세팅한다.
#
#   bash ~/web1/claude-backup/setup/setup-wsl.sh
#
# 하는 일: 필수 도구 설치 → 가드 훅 배치 → settings.json 설치 →
#          프로젝트 루트 생성 → 일일 백업 cron 등록
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECTS_ROOT="${PROJECTS_ROOT:-$HOME/projects}"

say() { printf '\n\033[36m▶ %s\033[0m\n' "$1"; }
ok()  { printf '  \033[32m✓\033[0m %s\n' "$1"; }

# ── 1. 필수 도구 ──
say "필수 도구 확인"
missing=()
for c in git jq curl node; do command -v "$c" >/dev/null 2>&1 || missing+=("$c"); done
if [ ${#missing[@]} -gt 0 ]; then
  echo "  설치 필요: ${missing[*]}"
  sudo apt-get update -qq && sudo apt-get install -y git jq curl
  command -v node >/dev/null 2>&1 || {
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
  }
fi
ok "git / jq / curl / node"

command -v gh >/dev/null 2>&1 || {
  say "GitHub CLI 설치"
  sudo apt-get install -y gh 2>/dev/null || {
    echo "  수동 설치 필요: https://cli.github.com"
  }
}
command -v gh >/dev/null 2>&1 && ok "gh CLI"

command -v claude >/dev/null 2>&1 || {
  say "Claude Code 설치"
  curl -fsSL https://claude.ai/install.sh | bash
}
ok "claude"

# ── 2. 가드 훅 배치 ──
say "가드 훅 배치 (~/.claude/guards/)"
mkdir -p "$HOME/.claude/guards"
cp "$HERE/guards/"*.sh "$HOME/.claude/guards/"
chmod +x "$HOME/.claude/guards/"*.sh
ok "session-start / bash-guard / bash-audit / unpushed-check"

# ── 3. settings.json 설치 ──
say "Claude Code 설정 설치 (~/.claude/settings.json)"
if [ -f "$HOME/.claude/settings.json" ]; then
  cp "$HOME/.claude/settings.json" "$HOME/.claude/settings.json.bak-$(date +%Y%m%d%H%M%S)"
  echo "  기존 설정을 .bak 으로 백업했습니다 — 필요한 값은 직접 병합하세요."
fi
cp "$HERE/claude-settings.json" "$HOME/.claude/settings.json"
jq -e . "$HOME/.claude/settings.json" >/dev/null || { echo "✗ settings.json JSON 오류"; exit 1; }
ok "권한 deny/ask 규칙 + 훅 4종 + 대화기록 10년 보존"

# ── 4. 작업 폴더 ──
say "프로젝트 루트 생성"
mkdir -p "$PROJECTS_ROOT"
ok "$PROJECTS_ROOT"

# ── 5. 스크립트를 PATH에 노출 ──
say "스크립트 링크 (~/.local/bin)"
mkdir -p "$HOME/.local/bin"
for s in new-project.sh daily-backup.sh safe-clean.sh secrets-backup.sh; do
  [ -f "$HERE/$s" ] || continue
  chmod +x "$HERE/$s"
  ln -sf "$HERE/$s" "$HOME/.local/bin/${s%.sh}"
done
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
     echo "  ~/.bashrc 에 PATH 추가 — 새 셸에서 적용됩니다" ;;
esac
ok "new-project / daily-backup / safe-clean / secrets-backup"

# ── 6. 일일 백업 예약 ──
say "일일 백업 예약 (매일 21:47)"
CRON_LINE="47 21 * * * PROJECTS_ROOT=$PROJECTS_ROOT $HERE/daily-backup.sh >> \$HOME/.claude/daily-backup.log 2>&1"
( crontab -l 2>/dev/null | grep -v 'daily-backup.sh' ; echo "$CRON_LINE" ) | crontab - 2>/dev/null \
  && ok "cron 등록 완료 (로그: ~/.claude/daily-backup.log)" \
  || echo "  cron 등록 실패 — WSL이면 'sudo service cron start' 후 재시도하세요."

# ── 마무리 ──
cat <<EOF

────────────────────────────────────────
세팅 완료. 남은 수동 작업:

 1) gh auth login              GitHub 인증
 2) claude                      로그인 (/login)
 3) 클라우드 동기화 폴더 지정:
      echo 'export CLAUDE_ARCHIVE_DIR=/mnt/c/Users/<사용자>/OneDrive/claude-archive' >> ~/.bashrc
 4) 새 프로젝트는 반드시:
      new-project <이름> "설명"

확인:
      claude --version
      new-project --help 2>/dev/null || echo 'new-project <name> 형태로 사용'
────────────────────────────────────────
EOF
