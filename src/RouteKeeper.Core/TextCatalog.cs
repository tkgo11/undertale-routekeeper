using System.Globalization;
using System.Text.Json;
using System.Text.RegularExpressions;

namespace RouteKeeper.Core;

/// <summary>Data-only locale resources shared with native generation; no game facts are written.</summary>
public static class TextCatalog
{
    public sealed record Locale(string Tag,string Name,string Font,int? LegacyValue);
    private static readonly System.Reflection.Assembly Assembly=typeof(TextCatalog).Assembly;
    private static JsonDocument Read(string name)
    {
        using var stream=Assembly.GetManifestResourceStream("RouteKeeper.Locales."+name+".json")??throw new InvalidDataException("Missing locale resource "+name);
        return JsonDocument.Parse(stream);
    }
    public static IReadOnlyList<Locale> Languages {get;}=LoadRegistry();
    private static readonly IReadOnlyDictionary<string,IReadOnlyDictionary<string,string>> Dictionaries=LoadDictionaries();
    private static IReadOnlyList<Locale> LoadRegistry()
    {
        using var document=Read("languages");
        return document.RootElement.GetProperty("languages").EnumerateArray().Where(x=>x.GetProperty("enabled").GetBoolean())
            .Select(x=>new Locale(x.GetProperty("tag").GetString()!,x.GetProperty("name").GetString()!,x.GetProperty("font").GetString()!,x.TryGetProperty("legacyValue",out var n)?n.GetInt32():null)).ToArray().AsReadOnly();
    }
    private static IReadOnlyDictionary<string,IReadOnlyDictionary<string,string>> LoadDictionaries()
    {
        var result=new Dictionary<string,IReadOnlyDictionary<string,string>>(StringComparer.Ordinal);
        foreach(var locale in Languages){using var doc=Read(locale.Tag);result[locale.Tag]=doc.RootElement.EnumerateObject().ToDictionary(x=>x.Name,x=>x.Value.GetString()!,StringComparer.Ordinal);}
        return result;
    }
    public static IEnumerable<string> Keys=>Dictionaries["en"].Keys;
    public static int Index(string? tag)=>Languages.Select((l,i)=>(l,i)).FirstOrDefault(x=>x.l.Tag==tag).i;
    public static int Migrate(string? tag,int legacy)=>!string.IsNullOrEmpty(tag)?Index(tag):Languages.Select((l,i)=>(l,i)).FirstOrDefault(x=>x.l.LegacyValue==legacy).i;
    public static string Get(string id,Language language=Language.English)=>Get(id,(int)language);
    public static string Get(string id,int language)=>Get(id,language>=0&&language<Languages.Count?Languages[language].Tag:"en");
    public static string Get(string id,string? tag)
    {
        if(!Dictionaries["en"].TryGetValue(id,out var english))throw new KeyNotFoundException("Unknown text ID "+id);
        return tag is not null&&Dictionaries.TryGetValue(tag,out var dictionary)&&dictionary.TryGetValue(id,out var value)&&!string.IsNullOrEmpty(value)?value:english;
    }
    public static string Format(string id,Language language,IReadOnlyDictionary<string,string> values)
    {
        return Regex.Replace(Get(id,language),@"\{([a-z_]+)\}",m=>values.TryGetValue(m.Groups[1].Value,out var value)?value:throw new ArgumentException("Missing placeholder "+m.Groups[1].Value));
    }
    public static string FormatNumber(string id,Language language,string name,int value)=>Format(id,language,new Dictionary<string,string>{{name,value.ToString(CultureInfo.InvariantCulture)}});
    public static string Gml(string id,string locale="global.rk_language")=>$"scr_routekeeper_text({GmlRuleEmitter.Quote(id)},{locale})";
}
