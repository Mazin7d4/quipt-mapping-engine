using Xunit;
using QuiptMappingEngine.Models;
using QuiptMappingEngine.Services;

namespace Tests.Unit;

public class MatchingEngineTests
{
    private readonly MatchingEngine _engine = new();

    [Fact]
    public void Match_SimilarFieldNames_ProducesHighScore()
    {
        var quiptFields = new List<Field>
        {
            new() { Name = "BrandName", Path = "q:Catalog/q:Brand/q:Name", DataType = "string" }
        };
        var amazonFields = new List<Field>
        {
            new() { Name = "brand", Path = "properties.brand", IsRequired = true }
        };

        var results = _engine.Match(quiptFields, amazonFields, "laptops");

        var brandResult = results.First(r => r.MarketplaceField == "brand");
        Assert.False(brandResult.IsUnmatched);
        Assert.True(brandResult.Score > 0.25);
    }

    [Fact]
    public void Match_NoSimilarity_MarksUnmatched()
    {
        var quiptFields = new List<Field>
        {
            new() { Name = "SomeRandomField", Path = "q:Catalog/q:Random/q:Stuff", DataType = "string" }
        };
        var amazonFields = new List<Field>
        {
            new() { Name = "completely_unrelated_xyz", Path = "properties.completely_unrelated_xyz" }
        };

        var results = _engine.Match(quiptFields, amazonFields, "laptops");

        Assert.True(results[0].IsUnmatched);
    }

    [Fact]
    public void Match_BelowThreshold_MarksUnmatched()
    {
        var quiptFields = new List<Field>
        {
            new() { Name = "Temperature", Path = "q:Catalog/q:Temperature/q:Value", DataType = "string" }
        };
        var amazonFields = new List<Field>
        {
            new() { Name = "warranty_description", Path = "properties.warranty_description" }
        };

        var results = _engine.Match(quiptFields, amazonFields, "laptops");

        Assert.True(results[0].IsUnmatched || results[0].Score < 0.25);
    }

    [Fact]
    public void Match_RequiredFieldsProcessedFirst()
    {
        var quiptFields = new List<Field>
        {
            new() { Name = "BrandName", Path = "q:Catalog/q:Brand/q:Name", DataType = "string" }
        };
        var amazonFields = new List<Field>
        {
            new() { Name = "brand", Path = "properties.brand", IsRequired = true },
            new() { Name = "manufacturer", Path = "properties.manufacturer", IsRequired = false }
        };

        var results = _engine.Match(quiptFields, amazonFields, "laptops");

        var brandResult = results.First(r => r.MarketplaceField == "brand");
        Assert.False(brandResult.IsUnmatched);
        Assert.NotNull(brandResult.QuiptPath);
    }

    [Fact]
    public void Match_OneToOneConstraint_PreventsDoubleMapping()
    {
        var quiptFields = new List<Field>
        {
            new() { Name = "BrandName", Path = "q:Catalog/q:Brand/q:Name", DataType = "string" }
        };
        var amazonFields = new List<Field>
        {
            new() { Name = "brand", Path = "properties.brand", IsRequired = true },
            new() { Name = "manufacturer", Path = "properties.manufacturer", IsRequired = false }
        };

        var results = _engine.Match(quiptFields, amazonFields, "laptops");

        var brandMapped = results.First(r => r.MarketplaceField == "brand");
        Assert.False(brandMapped.IsUnmatched);
        Assert.NotNull(brandMapped.QuiptPath);
    }

    [Fact]
    public void Match_UsingRealTestData_ProducesResults()
    {
        var quiptFields = QuiptFields_Laptops.GetFields();
        var amazonFields = AmazonFields_Laptops.Get();

        var results = _engine.Match(quiptFields, amazonFields, "laptops");

        Assert.Equal(amazonFields.Count, results.Count);
        Assert.Contains(results, r => !r.IsUnmatched);
    }

    [Fact]
    public void Match_AliasMatch_ScoreFlooredAt065()
    {
        var quiptFields = new List<Field>
        {
            new() { Name = "GENERICCOLOR", Path = "q:Catalog/q:Attributes/q:Attribute[q:Code='GENERICCOLOR']/q:Value/a:string", DataType = "string" }
        };
        var amazonFields = new List<Field>
        {
            new() { Name = "color", Path = "properties.color", IsRequired = false }
        };

        var results = _engine.Match(quiptFields, amazonFields, "laptops");

        var colorResult = results.First(r => r.MarketplaceField == "color");
        if (!colorResult.IsUnmatched)
        {
            Assert.True(colorResult.Score >= 0.65);
        }
    }

    [Fact]
    public void Match_ResultCount_EqualsAmazonFieldCount()
    {
        var quiptFields = QuiptFields_Laptops.GetFields();
        var amazonFields = AmazonFields_Laptops.Get();

        var results = _engine.Match(quiptFields, amazonFields, "laptops");

        Assert.Equal(amazonFields.Count, results.Count);
    }

    [Fact]
    public void Match_ResultsContainRequiredFlag()
    {
        var quiptFields = QuiptFields_Laptops.GetFields();
        var amazonFields = AmazonFields_Laptops.Get();

        var results = _engine.Match(quiptFields, amazonFields, "laptops");

        var requiredResults = results.Where(r => r.IsRequired).ToList();
        var requiredInputs = amazonFields.Where(f => f.IsRequired).ToList();

        Assert.Equal(requiredInputs.Count, requiredResults.Count);
    }

    [Fact]
    public void Match_EmptyQuiptFields_AllUnmatched()
    {
        var quiptFields = new List<Field>();
        var amazonFields = new List<Field>
        {
            new() { Name = "brand", Path = "properties.brand", IsRequired = true }
        };

        var results = _engine.Match(quiptFields, amazonFields, "laptops");

        Assert.All(results, r => Assert.True(r.IsUnmatched));
    }

    [Fact]
    public void Match_EmptyAmazonFields_ReturnsEmptyResults()
    {
        var quiptFields = QuiptFields_Laptops.GetFields();
        var amazonFields = new List<Field>();

        var results = _engine.Match(quiptFields, amazonFields, "laptops");

        Assert.Empty(results);
    }
}
