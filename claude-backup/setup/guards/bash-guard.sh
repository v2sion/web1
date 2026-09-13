#!/usr/bin/env bash
# PreToolUse(Bash) guard — 파국적 삭제/강제푸시를 실행 전에 차단한다.
# permissions.deny 와 중복이지만, deny 는 패턴 매칭이 느슨할 수 있어 2중 방어로 둔다.
set -uo pipefail

payload=$(cat)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')

deny() {
  jq -n --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

# 1) 루트 / 홈 디렉터리 통째 삭제
if printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+(-[a-zA-Z]+[[:space:]]+)*(-[a-zA-Z]*[rR][a-zA-Z]*)[[:space:]]+(/|~|\$HOME)[[:space:]]*(;|&|\||$)'; then
  deny "루트 또는 홈 디렉터리 전체 삭제로 판정했습니다. 차단합니다."
fi

# 2) 검증 없는 변수 전개 삭제 — 변수가 비면 상위 경로가 지워진다 (사고 유형 1위)
if printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[[:space:]]+"?\$\{?[A-Za-z_][A-Za-z0-9_]*\}?"?[[:space:]]*(;|&|\||$)'; then
  deny "변수를 그대로 rm -r 대상으로 썼습니다. 변수가 비면 상위 경로가 삭제됩니다. [ -n \"\$VAR\" ] && [ -d \"\$VAR\" ] 검증을 넣거나 경로를 리터럴로 고정하세요."
fi

# 3) 상위 디렉터리 탈출 삭제
if printf '%s' "$cmd" | grep -Eq 'rm[[:space:]]+-[a-zA-Z]*[rR][a-zA-Z]*[[:space:]]+[^;|&]*\.\.'; then
  deny "삭제 경로에 .. 가 포함되어 작업 폴더 밖을 지울 수 있습니다. 절대경로로 다시 지정하세요."
fi

# 4) main/master 강제 푸시
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+push[^;|&]*(--force|[[:space:]]-f)([[:space:]]|$)' \
  && printf '%s' "$cmd" | grep -Eq '(main|master)'; then
  deny "main/master 강제 푸시입니다. 원격 이력이 사라질 수 있어 차단합니다."
fi

exit 0
