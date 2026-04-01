using System.Linq;
using QuiptMappingEngine.Models;
using QuiptMappingEngine.Normalization;

namespace QuiptMappingEngine.Services;

/// <summary>
/// Extra synonym tokens and path bonuses so Amazon JSON names (snake_case, long phrases)
/// align with Quipt attribute codes and paths used in manual XSLT.
/// </summary>
internal static class AmazonMatchingHints
{
    internal static string CanonicalAmazonKey(string amazonFieldName) =>
        string.Join("", FieldNormalizer.GetNormalizedTokens(amazonFieldName));

    /// <summary>Tokens merged into the Amazon side before scoring (improves Jaccard / recall).</summary>
    internal static void AppendHintTokens(string amazonFieldName, List<string> tokens)
    {
        var key = CanonicalAmazonKey(amazonFieldName);
        if (!ExtraTokensByCanonKey.TryGetValue(key, out var extras))
            return;
        foreach (var t in extras)
        {
            if (!tokens.Any(x => x.Equals(t, StringComparison.OrdinalIgnoreCase)))
                tokens.Add(t);
        }
    }

    /// <summary>Small additive bonus when the chosen Quipt XPath clearly matches the Amazon field intent.</summary>
    internal static double PathAlignmentBonus(string amazonFieldName, Field quipt)
    {
        var key = CanonicalAmazonKey(amazonFieldName);
        var path = quipt.Path ?? "";
        if (path.Length == 0) return 0.0;

        // Attribute codes (most reliable)
        if (key is "modelnumber" or "modelname" or "partnumber")
        {
            if (path.Contains("MODELNBR", StringComparison.OrdinalIgnoreCase) ||
                path.Contains("ModelNumber", StringComparison.OrdinalIgnoreCase))
                return 0.14;
        }

        return key switch
        {
            "brand" when Contains(path, "Brand") && Contains(path, "Name") => 0.14,
            "manufacturer" when Contains(path, "Brand") || Contains(path, "Manufacturer") => 0.10,
            "itemname" when Contains(path, "Title") || (Contains(path, "Catalog") && Contains(path, "Name")) => 0.12,
            "productdescription" when Contains(path, "Description") => 0.12,
            "bulletpoint" when Contains(path, "Bullet") || Contains(path, "Description") => 0.08,
            "modelnumber" or "modelname" when path.Contains("Attribute", StringComparison.OrdinalIgnoreCase) &&
                (Contains(path, "MODELNBR") || Contains(path, "Model")) => 0.10,
            "itemweight" when Contains(path, "Weight") && Contains(path, "Shipping") => 0.12,
            "itemweight" when Contains(path, "Weight") => 0.08,
            "countryoforigin" when Contains(path, "Country") || Contains(path, "Origin") => 0.10,
            "processordescription" or "cpumodel" or "processorcount" when Contains(path, "CPU") ||
                Contains(path, "Processor") || Contains(path, "CPUSPEED") || Contains(path, "CPUCORE") => 0.11,
            "graphicsdescription" or "graphicscoprocessor" when Contains(path, "GPU") ||
                Contains(path, "Graphics") || Contains(path, "GPUMODEL") => 0.11,
            "memorystoragecapacity" or "computermemory" or "rammemory" or "digitalstoragecapacity"
                when Contains(path, "RAM") || Contains(path, "Memory") || Contains(path, "HD") ||
                   Contains(path, "Storage") || Contains(path, "Solid") => 0.10,
            "harddisk" or "solidstatestoragedrive" when Contains(path, "HD") ||
                Contains(path, "SSD") || Contains(path, "Storage") => 0.10,
            "screensize" or "display" when Contains(path, "SCRN") || Contains(path, "Display") ||
                Contains(path, "Screen") => 0.10,
            "resolution" or "nativeresolution" when Contains(path, "Resolution") ||
                Contains(path, "SCRNRES") => 0.10,
            "color" when Contains(path, "Color") || Contains(path, "Colour") => 0.08,
            "connectivitytechnology" or "wirelesscommunicationtechnology" or "wirelesscommstandard"
                when Contains(path, "Wireless") || Contains(path, "Bluetooth") ||
                     Contains(path, "LAN") || Contains(path, "Ethernet") => 0.10,
            "operatingsystem" when Contains(path, "OS") || Contains(path, "Operating") => 0.10,
            "formfactor" when Contains(path, "Form") || Contains(path, "FACT") => 0.08,
            "warrantytype" when Contains(path, "Warranty") => 0.08,
            "itemtypekeyword" or "generickeyword" when Contains(path, "Keyword") || Contains(path, "Search") => 0.06,
            _ => 0.0
        };
    }

    private static bool Contains(string path, string sub) =>
        path.Contains(sub, StringComparison.OrdinalIgnoreCase);

    /// <summary>Canonical key → extra tokens (post-normalization) that appear on Quipt side.</summary>
    private static readonly Dictionary<string, string[]> ExtraTokensByCanonKey = new(StringComparer.OrdinalIgnoreCase)
    {
        ["brand"] = new[] { "brand", "name" },
        ["manufacturer"] = new[] { "brand", "manufacturer" },
        ["itemname"] = new[] { "name", "title", "item" },
        ["productdescription"] = new[] { "description" },
        ["bulletpoint"] = new[] { "bullet", "description", "feature" },
        ["modelnumber"] = new[] { "model", "modelnbr", "sku" },
        ["modelname"] = new[] { "model", "modelnbr" },
        ["partnumber"] = new[] { "part", "modelnbr" },
        ["itemweight"] = new[] { "weight", "shipping" },
        ["countryoforigin"] = new[] { "country", "origin" },
        ["processordescription"] = new[] { "processor", "cpu", "core", "speed" },
        ["cpumodel"] = new[] { "processor", "cpu", "model" },
        ["processorcount"] = new[] { "processor", "core", "count" },
        ["graphicsdescription"] = new[] { "graphics", "gpu", "video" },
        ["graphicscoprocessor"] = new[] { "graphics", "gpu" },
        ["memorystoragecapacity"] = new[] { "memory", "ram", "storage", "hd" },
        ["computermemory"] = new[] { "memory", "ram" },
        ["rammemory"] = new[] { "memory", "ram" },
        ["digitalstoragecapacity"] = new[] { "storage", "harddisk", "ssd" },
        ["harddisk"] = new[] { "harddisk", "storage", "hd" },
        ["solidstatestoragedrive"] = new[] { "ssd", "storage" },
        ["screensize"] = new[] { "display", "screen", "size" },
        ["display"] = new[] { "display", "screen", "scrn" },
        ["resolution"] = new[] { "resolution", "display" },
        ["nativeresolution"] = new[] { "resolution", "scrnres" },
        ["color"] = new[] { "color", "colour" },
        ["connectivitytechnology"] = new[] { "connectivity", "wireless", "wifi", "bluetooth", "lan" },
        ["wirelesscommunicationtechnology"] = new[] { "wireless", "wifi", "bluetooth" },
        ["wirelesscommstandard"] = new[] { "wireless", "wifi" },
        ["operatingsystem"] = new[] { "operatingsystem", "os", "desktop" },
        ["formfactor"] = new[] { "form", "factor", "laptop" },
        ["warrantytype"] = new[] { "warranty" },
        ["itemtypekeyword"] = new[] { "keyword", "type" },
        ["generickeyword"] = new[] { "keyword", "search" },
        ["modelyear"] = new[] { "year", "release" },
        ["keyboarddescription"] = new[] { "keyboard" },
        ["touchscreentype"] = new[] { "touch", "screen" },
        ["audiodescription"] = new[] { "audio", "speaker" },
        ["cameradescription"] = new[] { "camera", "webcam" },
        ["numberofcells"] = new[] { "battery", "cell" },
        ["softwareincluded"] = new[] { "software", "bundle" },
        ["includedcomponents"] = new[] { "component", "included" },
        ["supplierdeclareddghzregulation"] = new[] { "dangerous", "regulation", "hazmat", "dg" },
    };
}
