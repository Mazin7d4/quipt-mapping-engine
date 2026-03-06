namespace QuiptMappingEngine.Normalization;

public static class NormalizationDictionary
{
    // Sprint 1 small dictionary (expand later)
    public static readonly Dictionary<string, string> Map = new()
    {
        ["screen"] = "display",
        ["display"] = "display",

        ["colour"] = "color",
        ["color"] = "color",

        ["ram"] = "memory",
        ["memory"] = "memory",

        ["hdd"] = "harddisk",
        ["harddisk"] = "harddisk",

        ["ssd"] = "storage",
        ["storage"] = "storage",

        ["manufacturer"] = "brand",
        ["maker"] = "brand",
        ["brand"] = "brand"
    };
}