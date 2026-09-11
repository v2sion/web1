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
| 보험천재(?) (boheoncheonjae) | `boheoncheonjae` | — | — | 미상 — 저장소 목록에 없음 | 세션 제목/아티팩트에서만 확인 |

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

## 2. GitHub 저장소 존재 여부 — ①/② 미확인 상태

이번 세션에서 접근 가능한 GitHub 저장소를 전수조회한 결과, **별점(starrating)·별핑계(starexcuse)
전용 저장소는 목록에 없었습니다.**

접근 가능했던 저장소(6개 중 이 세션 스코프 4개):

- `v2sion/web1`
- `v2sion/hwaseong-heatfeel-miniapp`
- `v2sion/mudeowebubble`
- `v2sion/mudeowe-battle`

**같은 차단이 3주 전 세션에서도 이미 있었습니다.** `사진 첨부 서비스 영향도 검토` 세션의
`post_turn_summary`에 다음과 같이 명시되어 있습니다:

> "starscore/starexcuse repos not accessible; need GitHub access"

즉 이번이 처음 발견된 문제가 아니라 **최소 3주간 지속된 동일 증상**입니다. 가능성은 둘 중 하나이며
아직 확정되지 않았습니다:

- **① 권한 문제** — 저장소는 실제로 존재하지만 이 GitHub 커넥터/조직 설정에 연결되어 있지 않음.
  → 해결책: GitHub 웹에서 저장소가 실제 존재하는지 확인 후, 필요 시 Claude 조직 설정에서 접근 허용.
- **② 로컬 전용 소실** — 저장소 자체가 애초에 GitHub에 푸시된 적 없이 로컬 PC에만 있었고,
  PC 데이터 소실과 함께 코드도 사라짐.
  → 이 경우 SDK 점검은 의미가 없고, **코드 복구(REVIVE-PLAN.md의 세션 자가-게시 방식 등)가 최우선**.

**→ 사용자가 GitHub 웹에서 직접 확인하기로 함. 결과 아직 전달받지 않음.**
①로 확인되면 바로 아래 SDK 점검을 진행합니다.

---

## 3. SDK 3.x 전환 마감 (참고용 — 저장소 확인 후 착수)

`09-life-chapter-launch-review.html` 근거:

- 마감: **2026-09-14** (오늘 2026-09-11 기준 D-3)
- 목표 버전: `@apps-in-toss/web-framework` **`^3.1.1` 이상**
- 대상: 4개 앱 (별점·별핑계 포함 추정, 무더위 계열과 동일 점검 필요)

이미 저장소가 확인된 무더위 3종(`hwaseong-heatfeel-miniapp`, `mudeowebubble`, `mudeowe-battle`)은
필요 시 즉시 SDK 영향도 점검이 가능합니다. 별점·별핑계는 저장소 존재가 확정된 뒤 동일하게 진행합니다.

---

## 4. 다음 액션

1. **[사용자]** GitHub 웹에서 별점/별핑계 저장소 실존 여부 확인 → ① 또는 ② 결과를 알려주기.
2. **[①로 확인 시]** 저장소를 이 세션 스코프에 추가(`add_repo`) → 무더위 3종과 동일하게
   `package.json`의 `@apps-in-toss/web-framework` 버전 점검 → 필요 시 `^3.1.1` 이상으로 업그레이드.
3. **[②로 확인 시]** REVIVE-PLAN.md의 절차대로 세션 자가-게시를 통한 코드/대화 복구를 우선 시도.
