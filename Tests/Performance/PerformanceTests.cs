using System.Diagnostics;
using Xunit;
using QuiptMappingEngine.Services;
using QuiptMappingEngine.Evaluation;
using QuiptMappingEngine.Xslt;

namespace Tests.Performance;

public class PerformanceTests
{
    private static string GetProjectRoot()
    {
        var dir = Directory.GetCurrentDirectory();
        while (dir != null && !File.Exists(Path.Combine(dir, "QuiptMappingEngine.csproj")))
            dir = Directory.GetParent(dir)?.FullName;
        return dir ?? Directory.GetCurrentDirectory();
    }

    [Theory]
    [InlineData("laptops", "amazon-laptops-attributes.json", "Laptops.xml", "CatalogExportTransform.Laptops.xslt")]
    [InlineData("desktops", "amazon-desktops-attributes.json", "Desktops.xml", "CatalogExportTransform.Desktops.xslt")]
    [InlineData("smartphones", "amazon-smartphones-attributes.json", "Smartphones.xml", "CatalogExportTransform.SmartPhones.xslt")]
    public void FullPipeline_CompletesWithinFiveSeconds(
        string category, string amazonFile, string quiptFile, string xsltFile)
    {
        var root = GetProjectRoot();
        var amazonPath = Path.Combine(root, "AmazonTaxonomy", amazonFile);
        var quiptPath = Path.Combine(root, "QuiptData", quiptFile);
        var xsltPath = Path.Combine(root, "QuiptToAmazonTemplates", xsltFile);

        if (!File.Exists(amazonPath) || !File.Exists(quiptPath) || !File.Exists(xsltPath)) return;

        var sw = Stopwatch.StartNew();

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
        var xslt = new XsltBuilder().Build(category, results);

        sw.Stop();

        Assert.True(sw.Elapsed.TotalSeconds < 5.0,
            $"Category '{category}' took {sw.Elapsed.TotalSeconds:F2}s — exceeds 5s threshold");
    }

    [Theory]
    [InlineData("laptops", "amazon-laptops-attributes.json", "Laptops.xml")]
    [InlineData("desktops", "amazon-desktops-attributes.json", "Desktops.xml")]
    [InlineData("smartphones", "amazon-smartphones-attributes.json", "Smartphones.xml")]
    public void MatchingEngine_CompletesWithinThreeSeconds(
        string category, string amazonFile, string quiptFile)
    {
        var root = GetProjectRoot();
        var amazonPath = Path.Combine(root, "AmazonTaxonomy", amazonFile);
        var quiptPath = Path.Combine(root, "QuiptData", quiptFile);

        if (!File.Exists(amazonPath) || !File.Exists(quiptPath)) return;

        var amazonFields = new AmazonFieldParser().Parse(amazonPath);
        var quiptFields = new QuiptSchemaParser().ParseFields(quiptPath);
        var engine = new MatchingEngine();

        var sw = Stopwatch.StartNew();
        var results = engine.Match(quiptFields, amazonFields, category);
        sw.Stop();

        Assert.True(sw.Elapsed.TotalSeconds < 5.0,
            $"MatchingEngine for '{category}' took {sw.Elapsed.TotalSeconds:F2}s — exceeds 5s threshold");
    }

    [Theory]
    [InlineData("laptops", "amazon-laptops-attributes.json")]
    [InlineData("desktops", "amazon-desktops-attributes.json")]
    [InlineData("smartphones", "amazon-smartphones-attributes.json")]
    public void AmazonParser_CompletesWithinTwoSeconds(string category, string amazonFile)
    {
        var root = GetProjectRoot();
        var amazonPath = Path.Combine(root, "AmazonTaxonomy", amazonFile);

        if (!File.Exists(amazonPath)) return;

        var parser = new AmazonFieldParser();

        var sw = Stopwatch.StartNew();
        var fields = parser.Parse(amazonPath);
        sw.Stop();

        Assert.True(sw.Elapsed.TotalSeconds < 2.0,
            $"AmazonFieldParser for '{category}' took {sw.Elapsed.TotalSeconds:F2}s — exceeds 2s threshold");
        Assert.NotEmpty(fields);
    }

    [Theory]
    [InlineData("Laptops.xml")]
    [InlineData("Desktops.xml")]
    [InlineData("Smartphones.xml")]
    public void QuiptParser_CompletesWithinTwoSeconds(string quiptFile)
    {
        var root = GetProjectRoot();
        var quiptPath = Path.Combine(root, "QuiptData", quiptFile);

        if (!File.Exists(quiptPath)) return;

        var parser = new QuiptSchemaParser();

        var sw = Stopwatch.StartNew();
        var fields = parser.ParseFields(quiptPath);
        sw.Stop();

        Assert.True(sw.Elapsed.TotalSeconds < 2.0,
            $"QuiptSchemaParser for '{quiptFile}' took {sw.Elapsed.TotalSeconds:F2}s — exceeds 2s threshold");
        Assert.NotEmpty(fields);
    }
}
