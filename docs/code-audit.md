# 실행 전 전체 저장소 코드 감사 — 2026-10-26

판정: **NO-GO — 현재 Windows 계정에서 비파괴 게임 smoke를 시작하지 않는다.**
원본 시작 코드의 Steam 영구 기록 처리와 실제 Windows 파일 보호 동작이 검증되지
않았다(A04/A05). 코드·오프라인 검사는 계속할 수 있다. VerifiedPatch, 엔딩 호환성,
병합 또는 출시 승인이 아니다. 공식 게임은 이번 감사에서 실행하지 않았다.
PR1은 OPEN/READY로 유지한다.

## 범위와 식별

- 조사 기준 HEAD: `818fabab978a465d2ae07ff7d054f6dcb1a667fb`.
  수정 후 상태는 이 문서와 함께 커밋된 파일 및 `git log -1 --format=%H`로 식별한다.
- [audit-coverage.json](audit-coverage.json): 전체 추적 파일의 경로·바이트·줄 수·
  SHA-256·검사 방법·검증 범위·관련 지적을 명시한다. 최초159개와 감사 중 추가4개,
  당시 총163개다. 최신 파일 집합·해시는 audit-coverage.json과 non-runtime-status.md를 따른다. 누락 검사는 `git ls-files`와 항목 집합을 정확히 비교한다.
- 직접 유지하는 코드·테스트·설정·문서는 전체 내용을 읽었다. 생성 GML33개는 생성기
  전체 코드 검토와 모든 출력의 바이트 비교로 검사했다. 손작성 GML12개는 전체 코드
  검토 대상이다. 데이터는 전체 레코드/원본 해시 검사, 바이너리 폰트는 전체 디코딩/
  재생성 비교로 검사했다. 제삼자 고지는 SDK와 전체 바이트 일치 및 고지 섹션 확인
  방식이다. 이를 수동 줄 단위 검토나 법률 승인으로 부르지 않는다.
- COMPLETE는 **검사 범위 완료**다. PASS는 명시한 오프라인 범위에만 적용된다.
  JSON 자체의 재귀 해시는 비워 두며 나머지 파일은 모두 해시를 갖는다.
- 원본:62,921,978 bytes / bytecode16 /
  `b718f8223a5bb31979ffeed10be6140c857b882fc0d0462b89d6287ae38c81c7`.
- 결과:63,169,638 bytes /
  `9abd0729f08497f8185ac9540eb514f3a466d41a4a2fcc5f005d484d8fa7ad4d`.
  GML/폰트/UI 변경 없이 기존 후보와 일치한다. 프로필은 **InspectedOnly**다.
- 기존 비공개 runtime lab의220개 원본 파일을 재검증했다.
  Windows PE32/x86, manifest build4279148/depot391541/manifest3413030246586915448.
  manifest 관찰은 Valve 인증/소유권 검증을 대신하지 않는다.

## 우선순위 지적 등록부

| ID / 심각도 | 위치 | 증거·재현 | 수정·회귀·현재 상태 |
|---|---|---|---|
| A01 HIGH, 확인된 결함 | `src/RouteKeeper.Tool/SafeInstaller.cs:150` | 상위 디렉터리를 symlink로 만들면 이전 RejectLinks는 통과하고 실제 대상/sidecar를 변경했다. synthetic FORM으로 수정 전 실패 재현. | 모든 경로 구성 요소의 링크/reparse 거부, 교체 전 재확인. `tests/RouteKeeper.Tool.Tests/Program.cs:52`의 설치/후보/복구3회귀 **PASS**(Linux). Windows 링크 권한은 NOT_RUN. TOCTOU는 A06으로 남긴다. |
| A02 HIGH, 확인된 결함 | `integration/export-preview-font.csx:8` | 이전 page.png를 일회용 원본 복사본으로 연결하자 복사본이 PNG로 덮어써졌다. 진짜 원본 SHA는 불변. 문자열에 /.research/가 있으면 저장소 밖도 허용했다. | 실제 .research 하위만 허용, 원본/출력 조상 링크·기존 출력 거부, 두 출력 CreateNew. `tools/test-preview-export.py`의 새 출력/기존 출력/외부 경로/두 파일 링크/조상 링크 **PASS**, 입력 SHA 불변. |
| A03 MEDIUM, 확인된 결함 | `src/RouteKeeper.Tool/ModBuilder.cs:50` | 입력이 VerifiedPatch이면 다른 출력 해시도 영수증 VerifiedPatch. 실제 installer는 계속 거부했다. test apphost synthetic compiler subprocess로 수정 전 실패 재현. | 정확한 출력 해시까지 같은 경우만 승인. `tests/RouteKeeper.Tool.Tests/Program.cs:180`에서 불일치/일치/InspectedOnly3분기·원본 보존 **PASS**. synthetic compiler는 GML 검증 증거가 아니다. |
| A04 HIGH, 원본에 근거한 미해결 전제 | `tools/runtime/run-current-account.ps1:50`, `current-account-state.ps1:133`; 원본 SCR_GAMESTART 시작 분기 | steam_initialised 후962/963의 Steam 존재에 따라 로컬 영구 기록을 쓰고,963이 있으면962의 Steam 삭제까지 요청한다. SAVE/RESET/엔딩 이전인 **시작 자체**의 효과다. 원본을 직접 확인했고 보존 검사도 통과했다. | 빈 관찰 cache/Cloud-off/Offline/로컬 복구는 SDK 반환값·계정 격리를 증명하지 못한다. **BLOCKED / NO-GO**. 원본 우회·SDK 위조·개인 기록 삭제로 통과시키지 않는다. 합법적인 읽기 전용 SDK/계정 안전성 근거가 필요하다. |
| A05 HIGH, 환경 미검증 | `tools/runtime/current-account-windows.ps1:21`, `current-account-state.ps1`, `run-current-account.ps1` | Win32 case-info/hardlink/stream/ACL/network/signature, 실제 NTFS snapshot/journal/rename, PS5.1/7의 네이티브 실행 증거 없음. | **NOT_RUN**. 비게임 임시 폴더에서 ordinary-user/PS5.1/7/Program Files read-only/link/ADS/case/권한 실패·중단 복구를 먼저 확인해야 한다. 개인 save로 시험하지 않는다. |
| A06 MEDIUM, 경로 경합 위험 | `SafeInstaller.cs:24,52,105,150`; `ModBuilder.cs:29`; exporter | 검사 후 open/move 사이 경로가 바뀔 수 있다. cooperative lock은 악의적 조상 rename을 잠그지 않는다. no-follow 디렉터리 핸들 트랜잭션이 아니다. | 공격 경합/NTFS **NOT_RUN**. 사용자 소유·동시 작성자 없는 공간 전제. 조상 거부 수정으로 경합까지 닫혔다고 주장하지 않는다. |
| A07 MEDIUM, 복구 보장 한계 | `current-account-state.ps1`, `safety.ps1`, `SafeInstaller.cs:120` | flush/atomic rename은 실제 정전 내구성 증명이 아니다. digest는 내용/존재를 비교하며 모든 ACL/시간/디렉터리 ADS 의미를 복원하지 않는다. Running 중단 후 사용자의 새 진행도 자동 구별할 수 없다. | synthetic failure99개 **PASS**; 실제 power-cut/Windows metadata **NOT_RUN**. 완료 fence/변경 save 거부 유지. 사고 후 게임 재실행/Cloud 연결 전 복구 검토 필요. |
| A08 MEDIUM, 캡처 사생활 한계 | `tools/runtime/capture-client.ps1:25,34`; `capture-game.ps1:33,43` | CopyFromScreen은 foreground/client 좌표 검사일 뿐 overlay·포커스·DPI 경합에서 다른 픽셀을 배제하지 못한다. | 잘못된 “other windows are excluded” 설명 수정. 실제 캡처 **NOT_RUN**. 선택적 비공개 증거이며 창 전용 캡처/게임 PASS가 아니다. 운영자의 사생활 검토 필요. |
| A09 MEDIUM, 오라클 한계 | `tests/*/Program.cs`, `Gml*Interpreter.cs`, `tools/audit-endings.py` | parity는 같은 테이블의 일치다. 일부 Candidate는 RouteCatalog 기대값을 사용한다. Contains/메뉴·입력·scheduler 모델은 실제 dispatch가 아니다. 제한 interpreter/conditional slice는 전체 VM/경로 증명이 아니다. | 원본115개 SHA·독립 조건 fixture·27 event 연결 검사 **PASS**. shared-oracle와 독립 검사를 구별했다. 실제 event order/softlock/모든 조합 **NOT_RUN**. |
| A10 MEDIUM, qlty 미열람 | GitHub qlty status / PR1 issues 대상 | success인데 설명은 “95 blocking issues”. 새 조회도 qlty 로그인으로 이동. check-run0개로 annotation도 없음. |95건 내용·중복·유효성 **BLOCKED / 미해결**. success로 통과/반박하지 않는다. 외부에 GitHub token을 보내지 않았다. |
| A11 LOW, 공급망·권한 전제 | `.github/workflows/ci.yml`, `authentic.yml:5` | Actions는 tag 고정이고 commit SHA 고정이 아니다. 비공개 Draft Release 조회에 contents:write를 사용한다. | upstream/private/nonfork8조건 **PASS**, checkout 자격 증명 미보존, 비공개 artifact 업로드 없음. token은 fetch 단계만 전달. upstream 코드는 신뢰 경계. hosted CI **BLOCKED**(billing), 재시도 없음. |
| A12 LOW, 신뢰된 입력 계약 | `tools/validate-authentic.py:42`, `ModBuilder.cs:61`, `G3MPackage.cs` | 비공개 작업 경로·프로필·compiler를 신뢰한다. version 문자열은 실행 파일 신뢰 증명이 아니며 진단 출력 메모리 크기 제한은 없다. G3M 경로는 Windows 예약명 전체를 모델링하지 않는다. | pinned 도구/현재 data.win 프로필/비공개 경로만 검증. 외부 입력 sandbox가 아니다. 실제 게임 G3M export/install **BLOCKED**(InspectedOnly); synthetic roundtrip만 PASS. |

수정 전/후 로그는 ignored `.research/audit-*`에 보관한다. 원본 소스·save 내용·
영문 atlas·patched binary·개인 증거는 Git/PR artifact에 포함하지 않는다.
역사적 Sandbox/별도 계정 스크립트도 전체 읽었지만 현재 계정 보호 증거로 승격하지
않는다. 이번 감사에서는 해당 스크립트나 Wine/QEMU bootstrap도 실행하지 않았다.

## 게임플레이·테스트 독립성

| 계열 | 원본 근거와 오프라인 결과 | 남은 불확실성 |
|---|---|---|
| Neutral18종/call goal | obj_mainend 선택·overwrite·슬롯 우선순위, 보스/우정/총 kill·비보스 차이/EXP/장비/회복/저장, pending reward/settlement 검토. 독립 fixture1728행·경계 **PASS**. | selector 만족은 도달 증명이 아니다. type6/goal8 **UNKNOWN** 유지. zero-EXP actor/inheritance/postbattle/backtracking 부분 폐쇄로 전체 불가능/가능을 단정하지 않는다. |
| Pacifist | prior Neutral/EXP/우정 순서/물·편지·lab 선행 조건/deadline 검토. 상태·objective·refusal 및 원본 골든 **PASS**. | 실제 대사·방 이동·reload·엔딩 NOT_RUN. |
| Genocide | scr_murderlv 지역·필수 적·plot, pending kill/overworld settlement/보스 deadline/late abandonment 검토. 원본 murder fixture53행 **PASS**. | runtime encounter/RNG·전투·모든 abandon 조합 NOT_RUN. Toriel19 경계는 kill/Destroy/settlement 근거가 있어 임의로20으로 바꾸지 않았다. |
| Soulless/RESET | local/Steam962/963, erase/restoration/history와 엔딩 분기 검토. pure history17검사 **PASS**. | 실제 Steam SDK/RESET/TRUE RESET NOT_RUN, 현재 계정 비파괴 smoke 범위에서도 제외. |
| Forced/자동 종료 | EX rating10000/12000(turn19 경계)·turn·Alarm/재자격/ack·mode·pending reward, ACT/FLEE/item·우정/물·optional/script 종료 anchor 검토. ratings24행·제한 scheduler 회귀 **PASS**. | 실제 Step/Alarm/Draw/Collision 순서·재시도 진행·입력/reload softlock NOT_RUN. 미증명 개입은 advisory/unsupported 유지. universal guarantee 없음. |
| UI/lifecycle | persistent controller·중복 instance·safe context·settings clamp·draw state/font 복원·key/pad edge/repeat/warning replay 전체 검토. UI20그룹/686 생성 비교/381 glyph **PASS**. | 실제 baseline/클리핑·DPI·overlay·물리 pad·cutscene/battle 입력 격리 NOT_RUN. 픽셀 UI/Galmuri14 보존. |

원본 골든도 제한 conditional slice와 수동 numeric branch mapping을 사용한다.
6245개 nonhook code 보존은 변하지 않은 코드의 의미가 안전함을 증명하지 않는다.
CompleteCoverage 플래그는 선언된 규칙 집합의 범위이지 실제 모든 플레이 경로 승인이 아니다.

## 실행 명령과 결과

Linux/Debian13 x64, SDK10.0.402, UndertaleModCli0.9.2.0, PowerShell7.6.8,
Pillow11.3.0에서 실행했다. `/path/to/`는 해당 검증 도구의 로컬 위치다.

```sh
dotnet build RouteKeeper.slnx -c Release
for suite in Core Neutral Decisions History Tool Saves Audit; do
  dotnet run --project tests/RouteKeeper.$suite.Tests -c Release --no-build
done
dotnet run --project tests/RouteKeeper.Core.Tests -c Release --no-build -- --verify-native integration/gml
dotnet run --project tests/RouteKeeper.Neutral.Tests -c Release --no-build -- --verify-gml integration/gml
dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release --no-build -- --verify-adapters integration/gml
dotnet run --project tests/RouteKeeper.Decisions.Tests -c Release --no-build -- --verify-ui integration
python integration/ui/generate.py --verify
python integration/generate_font.py --verify
python integration/ui/test_ui.py
python tools/test_runtime_lab.py
python tools/test_workflow_safety.py
python tools/audit-endings.py --source .research/all-code --output tests/golden/original-endings.json --verify
UndertaleModCli load private-data/data.win -s tools/audit-hooks.csx
python tools/test-preview-export.py --input private-data/data.win --cli /path/to/UndertaleModCli
pwsh -NoProfile -File tools/runtime/test-sandbox.ps1
python tools/validate-authentic.py --input private-data/data.win --cli /path/to/UndertaleModCli \
  --builder src/RouteKeeper.Tool/bin/Release/net10.0/RouteKeeper.Tool.dll --work .research/audit-authentic-current
python tools/runtime_lab.py verify --work .research/runtime-prepared
for rid in linux-x64 win-x64 osx-x64 osx-arm64; do
  dotnet publish src/RouteKeeper.Tool -c Release -r "$rid" --self-contained true -o "artifacts/audit-freeze-$rid"
done
PYTHONPATH=.research/g3m-deps python tools/test-g3m.py \
  --tool artifacts/audit-freeze-linux-x64/RouteKeeper.Tool \
  --xdelta .research/xdelta/runtime/usr/bin/xdelta3 --upstream .research/G3M-current
artifacts/audit-freeze-linux-x64/RouteKeeper.Tool build private-data/data.win \
  .research/audit-freeze-packaged.win /path/to/UndertaleModCli artifacts/audit-freeze-linux-x64
```

| 검사 | 실제 결과 |
|---|---|
| Build / 기본 C#6 suite / Audit | **PASS**:0 warnings/errors;268개(38/60/87/17/59/7); 별도9314 assertion |
| 생성 GML/font/UI | **PASS**:33개 전부 재생성 바이트 일치;381 glyph;20 UI그룹;686 GML 비교; 실제 영문 outline의 private offline preview |
| 독립 원본 provenance | **PASS**:127 binding signature,27 script/object/event/subtype dispatch, golden 전체115 source hash; fixture1728/53/24행 재도출 |
| PowerShell | **PASS(오프라인)**:12개 AST, interop compile,99 current-account filesystem/failure 및 legacy helper 검사; Win32 API 호출 없음 |
| Archive/workflow | **PASS**:9 archive/path 그룹, workflow8환경 조건, 기존 lab220개 원본 파일 불변 |
| 실제 데이터 컴파일/보존 | **PASS**:compile/serialize/reload,6245 nonhook code/나머지 resource 검사, modified/overwrite 거부, packaged builder 동일 해시 |
| 패키징/G3M | **PASS**:4 RID self-contained publish, source/tool/license만 포함, 실제 xdelta synthetic encode/decode·deterministic ZIP·현행 upstream parser·unverified 거부 |
| audio | **NOT_RUN(재생)**:216 stream-flag 중212 파일,4개 embedded buffer 참조, unresolved0. 처음 환경변수 없는 audit-assets 호출은 거부; 지정 후 read-only 검사 성공 |
| Native Windows PS5.1/7·NTFS·Steam·game, macOS/Linux gameplay | **NOT_RUN** |
| Hosted CI / qlty95건 상세 | **BLOCKED**:billing / 별도 qlty 로그인. 재실행·과금 변경 없음 |

다른 플랫폼으로 publish한 사실은 해당 플랫폼에서 실행했다는 뜻이 아니다.
원본 ZIP 재다운로드·개인 save/Steam 설치 변경·실제 게임 실행을 하지 않았다.

파일 목록과 해시는 다음 명령으로 다시 검사할 수 있다(저장소 루트에서 실행).

```sh
python - <<'PY'
import hashlib,json,pathlib,subprocess
m=json.loads(pathlib.Path('docs/audit-coverage.json').read_text())
paths=set(subprocess.check_output(['git','ls-files','-z']).decode().split('\0'))-{''}
assert paths=={r['path'] for r in m['files']}
for r in m['files']:
    if r['sha256']:
        assert hashlib.sha256(pathlib.Path(r['path']).read_bytes()).hexdigest()==r['sha256'],r['path']
print('PASS full tracked-file coverage and hashes:',len(paths))
PY
```

## 동적 GitHub 검토

인증 REST 전체 페이지(reviews/inline/issue/check-runs/statuses), GraphQL thread와
중첩 comments 전체 페이지를 직접 조회하고 HEAD 전후 일치를 확인했다.
818faba에서 reviews1(COMMENTED), inline2, issue12, threads2, check-runs0, statuses2.

- inline4371176621, updated2026-10-25T14:29:46Z: Snowdin 미정산 kill.
  현재 pending projection/ACT/SPARE/FLEE 경계 회귀로 **수정 유지 PASS**.
- inline4371176628, 같은 updated: private fork authentic job.
  upstream/private/nonfork gate와8환경 회귀로 **수정 유지 PASS**.
- 두 thread는 **outdated=true / resolved=false**. 코드 수정과 reviewer resolution은
  다르다. 해결/승인으로 자동 처리하지 않았다.
- review5643670524와 issue6398829491의 자동 요약은 새 기술 지적을 제공하지 않았다.
  나머지 댓글도 개별 확인했다. qlty95건은 A10처럼 미해결이다.
- push 전·후·최종 보고 직전 재조회한다. 최종 HEAD/시각/추가·수정 댓글은 세션 최종
  보고 및 비공개 ID/updated/HEAD/검증 ledger에 기록한다. 이후의 지속 감시/영구
  review 완료나 자동 요약에 의한 정식 승인을 주장하지 않는다.

## 다음 단계와 실행 경계

1. qlty 인증 상세를 소유자의 기존 접근권으로 열람·분류해야 한다. 이번 세션의95건은
   로그인 차단으로 판정하지 못했다.
2. 실제 Windows에서 **게임 없는** ordinary-user 임시 폴더/API 검증을 먼저 수행한다.
   PS5.1/7·ACL/hardlink/junction/ADS/case·부분 복사·journal 실패·복구·중복 호출을
   검사한다. test-current-account.ps1의 synthetic 검사가 Win32 gate 전체 실행은 아니다.
3. 원본 Steam 시작 분기의 계정 영구 기록 영향에 대한 읽기 전용 근거와 안전성 전제가
   확인되기 전에는 **run-current-account.ps1 -Action Run 실행 금지**.
   사용자 확인 flag는 격리 증거가 아니다. cache/history를 지워 gate를 넘기지 않는다.
4. 이후 별도 검토로 비파괴 original→patched smoke 허용 여부를 정한다. 개인 save 복구
   한계·원본 우선·수동 expected/actual 요구를 유지한다. 합법적 Steam 준비가 안 되면
   BLOCKED이며 우회하지 않는다.
5. 실제 UI/입력/전투/event order/softlock·엔딩별 경로와 native macOS/Linux exact-build
   profile/실행 검증은 남아 있다. 현재 호환 승인·병합·출시도 차단한다.

## 2026-10-27 follow-up (KST)

Latest scope/results are in non-runtime-status.md; original2026-10-26 totals above
are historical. The inventory now covers the current tracked tree.

| ID | Severity / evidence | Fix and regression | Status |
|---|---|---|---|
| A13 | HIGH: exact CLI03c7048 SaveDataFile writes OUTPUT+temp with Create; direct patch guards omitted this path. Authentic disposable-copy regression accepted/overwrote an existing scratch file before the fix. | patch.csx rejects existing/link/reparse scratch and dangling output; test-patch-paths.py exercises all3 cases without touching pristine data. | PASS offline; hostile TOCTOU remains A06 |
| A14 | HIGH: validate-authentic.py overwrote summary.json through a symlink after its final original check. Synthetic reproduction changed the input hash. Public work paths and linked ancestors also passed. | Actual .research boundary, lexical ancestor guards, fresh per-run directories, exclusive logs/summary, final hash recheck. test_private_validation.py5 regressions. | PASS offline |
| A15 | HIGH: NO-GO was documentation only; operator flags still reached Run platform/launch logic. | Unconditional Run refusal before helpers/OS/files/processes. Both cases tested despite risk flags. Preflight/recovery gates retained. | PASS offline; account safety still BLOCKED A04 |
| A16 | MEDIUM: compiler/xdelta output accumulated without bound; version prefix accepted other versions. | Concurrent bounded/cancellable pipe drain; strict version/metadata response limit; boundary tests and noisy subprocess. | PASS offline |
| A17 | LOW: G3M config accepted newline-suffixed hashes/paths and Windows reserved/aliased directory names. Failing C# regression before fix. | Whole-string anchors and portable component validation; valid macOS path retained. | PASS offline |

A11 mutable Action tags are now pinned to independently fetched commit IDs and
checked by local workflow tests. contents:write for private Draft input remains
scoped/gated; CI billing is still BLOCKED. A12 private work/memory/path defects
listed above were corrected; operator compiler/profile trust remains explicit.
No gameplay, Steam, native Windows APIs, compatibility promotion, merge or release.

A18 HIGH: sound Volume changes passed the old payload/count preservation checker
(reproduced in memory against the authentic candidate). Explicit legacy sound,
sprite/collision, font and texture-page metadata comparisons now reject7 independent
corruptions after a positive control; pristine/candidate files remain unchanged.
The bytecode16 policy now also compares original room/view/instance/tile and
object/event/action links. It is not a generalized GMS2 schema or engine behavior
proof. See test-resource-preservation.py.

A19 HIGH: default-encoding Python reads failed on the Hangul catalog in a CP1252
locale simulation. All tracked Path text IO now explicitly selects UTF-8 and
LF writes. Locale and whole-tree AST policy regressions pass; generated GML/font
bytes and the candidate hash remain unchanged. This is not native Windows evidence.
