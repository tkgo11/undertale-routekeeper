using System.IO;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using Microsoft.Win32;

namespace RouteKeeper.Beta.Windows;

public sealed partial class MainWindow
{
    private readonly NativeController native = new();
    private readonly DataGrid historySessions = Grid(), historyCoverage = Grid(), historyChanges = Grid();
    private readonly TextBlock historyErrors = Text("");
    private UIElement NativePreparation()
    {
        var panel = new StackPanel();
        panel.Children.Add(Text(T("Prepare and control a human-operated native session", "사람이 조작하는 네이티브 세션 준비 및 관리"), 24));
        panel.Children.Add(Text(T("Exact profile: InspectedOnly; Windows runtime NOT_RUN here. Human controls every game action. No automatic game input or upload. During a trial, Pause is the emergency stop key; safe stop still requires recovery. Before launch the required native API self-test opens owned harmless fixture windows, sends guarded test keys only to that fixture and retains local fixture captures. The shipped helper uses process-only PowerShell execution policy; no machine/user or domain policy is changed. Native receipts are immutable, timestamped historical process/recovery observations, never current recovery readiness or gameplay PASS. Preparation copies your legitimate installation and builds a separate candidate; it never swaps registered files.", "정확한 프로필: InspectedOnly. 이 환경의 Windows 실행은 NOT_RUN입니다. 게임은 사람이 직접 조작하며 자동 게임 입력·업로드가 없습니다. 시험 중 비상 중지는 Pause 키이며 중지 후에도 안전 복구가 필요합니다. 실행 전 필수 네이티브 API 검사는 소유한 무해한 시험 창을 열어 그 창에만 보호된 시험 키를 보내고 로컬 시험 화면을 보관합니다. 배포한 도우미에 프로세스 한정 PowerShell 실행 정책을 사용하며 컴퓨터·사용자·도메인 정책은 변경하지 않습니다. 네이티브 기록은 시각이 기록된 변경 불가 과거 프로세스·복구 관찰이며 현재 복구 준비 상태나 게임플레이 PASS가 아닙니다. 준비는 정상 설치를 복사해 별도 후보를 빌드하며 등록 파일을 교체하지 않습니다.")));
        var install = Input(); var steam = Input();
        var trials = new ComboBox { Margin = new Thickness(4), DisplayMemberPath = "Id" };
        NativeController.Binding? binding = null;
        var info = Text("");
        void LoadBinding()
        {
            binding = NativeController.Load(Current().Id);
            install.Text = binding?.GameInstall ?? ""; steam.Text = binding?.SteamExe ?? "";
            trials.ItemsSource = binding?.Trials.Reverse().ToArray(); trials.SelectedIndex = 0;
            info.Text = binding is null ? T("No prepared workspace linked to this checklist.", "이 체크리스트에 연결한 준비 공간이 없습니다.") : binding.Work;
        }
        panel.Children.Add(Button(T("Load private native reference for current checklist", "현재 체크리스트의 비공개 네이티브 연결 불러오기"), LoadBinding));
        Label(panel, T("Legitimate registered game installation folder", "정상 등록 게임 설치 폴더"), install);
        panel.Children.Add(Button(T("Choose installation folder", "설치 폴더 선택"), () =>
        { var picker = new OpenFolderDialog(); if (picker.ShowDialog(this) == true) install.Text = picker.FolderName; }));
        Label(panel, T("Owned authenticated Steam client executable", "소유 계정으로 인증한 Steam 실행 파일"), steam);
        panel.Children.Add(Button(T("Choose Steam client", "Steam 클라이언트 선택"), () => Pick(steam, "Steam client|steam.exe")));
        panel.Children.Add(Button(T("Discover installed-game hints", "설치 게임 위치 탐색"), () =>
        {
            var found = RouteKeeper.Tool.SteamDiscovery.Discover();
            if (found.Count == 1) install.Text = Path.GetDirectoryName(found[0].DataPath) ?? "";
            Say(string.Join("\n", found.Select(c => c.DataPath + " · " + c.Status)));
        }));
        panel.Children.Add(AsyncButton(T("Check packaged native prerequisites (no game)", "패키지 네이티브 전제 조건 검사 (게임 실행 없음)"), async () =>
        { int code = await native.Invoke("Check"); Say(code == 0 ? "READY_NATIVE_PREREQUISITES_ONLY · GAMEPLAY NOT_RUN" : "BLOCKED_NATIVE_PREREQUISITES"); }));
        panel.Children.Add(AsyncButton(T("Prepare a new verified separate copy", "검증한 별도 복사본 새로 준비"), async () =>
        {
            var current = Current();
            binding = NativeController.Load(current.Id);
            if (binding is not null) throw new InvalidOperationException(T("A workspace is already linked. Preserve and recover its trials before preparing another checklist session.", "이미 연결한 작업 공간이 있습니다. 이력을 보존·복구한 뒤 별도 체크리스트 세션을 사용하세요."));
            var next = new NativeController.Binding(current.Id, NativeController.NewWork(), OwnedFiles.NoLinks(install.Text), OwnedFiles.NoLinks(steam.Text), []);
            // Persist before dispatch: even a failed preparation has a discoverable private location.
            NativeController.Save(next); binding = next; info.Text = next.Work;
            int code = await native.Invoke("Prepare", next);
            Say(code == 0 ? T("Prepared; game NOT_RUN. Native launch still requires fresh disclosure and typed consent.", "준비 완료, 게임 NOT_RUN. 실행에는 새 고지 검토와 직접 입력 승인이 필요합니다.") : T("Preparation blocked. Preserve this private workspace; no runtime verification.", "준비가 차단됐습니다. 비공개 작업 공간을 보존하세요. 실행 검증이 아닙니다."));
        }));
        panel.Children.Add(info);
        panel.Children.Add(Text(T("Native references, requests, screenshots, diagnostic logs, trial save copies and recovery journals are private local records, retained separately from checklist deletion/export under RouteKeeper/Beta/native, RouteKeeper/Beta/native-ui and RoutekeeperE2E/native-beta-ID in LocalAppData. Cleanup below removes only a verified owned game copy. Preserve all copies whenever restoration is unknown or blocked; do not manually remove trial saves or journals to bypass guards. After every trial has verified restoration and unchanged registered/cache checks, you may delete the retired workspace and separate native-ui reference/log records yourself in Explorer; this destroys private evidence and backups. Exports remain separate.", "네이티브 연결·요청·화면·진단 로그·시험 세이브 복사본·복구 기록은 체크리스트 삭제·내보내기와 별개로 LocalAppData의 RouteKeeper/Beta/native, RouteKeeper/Beta/native-ui, RoutekeeperE2E/native-beta-ID에 보관하는 비공개 로컬 기록입니다. 아래 정리는 검증한 소유 게임 복사본만 제거합니다. 복구가 미확인·차단이면 모든 복사본을 보존하고 보호를 우회하려고 세이브·기록을 수동 삭제하지 마세요. 모든 시험의 복구와 등록 파일·캐시 무변경을 검증한 뒤에만 폐기할 작업 공간과 별도 native-ui 연결·로그를 탐색기에서 직접 삭제할 수 있습니다. 비공개 증거·백업도 삭제되며 내보낸 복사본은 별개입니다.")));
        panel.Children.Add(Button(T("Open current private workspace for local inspection", "현재 비공개 작업 공간을 로컬 검토용으로 열기"), () =>
        {
            var owned = NativeController.Load(Current().Id) ?? throw new InvalidOperationException("No private workspace linked.");
            var start = new System.Diagnostics.ProcessStartInfo(OwnedFiles.NoLinks(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Windows), "explorer.exe"))) { UseShellExecute = false };
            start.ArgumentList.Add(OwnedFiles.NoLinks(owned.Work)); System.Diagnostics.Process.Start(start)?.Dispose();
        }));
        var scope = new ComboBox { ItemsSource = new[] { "Smoke", "Gameplay", "HighRisk" }, SelectedIndex = 0, Margin = new Thickness(4) };
        var variant = new ComboBox { ItemsSource = new[] { "original", "patched" }, SelectedIndex = 0, Margin = new Thickness(4) };
        var duration = Input("180");
        var pixels = new CheckBox { Content = T("Separately allow optional local screenshots (never automatic sharing)", "선택한 로컬 화면 수집 별도 허용 (자동 공유 없음)"), Margin = new Thickness(4) };
        Label(panel, T("Native scope (separate from checklist authorization)", "네이티브 범위 (체크리스트 승인과 별개)"), scope);
        Label(panel, T("Original / patched copy", "원본 / 패치 복사본"), variant);
        Label(panel, T("Absolute maximum seconds: 60–300 Smoke; 60–7200 other scopes", "최대 실행 시간: Smoke 60~300초, 그 외 60~7200초"), duration);
        panel.Children.Add(pixels);
        var continuation = new CheckBox { Content = T("Continue the selected prior trial's verified private save (Gameplay / HighRisk only; never personal saves)", "선택한 이전 시험의 검증된 비공개 세이브 이어하기 (Gameplay·HighRisk 전용, 개인 세이브 사용 없음)"), Margin = new Thickness(4) };
        panel.Children.Add(continuation);
        panel.Children.Add(AsyncButton(T("Review disclosure and start selected human scenario / step", "고지 검토 후 선택한 사람 시험 시나리오·단계 시작"), async () =>
        {
            var current = Current(); var pair = Selected();
            if (current.State != "Active") throw new InvalidOperationException("Native launch requires an active checklist.");
            binding = NativeController.Load(current.Id) ?? throw new InvalidOperationException("Prepare the current checklist first.");
            string selectedScope = (string)scope.SelectedItem;
            if (!int.TryParse(duration.Text, out int seconds) || seconds < 60 || seconds > (selectedScope == "Smoke" ? 300 : 7200)) throw new InvalidOperationException("Deadline outside scope.");
            if (pair.Scenario.Risk == Risk.HighRisk && selectedScope != "HighRisk" || pair.Scenario.Risk == Risk.Gameplay && selectedScope == "Smoke") throw new InvalidOperationException("Scenario requires a separate broader scope.");
            string prior = "";
            if (continuation.IsChecked == true)
            {
                if (selectedScope == "Smoke" || trials.SelectedItem is not NativeController.Trial selectedPrior || !binding.Trials.Contains(selectedPrior))
                    throw new InvalidOperationException("Continuation requires explicit matching prior trial and Gameplay / HighRisk scope.");
                prior = selectedPrior.Id;
            }
            string disclosure = NativeController.PolicyDisclosure();
            string nonce = Guid.NewGuid().ToString("N");
            string phrase = "AUTHORIZE HUMAN BETA " + nonce;
            string? typed = Prompt(disclosure + "\n\n" + T("Private diagnostics are mandatory for safe recovery. A required harmless native fixture tests guarded key dispatch and retains its local window capture; no automatic game inputs are sent. Local restoration does not undo Steam account history. Review the selected scope, scenario, step and deadline; type the fresh phrase yourself.", "안전한 복구를 위해 비공개 진단 기록이 필수입니다. 무해한 소유 네이티브 시험 창에서 보호된 키 전송을 검사하고 해당 창의 로컬 화면을 보관합니다. 게임에는 자동 입력을 보내지 않습니다. 로컬 복구는 Steam 계정 이력을 되돌리지 못합니다. 선택 범위·시나리오·단계·시간을 확인한 뒤 새 문구를 직접 입력하세요.") +
                $"\n{selectedScope} · {pair.Scenario.Id}/{pair.Step.Id} · {variant.SelectedItem} · {seconds}s\nContinuation: { (prior.Length == 0 ? "NONE_FRESH_TRIAL" : prior) }\n{phrase}");
            if (typed is null) return;
            if (typed != phrase) throw new InvalidOperationException("Fresh typed native consent differs.");
            string? highRisk = null;
            if (selectedScope == "HighRisk")
            {
                string required = "AUTHORIZE HIGH RISK " + pair.Scenario.Id;
                highRisk = Prompt(T("This scenario may permanently change account history. Separate high-risk scope is required. Type: ", "이 시나리오는 계정 이력을 영구 변경할 수 있습니다. 고위험 범위 별도 승인 입력: ") + required);
                if (highRisk is null) return;
                if (highRisk != required) throw new InvalidOperationException("High-risk scope differs.");
            }
            var trial = new NativeController.Trial(Guid.NewGuid().ToString("N"), pair.Scenario.Id, pair.Step.Id);
            byte[] request = NativeController.Request(binding, trial, current.Configuration, pair.Scenario.Risk, selectedScope, (string)variant.SelectedItem, seconds, pixels.IsChecked == true, nonce, typed, highRisk, prior);
            string requestPath = NativeController.WriteRequest(binding, trial, request);
            binding = binding with { Trials = [.. binding.Trials, trial] }; NativeController.Save(binding);
            trials.ItemsSource = binding.Trials.Reverse().ToArray(); trials.SelectedIndex = 0;
            Say(T("Controller starting. Human input only. Stop requests safe shutdown; do not kill the app/controller or Steam. A recovery-required result must remain unresolved until verified.", "조정기를 시작합니다. 입력은 사람만 합니다. 중지는 안전 종료를 요청합니다. 앱·조정기·Steam을 강제 종료하지 마세요. 복구 필요 상태는 검증 전까지 미해결입니다."));
            int code = await native.Invoke("Run", binding, trial, requestPath);
            Say(code == 0 ? "CONTROLLER_FINISHED · inspect/import recovery receipt · GAMEPLAY NOT_INDEPENDENTLY_VERIFIED" : "BLOCKED / RECOVERY_MAY_BE_REQUIRED · preserve workspace · inspect locally");
            ImportNativeReceipt(binding, trial, false);
        }));
        panel.Children.Add(Button(T("Request safe stop (never kill controller)", "안전 중지 요청 (조정기 강제 종료 없음)"), () => { native.Command("stop"); Say("SAFE_STOP_REQUESTED · wait for recovery receipt"); }));
        panel.Children.Add(Button(T("Request consented local capture", "별도 동의한 로컬 화면 수집 요청"), () => { native.Command("capture"); Say(T("CAPTURE_REQUESTED · return focus to the game within 3 seconds · private unreviewed pixels only", "화면 요청 전송 · 3초 안에 게임으로 초점을 직접 돌리세요 · 검토 전 비공개 화면")); }));
        Label(panel, T("Exact owned native trial for inspection / recovery", "검토·복구할 정확한 소유 네이티브 시험"), trials);
        NativeController.Trial Trial() => trials.SelectedItem as NativeController.Trial ?? throw new InvalidOperationException("Select an exact native trial.");
        NativeController.Binding Bound() => NativeController.Load(Current().Id) ?? throw new InvalidOperationException("Load a matching native reference.");
        panel.Children.Add(Button(T("Import historical process / recovery receipt", "개인정보 제외 과거 프로세스·복구 관찰 가져오기"), () => ImportNativeReceipt(Bound(), Trial(), true)));
        panel.Children.Add(Button(T("Import optional capture through pixel redaction / review", "선택 화면을 픽셀 가림·검토 후 가져오기"), () =>
        {
            var selected = Trial(); var pair = Selected();
            if (pair.Scenario.Id != selected.Scenario || pair.Step.Id != selected.Step) throw new InvalidOperationException("Select the native trial's exact scenario and step before attaching pixels.");
            var picker = new OpenFileDialog { Filter = "Private native capture|human-capture-*.png", InitialDirectory = NativeController.TrialRoot(Bound(), selected) };
            if (picker.ShowDialog(this) == true) AttachPath(picker.FileName);
        }));
        panel.Children.Add(Button(T("Inspect selected trial journal phase and historical recovery exits (not reverified)", "선택 시험의 저널 단계·과거 복구 종료 관찰 확인 (재검증 아님)"), () =>
        {
            string text = NativeController.RecoveryHistory(Bound(), Trial());
            new Window { Owner = this, Title = T("Private historical recovery observations — current readiness UNKNOWN", "비공개 과거 복구 관찰 — 현재 준비 상태 UNKNOWN"), Width = 900, Height = 650,
                Content = Scroll(new TextBox { Text = text, IsReadOnly = true, TextWrapping = TextWrapping.Wrap, AcceptsReturn = true }) }.ShowDialog();
        }));
        foreach (string action in new[] { "Recover", "Cleanup" })
        {
            string operation = action;
            panel.Children.Add(AsyncButton(operation == "Recover" ? T("Explicitly recover selected native transaction", "선택 네이티브 트랜잭션 명시적 복구") : T("Clean verified owned game copy (evidence retained)", "검증된 소유 게임 복사본 정리 (증거 보존)"), async () =>
            {
                var selected = Trial(); var owned = Bound();
                string expected = operation.ToUpperInvariant() + " HUMAN " + selected.Id;
                if (Prompt(T("Close all game and Steam processes yourself. Recovery guards remain mandatory. Unknown changes preserve all copies. Type: ", "게임·Steam 프로세스를 직접 종료하세요. 복구 보호는 유지됩니다. 알 수 없는 변경은 모든 복사본을 보존합니다. 입력: ") + expected) != expected) return;
                int code = await native.Invoke(operation, owned, selected);
                NativeController.RecordRecovery(owned, selected, operation, code);
                Say(code == 0 ? "LOCAL_RECOVERY_CONTENT_VERIFIED · ACCOUNT_HISTORY_NOT_RESTORED" : "RECOVERY_BLOCKED · PRESERVE_ALL_COPIES");
                // Recovery never fabricates a new run summary. Inspect retained evidence separately.
            }));
        }
        return Scroll(panel);
    }
    private Button AsyncButton(string title, Func<Task> action)
    {
        var button = new Button { Content = title };
        button.Click += async (_, _) =>
        {
            button.IsEnabled = false;
            try { await action(); }
            catch (Exception error) { Say(T("Native operation refused; preserve private evidence: ", "네이티브 작업 거부. 비공개 증거 보존: ") + error.Message); }
            finally { button.IsEnabled = true; if (native.LastLogDirectory is not null) status.Text += "\n" + T("Private diagnostic logs (not exported): ", "비공개 진단 로그 (내보내기 제외): ") + native.LastLogDirectory; }
        };
        return button;
    }
    private void ImportNativeReceipt(NativeController.Binding binding, NativeController.Trial trial, bool required)
    {
        string path = Path.Combine(NativeController.TrialRoot(binding, trial), "human-summary.json");
        if (!File.Exists(OwnedFiles.NoLinks(path)))
        { if (required) throw new InvalidOperationException("No completed native summary. Preserve workspace and inspect/recover explicitly."); return; }
        var receipt = NativeReceipt.Parse(OwnedFiles.Read(path, 65536));
        if (receipt.Session != trial.Id || receipt.BetaSession != binding.BetaSession.ToString("N") || receipt.Scenario != trial.Scenario || receipt.Step != trial.Step)
            throw new InvalidDataException("Native summary differs from the selected exact transaction/scenario/step. Preserve it for inspection.");
        var latest = store.Load(binding.BetaSession);
        session = store.AppendNativeReceipt(latest.Id, latest.Revision, receipt); Refresh();
        Say("NATIVE_PROCESS_RECEIPT_IMPORTED · GAMEPLAY_NOT_INDEPENDENTLY_VERIFIED · ACCOUNT_HISTORY_NOT_RESTORED");
    }
    private void RefreshHistory()
    {
        historySessions.ItemsSource = null; historyCoverage.ItemsSource = null; historyChanges.ItemsSource = null;
        var loaded = new List<BetaSession>(); var blocked = new List<string>();
        foreach (Guid id in store.List())
        {
            try { loaded.Add(store.Load(id)); }
            catch (Exception e) when (e is IOException or InvalidDataException or InvalidOperationException or System.Text.Json.JsonException or UnauthorizedAccessException)
            { blocked.Add(id.ToString("N") + " · BLOCKED / preserved · " + e.Message); }
        }
        var report = TestingHistory.Build(loaded, catalog);
        historySessions.ItemsSource = report.Sessions; historyCoverage.ItemsSource = report.Coverage; historyChanges.ItemsSource = report.Changes;
        historyErrors.Text = blocked.Count == 0 ? T("All local histories loaded. Comparisons are human reports only.", "모든 로컬 이력을 읽었습니다. 비교는 사람의 보고만 반영합니다.") : string.Join("\n", blocked);
    }
    private void CollectDisplayMetadata()
    {
        if (MessageBox.Show(this, T("Collect only Windows version, primary logical display dimensions and this window's DPI scale? No account, device name, monitor serial, paths or process list is collected. Review before creating a session.", "Windows 버전·주 화면 논리 크기·이 창의 DPI 비율만 수집할까요? 계정·장치명·모니터 일련번호·경로·프로세스 목록은 수집하지 않습니다. 세션 생성 전에 확인하세요."), Title, MessageBoxButton.YesNo, MessageBoxImage.Question, MessageBoxResult.No) != MessageBoxResult.Yes) return;
        var dpi = VisualTreeHelper.GetDpi(this);
        display.Text = FormattableString.Invariant($"Windows {Environment.OSVersion.Version}; primary logical {SystemParameters.PrimaryScreenWidth:0}x{SystemParameters.PrimaryScreenHeight:0}; DPI {dpi.PixelsPerInchX:0.#}x{dpi.PixelsPerInchY:0.#}");
    }
}
