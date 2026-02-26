public static class Normalizer
{
    private static readonly Dictionary<string, string> dict = new()
    {
        { "screen", "display" },
        { "colour", "color" },
        { "ram", "memory" },
        { "hdd", "harddisk" }
    };

    public static string Normalize(string input)
    {
        string lower = input.ToLower();

        foreach (var kv in dict)
        {
            lower = lower.Replace(kv.Key, kv.Value);
        }

        return lower;
    }
}


