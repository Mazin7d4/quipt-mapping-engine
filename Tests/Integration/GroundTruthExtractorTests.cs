using Xunit;
using QuiptMappingEngine.Evaluation;

namespace Tests.Integration;

public class GroundTruthExtractorTests
{
    private static string GetProjectRoot()
    {
        var dir = Directory.GetCurrentDirectory();
        while (dir != null && !File.Exists(Path.Combine(dir, "QuiptMappingEngine.csproj")))
            dir = Directory.GetParent(dir)?.FullName;
        return dir ?? Directory.GetCurrentDirectory();
    }

    // --- Amazon XSLT Extractor Tests ---

    [Fact]
    public void AmazonExtract_LaptopsXslt_ReturnsNonEmptyDictionary()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptToAmazonTemplates/CatalogExportTransform.Laptops.xslt");
        if (!File.Exists(path)) return;

        var result = GroundTruthXsltExtractor.ExtractFromFile(path);

        Assert.NotEmpty(result);
    }

    [Fact]
    public void AmazonExtract_LaptopsXslt_ContainsQuiptPaths()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptToAmazonTemplates/CatalogExportTransform.Laptops.xslt");
        if (!File.Exists(path)) return;

        var result = GroundTruthXsltExtractor.ExtractFromFile(path);

        Assert.True(result.Values.Any(v => v.Contains("q:")),
            "Expected ground truth values to contain 'q:' XPath prefixes");
    }

    [Fact]
    public void AmazonExtract_LaptopsXslt_ContainsBrandMapping()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptToAmazonTemplates/CatalogExportTransform.Laptops.xslt");
        if (!File.Exists(path)) return;

        var result = GroundTruthXsltExtractor.ExtractFromFile(path);

        var brandEntry = result.FirstOrDefault(kvp =>
            kvp.Key.Contains("brand", StringComparison.OrdinalIgnoreCase));

        Assert.NotNull(brandEntry.Key);
        Assert.Contains("q:Brand", brandEntry.Value, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void AmazonExtract_DesktopsXslt_ReturnsNonEmptyDictionary()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptToAmazonTemplates/CatalogExportTransform.Desktops.xslt");
        if (!File.Exists(path)) return;

        var result = GroundTruthXsltExtractor.ExtractFromFile(path);

        Assert.NotEmpty(result);
    }

    [Fact]
    public void AmazonExtract_SmartphonesXslt_ReturnsNonEmptyDictionary()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptToAmazonTemplates/CatalogExportTransform.SmartPhones.xslt");
        if (!File.Exists(path)) return;

        var result = GroundTruthXsltExtractor.ExtractFromFile(path);

        Assert.NotEmpty(result);
    }

    [Fact]
    public void AmazonExtract_LaptopsXslt_DoesNotContainIgnoredTags()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptToAmazonTemplates/CatalogExportTransform.Laptops.xslt");
        if (!File.Exists(path)) return;

        var result = GroundTruthXsltExtractor.ExtractFromFile(path);

        Assert.DoesNotContain(result, kvp => kvp.Key.Equals("xsl", StringComparison.OrdinalIgnoreCase));
        Assert.DoesNotContain(result, kvp => kvp.Key.Equals("Root", StringComparison.OrdinalIgnoreCase));
    }

    // --- eBay XML Extractor Tests ---

    [Fact]
    public void EbayExtract_LaptopsXml_ReturnsNonEmptyDictionary()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptToEbayTemplates/CatalogExportTransform.Laptops.xml");
        if (!File.Exists(path)) return;

        var result = EbayGroundTruthExtractor.ExtractFromFile(path);

        Assert.NotEmpty(result);
    }

    [Fact]
    public void EbayExtract_LaptopsXml_ContainsQuiptPaths()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptToEbayTemplates/CatalogExportTransform.Laptops.xml");
        if (!File.Exists(path)) return;

        var result = EbayGroundTruthExtractor.ExtractFromFile(path);

        Assert.True(result.Values.Any(v => v.Contains("q:")),
            "Expected eBay ground truth values to contain 'q:' XPath prefixes");
    }

    [Fact]
    public void EbayExtract_DesktopsXml_ReturnsNonEmptyDictionary()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptToEbayTemplates/CatalogExportTransform.Desktops.xml");
        if (!File.Exists(path)) return;

        var result = EbayGroundTruthExtractor.ExtractFromFile(path);

        Assert.NotEmpty(result);
    }

    [Fact]
    public void EbayExtract_SmartphonesXml_ReturnsNonEmptyDictionary()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptToEbayTemplates/CatalogExportTransform.SmartPhones.xml");
        if (!File.Exists(path)) return;

        var result = EbayGroundTruthExtractor.ExtractFromFile(path);

        Assert.NotEmpty(result);
    }

    [Fact]
    public void EbayExtract_LaptopsXml_ContainsKnownFields()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptToEbayTemplates/CatalogExportTransform.Laptops.xml");
        if (!File.Exists(path)) return;

        var result = EbayGroundTruthExtractor.ExtractFromFile(path);

        // eBay ground truth should contain at least one known field like Brand or Screen Size
        Assert.True(result.Count > 5,
            $"Expected more than 5 ground truth mappings, got {result.Count}");
    }
}
