using System.Buffers.Binary;
using System.IO.Compression;

namespace RouteKeeper.Beta;

public static class Screenshot
{
    public const int MaximumBytes = 8 * 1024 * 1024;
    private static readonly byte[] Signature = [137, 80, 78, 71, 13, 10, 26, 10];
    public static void ValidateDimensions(byte[] bytes)
    {
        ArgumentNullException.ThrowIfNull(bytes);
        if (bytes.Length is < 33 or > MaximumBytes || !bytes.AsSpan(0, 8).SequenceEqual(Signature) ||
            BinaryPrimitives.ReadUInt32BigEndian(bytes.AsSpan(8, 4)) != 13 ||
            !bytes.AsSpan(12, 4).SequenceEqual("IHDR"u8) || Crc(bytes.AsSpan(12, 17)) != BinaryPrimitives.ReadUInt32BigEndian(bytes.AsSpan(29, 4)))
            throw new InvalidDataException("Invalid PNG header.");
        int width = BinaryPrimitives.ReadInt32BigEndian(bytes.AsSpan(16, 4)), height = BinaryPrimitives.ReadInt32BigEndian(bytes.AsSpan(20, 4));
        if (width is < 1 or > 8192 || height is < 1 or > 8192 || (long)width * height > 16000000)
            throw new InvalidDataException("Screenshot exceeds 16 million pixels.");
    }
    /// <summary>Accept bounded non-interlaced RGBA8 PNG; remove all ancillary metadata without changing pixels.</summary>
    public static byte[] Sanitize(byte[] bytes)
    {
        ValidateDimensions(bytes);
        if (bytes.Length is < 45 or > MaximumBytes || !bytes.AsSpan(0, 8).SequenceEqual(Signature)) throw new InvalidDataException("Select a PNG screenshot, at most 8 MiB.");
        using var output = new MemoryStream(); output.Write(bytes, 0, 33);
        using var pixels = new MemoryStream();
        int offset = 8, width = 0, height = 0; bool ended = false, data = false, dataEnded = false;
        while (offset < bytes.Length)
        {
            if (bytes.Length - offset < 12) throw new InvalidDataException("Truncated PNG chunk.");
            uint length = BinaryPrimitives.ReadUInt32BigEndian(bytes.AsSpan(offset, 4));
            if (length > bytes.Length - offset - 12) throw new InvalidDataException("PNG chunk exceeds file.");
            int count = (int)length;
            string type = System.Text.Encoding.ASCII.GetString(bytes, offset + 4, 4);
            var contents = bytes.AsSpan(offset + 8, count);
            if (Crc(bytes.AsSpan(offset + 4, count + 4)) != BinaryPrimitives.ReadUInt32BigEndian(bytes.AsSpan(offset + 8 + count, 4))) throw new InvalidDataException("PNG CRC mismatch.");
            if (offset == 8 && type != "IHDR") throw new InvalidDataException("PNG header missing.");
            if (type == "IHDR")
            {
                if (offset != 8 || count != 13) throw new InvalidDataException("Invalid PNG header.");
                width = BinaryPrimitives.ReadInt32BigEndian(contents); height = BinaryPrimitives.ReadInt32BigEndian(contents[4..]);
                if (width is < 1 or > 8192 || height is < 1 or > 8192 || (long)width * height > 16000000 ||
                    contents[8] != 8 || contents[9] != 6 || contents[10] != 0 || contents[11] != 0 || contents[12] != 0)
                    throw new InvalidDataException("Screenshot must be non-interlaced RGBA8 PNG within 16 million pixels. Use the application import dialog to convert it.");
            }
            else if (type == "IDAT")
            {
                if (dataEnded) throw new InvalidDataException("Non-contiguous PNG image data.");
                data = true; pixels.Write(contents);
            }
            else
            {
                if (data) dataEnded = true;
                if (type == "IEND")
                {
                    if (!data || count != 0 || offset + 12 != bytes.Length) throw new InvalidDataException("Invalid PNG end.");
                    ended = true;
                }
                else if (type.Length != 4 || type.Any(c => !char.IsAsciiLetter(c)) || char.IsUpper(type[0]))
                    throw new InvalidDataException("Unsupported critical PNG chunk.");
            }
            offset += count + 12;
        }
        if (!ended) throw new InvalidDataException("PNG has no end marker.");
        pixels.Position = 0;
        using var inflater = new ZLibStream(pixels, CompressionMode.Decompress);
        using var compressed = new MemoryStream();
        byte[] row = new byte[checked(width * 4 + 1)];
        using (var compressor = new ZLibStream(compressed, CompressionLevel.SmallestSize, true))
        {
            for (int y = 0; y < height; y++)
            {
                inflater.ReadExactly(row);
                if (row[0] > 4) throw new InvalidDataException("Invalid PNG filter.");
                compressor.Write(row);
            }
            if (inflater.ReadByte() != -1) throw new InvalidDataException("Excess PNG pixels.");
        }
        // Never retain original compressed bytes: zlib readers may ignore an
        // appended non-pixel payload inside a CRC-valid IDAT chunk.
        if (compressed.Length + 57 > MaximumBytes) throw new InvalidDataException("Sanitized screenshot exceeds the byte budget.");
        WriteChunk(output, "IDAT"u8, compressed.ToArray()); WriteChunk(output, "IEND"u8, []);
        return output.ToArray();
    }
    private static void WriteChunk(Stream output, ReadOnlySpan<byte> type, ReadOnlySpan<byte> payload)
    {
        Span<byte> number = stackalloc byte[4];
        BinaryPrimitives.WriteInt32BigEndian(number, payload.Length); output.Write(number);
        byte[] bytes = new byte[checked(payload.Length + 4)]; type.CopyTo(bytes); payload.CopyTo(bytes.AsSpan(4)); output.Write(bytes);
        BinaryPrimitives.WriteUInt32BigEndian(number, Crc(bytes)); output.Write(number);
    }
    private static uint Crc(ReadOnlySpan<byte> bytes)
    {
        uint value = uint.MaxValue;
        foreach (byte b in bytes)
        {
            value ^= b;
            for (int i = 0; i < 8; i++) value = (value >> 1) ^ ((value & 1) != 0 ? 0xedb88320u : 0u);
        }
        return ~value;
    }
}
