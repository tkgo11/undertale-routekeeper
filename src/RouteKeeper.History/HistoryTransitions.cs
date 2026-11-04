namespace RouteKeeper.History;

public enum ResetKind { Reset, TrueReset }

/// <summary>Observed metadata only. No filesystem mutation API is exposed.</summary>
public sealed record HistorySnapshot
{
    public IReadOnlyDictionary<string, int> Ini { get; }
    public IReadOnlyDictionary<string, string> PermanentFiles { get; }
    public bool HasFile8 { get; }
    public HistorySnapshot(IReadOnlyDictionary<string, int> ini, IReadOnlyDictionary<string, string> permanentFiles, bool hasFile8)
    {
        Ini = new Dictionary<string, int>(ini).AsReadOnly();
        PermanentFiles = new Dictionary<string, string>(permanentFiles).AsReadOnly();
        HasFile8 = hasFile8;
    }
    public bool SoulSold => PermanentFiles.ContainsKey("system_information_963");
    public bool WorldErased => !SoulSold && PermanentFiles.ContainsKey("system_information_962");
    public bool PriorNeutralAvailable => Ini.GetValueOrDefault("General.Won") > 0;
    public bool TrueResetAvailable => Ini.GetValueOrDefault("EndF.EndF") > 0;
}

public sealed record ResetPreview(HistorySnapshot Result, bool ClearsRunProgress, bool ReplacesIni,
    bool NewFunValueRequired, IReadOnlyList<string> Notes);

public static class HistoryTransitions
{
    /// <summary>
    /// Pure preview of the inspected naming-screen reset branch. Actual game
    /// execution and platform synchronization are separate; this never deletes files.
    /// </summary>
    public static ResetPreview Preview(ResetKind kind, HistorySnapshot before)
    {
        if (!Enum.IsDefined(kind)) throw new ArgumentOutOfRangeException(nameof(kind));
        if (kind == ResetKind.TrueReset && !before.TrueResetAvailable)
            throw new InvalidOperationException("The observed game state does not offer True Reset.");
        var ini = kind == ResetKind.Reset ? new Dictionary<string, int>(before.Ini) : new Dictionary<string, int>();
        if (kind == ResetKind.TrueReset)
        {
            ini["reset.reset"] = 1;
            CopyNonzero("reset.s_key", "reset.s_key");
            CopyNonzero("General.Won", "General.BW");
            CopyNonzero("General.CP", "General.BP");
            CopyNonzero("General.CH", "General.BH");
        }
        // The source randomizes General.fun after either reset; its future value
        // cannot be obtained from the old snapshot and is not fabricated here.
        ini.Remove("General.fun");
        return new(new(ini, before.PermanentFiles, before.HasFile8), true, kind == ResetKind.TrueReset, true,
            ["Run flags, friendships, EXP and plot are initialized for a new run.",
             "No system_information_* file is removed by this reset branch.",
             "file8 is not deleted by the naming-screen reset branch."]);

        void CopyNonzero(string source, string destination)
        {
            var value = before.Ini.GetValueOrDefault(source);
            if (value != 0) ini[destination] = value;
        }
    }
}
