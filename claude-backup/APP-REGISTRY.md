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

---

## 3. SDK 3.x 전환 마감 — 무더위 3종만 해당

`09-life-chapter-launch-review.html` 근거:

- 마감: **2026-09-14** (오늘 2026-09-12 기준 **D-2**)
- 목표 버전: `@apps-in-toss/web-framework` **`^3.1.1` 이상**
- 원문상 대상은 4개 앱으로 기록되어 있으나, 별점·별핑계는 저장소 자체가 없어 **점검 대상에서
  실질적으로 제외**됩니다. 저장소가 확인된 무더위 3종(`hwaseong-heatfeel-miniapp`,
  `mudeowebubble`, `mudeowe-battle`)만 실제 점검·업그레이드가 가능합니다.

마감이 이틀 앞으로 다가온 만큼, 무더위 3종의 SDK 버전 점검은 **미루지 말고 지금 진행하는 것을
권장**합니다.

---

## 4. 다음 액션

1. **[완료]** GitHub 저장소 존재 여부 확인 — ②(로컬 전용 소실)로 확정.
2. **[다음, 급함]** 무더위 3종의 `package.json`에서 `@apps-in-toss/web-framework` 버전을
   점검 → `^3.1.1` 미만이면 마감(2026-09-14, D-2) 전 업그레이드. 원하시면 지금 바로 3개
   저장소를 점검하겠습니다.
3. **[별점/별핑계 코드 복구]** SDK 점검과 무관하게, 필요하다면 `REVIVE-PLAN.md`의 세션
   자가-게시 방식으로 과거 세션이 갖고 있던 코드/대화를 아티팩트로 뽑아내는 것이 유일한 복구
   경로입니다. 진행 여부와 시점은 사용자 판단.
