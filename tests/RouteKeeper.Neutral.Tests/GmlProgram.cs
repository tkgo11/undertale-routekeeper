using System.Globalization;
using System.Text.RegularExpressions;

// Independent executable interpreter of the generated numeric/control-flow GML subset.
// String output is tokenized but not rendered. This is not a GameMaker runtime.
internal sealed class GmlProgram
{
    readonly string[] tokens;
    readonly Dictionary<string,int> values;
    int cursor;
    int? returned;
    public GmlProgram(string source,IReadOnlyDictionary<string,int?> facts)
    {
        source=Regex.Replace(source,@"//[^\r\n]*","");
        tokens=Regex.Matches(source,"\"(?:\\\\.|[^\"\\\\])*\"|[A-Za-z_][A-Za-z_0-9.]*|-?\\d+|\\|\\||&&|!=|==|<=|>=|\\+=|[+<>=;{},()]").Select(x=>x.Value).ToArray();
        values=facts.ToDictionary(x=>"global.rk_"+x.Key,x=>x.Value??-1);
    }
    public int Run() { while(cursor<tokens.Length) Statement(true);return returned??throw new Exception("No return"); }
    string Next()=>tokens[cursor++];
    bool Is(string text)=>cursor<tokens.Length&&tokens[cursor]==text;
    void Need(string text) { var found=Next();if(found!=text)throw new Exception($"Expected {text},found {found}"); }
    void Statement(bool execute)
    {
        if(Is("var")) { while(Next()!=";"){};return; }
        if(Is("{")) { Next();while(!Is("}"))Statement(execute);Next();return; }
        if(Is("if")) { Next();Need("(");var condition=Expression()!=0;Need(")");Statement(execute&&condition);if(Is("else")){Next();Statement(execute&&!condition);}return; }
        if(Is("return")) { Next();var v=Expression();Need(";");if(execute&&returned is null)returned=v;return; }
        var key=Next();var op=Next();if(op is not ("=" or "+="))throw new Exception("Bad assignment "+op);
        var value=Expression();Need(";");if(execute&&returned is null)values[key]=op=="+="?Read(key)+value:value;
    }
    int Expression()
    {
        int value=And();while(Is("||")){Next();var r=And();value=value!=0||r!=0?1:0;}return value;
    }
    int And()
    {
        int value=Compare();while(Is("&&")){Next();var r=Compare();value=value!=0&&r!=0?1:0;}return value;
    }
    int Compare()
    {
        var left=Atom();if(!(Is("==")||Is("!=")||Is("<")||Is(">")||Is("<=")||Is(">=")))return left;
        var op=Next();var right=Atom();return (op switch {"=="=>left==right,"!="=>left!=right,"<"=>left<right,">"=>left>right,"<="=>left<=right,">="=>left>=right,_=>false})?1:0;
    }
    int Atom()
    {
        if(Is("(")){Next();var value=Expression();Need(")");return value;}
        var token=Next();if(token.StartsWith('"'))return 0;
        return int.TryParse(token,NumberStyles.Integer,CultureInfo.InvariantCulture,out var n)?n:Read(token);
    }
    int Read(string key)=>values.GetValueOrDefault(key,-1);
}
