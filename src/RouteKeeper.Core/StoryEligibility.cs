namespace RouteKeeper.Core;

/// <summary>Original event gates; availability is distinct from completing an ending.</summary>
public static class StoryEligibility
{
    public static bool LetterCallAvailable(int won,int friendship,int kills,int plot10,int phase) => won>=1&&friendship>=3&&kills==0&&plot10>1980&&phase<8;
    public static bool PacifistFinaleSelected(int phase,int murderStage) => phase>=12&&murderStage<16;
}
