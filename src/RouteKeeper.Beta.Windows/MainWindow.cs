using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Automation;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using Microsoft.Win32;
using RouteKeeper.Tool;

namespace RouteKeeper.Beta.Windows;

public sealed partial class MainWindow : Window
{
    private readonly ScenarioCatalog catalog = ScenarioCatalog.Load();
    private readonly SessionStore store;
    private BetaSession? session;
    private string language = "en";
    private readonly TabControl tabs = new();
    private readonly TextBlock status = new() { TextWrapping = TextWrapping.Wrap, Margin = new Thickness(12) };
    private readonly ComboBox sessions = new() { MinWidth = 330, Margin = new Thickness(4), DisplayMemberPath = "Label" };
    private readonly ComboBox modes = new() { ItemsSource = new[] { "Off", "Passive", "Active", "Forced" }, SelectedIndex = 0, Width = 120, Margin = new Thickness(4) };
    private readonly TextBox build = Input("UNKNOWN"), display = Input("NOT_COLLECTED");
    private readonly TextBox gameData = Input(), compiler = Input();
    private readonly ListBox scenarios = new() { MinWidth = 240, DisplayMemberPath = "Label" };
    private readonly StackPanel scenarioPanel = new();
    private readonly DataGrid dashboard = Grid();
    private readonly DataGrid coverage = Grid();
    private readonly DataGrid issues = Grid();
    private readonly StackPanel stepPanel = new();
    private readonly TextBox actual = Input("", true), expectedBug = Input("", true), reproduce = Input("", true);
    private readonly ComboBox steps = new() { DisplayMemberPath = "Label", Margin = new Thickness(4) };
    private readonly ComboBox result = new() { ItemsSource = Enum.GetValues<TestResult>(), SelectedIndex = 0, Margin = new Thickness(4) };
    private readonly ComboBox severity = new() { ItemsSource = new[] { "P0", "P1", "P2", "P3" }, SelectedIndex = 2, Margin = new Thickness(4) };
    private readonly ListBox evidence = new() { DisplayMemberPath = "Label", MaxHeight = 120, Margin = new Thickness(4) };
    private readonly TextBox redact = Input("", true);
    private readonly CheckBox exportPixels = new() { Margin = new Thickness(4) };
    private sealed record Choice(string Id, string Label);
    private sealed record SessionChoice(Guid Id, string Label);
    private sealed record StepDraft(string Actual, string Expected, string Reproduction, TestResult Result);
    private readonly Dictionary<string, StepDraft> drafts = [];
    private string? displayedStep;
    private bool loadingStep;

    public MainWindow()
    {
        Title = "ROUTEKEEPER Beta Tester · 0.1.0-beta.1";
        Width = 1200; Height = 850; MinWidth = 860; MinHeight = 600;
        FontFamily = new FontFamily("Segoe UI"); FontSize = 15;
        string local = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        store = new SessionStore(Path.Combine(local, "RouteKeeper", "Beta", "sessions"), catalog);
        var shell = new DockPanel { Margin = new Thickness(12) };
        var header = new StackPanel { Orientation = Orientation.Horizontal };
        header.Children.Add(new TextBlock { Text = "ROUTEKEEPER  /  Human Beta", FontSize = 25, FontWeight = FontWeights.SemiBold, Margin = new Thickness(8) });
        var languages = new ComboBox { ItemsSource = new[] { "English", "한국어" }, SelectedIndex = 0, Width = 120, Margin = new Thickness(12) };
        AutomationProperties.SetName(languages, "Application language / 앱 언어");
        languages.SelectionChanged += (_, _) => { language = languages.SelectedIndex == 1 ? "ko" : "en"; BuildTabs(); };
        header.Children.Add(languages); DockPanel.SetDock(header, Dock.Top); shell.Children.Add(header);
        DockPanel.SetDock(status, Dock.Bottom); shell.Children.Add(status); shell.Children.Add(tabs);
        Content = shell;
        scenarios.SelectionChanged += (_, _) => ShowScenario();
        steps.SelectionChanged += (_, _) => ShowStep();
        actual.TextChanged += (_, _) => CaptureDraft();
        expectedBug.TextChanged += (_, _) => CaptureDraft();
        reproduce.TextChanged += (_, _) => CaptureDraft();
        result.SelectionChanged += (_, _) => CaptureDraft();
        Closing += (_, e) =>
        {
            if (native.Busy)
            { e.Cancel = true; Say(T("Owned native controller is active. Request safe stop and wait for its recovery result before closing.", "소유 네이티브 조정기가 실행 중입니다. 안전 중지를 요청하고 복구 결과를 기다린 뒤 종료하세요.")); return; }
            if (drafts.Count != 0 && MessageBox.Show(this,
                T("Unsaved drafts remain. Commit actual/result and create/update issues separately to preserve their fields. Close and discard unsaved drafts?", "미저장 초안이 있습니다. 실제 관찰·결과는 단계 저장으로, 오류 예상·재현 절차는 오류 보고 저장으로 보관하세요. 초안을 버리고 종료할까요?"),
                Title, MessageBoxButton.YesNo, MessageBoxImage.Warning, MessageBoxResult.No) != MessageBoxResult.Yes) e.Cancel = true;
        };
        BuildTabs();
        RefreshSessions();
        Say(T("Local-only beta. No automatic upload. Native human sessions require preparation and fresh scoped consent.", "로컬 전용 베타입니다. 자동 업로드가 없습니다. 네이티브 사람 시험은 준비와 새로운 범위별 승인이 필요합니다."));
    }
    private string T(string en, string ko) => language == "ko" ? ko : en;
    private static TextBox Input(string text = "", bool multiline = false) => new()
    {
        Text = text, Margin = new Thickness(4), Padding = new Thickness(6), MaxLength = 8000,
        AcceptsReturn = multiline, TextWrapping = multiline ? TextWrapping.Wrap : TextWrapping.NoWrap,
        MinHeight = multiline ? 80 : 30, VerticalScrollBarVisibility = ScrollBarVisibility.Auto
    };
    private static DataGrid Grid() => new() { IsReadOnly = true, AutoGenerateColumns = true, CanUserAddRows = false, Margin = new Thickness(4), MinHeight = 180, MaxHeight = 400 };
    private static TextBlock Text(string value, double size = 15) => new() { Text = value, TextWrapping = TextWrapping.Wrap, FontSize = size, Margin = new Thickness(6) };
    private static void Label(Panel panel, string label, Control control)
    {
        panel.Children.Add(new Label { Content = label, Target = control });
        AutomationProperties.SetName(control, label);
        panel.Children.Add(control);
    }
    private Button Button(string title, Action action)
    {
        var button = new Button { Content = title };
        button.Click += (_, _) => Guard(action); return button;
    }
    private void Guard(Action action)
    {
        try { action(); }
        catch (Exception e) when (e is IOException or InvalidDataException or InvalidOperationException or System.Text.Json.JsonException or ArgumentException or UnauthorizedAccessException)
        {
            Say(T("Refused: ", "거부: ") + e.Message);
            MessageBox.Show(this, e.Message, T("Operation refused — committed results preserved", "작업 거부 — 저장된 결과 보존"), MessageBoxButton.OK, MessageBoxImage.Warning);
        }
    }
    private void Say(string message) => status.Text = message;
    private void Tab(string title, UIElement content) => tabs.Items.Add(new TabItem { Header = title, Content = content });
    private static ScrollViewer Scroll(UIElement child) => new() { Content = child, VerticalScrollBarVisibility = ScrollBarVisibility.Auto, Padding = new Thickness(8) };
    private void BuildTabs()
    {
        // Release parents before reusing input controls when switching UI language.
        foreach (var control in new UIElement[] { sessions, modes, build, display, gameData, compiler, scenarios, scenarioPanel, steps, result, actual, expectedBug, reproduce, severity, issues, dashboard, coverage, redact, exportPixels, stepPanel, evidence, historySessions, historyCoverage, historyChanges, historyErrors })
            if (VisualTreeHelper.GetParent(control) is Panel parent) parent.Children.Remove(control);
        tabs.Items.Clear();
        var start = new StackPanel();
        start.Children.Add(Text(T("Create or resume a local test session", "로컬 시험 세션 만들기 또는 재개"), 24));
        start.Children.Add(Text(T("The application records human observations. It does not certify gameplay or restore Steam account history. Resuming a checklist never resumes a game process.", "앱은 사람의 관찰을 기록합니다. 게임플레이를 인증하거나 Steam 계정 기록을 복원하지 않습니다. 체크리스트 재개는 게임 프로세스를 재개하지 않습니다.")));
        Label(start, T("Game build (exact identity when known)", "게임 빌드 (알고 있다면 정확한 식별값)"), build);
        Label(start, T("Game mode", "게임 모드"), modes);
        Label(start, T("Display / DPI (optional; do not enter personal metadata)", "해상도 / DPI (선택; 개인 정보 입력 금지)"), display);
        start.Children.Add(Button(T("Collect optional Windows / display / DPI metadata with consent", "선택 Windows·화면·DPI 정보 동의 후 수집"), CollectDisplayMetadata));
        start.Children.Add(Button(T("Create session", "세션 만들기"), () =>
        {
            RefuseWhileNative();
            session = store.Create(new(language, (string)modes.SelectedItem, build.Text, Version, display.Text));
            Refresh(); RefreshSessions();
        }));
        Label(start, T("Saved sessions", "저장된 세션"), sessions);
        start.Children.Add(Button(T("Open selected session", "선택 세션 열기"), () =>
        {
            RefuseWhileNative();
            if (sessions.SelectedItem is not SessionChoice choice) throw new InvalidOperationException("Select a saved session.");
            session = store.Load(choice.Id); Refresh();
        }));
        start.Children.Add(Button(T("Refresh session history", "세션 이력 새로고침"), RefreshSessions));
        start.Children.Add(Button(T("Inspect and recover interrupted checklist publication", "중단된 체크리스트 저장 검토 및 복구"), () =>
        {
            RefuseWhileNative();
            if (sessions.SelectedItem is not SessionChoice choice) throw new InvalidOperationException("Select the affected saved session.");
            var candidate = store.InspectPublicationRecovery(choice.Id);
            var preview = new Window { Owner = this, Title = T("Review pending checklist revision", "보류 중인 체크리스트 기록 검토"), Width = 900, Height = 650,
                Content = Scroll(new TextBox { Text = System.Text.Json.JsonSerializer.Serialize(candidate, BetaJson.Options), IsReadOnly = true, TextWrapping = TextWrapping.Wrap, AcceptsReturn = true }) };
            preview.ShowDialog();
            string phrase = "RECOVER SESSION " + choice.Id.ToString("N");
            string? typed = Prompt(T("Adopt only this fully validated pending revision? Existing history and pixels remain. No game process is resumed. Type: ", "완전히 검증한 이 보류 기록을 반영할까요? 기존 이력과 화면은 유지되며 게임은 재개하지 않습니다. 입력: ") + phrase);
            if (typed is null) return;
            session = store.RecoverPublication(choice.Id, candidate.OldHeadSha256, candidate.PendingSha256, typed); Refresh(); RefreshSessions();
        }));
        start.Children.Add(Button(T("Pause", "일시 중지"), () => Change(s => store.SetState(s.Id, s.Revision, "Paused"))));
        start.Children.Add(Button(T("Resume checklist", "체크리스트 재개"), () => Change(s => store.SetState(s.Id, s.Revision, "Active"))));
        start.Children.Add(Button(T("Complete session (immutable)", "세션 완료 (이후 수정 불가)"), () =>
        {
            if (MessageBox.Show(this, T("Finish this session? Untested steps remain NOT_RUN.", "세션을 완료할까요? 시험하지 않은 단계는 NOT_RUN으로 유지됩니다."), Title, MessageBoxButton.YesNo) == MessageBoxResult.Yes)
                Change(s => store.SetState(s.Id, s.Revision, "Completed"));
        }));
        Tab(T("Sessions", "세션"), Scroll(start));

        Tab(T("Preparation", "준비"), NativePreparation());

        var testing = new System.Windows.Controls.Grid();
        testing.ColumnDefinitions.Add(new ColumnDefinition { Width = new GridLength(300) });
        testing.ColumnDefinitions.Add(new ColumnDefinition());
        scenarios.ItemsSource = catalog.Scenarios.Select(s => new Choice(s.Id, s.Title.In(language) + " · " + s.Risk)).ToArray();
        testing.Children.Add(scenarios);
        var detail = new StackPanel(); detail.Children.Add(scenarioPanel); detail.Children.Add(stepPanel);
        detail.Children.Add(Button(T("Authorize this high-risk scenario separately", "이 고위험 시나리오 별도 승인"), Authorize));
        Label(detail, T("Individual step", "개별 단계"), steps);
        Label(detail, T("Human-reported result", "사람이 보고한 결과"), result);
        Label(detail, T("Actual observation (required when executed)", "실제 관찰 (실행 결과에 필수)"), actual);
        detail.Children.Add(Button(T("Commit step result", "단계 결과 저장"), () =>
        {
            CommitStep();
        }));
        detail.Children.Add(Button(T("Import optional screenshot and review", "선택 화면 가져오기 및 검토"), Attach));
        Label(detail, T("Private evidence for this step", "이 단계의 비공개 증거"), evidence);
        detail.Children.Add(Button(T("Review selected existing screenshot for sharing", "선택한 기존 화면의 공유 검토"), ReviewExisting));
        var detailScroll = Scroll(detail); System.Windows.Controls.Grid.SetColumn(detailScroll, 1); testing.Children.Add(detailScroll);
        Tab(T("Guided testing", "안내 시험"), testing);
        var dash = new StackPanel(); dash.Children.Add(Text(T("Independent coverage dimensions", "독립적인 검증 상태"), 24));
        dash.Children.Add(Text(T("Human PASS does not become independent PASS. Implementation and automated status reflect the catalog's declared scope, not an inferred runtime certification.", "사람의 PASS는 독립 검증 PASS가 되지 않습니다. 구현·자동 검사는 목록의 명시 범위이며 실행 인증을 뜻하지 않습니다.")));
        dash.Children.Add(dashboard); dash.Children.Add(coverage);
        dash.Children.Add(Button(T("Refresh all local sessions and comparable human result changes", "모든 로컬 세션 및 비교 가능한 사람 결과 변경 새로고침"), RefreshHistory));
        dash.Children.Add(historyErrors); dash.Children.Add(historySessions); dash.Children.Add(historyCoverage); dash.Children.Add(historyChanges); Tab(T("Dashboard", "현황"), Scroll(dash));

        var bugs = new StackPanel();
        bugs.Children.Add(Text(T("Report the currently selected scenario / step", "현재 선택한 시나리오 / 단계 오류 보고"), 24));
        Label(bugs, T("Expected", "예상 동작"), expectedBug);
        bugs.Children.Add(Text(T("Actual observation is taken from the Guided testing field.", "실제 관찰은 안내 시험 탭의 입력란을 사용합니다.")));
        Label(bugs, T("Reproduction steps", "재현 절차"), reproduce); Label(bugs, T("Severity", "심각도"), severity);
        bugs.Children.Add(Button(T("Create issue", "오류 보고 만들기"), () => SaveBug(null)));
        bugs.Children.Add(Button(T("Append revision to selected issue", "선택 오류에 수정 이력 추가"), () =>
        {
            if (issues.SelectedItem is not BugReport issue) throw new InvalidOperationException("Select an issue history row.");
            SaveBug(issue.Id);
        }));
        bugs.Children.Add(issues); Tab(T("Issues", "오류"), Scroll(bugs));
        var exports = new StackPanel();
        exports.Children.Add(Text(T("Offline export and privacy", "오프라인 내보내기 및 개인정보"), 24));
        exports.Children.Add(Text(T("Review all notes and screenshots first. No automatic upload. Checklist exports exclude binary game resources, saves, usernames, installation paths, process lists and credentials. Native preparation separately retains private paths and recovery evidence. User-entered text and screenshots may still contain private information. Use opaque pixel rectangles during import; redaction phrases affect exported text only. Native workspace paths and raw diagnostics stay in separate private local storage.", "먼저 모든 메모와 화면을 검토하세요. 자동 업로드가 없습니다. 체크리스트 내보내기는 게임 바이너리·세이브·사용자명·설치 경로·프로세스 목록·인증 정보를 제외합니다. 네이티브 준비는 경로·복구 증거를 별도로 비공개 보관합니다. 직접 입력한 글과 화면에는 개인정보가 있을 수 있습니다. 가져올 때 불투명 사각형으로 픽셀을 가릴 수 있습니다. 가림 문구는 내보내는 텍스트에만 적용됩니다. 네이티브 경로·원본 진단은 별도 비공개 로컬 저장소에 유지됩니다.")));
        Label(exports, T("Redact these literal phrases (one per line)", "가릴 문구 (한 줄에 하나)"), redact);
        exportPixels.Content = T("Include only screenshots explicitly reviewed for sharing", "공유 검토를 완료한 화면만 포함"); exports.Children.Add(exportPixels);
        exports.Children.Add(Button(T("Preview sanitized report", "개인정보 처리 보고서 미리보기"), () =>
        {
            var s = Current(); var report = Reports.Build(store.Load(s.Id), catalog, Options());
            var preview = new Window { Owner = this, Title = "Export preview / 내보내기 검토", Width = 900, Height = 650, Content = Scroll(new TextBox { Text = System.Text.Json.JsonSerializer.Serialize(report, BetaJson.Options), IsReadOnly = true, TextWrapping = TextWrapping.Wrap, AcceptsReturn = true }) };
            preview.ShowDialog();
        }));
        exports.Children.Add(Button(T("Export JSON / HTML / CSV to a new folder", "새 폴더에 JSON / HTML / CSV 내보내기"), () =>
        {
            var dialog = new OpenFolderDialog { Title = T("Choose parent folder for a new export", "새 내보내기의 상위 폴더 선택") };
            if (dialog.ShowDialog(this) != true) return;
            var s = Current(); string output = Path.Combine(dialog.FolderName, "routekeeper-report-" + Guid.NewGuid().ToString("N"));
            Reports.Export(store, s.Id, s.Revision, catalog, output, Options()); Reports.VerifyExport(output); Say(output);
        }));
        exports.Children.Add(Button(T("Delete current session and local history", "현재 세션 및 로컬 이력 삭제"), () =>
        {
            RefuseWhileNative();
            var s = Current(); string phrase = "DELETE " + s.Id.ToString("N");
            if (Prompt(T("This permanently deletes results, issue history and attached screenshots. Exported copies remain. Type: ", "결과·오류 이력·첨부 화면을 영구 삭제합니다. 내보낸 복사본은 남습니다. 입력: ") + phrase) != phrase) return;
            store.Delete(s.Id, s.Revision, phrase);
            foreach (string key in drafts.Keys.Where(k => k.StartsWith(s.Id.ToString("N") + "/", StringComparison.Ordinal)).ToArray()) drafts.Remove(key);
            session = null; Refresh(); RefreshSessions();
        }));
        exports.Children.Add(Text(T("Retention: local sessions persist until explicitly deleted. Exports are separate copies and must be deleted separately. No background retention service runs.", "보관: 로컬 세션은 직접 삭제할 때까지 유지됩니다. 내보낸 복사본은 별도로 삭제하세요. 백그라운드 보관 서비스는 없습니다.")));
        Tab(T("Export / Privacy", "내보내기 / 개인정보"), Scroll(exports));
        if (scenarios.SelectedIndex < 0) scenarios.SelectedIndex = 0;
        Refresh();
    }
    private static string Version => typeof(MainWindow).Assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>()?.InformationalVersion ?? "UNKNOWN";
    private void Pick(TextBox target, string filter)
    {
        var dialog = new OpenFileDialog { Filter = filter, CheckFileExists = true };
        if (dialog.ShowDialog(this) == true) target.Text = dialog.FileName;
    }
    private BetaSession Current() => session ?? throw new InvalidOperationException(T("Create or open a session first.", "먼저 세션을 만들거나 여세요."));
    private void RefuseWhileNative() { if (native.Busy) throw new InvalidOperationException(T("Wait for the owned native controller to finish safe recovery before changing sessions or lifecycle state.", "세션·상태 변경 전에 소유 네이티브 조정기의 안전 복구 완료를 기다리세요.")); }
    private void Change(Func<BetaSession, BetaSession> action) { RefuseWhileNative(); session = action(Current()); Refresh(); }
    private void RefreshSessions()
    {
        sessions.ItemsSource = store.List().Select(id =>
        {
            try { var s = store.Load(id); return new SessionChoice(id, $"{s.Created:yyyy-MM-dd HH:mm} · {s.State} · {s.Configuration.Language}/{s.Configuration.Mode} · {id:N}"); }
            catch (Exception e) when (e is IOException or InvalidDataException or InvalidOperationException or System.Text.Json.JsonException) { return new SessionChoice(id, $"CORRUPT / BLOCKED · {id:N}"); }
        }).ToArray();
    }
    private void Refresh()
    {
        dashboard.ItemsSource = session is null ? null : Reports.Summarize(session, catalog);
        coverage.ItemsSource = session is null ? null : Reports.Coverage(session, catalog);
        issues.ItemsSource = session?.Bugs.Reverse().ToArray();
        if (session is not null) Say($"{session.Id:N} · revision {session.Revision} · {session.State} · HumanReported · Independent NOT_RUN");
        ShowScenario();
    }
    private (Scenario Scenario, TestStep Step) Selected()
    {
        if (scenarios.SelectedItem is not Choice scenario || steps.SelectedItem is not Choice step) throw new InvalidOperationException("Select a scenario and individual step.");
        var s = catalog.Scenarios.Single(s => s.Id == scenario.Id); return (s, s.Steps.Single(p => p.Id == step.Id));
    }
    private void ShowScenario()
    {
        scenarioPanel.Children.Clear();
        if (scenarios.SelectedItem is not Choice choice) return;
        var s = catalog.Scenarios.Single(s => s.Id == choice.Id);
        scenarioPanel.Children.Add(Text(s.Title.In(language), 23));
        scenarioPanel.Children.Add(Text($"{s.Id} · v{s.Version} · {s.Risk}\n{s.Source}\n{s.Configuration}"));
        foreach (var text in new[] { s.Purpose, s.Preconditions, s.EvidenceRequirements, s.CompletionCriteria, s.Reproduction }) scenarioPanel.Children.Add(Text(text.In(language)));
        string? prior = (steps.SelectedItem as Choice)?.Id;
        steps.ItemsSource = s.Steps.Select(step => new Choice(step.Id, step.Id + " · " + (session?.Observations.GetValueOrDefault(BetaSession.Key(s.Id, step.Id))?.Result ?? TestResult.NOT_RUN))).ToArray();
        steps.SelectedIndex = Math.Max(0, Array.FindIndex(s.Steps, p => p.Id == prior));
        ShowStep();
    }
    private void ShowStep()
    {
        stepPanel.Children.Clear();
        if (scenarios.SelectedItem is not Choice || steps.SelectedItem is not Choice) return;
        var pair = Selected();
        stepPanel.Children.Add(Text(pair.Step.Instruction.In(language)));
        stepPanel.Children.Add(Text(T("Expected: ", "예상: ") + pair.Step.Expected.In(language)));
        var observation = session?.Observations.GetValueOrDefault(BetaSession.Key(pair.Scenario.Id, pair.Step.Id));
        displayedStep = (session?.Id.ToString("N") ?? "no-session") + "/" + BetaSession.Key(pair.Scenario.Id, pair.Step.Id);
        drafts.TryGetValue(displayedStep, out var draft);
        loadingStep = true;
        try
        {
            actual.Text = draft?.Actual ?? observation?.Actual ?? ""; result.SelectedItem = draft?.Result ?? observation?.Result ?? TestResult.NOT_RUN;
            expectedBug.Text = draft?.Expected ?? pair.Step.Expected.In(language); reproduce.Text = draft?.Reproduction ?? pair.Step.Instruction.In(language);
        }
        finally { loadingStep = false; }
        if (draft is not null) stepPanel.Children.Add(Text(T("Draft retained. Commit actual/result before closing; create/update an issue separately to preserve expected/reproduction fields.", "초안을 유지했습니다. 종료 전 실제 관찰·결과는 단계 저장으로, 예상·재현 절차는 오류 보고 저장으로 따로 보관하세요.")));
        evidence.ItemsSource = session?.Attachments.Where(a => a.ScenarioId == pair.Scenario.Id && a.StepId == pair.Step.Id)
            .Select(a => new Choice(a.Id, a.Id + (a.ReviewedForSharing ? " · reviewed / 검토됨" : " · private / 비공개"))).ToArray();
    }
    private void CaptureDraft()
    {
        if (!loadingStep && displayedStep is not null && result.SelectedItem is TestResult selection)
        {
            var pair = Selected();
            var committed = session?.Observations.GetValueOrDefault(BetaSession.Key(pair.Scenario.Id, pair.Step.Id));
            if (actual.Text == (committed?.Actual ?? "") && selection == (committed?.Result ?? TestResult.NOT_RUN) &&
                expectedBug.Text == pair.Step.Expected.In(language) && reproduce.Text == pair.Step.Instruction.In(language)) drafts.Remove(displayedStep);
            else drafts[displayedStep] = new(actual.Text, expectedBug.Text, reproduce.Text, selection);
        }
    }
    private void CommitStep()
    {
        var pair = Selected(); var s = Current();
        session = store.Record(s.Id, s.Revision, pair.Scenario.Id, pair.Step.Id, (TestResult)result.SelectedItem, actual.Text);
        // Committing a step does not save the issue form. Preserve its distinct
        // expected/reproduction draft until the tester reports the issue.
        CaptureDraft(); Refresh();
    }
    private void Authorize()
    {
        var pair = Selected(); string phrase = "AUTHORIZE HIGH RISK " + pair.Scenario.Id;
        string? typed = Prompt(T("Checklist authorization does not authorize native game launch or remove Steam/save guards. Permanent account changes may not be reversible. Type: ", "체크리스트 승인은 게임 실행을 승인하거나 Steam·세이브 보호를 해제하지 않습니다. 계정의 영구 변경은 복구되지 않을 수 있습니다. 입력: ") + phrase);
        if (typed is not null) Change(s => store.AuthorizeHighRisk(s.Id, s.Revision, pair.Scenario.Id, typed));
    }
    private string? Prompt(string instruction)
    {
        var input = Input(); var panel = new StackPanel { Margin = new Thickness(12) }; panel.Children.Add(Text(instruction)); panel.Children.Add(input);
        var dialog = new Window { Owner = this, Title = Title, Width = 750, Height = Math.Min(750, SystemParameters.WorkArea.Height - 50), Content = Scroll(panel), WindowStartupLocation = WindowStartupLocation.CenterOwner };
        panel.Children.Add(Button(T("Confirm", "확인"), () => dialog.DialogResult = true));
        return dialog.ShowDialog() == true ? input.Text : null;
    }
    private void Attach()
    {
        Current(); Selected();
        var dialog = new OpenFileDialog { Filter = "Screenshot PNG|*.png", CheckFileExists = true };
        if (dialog.ShowDialog(this) != true) return;
        AttachPath(dialog.FileName);
    }
    private void AttachPath(string path)
    {
        var pair = Selected(); var s = Current();
        byte[] bytes = OwnedFiles.Read(path, Screenshot.MaximumBytes);
        Screenshot.ValidateDimensions(bytes);
        using var stream = new MemoryStream(bytes);
        var decoder = BitmapDecoder.Create(stream, BitmapCreateOptions.PreservePixelFormat, BitmapCacheOption.OnLoad);
        var frame = decoder.Frames[0];
        if ((long)frame.PixelWidth * frame.PixelHeight > 16000000) throw new InvalidDataException("Screenshot exceeds pixel budget.");
        var clean = new WriteableBitmap(new FormatConvertedBitmap(frame, PixelFormats.Bgra32, null, 0));
        var panel = new StackPanel();
        panel.Children.Add(Text(T("Review all pixels. Apply opaque black rectangles using source-image pixel coordinates (x,y,width,height); original private file stays unchanged. This local claim does not certify authenticity.", "전체 픽셀을 검토하세요. 원본 이미지 픽셀 좌표(x,y,너비,높이)로 검정 불투명 사각형을 적용할 수 있습니다. 원본 비공개 파일은 유지됩니다. 이 로컬 주장은 진위를 인증하지 않습니다.")));
        panel.Children.Add(Text($"{clean.PixelWidth} × {clean.PixelHeight} pixels"));
        var image = new Image { Source = clean, MaxHeight = 450, Stretch = Stretch.Uniform }; panel.Children.Add(image);
        var rectangle = Input("0,0,1,1"); Label(panel, T("Black rectangle: x,y,width,height (source pixels)", "검정 사각형: x,y,너비,높이 (원본 픽셀)"), rectangle);
        var reviewed = new CheckBox { Content = T("I reviewed the current pixels for sharing", "현재 화면의 공유 적합성을 검토했습니다"), Margin = new Thickness(12) };
        panel.Children.Add(Button(T("Apply opaque rectangle", "불투명 사각형 적용"), () =>
        {
            var numbers = rectangle.Text.Split(',').Select(v => int.TryParse(v.Trim(), out int n) ? n : -1).ToArray();
            if (numbers.Length != 4) throw new InvalidDataException("Enter exactly x,y,width,height.");
            RedactPixels(clean, numbers[0], numbers[1], numbers[2], numbers[3]); reviewed.IsChecked = false;
        }));
        panel.Children.Add(reviewed);
        var preview = new Window { Owner = this, Title = "Private screenshot redaction / 비공개 화면 가림", Width = 900, Height = 750, Content = Scroll(panel) };
        panel.Children.Add(Button(T("Attach current pixels locally", "현재 화면 로컬 첨부"), () => preview.DialogResult = true));
        if (preview.ShowDialog() != true) return;
        var encoder = new PngBitmapEncoder(); encoder.Frames.Add(BitmapFrame.Create(clean));
        using var output = new MemoryStream(); encoder.Save(output);
        byte[] sanitized = Screenshot.Sanitize(output.ToArray());
        session = store.Attach(s.Id, s.Revision, pair.Scenario.Id, pair.Step.Id, sanitized, reviewed.IsChecked == true); Refresh();
    }
    private static void RedactPixels(WriteableBitmap bitmap, int x, int y, int width, int height)
    {
        if (x < 0 || y < 0 || width <= 0 || height <= 0 || width > bitmap.PixelWidth || height > bitmap.PixelHeight ||
            x > bitmap.PixelWidth - width || y > bitmap.PixelHeight - height) throw new InvalidDataException("Rectangle lies outside the image.");
        byte[] row = new byte[checked(width * 4)];
        for (int i = 3; i < row.Length; i += 4) row[i] = 255;
        for (int offset = 0; offset < height; offset++) bitmap.WritePixels(new Int32Rect(x, y + offset, width, 1), row, width * 4, 0);
    }
    private void SaveBug(string? id)
    {
        var pair = Selected(); string actualText = actual.Text;
        Change(s => store.ReportBug(s.Id, s.Revision, pair.Scenario.Id, pair.Step.Id, expectedBug.Text, actualText, reproduce.Text, (string)severity.SelectedItem,
            s.Attachments.Where(a => a.ScenarioId == pair.Scenario.Id && a.StepId == pair.Step.Id && a.ReviewedForSharing).Select(a => a.Id).ToArray(), id));
    }
    private void ReviewExisting()
    {
        var s = Current();
        if (evidence.SelectedItem is not Choice choice) throw new InvalidOperationException("Select a screenshot attached to this step.");
        var attachment = s.Attachments.Single(a => a.Id == choice.Id);
        byte[] bytes = store.ReadPrivateAttachment(s.Id, s.Revision, attachment.Id);
        using var stream = new MemoryStream(bytes);
        var bitmap = BitmapFrame.Create(stream, BitmapCreateOptions.None, BitmapCacheOption.OnLoad);
        var panel = new StackPanel();
        panel.Children.Add(Text(T("Inspect all pixels. Confirmation marks exactly these bytes as reviewed for sharing; exports still exclude screenshots by default.", "전체 픽셀을 확인하세요. 확인하면 이 바이트의 공유 검토 완료를 기록합니다. 내보내기 기본값은 여전히 화면 제외입니다.")));
        panel.Children.Add(new Image { Source = bitmap, MaxHeight = 500, Stretch = Stretch.Uniform });
        var dialog = new Window { Owner = this, Title = "Private evidence review / 비공개 증거 검토", Width = 900, Height = 650, Content = Scroll(panel) };
        panel.Children.Add(Button(T("I reviewed these pixels for sharing", "이 화면의 공유 적합성을 검토했습니다"), () => dialog.DialogResult = true));
        if (dialog.ShowDialog() == true) Change(current => store.ReviewAttachment(current.Id, current.Revision, attachment.Id, attachment.Sha256));
    }
    public void SmokeTest()
    {
        NativeController.SmokeDrainFailure().GetAwaiter().GetResult();
        var fixture = store.Create(new("en", "Off", "SYNTHETIC-CONSTRUCTION-ONLY", Version));
        session = fixture;
        try
        {
            foreach (string value in new[] { "ko", "en" })
            {
                language = value; BuildTabs(); UpdateLayout();
                if (tabs.Items.Count != 6 || scenarios.Items.Count != catalog.Scenarios.Length || steps.Items.Count != Selected().Scenario.Steps.Length)
                    throw new InvalidOperationException("Beta UI construction/data binding contract failed.");
                actual.Text = "SYNTHETIC UNSAVED OBSERVATION"; expectedBug.Text = "SYNTHETIC EXPECTED"; reproduce.Text = "SYNTHETIC REPRODUCTION";
                Refresh();
                if (actual.Text != "SYNTHETIC UNSAVED OBSERVATION" || expectedBug.Text != "SYNTHETIC EXPECTED" || reproduce.Text != "SYNTHETIC REPRODUCTION")
                    throw new InvalidOperationException("UI refresh lost an unsaved observation draft.");
                var pixels = new WriteableBitmap(2, 2, 96, 96, PixelFormats.Bgra32, null);
                RedactPixels(pixels, 1, 0, 1, 1);
                byte[] check = new byte[16]; pixels.CopyPixels(check, 8, 0);
                if (check[7] != 255 || check[3] != 0) throw new InvalidOperationException("Opaque redaction smoke contract failed.");
                RefreshHistory();
                CommitStep();
                if (expectedBug.Text != "SYNTHETIC EXPECTED" || reproduce.Text != "SYNTHETIC REPRODUCTION")
                    throw new InvalidOperationException("Step commit discarded the separate issue draft.");
            }
        }
        finally { store.Delete(fixture.Id, store.Load(fixture.Id).Revision, "DELETE " + fixture.Id.ToString("N")); session = null; drafts.Clear(); }
    }
    private ExportOptions Options() => new(exportPixels.IsChecked == true, redact.Text.Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries));
}
