# ROUTEKEEPER Beta Tester — tester guide / 시험자 안내

Version: 0.1.0-beta.1. Windows 10/11 x64, ordinary user, offline-capable WPF.
The desktop connects preparation, human-controlled launch, stop and guarded local
recovery. **Fresh Windows CI and interactive/native acceptance are pending.**
The exact game profile remains InspectedOnly; no compatibility promotion. A
successful process receipt is not independent gameplay verification.

## English

1. Obtain `routekeeper-beta-win-x64` from the **successful Windows job for the
   exact desired commit** in GitHub Actions, extract the ZIP to your own ordinary
   local folder, and run `RouteKeeper.Beta.Windows.exe`. No Visual Studio, SDK,
   Python, compiler installation or administrator privileges are needed with a
   complete dependency-bundled artifact. Keep all extracted files together.
   Unsigned beta builds may receive Windows trust prompts; verify provenance and
   the exact job/commit rather than disabling security settings.
2. Select application language at the top. In Sessions, enter the actual game
   build, mode and optional display/DPI, then create a session. Configuration is
   immutable for that session; create another for a different build/language/mode.
   Optional Windows/display/DPI collection asks first, shows the resulting text
   for review, and collects no account/device name or monitor serial.
3. Preparation discovers read-only Steam installation hints and checks exact
   identities. Hints, manifest/version strings and successful compilation do not
   prove ownership or supported gameplay. Select your legitimate installation and
   authenticated Steam client. Unknown or modified required files refuse.
4. The native preparation layer creates a new private working copy below
   `%LOCALAPPDATA%\RouteKeeper\Beta\native\prepared-<id>` and builds its patched
   candidate with the bundled official compiler and shared self-contained Tool.
   It preserves the registered original. A complete package includes physical
   `python/python.exe`, `python/pythonw.exe`, `compiler/UndertaleModCli.exe`,
   corresponding compiler source and notices; no developer installation is needed.
   In Preparation, use Check packaged native prerequisites (no game), then
   Prepare a new verified separate copy. Load private native reference restores
   the current checklist’s existing workspace/trial list. One workspace is linked
   to each checklist; a failed preparation remains discoverable for inspection.
   Preparation alone does not authorize launch. See the guarded lifecycle below.
5. In Guided testing, select a scenario and an individual step. Read its purpose,
   preconditions, risk, configuration, source, expected behavior and completion
   requirements. Follow existing authorized native procedures only. Record PASS,
   FAIL, BLOCKED, NOT_RUN, NEEDS_REVIEW or NOT_APPLICABLE with actual observations.
   Each click commits a new immutable revision. One passing step never passes an
   entire scenario. A failed step dominates; partial execution stays NOT_RUN.
   Catalog version2 contains 82 scenarios and 434 independently recordable steps.
   Route prerequisites and ordered objectives are presented directly from the
   maintained Core tables, including their existing Korean text. A condition that
   is not yet observable stays UNKNOWN; do not guess raw game flags from a picture.
6. High-risk scenarios (including SAVE/LOAD, RESET, routes/endings) need their own
   exact typed scenario phrase before recording executed results. This is a local
   documentary authorization, **not** independent authentication or native-launch
   consent. Ordinary smoke approval cannot authorize destructive gameplay.
7. Optional screenshots are imported, bounded, converted to RGBA PNG and stripped
   of ancillary metadata. The import dialog shows source-image pixel dimensions.
   Enter `x,y,width,height` and Apply opaque rectangle to black out private areas;
   repeat as needed and review the entire resulting image. Each change clears
   the sharing-review checkbox. The original private file remains unchanged.
   Literal text redaction does not change image pixels.
   Mark reviewed-for-sharing only after inspection. Import never uploads anything.
   Duplicate sanitized screenshots within one session are refused. Imports remain
   UnverifiedClaim: local hashes cannot prove when or where pixels were captured.
8. Use Issues for expected/actual behavior, reproduction and severity P0–P3.
   It uses the currently selected scenario/step and actual-observation field.
   Create an issue or append a revision to its stable ID. Only reviewed screenshots
   for that same step are linked. Nothing is posted to GitHub automatically.
9. Pause and reopen a saved session to resume the checklist. Completed sessions are
   immutable; untested steps remain NOT_RUN. Resuming never resumes a game or
   replays input. Corrupt, changed-catalog, missing-revision and changed-screenshot
   sessions refuse visibly. The explicit interrupted-publication recovery action
   can publish only a verified next revision after exact review and typed consent;
   it does not repair arbitrary corruption or delete history.
10. Dashboard separates implementation, automated, human execution, human result,
    independent verification, evidence and compatibility. Feature/build/language/
    configuration coverage applies to this session. Refresh all local sessions
    shows combined coverage and human result changes between comparable sessions
    with the same build/language/mode/display. NOT_RUN gaps are not behavioral
    changes; corrupt histories stay visibly blocked. These comparisons are human
    reports, not gameplay certification. Independent verification stays NOT_RUN.
11. Export/Privacy offers literal text redaction, a sanitized JSON preview and
    JSON/HTML/CSV export to a **new** folder. Screenshot inclusion is off by default
    and still excludes unreviewed images when enabled. HTML works offline and
    escapes notes. CSV escapes formula prefixes. `integrity.json` detects changed
    exported bytes, not external authenticity. Review the final report before
    sharing it yourself. No upload or issue publication occurs.
12. Local results live in `%LOCALAPPDATA%\RouteKeeper\Beta\sessions`. Candidates
    and native trials live under the sibling `native` directory; private bindings
    and controller logs live under `native-ui`. These are not report attachments.
    Results/issue history/screenshots persist until explicitly deleted. Deleting a
    session requires its exact ID phrase and refuses unknown files or links.
    Exported copies remain and need separate deletion. No secure erasure claim.
    No Steam credentials, save contents, installed binaries, process census,
    usernames or full installation paths are collected into exported session data.
    Native preparation/recovery necessarily uses private local paths, exact owned
    process identities and save backups. These stay in the private workspace.
    Your own text and pixels can still disclose private information.

Guarded human lifecycle: the controller in `tools/runtime/human-session.ps1`
provides Check, Prepare, Run, Recover and Cleanup. Use the desktop integration only
through Preparation; these names describe the protocol, not a request to execute
scripts manually. First select the scenario and step in Guided testing. Back in
Preparation, select original/patched, scope and maximum seconds. Use Review
disclosure and start selected human scenario / step. Read the disclosure and authorize the selected
original/patched case, scenario and scope. Smoke is limited to 300 seconds and
excludes gameplay; Gameplay/HighRisk allow at most 7200 seconds including reserved
shutdown time. High-risk cases also require their own exact scenario phrase.
The request expires after five minutes. Checklist authorization is separate.

Continuation is off by default: a new trial uses a fresh isolated save. To continue,
select an exact earlier trial in the current checklist’s prepared workspace and
check Continue the selected prior trial’s verified private save. Choose matching
original/patched case, language and mode with Gameplay or HighRisk scope; Smoke
cannot continue. The disclosure shows the prior ID and still requires fresh consent.
A prior HighRisk trial requires fresh HighRisk scope and the current scenario’s
exact phrase, even when the selected scenario itself has lower declared risk.
Continuation checks completed local restoration/fence, unchanged personal baseline,
matching prepared build and sealed process/result/archive hashes. It copies only
the owned archived trial save after personal-save quarantine and verifies the copy;
it does not import personal saves, rewrite the source archive or replay inputs.
Missing, changed or incompatible prior evidence refuses and preserves every copy.

The controller requires its native Windows desktop, verified owned working copy,
physical-network/offline policy, Steam registration/signature/identity,
cache/history checks, save transaction and external watchdog. Prepare Steam
Offline and keep Cloud disabled as disclosed; unknown prerequisites refuse.
You control every game action; the human loop dispatches zero automated inputs.
Steam/game actions can still alter permanent account history or queue Cloud work.
Local restoration cannot undo achievements, RemoteStorage or account history.

Use Request safe stop or the Pause/Break emergency key, then wait for the
local recovery result before closing the app. A deadline, lost app/process identity,
network-policy failure or unknown child process stops the trial through the guarded
coordinator. Keep private workspaces and all copies after BLOCKED or
RECOVERY_REQUIRED. Use the explicit recovery path for that exact native transaction;
reopening a checklist never relaunches the game. Cleanup only removes the owned
unchanged game copy after restoration/fence checks; it is not session deletion.
Never delete unknown files, reconnect Cloud or manually launch the copy to clear a
refusal.

For an authorized screenshot, choose Request consented local capture, then return
focus to the game within its three-second grace period. The app never focuses the
game for you. Stop and emergency checks remain active while capture is pending.
Request one capture at a time; an unfocused/invalid capture is visibly refused.

Process start/stop/exit receipts are AutomatedObservation with
PROCESS_ONLY_NOT_GAMEPLAY scope. They do not prove a crash cause, route state,
input correctness or gameplay PASS. Optional capture requires separate launch
consent and sharing review; a refused capture remains visible without refocusing
or sending game input. Select the exact trial and matching Guided testing step,
then Import optional capture through pixel redaction / review. Import sanitized
process / recovery receipt separately if needed. Images remain UnverifiedClaim. Local process diagnostics
and recovery evidence are not a license to export private paths or saves.

## 한국어

데스크톱에서 준비·사람의 게임 실행·중지·보호된 로컬 복구를 연결합니다.
새 Windows CI와 실제 화면·네이티브 시험은 아직 검증해야 합니다. 정확한 게임
프로필은 InspectedOnly이며 프로세스 기록만으로 게임플레이를 인증하지 않습니다.

1. 원하는 커밋의 **성공한 Windows Actions 작업**에서
   `routekeeper-beta-win-x64`를 받아 압축을 풀고
   `RouteKeeper.Beta.Windows.exe`를 실행하세요.
   완전한 의존성 묶음에는 Visual Studio, SDK, Python, 컴파일러를 따로 설치하거나
   관리자 권한을 사용할 필요가 없습니다. 압축을 푼 파일은 함께 보관하세요.
2. 상단에서 한국어를 선택하세요. 세션 탭에 실제 빌드·모드·선택적 해상도/DPI를
   입력하고 세션을 만드세요. 다른 설정은 새 세션에서 시험하세요. 선택적
   Windows·화면·DPI 수집은 먼저 동의를 묻고 세션 생성 전 결과를 확인하게 합니다.
   계정·장치명·모니터 일련번호는 수집하지 않습니다.
3. 준비 탭의 탐색은 읽기 전용 위치 힌트입니다. 버전·manifest·컴파일 성공은
   소유권이나 게임플레이 호환성을 입증하지 않습니다. 본인의 정상 설치와 인증된
   Steam을 선택하세요. 알 수 없거나 바뀐 필수 파일은 거부합니다. 네이티브 준비는
   `%LOCALAPPDATA%\RouteKeeper\Beta\native\prepared-<id>`에 새 작업 복사본을
   만들고 동봉된 공식 컴파일러와 Tool로 후보를 빌드합니다. 등록된 원본은 보존합니다.
   패키지 전제 조건 검사 후 별도 복사본 새로 준비를 사용하세요. 비공개 네이티브
   연결 불러오기로 현재 체크리스트의 공간과 시험 목록을 다시 읽습니다. 실패한
   준비도 검토할 수 있도록 남습니다. 준비 성공만으로 실행이 승인되지는 않습니다.
4. 안내 시험에서 시나리오와 개별 단계를 고르고 목적·사전 조건·위험·예상 결과를
   읽으세요. 기존 승인된 네이티브 절차의 범위에서만 시험하세요. 단계마다 실제
   관찰과 PASS/FAIL/BLOCKED/NOT_RUN/NEEDS_REVIEW/NOT_APPLICABLE을 저장하세요.
   한 단계의 PASS로 시나리오 전체가 PASS가 되지 않습니다. 목록 버전2에는
   시나리오82개와 개별 기록 단계434개가 있습니다. 경로의 선행 조건·순서별 목표는
   유지하는 Core 표와 기존 한국어 문구를 직접 사용합니다. 아직 관찰할 수 없는
   조건은 UNKNOWN으로 남기고 그림만 보고 내부 게임 플래그를 추측하지 마세요.
5. SAVE/LOAD·RESET·경로·엔딩은 고위험 별도 승인 문구가 필요합니다. 이 승인은
   체크리스트의 기록용이며 게임 실행 승인이나 Steam 안전성 보증이 아닙니다.
6. 화면 첨부는 선택입니다. 가져오기 창에서 원본 픽셀 크기를 확인하고
   `x,y,너비,높이` 좌표를 입력해 검정 불투명 사각형으로 개인정보를 가리세요.
   필요한 만큼 반복한 뒤 전체 화면을 검토하세요. 변경할 때마다 공유 검토 선택은
   해제됩니다. 원본 비공개 파일은 바뀌지 않습니다. PNG 메타데이터는 제거하지만
   개인정보를 자동으로 찾아 지우지는 않습니다. 문구 가림은 픽셀을 바꾸지 않습니다.
   전체 화면을 검토한 뒤에만 공유 검토 완료를 선택하세요. 자동 업로드는 없습니다.
7. 오류 탭에서 예상·실제·재현 절차·심각도를 입력하세요. 현재 선택한 단계와 실제
   관찰 입력란을 사용합니다. 오류 ID와 이전 수정 이력은 유지됩니다. GitHub에
   자동 게시하지 않습니다.
8. 일시 중지 후 앱을 다시 열어 저장한 세션을 재개하세요. 완료한 세션은 수정할
   수 없습니다. 앱 재개는 게임 실행이나 입력 재개가 아닙니다. 손상된 기록은
   덮어쓰지 않고 거부합니다. 거부된 파일을 임의로 삭제하여 통과시키지 마세요.
9. 현황판은 구현·자동 검사·사람의 실행·사람의 결과·독립 검증·증거·호환성을
   따로 표시합니다. 전체 로컬 세션 새로고침은 합산 범위와 같은 빌드·언어·모드·
   화면 설정 사이의 사람 결과 변경을 보여 줍니다. NOT_RUN은 행동 변경으로
   취급하지 않으며 손상된 기록은 차단 상태로 표시합니다. 사람의 PASS는 독립 검증
   PASS가 아닙니다.
10. 내보내기 탭에서 가릴 문구를 한 줄씩 입력하고 JSON 미리보기를 검토하세요.
    새 폴더에 JSON·오프라인 HTML·CSV를 내보냅니다. 화면은 기본 제외이며,
    포함을 선택해도 공유 검토한 화면만 들어갑니다. 최종 보고서는 직접 다시
    검토한 뒤 공유하세요. 해시는 변경 탐지 수단이며 외부 진위 인증이 아닙니다.
11. 기록은 `%LOCALAPPDATA%\RouteKeeper\Beta\sessions`에 남습니다. 세션 삭제는
    정확한 ID 문구를 입력해야 하며 알 수 없는 파일·링크가 있으면 거부합니다.
    이미 내보낸 복사본은 따로 삭제하세요. 세션은 직접 삭제할 때까지 보관됩니다.
12. 안내 시험에서 시나리오·단계를 고른 뒤 준비 탭에서 원본/패치·범위·시간을
    선택하고 고지 검토 후 시작을 사용하세요. 선택한 시나리오·범위의 고지를
    읽고 별도로 승인하세요. Smoke는 최대300초이며 게임 진행을 포함하지 않습니다.
    Gameplay·HighRisk는 종료 여유를 포함해 최대7200초이고 고위험 시나리오는
    전용 문구도 필요합니다. 승인은5분 후 만료됩니다. 체크리스트 승인과는 별개입니다.
이어하기는 기본 해제입니다. 새 시험은 새 격리 세이브를 사용합니다. 이어하려면 현재
체크리스트의 같은 준비 공간에서 정확한 이전 시험을 고르고 검증된 비공개 세이브
이어하기를 선택하세요. 원본/패치·언어·모드가 같아야 하고 Gameplay·HighRisk만
허용됩니다. 고지에 이전 ID가 표시되며 새 승인이 필요합니다. 이전 시험이 HighRisk면
현재 시나리오 위험도가 낮아도 HighRisk 범위와 현재 시나리오 전용 문구가 필요합니다.
복구·완료 fence·개인 기준선 무변경·동일 빌드·기록 및 보관 세이브 해시를 검증한 뒤
개인 세이브를 격리하고 시험 보관본만 복사합니다. 개인 세이브를 가져오거나 이전
입력을 재생하지 않습니다. 증거가 없거나 바뀌거나 맞지 않으면 복사본을 보존하고
거부합니다.

13. 네이티브 조정기는 물리 네트워크·오프라인 정책, Steam 등록·서명·신원,
    캐시·기록, 세이브 거래와 외부 watchdog을 검사합니다. Steam 오프라인과 Cloud
    비활성화 조건을 지키세요. 조건이 불명확하면 거부합니다. 게임 조작은 사람이
    직접 하며 수동 시험 루프는 자동 입력을 보내지 않습니다.
14. 종료는 조정기의 Stop 또는 Pause/Break 비상 키를 사용하고 로컬 복구 결과를
    기다리세요. 제한 시간·신원 상실·네트워크 조건 실패·알 수 없는 자식 프로세스는
    보호된 종료 절차로 이어집니다. BLOCKED·RECOVERY_REQUIRED이면 모든 복사본을
    보존하고 정확한 거래의 복구 경로를 사용하세요. 체크리스트 재개는 게임 재실행이
    아닙니다. 검증된 복구 뒤의 Cleanup은 소유한 게임 복사본 정리이며 세션 삭제와
    다릅니다. Cloud 재연결·파일 삭제·수동 실행으로 거부를 해제하지 마세요.
15. 화면 수집을 요청하면3초 안에 직접 게임으로 초점을 돌리세요. 앱이 대신
    초점을 바꾸지 않으며 대기 중에도 중지·비상 검사는 유지됩니다. 한 번에 한 화면만
    요청하세요. 초점·보호 조건이 맞지 않으면 수집을 거부합니다.
    정확한 시험과 안내 단계를 선택한 뒤 선택 화면 가져오기를 사용하면 픽셀
    가림·검토를 거쳐 첨부합니다. 프로세스·복구 기록은 별도 가져올 수 있습니다.
    자동 프로세스 시작·종료 기록은 PROCESS_ONLY_NOT_GAMEPLAY 범위입니다.
    충돌 원인·게임 상태·사람의 PASS를 입증하지 않습니다. 선택적 화면 수집에는
    별도 동의와 공유 전 픽셀 검토가 필요합니다. 수집 거부는 게임에 입력을 보내지
    않고 표시됩니다. 로컬 백업·진단에는 개인 경로가 있을 수 있으니 내보내지 마세요.
    로컬 복구는 Steam 계정·업적·RemoteStorage·영구 기록을 되돌리지 않습니다.
16. `native` 작업 공간과 `native-ui` 연결·로그·비공개 백업은 체크리스트 삭제와
    별개로 남습니다. 모든 시험의 복구·등록 파일·캐시 무변경 검증이 끝난 뒤에만
    폐기할 공간을 직접 삭제하세요. 미확인 상태의 증거·백업은 보존하세요.

## Developer verification and local acceptance

Scenario coverage / 시나리오 범위:

- Neutral targets 0..18 cover Any Neutral and each specific target, with individual
  boss outcome, total-kill, relevant friendship-order and ending-observation steps.
  중립 목표0..18은 아무 중립 엔딩과 각 세부 목표를 다루며 보스 결과·총 처치 수·
  해당 우정 순서·엔딩 관찰을 각각 기록합니다.
- All eight optional call goals include their canonical compatible targets and
  each prerequisite. Matching optional conditions can overwrite shared dialogue
  slots; they do not guarantee an exclusive spoken line. Target6/call-goal8 remains
  explicitly UNKNOWN where its global reachability is unresolved.
  선택 통화 목표8개에는 원래 호환 목표와 각 선행 조건이 있습니다. 조건이 맞아도
  공유 대사 슬롯이 덮어써질 수 있으며 배타적 대사 한 줄을 보장하지 않습니다.
  전체 도달 여부가 미해결인 목표6·통화 목표8 조합은 명시적으로 UNKNOWN입니다.
- True/Soulless Pacifist and Genocide check each source requirement and ordered
  objective separately. Stay/Leave epilogues, SAVE/LOAD, ordinary RESET and TRUE
  RESET have separate high-risk scenarios. Existing SOUL history is observed,
  never created, erased or repaired by the tester app.
  평화·몰살 및 영혼 없는 변형은 원본 근거 조건·순서별 목표를 각각 검사합니다.
  함께 살기·떠나기, SAVE/LOAD, 일반 RESET, TRUE RESET은 각각 별도 고위험
  시나리오입니다. 기존 SOUL 기록을 관찰할 뿐 앱이 만들거나 지우거나 고치지 않습니다.
- Off/Passive/Active/Forced, keyboard/controller conflicts, localization, display,
  configuration, warnings, inventory, backup/identity/filesystem/watchdog and
  checklist/report/privacy flows have concrete bilingual step instructions.
  Off·Passive·Active·Forced, 키보드·컨트롤러 충돌, 언어·화면·설정·경고·소지품,
  백업·신원·파일시스템·감시기와 체크리스트·보고서·개인정보 흐름에 구체적인
  영어·한국어 단계 지침이 있습니다.

```sh
dotnet build RouteKeeper.slnx -c Release
dotnet run --project tests/RouteKeeper.Beta.Tests -c Release
dotnet publish src/RouteKeeper.Beta.Windows -c Release -r win-x64 --self-contained true -o artifacts/beta
python tools/package_beta_dependencies.py --output artifacts/beta
python tools/verify_beta_package.py artifacts/beta
```

On Windows only: `RouteKeeper.Beta.Windows.exe --smoke-test` constructs and lays out
WPF controls without a game. This does not certify interactive rendering. Actual
acceptance remains NOT_RUN until a human verifies keyboard-only operation, Narrator,
100/125/150/200% DPI, English/Korean switching, scroll/resize, create/pause/restart,
each step result, all-step aggregation, corruption refusal, optional private PNG
review, issue revisions, redacted exports and explicit deletion on disposable data.
Then separately test the legitimate game using the existing documented guards.
Do not upload the resulting personal screenshots or saves to CI.
