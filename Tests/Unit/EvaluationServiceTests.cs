using Xunit;
using QuiptMappingEngine.Evaluation;

namespace Tests.Unit;

public class EvaluationServiceTests
{
    [Fact]
    public void Evaluate_PerfectMatch_Returns100PercentAccuracy()
    {
        var groundTruth = new Dictionary<string, string>
        {
            ["brand"] = "q:Catalog/q:Brand/q:Name",
            ["color"] = "q:Catalog/q:Attributes/q:Attribute[q:Code='GENERICCOLOR']/q:Value/a:string"
        };

        var autoMappings = new List<EvaluatedMapping>
        {
            new() { MarketplaceFieldName = "brand", MatchedQuiptXPath = "q:Catalog/q:Brand/q:Name", IsRequired = true },
            new() { MarketplaceFieldName = "color", MatchedQuiptXPath = "q:Catalog/q:Attributes/q:Attribute[q:Code='GENERICCOLOR']/q:Value/a:string", IsRequired = false }
        };

        var report = EvaluationService.Evaluate("laptops", autoMappings, groundTruth);

        Assert.Equal(100.0, report.AccuracyPercent);
    }

    [Fact]
    public void Evaluate_NoMatches_ReturnsZeroAccuracy()
    {
        var groundTruth = new Dictionary<string, string>
        {
            ["brand"] = "q:Catalog/q:Brand/q:Name",
            ["color"] = "q:Catalog/q:Attributes/q:Attribute[q:Code='GENERICCOLOR']/q:Value/a:string"
        };

        var autoMappings = new List<EvaluatedMapping>
        {
            new() { MarketplaceFieldName = "brand", MatchedQuiptXPath = null, IsRequired = true },
            new() { MarketplaceFieldName = "color", MatchedQuiptXPath = null, IsRequired = false }
        };

        var report = EvaluationService.Evaluate("laptops", autoMappings, groundTruth);

        Assert.Equal(0.0, report.AccuracyPercent);
    }

    [Fact]
    public void Evaluate_PartialMatch_ReturnsCorrectPercentage()
    {
        var groundTruth = new Dictionary<string, string>
        {
            ["brand"] = "q:Catalog/q:Brand/q:Name",
            ["color"] = "q:Catalog/q:Attributes/q:Attribute[q:Code='GENERICCOLOR']/q:Value/a:string"
        };

        var autoMappings = new List<EvaluatedMapping>
        {
            new() { MarketplaceFieldName = "brand", MatchedQuiptXPath = "q:Catalog/q:Brand/q:Name", IsRequired = true },
            new() { MarketplaceFieldName = "color", MatchedQuiptXPath = "q:Catalog/q:SomeWrongPath", IsRequired = false }
        };

        var report = EvaluationService.Evaluate("laptops", autoMappings, groundTruth);

        Assert.Equal(50.0, report.AccuracyPercent);
    }

    [Fact]
    public void Evaluate_EmptyGroundTruth_ReturnsZeroAccuracy()
    {
        var groundTruth = new Dictionary<string, string>();

        var autoMappings = new List<EvaluatedMapping>
        {
            new() { MarketplaceFieldName = "brand", MatchedQuiptXPath = "q:Catalog/q:Brand/q:Name", IsRequired = true }
        };

        var report = EvaluationService.Evaluate("laptops", autoMappings, groundTruth);

        Assert.Equal(0.0, report.AccuracyPercent);
    }

    [Fact]
    public void Evaluate_RequiredFieldCoverage_AllMatched_Returns100()
    {
        var groundTruth = new Dictionary<string, string>();
        var autoMappings = new List<EvaluatedMapping>
        {
            new() { MarketplaceFieldName = "brand", MatchedQuiptXPath = "q:Catalog/q:Brand/q:Name", IsRequired = true },
            new() { MarketplaceFieldName = "item_name", MatchedQuiptXPath = "q:Catalog/q:Title", IsRequired = true }
        };

        var report = EvaluationService.Evaluate("laptops", autoMappings, groundTruth);

        Assert.Equal(100.0, report.RequiredCoveragePercent);
        Assert.Equal(2, report.MatchedRequiredFields);
        Assert.Empty(report.UnmatchedRequiredFields);
    }

    [Fact]
    public void Evaluate_RequiredFieldCoverage_NoneMatched_ReturnsZero()
    {
        var groundTruth = new Dictionary<string, string>();
        var autoMappings = new List<EvaluatedMapping>
        {
            new() { MarketplaceFieldName = "brand", MatchedQuiptXPath = null, IsRequired = true },
            new() { MarketplaceFieldName = "item_name", MatchedQuiptXPath = null, IsRequired = true }
        };

        var report = EvaluationService.Evaluate("laptops", autoMappings, groundTruth);

        Assert.Equal(0.0, report.RequiredCoveragePercent);
        Assert.Equal(0, report.MatchedRequiredFields);
        Assert.Equal(2, report.UnmatchedRequiredFields.Count);
    }

    [Fact]
    public void Evaluate_RequiredFieldCoverage_PartialMatch_ReturnsCorrectPercentage()
    {
        var groundTruth = new Dictionary<string, string>();
        var autoMappings = new List<EvaluatedMapping>
        {
            new() { MarketplaceFieldName = "brand", MatchedQuiptXPath = "q:Catalog/q:Brand/q:Name", IsRequired = true },
            new() { MarketplaceFieldName = "item_name", MatchedQuiptXPath = null, IsRequired = true },
            new() { MarketplaceFieldName = "color", MatchedQuiptXPath = "q:SomePath", IsRequired = false }
        };

        var report = EvaluationService.Evaluate("laptops", autoMappings, groundTruth);

        Assert.Equal(50.0, report.RequiredCoveragePercent);
        Assert.Contains("item_name", report.UnmatchedRequiredFields);
    }

    [Fact]
    public void Evaluate_CoveragePercent_CountsAnyMatch()
    {
        var groundTruth = new Dictionary<string, string>();
        var autoMappings = new List<EvaluatedMapping>
        {
            new() { MarketplaceFieldName = "brand", MatchedQuiptXPath = "q:Catalog/q:Brand/q:Name", IsRequired = true },
            new() { MarketplaceFieldName = "color", MatchedQuiptXPath = null, IsRequired = false },
            new() { MarketplaceFieldName = "weight", MatchedQuiptXPath = "q:Catalog/q:Weight/q:Value", IsRequired = false }
        };

        var report = EvaluationService.Evaluate("laptops", autoMappings, groundTruth);

        // 2 out of 3 have a match
        Assert.Equal(2.0 / 3.0 * 100.0, report.CoveragePercent, precision: 1);
    }

    // --- PathsEqual Tests ---

    [Fact]
    public void PathsEqual_ExactMatch_ReturnsTrue()
    {
        Assert.True(EvaluationService.PathsEqual(
            "q:Catalog/q:Brand/q:Name",
            "q:Catalog/q:Brand/q:Name"));
    }

    [Fact]
    public void PathsEqual_CaseInsensitive_ReturnsTrue()
    {
        Assert.True(EvaluationService.PathsEqual(
            "q:Catalog/q:Brand/q:Name",
            "q:catalog/q:brand/q:name"));
    }

    [Fact]
    public void PathsEqual_EndsWith_ReturnsTrue()
    {
        Assert.True(EvaluationService.PathsEqual(
            "q:ArrayOfInventoryVirtualResult/q:InventoryVirtualResult/q:Catalog/q:Brand/q:Name",
            "q:Catalog/q:Brand/q:Name"));
    }

    [Fact]
    public void PathsEqual_SameAttributeCode_ReturnsTrue()
    {
        Assert.True(EvaluationService.PathsEqual(
            "q:Catalog/q:Attributes/q:Attribute[q:Code='GENERICCOLOR']/q:Value/a:string",
            "q:Catalog/q:Attributes/q:Attribute[q:Code='GENERICCOLOR']/q:Value/a:string[1]"));
    }

    [Fact]
    public void PathsEqual_DifferentAttributeCodes_ReturnsFalse()
    {
        Assert.False(EvaluationService.PathsEqual(
            "q:Catalog/q:Attributes/q:Attribute[q:Code='GENERICCOLOR']/q:Value/a:string",
            "q:Catalog/q:Attributes/q:Attribute[q:Code='RAMSIZE']/q:Value/a:string"));
    }

    [Fact]
    public void PathsEqual_CompletelyDifferentPaths_ReturnsFalse()
    {
        Assert.False(EvaluationService.PathsEqual(
            "q:Catalog/q:Brand/q:Name",
            "q:Catalog/q:Weight/q:Value"));
    }

    [Fact]
    public void PathsEqual_IndexPredicateStripped_ReturnsTrue()
    {
        Assert.True(EvaluationService.PathsEqual(
            "q:Catalog/q:Attributes/q:Attribute[q:Code='MODELNBR']/q:Value/a:string[1]",
            "q:Catalog/q:Attributes/q:Attribute[q:Code='MODELNBR']/q:Value/a:string"));
    }

    [Fact]
    public void PathsEqual_LastTwoSegments_MatchesCorrectly()
    {
        Assert.True(EvaluationService.PathsEqual(
            "q:ArrayOfInventoryVirtualResult/q:InventoryVirtualResult/q:Catalog/q:CountryOfOrigin/q:ISO3",
            "q:Catalog/q:CountryOfOrigin/q:ISO3"));
    }
}
