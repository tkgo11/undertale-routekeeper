using System.Text.Json;
using System.Text.Json.Serialization;

namespace RouteKeeper.Beta;

/// <summary>Sanitized process observations only; local provenance is not gameplay authentication.</summary>
public sealed record NativeProcessEvent(
    [property: JsonPropertyName("kind")] string Kind,
    [property: JsonPropertyName("utc")] DateTimeOffset Utc,
    [property: JsonPropertyName("classification")] string Classification,
    [property: JsonPropertyName("scope")] string Scope);

public sealed record NativeReceipt(
    [property: JsonPropertyName("schema")] int Schema,
    [property: JsonPropertyName("session")] string Session,
    [property: JsonPropertyName("betaSession")] string BetaSession,
    [property: JsonPropertyName("scenario")] string Scenario,
    [property: JsonPropertyName("step")] string Step,
    [property: JsonPropertyName("state")] string State,
    [property: JsonPropertyName("case")] string Case,
    [property: JsonPropertyName("inputsDispatched")] int InputsDispatched,
    [property: JsonPropertyName("gameplay")] string Gameplay,
    [property: JsonPropertyName("humanResults")] string HumanResults,
    [property: JsonPropertyName("localRecovery")] string LocalRecovery,
    [property: JsonPropertyName("accountHistory")] string AccountHistory,
    [property: JsonPropertyName("originalSha256")] string OriginalSha256,
    [property: JsonPropertyName("candidateSha256")] string CandidateSha256,
    [property: JsonPropertyName("events")] NativeProcessEvent[] Events,
    [property: JsonPropertyName("utc")] DateTimeOffset Utc)
{
    public const int MaximumBytes = 65536;
    [JsonIgnore] public EvidenceKind Classification => EvidenceKind.AutomatedObservation;
    [JsonIgnore] public string Scope => "PROCESS_ONLY";
    [JsonIgnore] public string IndependentGameplayVerification => "NOT_RUN";
    private static bool Hex(string? value, int length) => value is not null && value.Length == length && value.All(c => c is >= '0' and <= '9' or >= 'a' and <= 'f');
    public void Validate()
    {
        if (Schema != 1 || !Hex(Session, 32) || !Hex(BetaSession, 32) ||
            State is not ("RESTORED" or "BLOCKED" or "RECOVERY_REQUIRED") || Case is not ("original" or "patched") ||
            InputsDispatched != 0 || Gameplay != "NOT_INDEPENDENTLY_VERIFIED" || HumanResults != "HUMAN_REPORTED_ONLY" ||
            AccountHistory != "NOT_RESTORED" || !Hex(OriginalSha256, 64) || !Hex(CandidateSha256, 64) ||
            LocalRecovery != (State == "RECOVERY_REQUIRED" ? "UNVERIFIED_PRESERVE_ALL_COPIES" : "CONTENT_TREE_VERIFIED") ||
            Utc == default || Utc > DateTimeOffset.UtcNow.AddMinutes(1) || Events is null || Events.Length > 200)
            throw new InvalidDataException("Invalid sanitized process receipt.");
        ScenarioCatalog.ValidateToken(Scenario); ScenarioCatalog.ValidateToken(Step);
        DateTimeOffset previous = DateTimeOffset.MinValue;
        foreach (var item in Events)
        {
            if (item is null || item.Kind is not ("OWNED_PROCESS_STARTED" or "OWNED_PROCESS_EXITED" or "OWNED_PROCESS_ABNORMAL_EXIT" or "HUMAN_SESSION_STOP_REQUESTED" or "OPTIONAL_CAPTURE_REFUSED") ||
                item.Classification != "AutomatedObservation" || item.Scope != "PROCESS_ONLY_NOT_GAMEPLAY" ||
                item.Utc == default || item.Utc < previous || item.Utc > Utc)
                throw new InvalidDataException("Unrecognized process-only observation.");
            previous = item.Utc;
        }
        if (JsonSerializer.SerializeToUtf8Bytes(this, BetaJson.Options).Length > MaximumBytes) throw new InvalidDataException("Process receipt exceeds size limit.");
    }
    public static NativeReceipt Parse(ReadOnlySpan<byte> bytes)
    {
        if (bytes.Length is 0 or > MaximumBytes) throw new InvalidDataException("Process receipt exceeds size limit.");
        // JsonSerializer otherwise accepts duplicate names with last-value wins.
        using (var doc = JsonDocument.Parse(bytes.ToArray(), new JsonDocumentOptions { MaxDepth = 8 })) CheckUnique(doc.RootElement);
        var receipt = JsonSerializer.Deserialize<NativeReceipt>(bytes, BetaJson.Options) ?? throw new InvalidDataException("Missing process receipt.");
        receipt.Validate();
        return receipt;
    }
    private static void CheckUnique(JsonElement value)
    {
        if (value.ValueKind == JsonValueKind.Object)
        {
            HashSet<string> names = [];
            foreach (var property in value.EnumerateObject())
            {
                if (!names.Add(property.Name)) throw new InvalidDataException("Duplicate receipt property.");
                CheckUnique(property.Value);
            }
        }
        else if (value.ValueKind == JsonValueKind.Array) foreach (var child in value.EnumerateArray()) CheckUnique(child);
    }
    internal static bool Same(NativeReceipt a, NativeReceipt b) => JsonSerializer.Serialize(a, BetaJson.Options) == JsonSerializer.Serialize(b, BetaJson.Options);
}
