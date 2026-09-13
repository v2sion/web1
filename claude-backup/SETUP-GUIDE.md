# 노트북 재세팅 가이드 — Claude Code 안전 작업 환경

작성 2026-09-13 · 2026-09 데이터 유실 사고 복구 과정에서 실측한 내용을 반영

이 문서는 **포맷된 노트북에서 처음부터 따라 하는 순서**입니다.
복붙 가능한 설정 파일과 스크립트가 `claude-backup/setup/` 에 함께 들어 있습니다.

---

## 0. 가장 먼저 — 이 저장소부터 받는다

```bash
# Windows: WSL 설치 후 재부팅
wsl --install

# WSL 안에서
git clone https://github.com/v2sion/web1.git ~/web1
ls ~/web1/claude-backup/setup/
```

이 안에 아래가 전부 들어 있습니다.

| 파일 | 역할 |
| --- | --- |
| `windows-hardening.ps1` | Windows 복원 지점 · 로깅 일괄 적용 (관리자 PowerShell) |
| `setup-wsl.sh` | WSL 안 전체 세팅 (도구 설치 → 훅 배치 → cron 등록) |
| `claude-settings.json` | Claude Code 권한·훅 설정 (`~/.claude/settings.json`) |
| `guards/*.sh` | 훅 스크립트 4종 — 이 저장소에서 실제 동작 검증 완료 |
| `new-project.sh` | 원격 저장소를 **먼저** 만드는 프로젝트 생성기 |
| `daily-backup.sh` | 일일 푸시 + 대화기록 보존 |
| `safe-clean.sh` | `rm -rf` 대체 — 안전 삭제 |
| `secrets-backup.sh` | `.env`·SSH 키 암호화 백업 |
| `CLAUDE.md.template` | 새 프로젝트 규칙 템플릿 |

---

## 1. 왜 이렇게 세팅하는가 — 사고 원인 실측 결과

추측이 아니라 이번 복구 과정에서 **증거로 확인한** 내용입니다.

### 결정적 원인: GitHub에 없는 코드가 서비스되고 있었다

Vercel API로 `starexcuse` 프로젝트를 조회한 결과:

```
"source": "cli"                         ← git 연동 없이 로컬에서 직접 배포
"gitCommitSha": "87276b536dfd..."       ← 로컬 git에만 있고 GitHub엔 없던 커밋
```

`vercel --prod` 로 PC에서 바로 배포했기 때문에, **서비스는 정상 동작하는데
GitHub에는 코드가 한 줄도 없는 상태**가 몇 달간 유지됐습니다. 배포가 잘 되니
문제를 눈치챌 계기가 없었습니다. PC가 사라지자 원본이 같이 사라졌습니다.

→ 대책: `new-project.sh`(원격 먼저 생성) + `session-start.sh` 훅(원격 없으면 경고)

### 두 번째 원인: 원격제어 세션은 PC가 없으면 못 이어간다

대화 74건 중 69건이 `bridge`(PC 원격제어) 세션이었습니다. 서버가
`recoverable: "true"` 플래그를 남겼는데도 **실제로는 재개가 불가능**했습니다.
앱에서 과거 대화를 "읽을" 수는 있지만, 새 프롬프트를 보내 코드를 다시 뽑아내는
것은 안 됩니다.

→ 대책: `autoUploadSessions: true` + `daily-backup.sh` 의 `~/.claude` 아카이브

### 세 번째 원인: 로컬 대화 기록이 PC와 함께 사라졌다

`~/.claude/projects/*.jsonl` 이 Claude Code 대화의 유일한 완전 사본인데
PC와 함께 지워졌습니다. 기본 보존 기간도 30일이라 그냥 두면 계속 삭제됩니다.

→ 대책: `cleanupPeriodDays: 3650` + 일일 tar 아카이브를 클라우드 동기화 폴더로

### 살아남은 것에서 배운 것

| 살아남음 | 이유 |
| --- | --- |
| GitHub 저장소 4개 | push 했기 때문 |
| 아티팩트 19건 | 서버 보관 — 여기서 API 명세·폴더 구조·함수명까지 복원했습니다 |
| Routines 2건 | 서버 보관 |
| Vercel 배포·빌드 로그 | 서버 보관 — 사고 원인 규명의 결정적 증거가 됐습니다 |

**아티팩트가 의외의 생명줄이었습니다.** 중요한 설계·결정은 대화에만 두지 말고
아티팩트로 게시해두면 로컬과 무관하게 살아남습니다.

---

## 2. Phase 1 — Windows 호스트 (코드 만지기 전에)

관리자 PowerShell에서:

```powershell
Set-ExecutionPolicy -Scope Process Bypass -Force
cd \\wsl$\Ubuntu\home\<사용자>\web1\claude-backup\setup
.\windows-hardening.ps1
```

자동 적용되는 것: C: 복원 지점(디스크 10%) · PowerShell 스크립트 블록 로깅 ·
프로세스 생성 감사 + 명령줄 기록.

**수동으로 해야 하는 것 하나** — 클라우드 동기화:
바탕화면·문서·`claude-archive` 폴더를 OneDrive 또는 Google Drive 동기화 대상으로
지정합니다. 클라우드 휴지통과 버전 히스토리가 로컬 영구 삭제를 되돌릴 수 있는
유일한 수단입니다.

---

## 3. Phase 2 — WSL 안 전체 세팅

```bash
bash ~/web1/claude-backup/setup/setup-wsl.sh
```

한 번에 처리되는 것:

1. git · jq · curl · node · gh · claude 설치
2. 훅 4종을 `~/.claude/guards/` 에 배치
3. `claude-settings.json` 을 `~/.claude/settings.json` 으로 설치 (기존 파일은 `.bak` 백업)
4. `~/projects` 생성
5. 스크립트를 `~/.local/bin` 에 링크 (`new-project`, `daily-backup`, `safe-clean`, `secrets-backup`)
6. 일일 백업 cron 등록 (매일 21:47)

이어서 수동으로:

```bash
gh auth login
claude          # /login 으로 계정 연결

# 클라우드 동기화 폴더 지정 (경로는 본인 환경에 맞게)
echo 'export CLAUDE_ARCHIVE_DIR=/mnt/c/Users/<사용자>/OneDrive/claude-archive' >> ~/.bashrc
source ~/.bashrc
```

### 격리가 왜 WSL인가

Windows 호스트에서 직접 CLI를 돌리면 경로 오류나 변수 전개 사고가
`C:\Users\...` 전체로 번집니다. WSL 안에서 작업하면 사고 반경이 WSL 파일시스템으로
한정되고, Windows의 문서·앱·설정은 영향받지 않습니다.

**작업은 반드시 WSL 파일시스템(`~/projects`)에서 합니다.** `/mnt/c/...` 아래에서
작업하면 격리 이점이 사라지고 I/O도 느립니다.

---

## 4. Phase 3 — Claude Code 설정이 실제로 막아주는 것

`claude-settings.json` 의 핵심만 설명합니다.

### 권한 (`permissions`)

```jsonc
"disableBypassPermissionsMode": "disable"   // --dangerously-skip-permissions 자체를 봉인
"blockReadsOutsideWorkingDirectories": true // 작업 폴더 밖 읽기 차단
"defaultMode": "default"                     // 항상 확인 후 실행
```

`deny`(실행 자체 차단): `rm -rf /` 계열, `sudo rm`, `mkfs`, `dd`, 강제 푸시,
`.env`·SSH 키 읽기.
`ask`(매번 확인): `rm -rf *`, `git reset --hard`, `git clean`, **`vercel` 명령**.

> `vercel`을 `ask`에 넣은 것이 이번 사고의 직접 대책입니다. 로컬 직접 배포는
> 금지가 아니라 "매번 의식하고 승인"하게 만듭니다.

### 훅 4종 (이 저장소에서 동작 검증 완료)

| 훅 | 시점 | 하는 일 |
| --- | --- | --- |
| `session-start.sh` | 세션 시작 | **origin 원격이 없으면 빨간 경고** · 미푸시 커밋/마지막 푸시 경과일 알림 |
| `bash-guard.sh` | Bash 실행 전 | 루트·홈 삭제, **빈 변수 전개 삭제**, `..` 탈출 삭제, main 강제푸시 차단 |
| `bash-audit.sh` | Bash 실행 전 | 모든 명령을 `~/.claude/bash-audit.log` 에 시각·세션·경로와 함께 기록 |
| `unpushed-check.sh` | 턴 종료 | 미커밋/미푸시가 남아 있으면 알림 |

`bash-guard.sh` 검증 결과 (실제 테스트):

```
차단됨: rm -rf /        rm -rf ~        rm -rf $HOME       rm -rf $TARGET
        rm -rf "$buildDir"   rm -rf ../dist   git push --force origin main
통과됨: rm -rf ./dist   rm -rf node_modules   git push origin feature/x
        rm -rf /home/user/web1/tmpdir   git push --force-with-lease origin feature/x
```

**빈 변수 전개 차단이 특히 중요합니다.** `rm -rf $VAR` 에서 `$VAR`가 비면
현재 디렉터리가 통째로 지워지는데, 이게 대량 삭제 사고의 1순위 유형입니다.

### 기록 보존

```jsonc
"cleanupPeriodDays": 3650   // 대화 기록 자동 삭제 방지 (기본 30일)
"autoUploadSessions": true  // 세션을 claude.ai에 미러링
"fileCheckpointingEnabled": true  // /rewind 로 편집 되돌리기
```

---

## 5. Phase 4 — 일상 작업 규칙

### 새 프로젝트는 반드시 이 명령으로

```bash
new-project starrating2 "별점 앱 재구축"
```

순서가 뒤집혀 있습니다 — **GitHub 비공개 저장소를 먼저 만들고 푸시한 뒤**
폴더를 돌려줍니다. `.gitignore`, `.env.example`, `CLAUDE.md`도 함께 생성됩니다.
원격 생성이 실패하면 프로젝트 자체가 안 만들어집니다.

Vercel에 올릴 계획이면 바로 이어서:

```bash
npx vercel link --project starrating2 --yes    # alias 선점 (2026-07-26 탈취 사고 대책)
```

### 배포는 git push 기반으로

Vercel 프로젝트를 GitHub 저장소에 연결해두면, 배포된 모든 코드가 자동으로
GitHub에 존재하게 됩니다. 이번 사고는 정확히 이게 없어서 발생했습니다.

### 산출물 정리는 safe-clean

```bash
safe-clean              # dist build .vercel/output
safe-clean node_modules
```

허용 목록(`dist build out coverage node_modules .next .turbo .vercel/output`)에
없는 이름, 저장소 밖 경로, 빈 값은 전부 거부합니다. 검증 결과:

```
삭제됨: dist
거부됨: src (허용 목록 밖) · ../../etc (저장소 밖) · "" (빈 값)
```

### 하루 마무리

cron이 21:47에 자동 실행하지만, 수동으로도 돌릴 수 있습니다.

```bash
daily-backup
```

모든 저장소의 미푸시 커밋을 올리고, origin 없는 저장소를 빨간색으로 알리고,
`~/.claude` 전체를 클라우드 동기화 폴더에 tar로 보존합니다.
**커밋 안 된 변경은 자동 커밋하지 않고 경고만 합니다** (의도 없는 커밋 방지).

### 시크릿은 별도 암호화 백업

```bash
secrets-backup                                   # 백업
secrets-backup restore ~/cloud-sync/.../secrets-2026-09-13.tar.gz.gpg   # 복원
```

`.env` 계열 · `~/.gitconfig` · `~/.ssh` · `~/.claude/settings.json` ·
`.vercel/project.json`(재배포에 필요)을 AES256으로 묶습니다.
**암호는 비밀번호 관리자에 저장하세요** — 잃으면 복호화 불가입니다.

---

## 6. Phase 5 — 복구 자산 재확보

포맷 전에 이 저장소에 보존해둔 것들입니다. 새 노트북에서 바로 참조하세요.

| 경로 | 내용 |
| --- | --- |
| `claude-backup/artifacts/` | 아티팩트 19건 원문 (브라우저로 바로 열림) |
| `claude-backup/recovered-code/starexcuse-starrating-architecture-reference.md` | 별점/별핑계 API 명세·Redis 스키마·폴더 구조·알려진 버그 7건 |
| `claude-backup/APP-REGISTRY.md` | 앱별 식별자(appName·miniAppId·딥링크·도메인) |
| `claude-backup/SESSIONS.md` | 세션 74건 인덱스 + 바로가기 링크 |
| `claude-backup/routines.json` | Routines 2건 프롬프트 전문 (그대로 재생성 가능) |
| `claude-backup/REVIVE-PLAN.md` | 남은 코드 복구 절차 |

---

## 7. 남은 작업 (인계)

세팅이 끝나면 이어서 할 일입니다.

1. **무더위 3종 SDK 3.x 점검** — `hwaseong-heatfeel-miniapp`, `mudeowebubble`,
   `mudeowe-battle` 의 `@apps-in-toss/web-framework` 버전 확인.
   목표 `^3.1.1` 이상, 마감은 이미 2026-09-14로 지났으므로 **현재 상태 확인이 먼저**입니다.
   3.x 배포 후 2.x 롤백이 불가능하니 빌드 성공 직후 반드시 커밋하세요.
2. **별점/별핑계 코드 복구** — `REVIVE-PLAN.md` 4-A. 앱에서 옛 세션을 스크롤해
   Write/Edit 코드 블록을 복사하는 수동 작업입니다. 서비스는 계속 돌고 있으므로
   긴급하지는 않습니다.
3. **Routines 재생성** — `routines.json` 의 `prompt`와 `cron_expression` 그대로.

---

## 8. 체크리스트

**Windows 호스트**
- [ ] `wsl --install` 후 재부팅
- [ ] `windows-hardening.ps1` 관리자 실행 (복원 지점 · 로깅)
- [ ] 바탕화면·문서·`claude-archive` 클라우드 동기화 지정
- [ ] 외장 SSD 주간 백업 일정 정하기

**WSL**
- [ ] `git clone https://github.com/v2sion/web1.git ~/web1`
- [ ] `bash ~/web1/claude-backup/setup/setup-wsl.sh`
- [ ] `gh auth login`
- [ ] `claude` → `/login`
- [ ] `CLAUDE_ARCHIVE_DIR` 환경변수 설정

**동작 확인**
- [ ] 빈 폴더에서 `claude` 실행 → "git 저장소가 아닙니다" 경고가 뜨는가
- [ ] `new-project test-delete-me "확인용"` → GitHub에 저장소가 생기는가
- [ ] `daily-backup` → 아카이브 파일이 클라우드 폴더에 생기는가
- [ ] `secrets-backup` → 암호 입력 후 `.gpg` 파일이 생기는가
- [ ] 확인 끝나면 `test-delete-me` 저장소 삭제

**습관**
- [ ] 새 프로젝트는 `new-project` 로만 만든다
- [ ] 배포는 git push 기반. `vercel --prod` 직접 배포는 예외적으로만
- [ ] 롤백 불가 작업은 성공 직후 즉시 커밋
- [ ] 중요한 설계 결정은 아티팩트로 게시 (로컬과 무관하게 살아남음)
