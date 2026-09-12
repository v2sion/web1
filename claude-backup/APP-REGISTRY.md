# 앱 식별자 레지스트리 (별점·별핑계·무더위 계열)

작성 2026-09-11 · 근거: 백업된 아티팩트 19건 원문 grep/대조 + GitHub 저장소 전수조회

이 문서는 **새로 조회한 것이 아니라**, 이미 `claude-backup/artifacts/`에 저장된
아티팩트 원문에서 앱 식별자(appName, miniAppId, 딥링크, 배포 도메인)를 추출해
한곳에 정리한 것입니다.

---

## 1. 확인된 식별자

| 앱 | appName / miniAppId | 딥링크 | 배포 도메인 | 역할 | 근거 아티팩트 |
| --- | --- | --- | --- | --- | --- |
| **별점** (starrating) | `starrating` / `61859` | `intoss://starrating` | `star-excuse.vercel.app` | **API 서버** (별점이 별핑계 백엔드 도메인을 공유) | `14-star-series-instagram-story.html`, `15-starscore-challenge-plan.html`, `17-crossapp-constellation-guide.html` |
| **별핑계** (starexcuse) | `starexcuse` / `61765` | `intoss://starexcuse` | `starexcuse.vercel.app` | 랜딩 페이지 | `14-star-series-instagram-story.html` |
| **무더위 체감 랭킹** (mudeowerank) | `mudeowerank` / `52367` | — | — | (hwaseong-heatfeel-miniapp 저장소로 추정) | `SESSIONS.md` 제목 대조 |
| 무더위 배틀 (mudeowebattle) | `mudeowebattle` | — | — | `mudeowe-battle` 저장소 | 저장소명 대조 |
| 무더위버블 (mudeowebubble) | `mudeowebubble` | — | — | `mudeowebubble` 저장소 | 저장소명 대조 |
| 보험천재 (bohum-cheonje) | `bohum-cheonje` | — | `bohum-cheonje.vercel.app` | Vercel 프로젝트 존재 확인(2026-09-12) | Vercel API 조회 |

공통: **workspaceId `58697`** (꿈청) — 별점·별핑계 계열이 같은 워크스페이스 소속으로 추정됨.

### 주의 — 유사 도메인 2개 혼동 금지

- `star-excuse.vercel.app` (하이픈 있음) → **별점의 API 서버**. `15-starscore-challenge-plan.html`에
  "API 서버(star-excuse.vercel.app) 응답 안정성 점검" 문구로 확정.
- `starexcuse.vercel.app` (하이픈 없음) → **별핑계 자체의 랜딩 도메인**.
- `17-crossapp-constellation-guide.html`: "두 앱은 이미 같은 Vercel 백엔드(`star-excuse.vercel.app`)와
  Upstash Redis를 공유" — 즉 별점 앱이 별핑계의 백엔드 인프라(API+Redis)에 얹혀 있는 구조로 보임.

### `14-star-series-instagram-story.html` 원문 데이터 블록

```js
starexcuse: { deeplink: 'intoss://starexcuse', url: 'starexcuse.vercel.app', ... }
starrating: { deeplink: 'intoss://starrating', url: 'star-excuse.vercel.app', ... }
```

---

## 2. GitHub 저장소 존재 여부 — ② 확정 (로컬 전용 소실)

이번 세션에서 접근 가능한 GitHub 저장소를 전수조회한 결과, **별점(starrating)·별핑계(starexcuse)
전용 저장소는 목록에 없었습니다.** 2026-09-12, 사용자가 **GitHub 웹에서 직접 확인**한 결과도
동일 — 저장소가 보이지 않음.

접근 가능했던 저장소(6개 중 이 세션 스코프 4개):

- `v2sion/web1`
- `v2sion/hwaseong-heatfeel-miniapp`
- `v2sion/mudeowebubble`
- `v2sion/mudeowe-battle`

**같은 증상이 3주 전 세션에서도 이미 있었습니다.** `사진 첨부 서비스 영향도 검토` 세션의
`post_turn_summary`에 다음과 같이 명시되어 있습니다:

> "starscore/starexcuse repos not accessible; need GitHub access"

즉 최소 3주 이상 지속된 증상이며, **사용자 본인이 GitHub 웹(계정 전체 권한)에서 직접 찾아봐도
안 보인다는 것으로 ①(커넥터 권한 문제)은 사실상 배제됩니다.** Claude 쪽 연결 문제였다면 저장소
자체는 GitHub에 존재해야 하는데, 계정 소유자 본인 눈에도 없다는 것은:

- **② 로컬 전용 소실 확정** — 별점·별핑계 저장소는 애초에 GitHub에 푸시된 적 없이 로컬 PC에만
  있었고, PC 데이터 소실과 함께 코드도 함께 사라진 것으로 결론.
  → **SDK 3.x 점검은 이 두 앱에 대해서는 의미가 없습니다.** 코드 자체가 없기 때문입니다.
  → **코드 복구가 최우선**이며, 유일한 경로는 `REVIVE-PLAN.md`의 "세션 자가-게시" 방식으로
    과거 세션이 갖고 있던 코드/대화를 아티팩트로 뽑아내는 것입니다.

(단, 조직 소유 저장소이고 사용자 계정이 그 조직의 멤버가 아니어서 목록 자체가 안 보이는
극히 드문 경우는 이론상 남아 있지만, 지금까지 나온 증거 — 3주 전부터의 동일 증상, 로컬 PC
소실과 시점이 겹침 — 를 볼 때 가능성은 낮게 봅니다.)

### 2-1. Vercel API 실측 (2026-09-12) — ② 물증 확보 + 서비스 영향도 확인

Vercel MCP(team slug `v2sioninmymind-4818`)로 프로젝트를 직접 조회해 **추론이 아니라
증거로 ②를 확정**했습니다.

| 프로젝트 | 배포 방식 | 마지막 배포 | 상태 |
| --- | --- | --- | --- |
| `starexcuse` | **`source: "cli"`** (git 연동 없음, `vercel --prod` 직접 배포) | 2026-09-06 09:18 KST · 커밋 `87276b5` (`main`, SDK 3.3.0 전환 빌드) | 🟢 **현재도 정상 서비스 중** (`starexcuse.vercel.app`, READY) |
| `starrating` | framework: vite로 프로젝트만 생성, **배포 이력 0건** | — | 별도 앱으로 배포된 적 없음 — 별핑계 백엔드에 얹혀 동작하는 구조 추정과 일치 |
| `starrating-landing` | git 메타데이터 없는 배포 2건 | 2026-08-31 08:52 UTC | 🟢 정상 서비스 중 |

**결정적 증거: `"source": "cli"`.** Vercel이 배포를 Git 저장소 대신 로컬 CLI(`vercel --prod`,
Claude Code 에이전트가 실행)에서 직접 받았다는 뜻입니다. 커밋 SHA(`87276b536dfd...`)는
**로컬 git 저장소에는 존재했지만 GitHub에 push된 적이 없는 커밋**입니다 — 그래서 GitHub
저장소 목록에 안 뜨는 것과 정확히 앞뒤가 맞습니다.

**중요 — 서비스는 멈추지 않았습니다.** `starexcuse.vercel.app`과 `starrating-landing.vercel.app`
둘 다 **지금 이 순간도 마지막으로 배포된 빌드가 정상 응답 중**입니다(readyState: READY,
target: production). 즉 **사용자에게 보이는 서비스 자체는 영향이 없고**, 잃어버린 것은
"그 빌드를 만들어낸, 앞으로 수정 가능한 원본 소스 코드"입니다.

**한계 — 이걸로 원본 소스까지 되찾을 순 없습니다.** Vercel API/MCP 도구 어디에도 배포에
포함된 원본 파일을 나열·다운로드하는 기능이 없습니다(빌드 로그·런타임 로그·배포 메타데이터만
조회 가능). 빌드 로그에서 확인되는 건 결과물 요약뿐입니다:

```
dist/web/index.html                 36.18 kB
dist/web/assets/index-BIonvo8q.js  348.63 kB (번들·압축됨, 원본 아님)
```

이 번들 JS를 가져와 리버스 엔지니어링하는 것은 이론상 가능하지만(`web_fetch_vercel_url`로
라이브 사이트 fetch), **압축·난독화된 결과물이라 유지보수 가능한 원본 코드로 되돌릴 수
없습니다.** 원본 소스를 되찾는 유일한 경로는 여전히 `REVIVE-PLAN.md` 4-A(세션 대화
수동 복사)입니다.

---

## 3. SDK 3.x 전환 마감 — 무더위 3종만 해당, 별핑계는 이미 완료 정황

`09-life-chapter-launch-review.html` 근거:

- 마감: **2026-09-14** (오늘 2026-09-12 기준 **D-2**)
- 목표 버전: `@apps-in-toss/web-framework` **`^3.1.1` 이상**
- 원문상 대상은 4개 앱으로 기록되어 있으나, 별점·별핑계는 저장소 자체가 없어 **점검 대상에서
  실질적으로 제외**됩니다. 저장소가 확인된 무더위 3종(`hwaseong-heatfeel-miniapp`,
  `mudeowebubble`, `mudeowe-battle`)만 실제 점검·업그레이드가 가능합니다.

마감이 이틀 앞으로 다가온 만큼, 무더위 3종의 SDK 버전 점검은 **미루지 말고 지금 진행하는 것을
권장**합니다.

**참고 — 별핑계는 이미 전환된 것으로 보입니다.** 2-1의 마지막 배포 빌드 로그에 `ait build` 및
"앱인토스 빌드가 완료되었습니다(starexcuse.ait)" 로그가 확인되어, 최소 2026-09-06 시점에는
새 빌드 툴체인(SDK 전환 이후)으로 정상 빌드된 것으로 보입니다. 다만 `package.json`의 정확한
버전 문자열은 원본 소스가 없어 확인 불가 — 현재 라이브 사이트 응답으로 간접 추정만 가능합니다.

---

## 4. 다음 액션

1. **[완료]** GitHub 저장소 존재 여부 확인 — ②(로컬 전용 소실)로 확정.
2. **[다음, 급함]** 무더위 3종의 `package.json`에서 `@apps-in-toss/web-framework` 버전을
   점검 → `^3.1.1` 미만이면 마감(2026-09-14, D-2) 전 업그레이드. 원하시면 지금 바로 3개
   저장소를 점검하겠습니다.
3. **[별점/별핑계 코드 복구]** SDK 점검과 무관하게, 필요하다면 `REVIVE-PLAN.md`의 세션
   자가-게시 방식으로 과거 세션이 갖고 있던 코드/대화를 아티팩트로 뽑아내는 것이 유일한 복구
   경로입니다. 진행 여부와 시점은 사용자 판단.

---

## 5. 나머지 아티팩트 전수 점검 (2026-09-12) — 추가로 발견된 위험

19개 아티팩트 중 별점/별핑계 관련 4건(09, 14, 15, 17) 외 나머지 15건을 전부 훑었습니다.
대부분(01·02·03·06·08·11·12·13·16·18·19)은 개인 트레이닝·뉴스레터·마케팅·디자인 문서로
**코드/아키텍처 정보 없음** — 추가로 할 일 없습니다. 다만 **새로운 위험 신호 2건**을 발견했습니다.

### 5-1. "인생 챕터" — 사용자 확인 완료: 서비스 미출시, 기획·디자인 단계까지만 ✅

아티팩트 04·05·07(2026-09-04 작성)에 다음과 같은 **실제 코드의 함수·파일명**이 그대로
등장합니다:

- `src/main.js`, `src/questions.js`, `src/screens/question.js`, `src/state.js`
- 함수: `pickQuestions()`, `stem()`, `focusField()`, `canSummarize()`
- 상수: `MAX_LEN 500`

09번 아티팩트(2026-09-02 작성)는 "인생 챕터"가 **아직 코드 착수 전**이라고 명시했는데
(`Phase 2 — 인생 챕터 개발`은 09-15 이후 권고), 04·05·07은 이틀 뒤(09-04)에 이미 실제
함수명을 인용하며 QA를 진행하고 있습니다 — **권고된 일정보다 먼저 코딩이 시작됐다는 뜻**입니다.

GitHub(`list_repos` 검색: life/chapter — 0건)와 Vercel 프로젝트 목록(§2-1) 어디에도
"인생 챕터"에 해당하는 저장소·배포가 없어 별점/별핑계와 같은 패턴처럼 보였으나,
**2026-09-12 사용자 확인: 실제 서비스 출시 없이 기획·디자인 단계까지만 진행했다고 함.**
즉 애초에 배포된 적이 없으니 GitHub·Vercel에 없는 게 당연한 결과였습니다 — 소실이 아니라
"거기까지만 진행"이 정확한 상태입니다.

→ **결론: 추가 조치 불필요.** 04·05·06·07·08·09 아티팩트에 남은 QA·레벨디자인·함수명
정보는 이미 아티팩트 백업으로 보존되어 있으므로, 나중에 이 기획을 재개하고 싶을 때
참고 자료로만 활용하면 됩니다. 별도의 architecture-reference 문서는 만들지 않습니다
(서비스 손실이 없어 긴급도가 없음).

### 5-2. "지름신 대기실" (jireumsin) — 사용자 확인 완료: 동일하게 기획·디자인 단계까지만 ✅

아티팩트 10(2026-09-02)의 "코드 0줄" 기록과 사용자 확인이 일치합니다 — **실제 서비스까지
가지 않았습니다.** GitHub·Vercel에 `jireumsin`이 없는 것도 같은 이유로 설명됩니다.

→ **결론: 추가 조치 불필요.** 세션(`session_016uYYucbF55rcFwFheRXxYH`)을 열어 확인할
필요도 없어졌습니다 — 서비스로 나간 적이 없으니 "복구할 프로덕션 코드" 자체가 없습니다.

### 5-3. 정리 — 실제 복구·점검이 필요한 대상은 여전히 별점/별핑계 + 무더위 3종뿐

이번 전수 점검으로 범위가 넓어질 뻔했지만, 확인 결과 **원래 범위(별점·별핑계 코드 복구,
무더위 3종 SDK 점검)에서 변동 없음**으로 정리됩니다.
