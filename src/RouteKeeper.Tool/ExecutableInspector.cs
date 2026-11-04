using System.Buffers.Binary;
using System.Security.Cryptography;

namespace RouteKeeper.Tool;

public sealed record ExecutableIdentity(string Format, string PlatformFamily, IReadOnlyList<string> Architectures,
    long Size, string Sha256, string Verification = "HeaderOnly_NotGameProvenance");

/// <summary>Read-only executable headers. A runner header never authorizes a game patch.</summary>
public static class ExecutableInspector
{
    public static ExecutableIdentity Inspect(string path)
    {
        using var stream = File.OpenRead(path);
        if (stream.Length < 20) throw new InvalidDataException("Truncated executable header.");
        byte[] header = Read(stream, 0, 20);
        string format, platform;
        List<string> architectures = [];
        if (header[0] == 'M' && header[1] == 'Z')
        {
            format = "PE"; platform = "WindowsPE";
            uint offset = BinaryPrimitives.ReadUInt32LittleEndian(Read(stream, 0x3c, 4));
            byte[] pe = Read(stream, offset, 24);
            if (!pe.AsSpan(0, 4).SequenceEqual(new byte[] { 80, 69, 0, 0 })) throw new InvalidDataException("Invalid PE signature.");
            architectures.Add(BinaryPrimitives.ReadUInt16LittleEndian(pe.AsSpan(4)) switch
            {
                0x014c => "x86", 0x8664 => "x64", 0xaa64 => "arm64", _ => throw new InvalidDataException("Unsupported PE machine.")
            });
        }
        else if (header.AsSpan(0, 4).SequenceEqual(new byte[] { 127, 69, 76, 70 }))
        {
            format = "ELF"; platform = header[7] == 3 ? "LinuxABI" : "ELFUnix";
            if (header[4] is not (1 or 2) || header[5] is not (1 or 2) || header[6] != 1)
                throw new InvalidDataException("Unsupported ELF class, encoding or version.");
            var machine = U16(header.AsSpan(18), header[5] == 1);
            string arch = machine switch { 3 => "x86", 62 => "x64", 183 => "arm64", _ => throw new InvalidDataException("Unsupported ELF machine.") };
            if ((arch == "x86") != (header[4] == 1)) throw new InvalidDataException("ELF machine/class mismatch.");
            var elf = Read(stream, 0, header[4] == 1 ? 52 : 64);
            if (U32(elf.AsSpan(20), header[5] == 1) != 1 || U16(elf.AsSpan(header[4] == 1 ? 40 : 52), header[5] == 1) != elf.Length)
                throw new InvalidDataException("Invalid ELF header version or size.");
            architectures.Add(arch);
        }
        else
        {
            uint magic = BinaryPrimitives.ReadUInt32BigEndian(header);
            platform = "MachOApple";
            if (magic is 0xfeedface or 0xcefaedfe or 0xfeedfacf or 0xcffaedfe)
            {
                format = "Mach-O";
                bool little = magic is 0xcefaedfe or 0xcffaedfe;
                bool is64 = magic is 0xfeedfacf or 0xcffaedfe;
                Read(stream, 0, is64 ? 32 : 28);
                string arch = Cpu(U32(header.AsSpan(4), little));
                if ((arch != "x86") != is64) throw new InvalidDataException("Mach-O CPU/header mismatch.");
                architectures.Add(arch);
            }
            else if (magic is 0xcafebabe or 0xbebafeca or 0xcafebabf or 0xbfbafeca)
            {
                format = "Mach-O Universal";
                bool little = magic is 0xbebafeca or 0xbfbafeca;
                bool is64 = magic is 0xcafebabf or 0xbfbafeca;
                uint count = U32(header.AsSpan(4), little);
                if (count == 0 || count > 32) throw new InvalidDataException("Invalid universal executable architecture count.");
                int entrySize = is64 ? 32 : 20;
                long tableEnd = 8L + count * entrySize;
                Read(stream, 0, checked((int)tableEnd));
                for (int i = 0; i < count; i++)
                {
                    byte[] entry = Read(stream, 8L + i * entrySize, entrySize);
                    architectures.Add(Cpu(U32(entry, little)));
                    ulong offset = is64 ? U64(entry.AsSpan(8), little) : U32(entry.AsSpan(8), little);
                    ulong size = is64 ? U64(entry.AsSpan(16), little) : U32(entry.AsSpan(12), little);
                    if (offset < (ulong)tableEnd || size < 28 || offset > (ulong)stream.Length || size > (ulong)stream.Length - offset)
                        throw new InvalidDataException("Universal executable slice out of bounds.");
                    var slice = InspectThinSlice(stream, checked((long)offset), size);
                    if (slice != architectures[^1]) throw new InvalidDataException("Universal executable CPU/slice mismatch.");
                }
                if (architectures.Distinct().Count() != architectures.Count) throw new InvalidDataException("Duplicate universal executable architecture.");
            }
            else throw new InvalidDataException("Unsupported executable format.");
        }
        stream.Position = 0;
        return new(format, platform, architectures.AsReadOnly(), stream.Length, Convert.ToHexStringLower(SHA256.HashData(stream)));
    }
    private static string InspectThinSlice(Stream stream, long offset, ulong size)
    {
        var header = Read(stream, offset, 8);
        uint magic = BinaryPrimitives.ReadUInt32BigEndian(header);
        bool little = magic is 0xcefaedfe or 0xcffaedfe;
        bool is64 = magic is 0xfeedfacf or 0xcffaedfe;
        if (magic is not (0xfeedface or 0xcefaedfe or 0xfeedfacf or 0xcffaedfe) || size < (is64 ? 32UL : 28UL))
            throw new InvalidDataException("Invalid universal Mach-O slice.");
        var cpu = Cpu(U32(header.AsSpan(4), little));
        if ((cpu != "x86") != is64) throw new InvalidDataException("Mach-O slice width mismatch.");
        return cpu;
    }
    private static string Cpu(uint cpu) => cpu switch
    {
        7 => "x86", 0x01000007 => "x64", 0x0100000c => "arm64", _ => throw new InvalidDataException("Unsupported Mach-O CPU.")
    };
    private static ushort U16(ReadOnlySpan<byte> bytes, bool little) => little ? BinaryPrimitives.ReadUInt16LittleEndian(bytes) : BinaryPrimitives.ReadUInt16BigEndian(bytes);
    private static uint U32(ReadOnlySpan<byte> bytes, bool little) => little ? BinaryPrimitives.ReadUInt32LittleEndian(bytes) : BinaryPrimitives.ReadUInt32BigEndian(bytes);
    private static ulong U64(ReadOnlySpan<byte> bytes, bool little) => little ? BinaryPrimitives.ReadUInt64LittleEndian(bytes) : BinaryPrimitives.ReadUInt64BigEndian(bytes);
    private static byte[] Read(Stream stream, long offset, int count)
    {
        if (offset < 0 || count < 0 || offset > stream.Length || count > stream.Length - offset)
            throw new InvalidDataException("Executable header exceeds file bounds.");
        stream.Position = offset;
        var buffer = new byte[count]; stream.ReadExactly(buffer); return buffer;
    }
}
