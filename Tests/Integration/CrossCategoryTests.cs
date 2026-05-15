using System.Xml.Linq;
using Xunit;
using QuiptMappingEngine.Services;
using QuiptMappingEngine.Evaluation;
using QuiptMappingEngine.Xslt;

namespace Tests.Integration;

public class CrossCategoryTests
{
    private static string GetProjectRoot()
    {
        var dir = Directory.GetCurrentDirectory();
        while (dir != null && !File.Exists(Path.Combine(dir, "QuiptMappingEngine.csproj")))
            dir = Directory.GetParent(dir)?.FullName;
        return dir ?? Directory.GetCurrentDirectory();
    }

    [Theory]
    [InlineData("laptops", "amazon-laptops-attributes.json", "Laptops.xml")]
    [InlineData("desktops", "amazon-desktops-attributes.json", "Desktops.xml")]
    [InlineData("smartphones", "amazon-smartphones-attributes.json", "Smartphones.xml")]
    public void FullPipeline_AllCategories_ProducesNonZeroMappings(
        string category, string amazonFile, string quiptFile)
    {
        var root = GetProjectRoot();
        var amazonPath = Path.Combine(root, "AmazonTaxonomy", amazonFile);
        var quiptPath = Path.Combine(root, "QuiptData", quiptFile);

        if (!File.Exists(amazonPath) || !File.Exists(quiptPath)) return;

        var amazonFields = new AmazonFieldParser().Parse(amazonPath);
        var quiptFields = new QuiptSchemaParser().ParseFields(quiptPath);
        var engine = new MatchingEngine();

        var results = engine.Match(quiptFields, amazonFields, category);

        var matchedCount = results.Count(r => !r.IsUnmatched);
        Assert.True(matchedCount > 0, $"Category '{category}' produced zero matches");
    }

    [Theory]
    [InlineData("laptops", "amazon-laptops-attributes.json", "Laptops.xml", "CatalogExportTransform.Laptops.xslt", 85.0)]
    [InlineData("desktops", "amazon-desktops-attributes.json", "Desktops.xml", "CatalogExportTransform.Desktops.xslt", 85.0)]
    [InlineData("smartphones", "amazon-smartphones-attributes.json", "Smartphones.xml", "CatalogExportTransform.SmartPhones.xslt", 85.0)]
    public void FullPipeline_AllCategories_AccuracyMeetsThreshold(
        string category, string amazonFile, string quiptFile, string xsltFile, double minAccuracy)
    {
        var root = GetProjectRoot();
        var amazonPath = Path.Combine(root, "AmazonTaxonomy", amazonFile);
        var quiptPath = Path.Combine(root, "QuiptData", quiptFile);
        var xsltPath = Path.Combine(root, "QuiptToAmazonTemplates", xsltFile);

        if (!File.Exists(amazonPath) || !File.Exists(quiptPath) || !File.Exists(xsltPath)) return;

        var amazonFields = new AmazonFieldParser().Parse(amazonPath);
        var quiptFields = new QuiptSchemaParser().ParseFields(quiptPath);
        var engine = new MatchingEngine();
        var results = engine.Match(quiptFields, amazonFields, category);

        var groundTruth = GroundTruthXsltExtractor.ExtractFromFile(xsltPath);
        var evaluatedMappings = results.Select(m => new EvaluatedMapping
        {
            MarketplaceFieldName = m.MarketplaceField,
            MatchedQuiptXPath = m.QuiptPath,
            IsRequired = m.IsRequired
        }).ToList();

        var report = EvaluationService.Evaluate(category, evaluatedMappings, groundTruth);

        Assert.True(report.AccuracyPercent >= minAccuracy,
            $"Category '{category}' accuracy {report.AccuracyPercent:F1}% is below {minAccuracy}% threshold");
    }

    [Theory]
    [InlineData("laptops", "amazon-laptops-attributes.json", "Laptops.xml")]
    [InlineData("desktops", "amazon-desktops-attributes.json", "Desktops.xml")]
    [InlineData("smartphones", "amazon-smartphones-attributes.json", "Smartphones.xml")]
    public void FullPipeline_AllCategories_RequiredCoverageCalculated(
        string category, string amazonFile, string quiptFile)
    {
        var root = GetProjectRoot();
        var amazonPath = Path.Combine(root, "AmazonTaxonomy", amazonFile);
        var quiptPath = Path.Combine(root, "QuiptData", quiptFile);

        if (!File.Exists(amazonPath) || !File.Exists(quiptPath)) return;

        var amazonFields = new AmazonFieldParser().Parse(amazonPath);
        var quiptFields = new QuiptSchemaParser().ParseFields(quiptPath);
        var engine = new MatchingEngine();
        var results = engine.Match(quiptFields, amazonFields, category);

        var evaluatedMappings = results.Select(m => new EvaluatedMapping
        {
            MarketplaceFieldName = m.MarketplaceField,
            MatchedQuiptXPath = m.QuiptPath,
            IsRequired = m.IsRequired
        }).ToList();

        var report = EvaluationService.Evaluate(category, evaluatedMappings, new Dictionary<string, string>());

        Assert.True(report.TotalRequiredFields > 0,
            $"Category '{category}' has no required fields");
        Assert.True(report.RequiredCoveragePercent >= 0 && report.RequiredCoveragePercent <= 100,
            $"Category '{category}' has invalid required coverage: {report.RequiredCoveragePercent}");
    }

    [Theory]
    [InlineData("laptops", "amazon-laptops-attributes.json", "Laptops.xml")]
    [InlineData("desktops", "amazon-desktops-attributes.json", "Desktops.xml")]
    [InlineData("smartphones", "amazon-smartphones-attributes.json", "Smartphones.xml")]
    public void FullPipeline_AllCategories_XsltOutputIsValidXml(
        string category, string amazonFile, string quiptFile)
    {
        var root = GetProjectRoot();
        var amazonPath = Path.Combine(root, "AmazonTaxonomy", amazonFile);
        var quiptPath = Path.Combine(root, "QuiptData", quiptFile);

        if (!File.Exists(amazonPath) || !File.Exists(quiptPath)) return;

        var amazonFields = new AmazonFieldParser().Parse(amazonPath);
        var quiptFields = new QuiptSchemaParser().ParseFields(quiptPath);
        var engine = new MatchingEngine();
        var results = engine.Match(quiptFields, amazonFields, category);

        var xslt = new XsltBuilder().Build(category, results);

        Assert.NotEmpty(xslt);
        var doc = XDocument.Parse(xslt);
        Assert.NotNull(doc);
        Assert.Contains("<xsl:stylesheet", xslt);
    }

    [Theory]
    [InlineData("laptops", "amazon-laptops-attributes.json", "Laptops.xml")]
    [InlineData("desktops", "amazon-desktops-attributes.json", "Desktops.xml")]
    [InlineData("smartphones", "amazon-smartphones-attributes.json", "Smartphones.xml")]
    public void FullPipeline_AllCategories_ResultCountEqualsAmazonFields(
        string category, string amazonFile, string quiptFile)
    {
        var root = GetProjectRoot();
        var amazonPath = Path.Combine(root, "AmazonTaxonomy", amazonFile);
        var quiptPath = Path.Combine(root, "QuiptData", quiptFile);

        if (!File.Exists(amazonPath) || !File.Exists(quiptPath)) return;

        var amazonFields = new AmazonFieldParser().Parse(amazonPath);
        var quiptFields = new QuiptSchemaParser().ParseFields(quiptPath);
        var engine = new MatchingEngine();
        var results = engine.Match(quiptFields, amazonFields, category);

        Assert.Equal(amazonFields.Count, results.Count);
    }
}
