namespace QuiptMappingEngine.Evaluation;

public static class GroundTruthLoader
{
    public static Dictionary<string, string> LoadAmazonGroundTruth(string category)
    {
        // Map category -> correct manual XSLT file
        var xsltPath = category.ToLowerInvariant() switch
        {
            "laptops" => "QuiptToAmazonTemplates/CatalogExportTransform.Laptops.xslt",
            "desktops" => "QuiptToAmazonTemplates/CatalogExportTransform.Desktops.xslt",
            "smartphones" => "QuiptToAmazonTemplates/CatalogExportTransform.SmartPhones.xslt",
            _ => throw new ArgumentException($"Unknown category: {category}")
        };

        var extracted = GroundTruthXsltExtractor.ExtractFromFile(xsltPath);

        // Keep only real Quipt XPaths for evaluation
        return extracted
            .Where(kvp => kvp.Value.StartsWith("q:", StringComparison.OrdinalIgnoreCase))
            .ToDictionary(kvp => kvp.Key, kvp => kvp.Value, StringComparer.OrdinalIgnoreCase);
    }
}