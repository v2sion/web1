# 별점(starrating) · 별핑계(starexcuse) 아키텍처 레퍼런스

작성 2026-09-12 · 원본 소스 없이, 백업된 아티팩트 19건 + Vercel API 실측만으로
재구성한 "as-built" 문서. 실제 코드가 아니라 **재구현 가능한 수준의 설계 명세**입니다.
각 항목에 근거 아티팩트를 표시했습니다 — 검증하려면 해당 파일을 다시 열어보면 됩니다.

---

## 0. 요약

| 항목 | 내용 |
| --- | --- |
| 서비스 상태 | 🟢 정상 운영 중 (2026-09-12 기준, Vercel 배포 살아있음) |
| 원본 소스 | ❌ 로컬 PC에만 존재, GitHub 미push, 소실 확정 |
| 이 문서의 근거 | 아티팩트 09, 15, 17 (기술 문서) — 실제 코드가 아니라 코드에 대한 서술 |
| 재구현 가능성 | 🟡 상 — API 스키마·데이터 모델·폴더 구조·알려진 버그까지 문서화되어 있어 처음부터 새로 설계하는 것보다 훨씬 빠르게 재구현 가능 |

---

## 1. 제품 개요

### 별점 (starrating)
- **핵심 메커닉**: 오늘 하루를 별점(1~5)으로 매기면 AI가 "우주 기준"으로 재채점해준다.
- **테마**: "하찮아도 괜찮아" — 바이브코딩 챌린지 출품작 (2026-08 챌린지, 출품 마감 8/26,
  1차 심사 9/1~9/27, DAU·리텐션 지표 평가).
- **출시**: v20260809-18, 2026-08-09.
- **연동**: 별핑계와 크로스 연동 — 별점이 낮게 나온 유저를 별핑계로 딥링크 유도.
- 근거: `15-starscore-challenge-plan.html` L296-320.

### 별핑계 (starexcuse / 앱 내부명 "핑계운세")
- **핵심 메커닉**: 병맛 톤의 "핑계" 생성 (지각·결석·미루기 등에 대한 유머러스한 변명).
- GROQ API(qwen3.6 모델)로 AI 텍스트 생성.
- 실제 프로덕션에서 검증 완료된 안정적인 스택으로, 이후 신규 앱("인생 챕터")이
  아키텍처를 그대로 재사용하려 했을 정도로 완성도가 높았음.
- 근거: `09-life-chapter-launch-review.html` L566-579, 612.

### 공통 식별자

| | 별점 | 별핑계 |
| --- | --- | --- |
| appName | `starrating` | `starexcuse` |
| miniAppId | `61859` | `61765` |
| workspaceId | `58697` (공통, "꿈청") | `58697` |
| 딥링크 | `intoss://starrating` | `intoss://starexcuse` |
| 배포 도메인 | (별도 배포 이력 없음 — 별핑계 백엔드에 얹혀 동작) | `starexcuse.vercel.app` |
| API 서버 | `https://star-excuse.vercel.app` (별핑계와 공유) | `https://star-excuse.vercel.app` |

---

## 2. 로컬 폴더 구조 (재구성)

아티팩트 09·15에 등장하는 실제 경로들을 모으면, 사라진 PC의 작업 폴더가 이런 구조였음을
알 수 있습니다 — 앱별 최상위 폴더 + `개발`/`마케팅` 하위 폴더 패턴:

```
(작업 루트)/
├── CLAUDE.md                          ← 앱 대장 표, "대형 파일 통째로 읽지 말 것" 경고
├── 별점/
│   ├── 개발/
│   │   ├── app/
│   │   │   ├── index.html
│   │   │   └── src/main.js            ← 단일 파일, 75KB (vanilla JS)
│   │   └── _SDK3전환.md               ← localStorage 키 목록, origin 마이그레이션 메모
│   └── 마케팅/
│       └── 9월_마케팅스케줄.md
├── 핑계운세/                           ← 별핑계의 내부 프로젝트명
│   └── 개발/
│       ├── landing/                   ← 별점 랜딩페이지가 참고한 레퍼런스
│       └── app/api/
│           ├── fortune.js             ← GROQ 프록시 (API 키는 서버에만)
│           └── _lib/
│               ├── redis.js           ← Upstash Redis 헬퍼 (todayKeyKST, secondsUntilMidnightKST)
│               └── korean.js          ← stripReasoning / isUsableKorean / cleanToKorean
├── 무더위 체감 랭킹/                    ← main.js 94KB (vanilla, 단일 파일)
├── 지름신 대기실/
│   └── 개발/01_개발_브리핑.md
└── (인생 챕터 — 신규 기획, 미착수)
```

근거: `09-life-chapter-launch-review.html` L567-579, 646, 752 / `15-starscore-challenge-plan.html` L314, 392.

**아키텍처 안티패턴 경고(팀 스스로 기록)**: "화면 3개에선 프레임워크 없는 단일 파일이
오히려 빨랐다. 화면 5개 이상이면 재검토." 별점·무더위 체감 랭킹은 이미 대가를 치른 상태
(main.js를 한 번 읽으면 200k 컨텍스트의 15%가 날아감). **재구현 시에는 처음부터 화면별
ES 모듈로 분할할 것.** (근거: L644-651)

---

## 3. API 명세 (크로스앱 연동, `star-excuse.vercel.app`)

별핑계 백엔드에 별점이 얹혀 쓰는 구조. 크로스앱 이벤트 연동용 엔드포인트 2개가
`17-crossapp-constellation-guide.html`에 전체 스펙으로 남아있습니다.

### `POST /api/cross-event`

```json
// Request
{
  "uid":  "uuid-xxxx",       // universe_device_id
  "src":  "starexcuse",      // 이벤트 발생 앱
  "type": "visit",           // 이벤트 타입
  "payload": {
    "date":  "20260808",     // YYYYMMDD (KST)
    "score": 2                // 별점 (있을 때만)
  }
}
// Response
{ "ok": true }
```

Redis 작업:
```
LPUSH cross:events:{uid}  JSON.stringify({ src, type, payload, ts })
LTRIM cross:events:{uid}  0 499     // 최대 500개 보관
EXPIRE cross:events:{uid} 31536000  // TTL 365일
```

### `GET /api/cross-data?uid=<uuid>`

```json
{
  "events": [
    { "src": "starexcuse", "type": "visit", "payload": { "date": "20260808", "score": 2 }, "ts": 1754649600 }
  ]
}
```
Redis 작업: `LRANGE cross:events:{uid} 0 499`

### 정의된 이벤트 타입

| src | type | payload 필드 | 발생 시점 |
| --- | --- | --- | --- |
| starexcuse | visit | date, score(optional) | 별점에서 deep link로 핑계운세 진입 시 |
| starexcuse | excuse_generated | date, category | 핑계 생성 완료 시 (향후 확장 예정이었음) |

### 클라이언트 공통 코드 (두 앱 모두 사용)

```js
// 두 앱 공통 — 최초 실행 시 UID 확보
function getOrCreateDeviceId() {
  const KEY = 'universe_device_id';
  let uid = localStorage.getItem(KEY);
  if (!uid) {
    uid = crypto.randomUUID();
    localStorage.setItem(KEY, uid);
  }
  return uid;
}
```

### 딥링크 파라미터

```
intoss://starexcuse?_src=starrating&_uid=<uuid>&_score=2&_date=20260808
```
흐름: 별점 결과 화면에서 "핑계운세" 버튼 탭 → 위 딥링크로 별핑계 오픈 →
별핑계가 `_uid`를 `universe_device_id`로 저장, `_src=starrating`이면 cross-event POST
→ 별점 쪽에서 `/api/cross-data`로 크로스 이벤트 조회해 별자리 판정에 반영.

근거: `17-crossapp-constellation-guide.html` L327-963 전체.

---

## 4. 백엔드 아키텍처 원칙 (핑계운세/별핑계 API, 신규 앱이 그대로 재사용하려던 스택)

- **AI 프록시**: `fortune.js` — GROQ 호출을 서버에서만 수행, API 키 클라이언트 노출 0.
- **저장소**: Supabase/Postgres 불필요 — Upstash Redis만으로 충분. 조인이 없는
  "anonKey 하나당 문서 하나" 구조라 Redis Hash/JSON 한 키로 끝남.
- **레이트리밋**: KST 기준 일자 키(`todayKeyKST`) + 자정 만료(`secondsUntilMidnightKST`)로
  "1일 N회 제한"을 구현. `.agents/skills/`에 `upstash-redis-js`, `upstash-ratelimit-js`
  스킬이 이미 설치되어 있었음.
- **AI 출력 가드**: `_lib/korean.js`의 `stripReasoning`(리즈닝 모델의 영어 사고과정 제거) ·
  `isUsableKorean`(품질 검사) · `cleanToKorean`(후처리).
- **정체성 모델**: 로그인 없이 `getAnonymousKey()`로 익명 식별. **서버(Redis)를 진실
  원본으로, anonKey를 키로, 클라이언트 저장(localStorage)은 캐시로만** 사용 — SDK
  origin 변경으로 localStorage가 날아가도 서버 데이터는 살아남는 설계.

근거: `09-life-chapter-launch-review.html` L566-600.

---

## 5. 알려진 이슈 · 운영 노하우 (재구현 시 반드시 참고)

1. **SDK 3.x 전환**: 2026-09-02 기준 별점·별핑계·무더위 버블 타임·무더위 체감 랭킹
   4앱 모두 `@apps-in-toss/web-framework: ^2.10.5`. 마감 2026-09-14, 목표 `^3.1.1`+
   (3.0.x는 origin 이슈로 사용 금지). **3.x 배포 후 2.x 롤백 불가** — 앱별 빌드 성공 직후
   `git commit` 필수. (Vercel 실측으로 별핑계는 2026-09-06에 3.3.0으로 전환 완료된 것으로
   확인됨 — §3 참고)
2. **SDK origin 변경 시 localStorage 유실 위험**: 2026-08-25 공지(postId 52623).
   마이그레이션 API로 병합 필요 — 별점의 `_SDK3전환.md`에 영향받는 localStorage 키
   목록이 별도 기록되어 있었음(내용 자체는 소실).
3. **GROQ qwen3.6 리즈닝 노출 버그**: `reasoning_effort`를 끄지 않으면 영어 사고과정이
   본문에 그대로 노출됨. 반드시 끌 것.
4. **push_template_create MCP 버그**: 콘솔 MCP로 기능성 푸시 템플릿을 만들면
   `enabled:false`로 고착되어 알림 동의 팝업이 떠도 무반응. **반드시 콘솔 웹에서 직접
   등록**해야 함. (라이브에서 수 주간 방치된 전례 있음)
5. **dev 서버에서 검증 불가한 SDK 3종**: `requestNotificationAgreement`,
   `share`/`getTossShareLink`, `requestReview` — 브라우저에서 `ReactNativeWebView is
   not available`로 **조용히 실패**(에러 없음). 반드시 실기기로 탭 시�퀀스 확인 필요.
6. **Vercel alias 탈취 사고 (2026-07-26)**: 신규 프로젝트 생성 즉시
   `npx vercel link --project <고유이름> --yes`로 별칭을 선점할 것.
7. **로그 정책**: 답변/사용자 생성 텍스트 원문은 절대 로그에 남기지 않고 길이만 기록.

근거: `09-life-chapter-launch-review.html` L488-686 전체.

---

## 6. Vercel 배포 실측 (2026-09-12, `claude-backup/APP-REGISTRY.md` §2-1과 동일 출처)

| 프로젝트 | 배포 방식 | 마지막 배포 | 상태 |
| --- | --- | --- | --- |
| `starexcuse` | CLI 직접 배포 (`source: "cli"`, git 연동 없음) | 2026-09-06 09:18 KST · 커밋 `87276b5`(SDK 3.3.0) | 🟢 서비스 중 |
| `starrating` | 프로젝트만 생성(vite), 배포 이력 0건 | — | 별도 배포 없음 — 별핑계 백엔드에 얹혀 동작 |
| `starrating-landing` | git 메타데이터 없는 배포 | 2026-08-31 08:52 UTC | 🟢 서비스 중 |

Vite 빌드 결과물(마지막 배포 로그 기준):
```
dist/web/index.html                 36.18 kB
dist/web/assets/index-BIonvo8q.js  348.63 kB (56 modules)
```
→ 56개 모듈이 번들된 것으로 보아, 위 §2의 "vanilla 단일 main.js"는 최소 별핑계 쪽은
이미 모듈 분할이 어느 정도 진행됐거나 Vite로 재구성됐을 가능성. (별점은 §2 시점 기준
75KB 단일 파일로 남아있었을 가능성이 더 높음 — 확인 불가.)

---

## 7. 이 문서로 할 수 있는 것 / 할 수 없는 것

✅ **할 수 있는 것**
- API 계약(요청/응답 스키마)을 그대로 새 프로젝트에 이식
- Redis 키 설계·TTL 정책 그대로 재사용
- 알려진 버그(§5)를 처음부터 회피
- 폴더 구조·빌드 명령(`ait build`) 그대로 재현

❌ **할 수 없는 것**
- UI 컴포넌트의 실제 마크업/스타일 (원본 없음 — 라이브 사이트 캡처나 세션 수동 복사 필요)
- 정확한 프롬프트 문구, 예외 처리 세부 로직
- `_SDK3전환.md`의 실제 localStorage 키 목록 (존재는 확인되나 내용 소실)

더 채우려면 `REVIVE-PLAN.md` 4-A(27개 세션 수동 스크롤 복사)가 다음 단계입니다.
