using System.Globalization;
using System.Text.RegularExpressions;

// Independent parser/interpreter for the emitted GML subset, not a GameMaker VM.
// Parses control flow and comparisons instead of consulting RouteCatalog.
internal sealed class GmlSubsetInterpreter
{
    private readonly string[] tokens;
    private readonly Dictionary<string, int> variables;
    private int position;
    private int? result;
    public GmlSubsetInterpreter(string source, IReadOnlyDictionary<string, int?> facts)
    {
        source = Regex.Replace(source, @"//[^\r\n]*", "");
        tokens = Regex.Matches(source, @"[A-Za-z_][A-Za-z_0-9.]*|-?\d+|\|\||!=|==|[<>=;{},()]")
            .Select(m => m.Value).ToArray();
        variables = facts.ToDictionary(x => "global.rk_" + x.Key, x => x.Value ?? -1);
    }
    public int Run()
    {
        while (position < tokens.Length) Statement(true);
        return result ?? throw new InvalidOperationException("No return statement executed");
    }
    private string Next() => position < tokens.Length ? tokens[position++] : throw new InvalidOperationException("Unexpected end");
    private bool Is(string token) => position < tokens.Length && tokens[position] == token;
    private void Expect(string token)
    {
        var actual = Next();
        if (actual != token) throw new InvalidOperationException($"Expected {token}; got {actual}");
    }
    private void Statement(bool execute)
    {
        if (Is("var"))
        {
            Next();
            while (!Is(";")) Next();
            Next();
        }
        else if (Is("{"))
        {
            Next();
            while (!Is("}")) Statement(execute);
            Next();
        }
        else if (Is("if"))
        {
            Next(); Expect("("); var condition = Expression() != 0; Expect(")");
            Statement(execute && condition);
            if (Is("else")) { Next(); Statement(execute && !condition); }
        }
        else if (Is("return"))
        {
            Next(); var value = Expression(); Expect(";");
            if (execute && result is null) result = value;
        }
        else
        {
            var variable = Next(); Expect("="); var value = Expression(); Expect(";");
            if (execute && result is null) variables[variable] = value;
        }
    }
    private int Expression()
    {
        var value = Comparison();
        while (Is("||"))
        {
            Next(); var right = Comparison();
            value = value != 0 || right != 0 ? 1 : 0;
        }
        return value;
    }
    private int Comparison()
    {
        var left = Atom();
        if (!(Is("<") || Is(">") || Is("!=") || Is("=="))) return left;
        var op = Next(); var right = Atom();
        return (op switch { "<" => left < right, ">" => left > right, "!=" => left != right, "==" => left == right, _ => false }) ? 1 : 0;
    }
    private int Atom()
    {
        var token = Next();
        if (int.TryParse(token, NumberStyles.Integer, CultureInfo.InvariantCulture, out var value)) return value;
        return variables.TryGetValue(token, out value) ? value : token.StartsWith("global.rk_", StringComparison.Ordinal) ? -1 :
            throw new InvalidOperationException("Uninitialized local " + token);
    }
}
