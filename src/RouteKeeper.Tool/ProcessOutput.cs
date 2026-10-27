using System.Text;

namespace RouteKeeper.Tool;

/// <summary>Drain both child pipes concurrently without retaining private diagnostics.</summary>
internal static class ProcessOutput
{
    internal readonly record struct Result(string Prefix, bool Truncated);

    internal static async Task<Result> DrainAsync(TextReader reader, int captureLimit = 0, CancellationToken cancellation = default)
    {
        if (captureLimit is < 0 or > 65536) throw new ArgumentOutOfRangeException(nameof(captureLimit));
        var prefix = new StringBuilder(captureLimit);
        var buffer = new char[4096];
        bool truncated = false;
        int count;
        while ((count = await reader.ReadAsync(buffer.AsMemory(), cancellation)) != 0)
        {
            int retained = Math.Min(count, captureLimit - prefix.Length);
            prefix.Append(buffer, 0, retained);
            truncated |= retained < count;
        }
        return new(prefix.ToString(), truncated);
    }
}
