using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;

// Executes emitted straight-line/branching objective source, independently of its
// rule tables. This is intentionally a small test interpreter, not GameMaker.
internal sealed class GmlObjectiveInterpreter
{
    private readonly string[] tokens;
    private readonly Dictionary<string, object> values;
    private int cursor;
    private object? returned;
    public GmlObjectiveInterpreter(string source, IReadOnlyDictionary<string, int?> facts)
    {
        source = Regex.Replace(source, @"//[^\r\n]*", "");
        tokens = Regex.Matches(source, "\"(?:\\\\.|[^\"\\\\])*\"|[A-Za-z_][A-Za-z_0-9.]*|-?\\d+|\\|\\||&&|!=|==|<=|>=|\\+=|[!+<>=;{},()\\-]").Select(m => m.Value).ToArray();
        values = facts.ToDictionary(x => "global.rk_" + x.Key, x => (object)(x.Value ?? -1));
    }
    public string Run()
    {
        while (cursor < tokens.Length) Statement(true);
        return returned?.ToString() ?? throw new Exception("Missing return");
    }
    public int Integer(string global) => Number(Read("global.rk_" + global));
    public string Text(string global) => Read("global.rk_" + global).ToString()!;
    private object Read(string key) => values.GetValueOrDefault(key, -1);
    private static int Number(object value) => Convert.ToInt32(value, CultureInfo.InvariantCulture);
    private static bool Truth(object value) => Number(value) != 0;
    private string Next() => cursor < tokens.Length ? tokens[cursor++] : throw new Exception("Unexpected end");
    private bool Is(string text) => cursor < tokens.Length && tokens[cursor] == text;
    private void Need(string text) { var actual = Next(); if (actual != text) throw new Exception($"Expected {text}; got {actual}"); }
    private void Statement(bool execute)
    {
        if (Is("var")) { while (Next() != ";") { } return; }
        if (Is("{")) { Next(); while (!Is("}")) Statement(execute); Next(); return; }
        if (Is("if"))
        {
            Next(); Need("("); var condition = Truth(Expression()); Need(")");
            Statement(execute && condition);
            if (Is("else")) { Next(); Statement(execute && !condition); }
            return;
        }
        if (Is("return")) { Next(); var value = Expression(); Need(";"); if (execute && returned is null) returned = value; return; }
        var name = Next(); var op = Next(); if (op != "=" && op != "+=") throw new Exception("Invalid assignment " + op);
        var result = Expression(); Need(";");
        if (execute && returned is null) values[name] = op == "+=" ? Add(Read(name), result) : result;
    }
    private object Expression()
    {
        var value = And(); while (Is("||")) { Next(); var right = And(); value = Truth(value) || Truth(right) ? 1 : 0; } return value;
    }
    private object And()
    {
        var value = Compare(); while (Is("&&")) { Next(); var right = Compare(); value = Truth(value) && Truth(right) ? 1 : 0; } return value;
    }
    private object Compare()
    {
        var value = Sum();
        if (!(Is("==") || Is("!=") || Is("<") || Is(">") || Is("<=") || Is(">="))) return value;
        var op = Next(); var right = Sum();
        return (op switch { "==" => Equals(value, right), "!=" => !Equals(value, right), "<" => Number(value) < Number(right), ">" => Number(value) > Number(right), "<=" => Number(value) <= Number(right), ">=" => Number(value) >= Number(right), _ => false }) ? 1 : 0;
    }
    private static object Add(object a, object b) => a is string || b is string ? a.ToString() + b.ToString() : Number(a) + Number(b);
    private object Sum()
    {
        var value = Atom(); while (Is("+") || Is("-")) { var op = Next(); var right = Atom(); value = op == "+" ? Add(value, right) : Number(value) - Number(right); } return value;
    }
    private object Atom()
    {
        if (Is("!")) { Next(); return Truth(Atom()) ? 0 : 1; }
        if (Is("(")) { Next(); var result = Expression(); Need(")"); return result; }
        var token = Next();
        if (token.StartsWith('"')) return JsonSerializer.Deserialize<string>(token)!;
        if (int.TryParse(token, NumberStyles.Integer, CultureInfo.InvariantCulture, out var number)) return number;
        if (!Is("(")) return Read(token);
        Next(); var first = Expression();
        if (token == "string") { Need(")"); return first.ToString()!; }
        Need(","); var second = Expression(); Need(")");
        return token switch { "max" => Math.Max(Number(first), Number(second)), "min" => Math.Min(Number(first), Number(second)), _ => throw new Exception("Unsupported function " + token) };
    }
}
