#!/usr/bin/env bash
# 새 프로젝트 생성 — 첫 줄을 쓰기 전에 원격 저장소부터 만든다.
#
#   사용법: new-project.sh <프로젝트명> [설명]
#
# 2026-09 사고의 원인은 "로컬에서 만들고 GitHub에 안 올림"이었다.
# 이 스크립트는 그 순서를 뒤집어, 원격이 없으면 폴더 자체가 안 만들어지게 한다.
set -euo pipefail

NAME="${1:?프로젝트명을 입력하세요: new-project.sh <name> [설명]}"
DESC="${2:-}"
ROOT="${PROJECTS_ROOT:-$HOME/projects}"
DIR="$ROOT/$NAME"

# 이름 검증 — 공백/슬래시가 들어가면 경로가 깨진다
if ! printf '%s' "$NAME" | grep -Eq '^[a-z0-9][a-z0-9._-]*$'; then
  echo "✗ 프로젝트명은 영소문자/숫자/._- 만 사용하세요 (Vercel·GitHub 양쪽 호환)." >&2
  exit 1
fi

command -v gh >/dev/null 2>&1 || { echo "✗ gh CLI가 필요합니다: https://cli.github.com" >&2; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "✗ gh auth login 먼저 실행하세요." >&2; exit 1; }
[ -e "$DIR" ] && { echo "✗ 이미 존재: $DIR" >&2; exit 1; }

mkdir -p "$DIR"
cd "$DIR"
git init -q -b main

cat > .gitignore <<'EOF'
node_modules/
dist/
build/
.vercel/
.env
.env.*
!.env.example
*.log
.DS_Store
.claude/settings.local.json
EOF

cat > .env.example <<'EOF'
# 실제 값은 .env 에 넣고 절대 커밋하지 않는다.
# .env 는 secrets-backup.sh 로 별도 암호화 백업한다.
EOF

printf '# %s\n\n%s\n' "$NAME" "${DESC:-TODO: 한 줄 설명}" > README.md

# 프로젝트 규칙 템플릿이 있으면 복사
TEMPLATE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/CLAUDE.md.template"
[ -f "$TEMPLATE" ] && sed "s/{{PROJECT_NAME}}/$NAME/g" "$TEMPLATE" > CLAUDE.md

git add -A
git commit -qm "chore: 프로젝트 초기화"

# ── 여기가 핵심: 코드를 쓰기 전에 원격을 만든다 ──
gh repo create "$NAME" --private --source=. --remote=origin --push \
  ${DESC:+--description "$DESC"}

# Vercel 배포 예정이면 alias 선점 (2026-07-26 alias 탈취 사고 재발 방지)
echo
echo "✓ 완료: $DIR"
echo "  원격: $(git remote get-url origin)"
echo
echo "다음 단계:"
echo "  cd $DIR && claude"
echo "  Vercel에 올릴 거면 먼저: npx vercel link --project $NAME --yes"
