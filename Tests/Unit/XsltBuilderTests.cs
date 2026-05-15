using System.Xml.Linq;
using Xunit;
using QuiptMappingEngine.Xslt;
using QuiptMappingEngine.Models;

namespace Tests.Unit;

public class XsltBuilderTests
{
    private readonly XsltBuilder _builder = new();

    [Fact]
    public void Build_ValidMappings_ProducesWellFormedXml()
    {
        var mappings = new List<MappingResult>
        {
            new() { MarketplaceField = "brand", QuiptPath = "q:Catalog/q:Brand/q:Name", Score = 0.95, IsRequired = true },
            new() { MarketplaceField = "color", QuiptPath = "q:Catalog/q:Attributes/q:Attribute[q:Code='GENERICCOLOR']/q:Value/a:string", Score = 0.80 }
        };

        var xslt = _builder.Build("laptops", mappings);

        // Should be parseable XML
        var doc = XDocument.Parse(xslt);
        Assert.NotNull(doc);
    }

    [Fact]
    public void Build_ValidMappings_HasStylesheetRoot()
    {
        var mappings = new List<MappingResult>
        {
            new() { MarketplaceField = "brand", QuiptPath = "q:Catalog/q:Brand/q:Name", Score = 0.95 }
        };

        var xslt = _builder.Build("laptops", mappings);

        Assert.Contains("<xsl:stylesheet", xslt);
        Assert.Contains("</xsl:stylesheet>", xslt);
    }

    [Fact]
    public void Build_ValidMappings_ContainsValueOfSelect()
    {
        var mappings = new List<MappingResult>
        {
            new() { MarketplaceField = "brand", QuiptPath = "q:Catalog/q:Brand/q:Name", Score = 0.95 }
        };

        var xslt = _builder.Build("laptops", mappings);

        Assert.Contains("<xsl:value-of select=\"q:Catalog/q:Brand/q:Name\"/>", xslt);
    }

    [Fact]
    public void Build_PartialMappings_OnlyIncludesMappedFields()
    {
        var mappings = new List<MappingResult>
        {
            new() { MarketplaceField = "brand", QuiptPath = "q:Catalog/q:Brand/q:Name", Score = 0.95 },
            new() { MarketplaceField = "color", QuiptPath = null, Score = 0.1, IsUnmatched = true }
        };

        var xslt = _builder.Build("laptops", mappings);

        Assert.Contains("<brand>", xslt);
        Assert.DoesNotContain("<color>", xslt);
    }

    [Fact]
    public void Build_NoMappings_ProducesMinimalValidStylesheet()
    {
        var mappings = new List<MappingResult>();

        var xslt = _builder.Build("laptops", mappings);

        var doc = XDocument.Parse(xslt);
        Assert.NotNull(doc);
        Assert.Contains("<xsl:stylesheet", xslt);
        Assert.Contains("</xsl:stylesheet>", xslt);
    }

    [Fact]
    public void Build_UnmatchedRequiredField_GeneratesComment()
    {
        var mappings = new List<MappingResult>
        {
            new() { MarketplaceField = "brand", QuiptPath = null, Score = 0.0, IsRequired = true, IsUnmatched = true }
        };

        var xslt = _builder.Build("laptops", mappings);

        Assert.Contains("<!-- Unmatched Required Field: brand -->", xslt);
    }

    [Fact]
    public void Build_UnmatchedNonRequiredField_NoCommentGenerated()
    {
        var mappings = new List<MappingResult>
        {
            new() { MarketplaceField = "color", QuiptPath = null, Score = 0.0, IsRequired = false, IsUnmatched = true }
        };

        var xslt = _builder.Build("laptops", mappings);

        Assert.DoesNotContain("<!-- Unmatched Required Field: color -->", xslt);
        Assert.DoesNotContain("<color>", xslt);
    }

    [Fact]
    public void Build_MultipleMappings_AllFieldsPresent()
    {
        var mappings = new List<MappingResult>
        {
            new() { MarketplaceField = "brand", QuiptPath = "q:Catalog/q:Brand/q:Name", Score = 0.95 },
            new() { MarketplaceField = "item_weight", QuiptPath = "q:Catalog/q:Weight/q:Value", Score = 0.85 },
            new() { MarketplaceField = "color", QuiptPath = "q:Catalog/q:Attributes/q:Attribute[q:Code='GENERICCOLOR']/q:Value/a:string", Score = 0.80 }
        };

        var xslt = _builder.Build("laptops", mappings);

        Assert.Contains("<brand>", xslt);
        Assert.Contains("<item_weight>", xslt);
        Assert.Contains("<color>", xslt);
    }

    [Fact]
    public void Build_OutputContainsTemplateMatch()
    {
        var mappings = new List<MappingResult>
        {
            new() { MarketplaceField = "brand", QuiptPath = "q:Catalog/q:Brand/q:Name", Score = 0.95 }
        };

        var xslt = _builder.Build("laptops", mappings);

        Assert.Contains("<xsl:template match=\"/\">", xslt);
        Assert.Contains("</xsl:template>", xslt);
    }

    [Fact]
    public void Build_OutputHasCorrectStructure()
    {
        var mappings = new List<MappingResult>
        {
            new() { MarketplaceField = "brand", QuiptPath = "q:Catalog/q:Brand/q:Name", Score = 0.95 }
        };

        var xslt = _builder.Build("laptops", mappings);

        Assert.Contains("<Root>", xslt);
        Assert.Contains("<attributes>", xslt);
        Assert.Contains("</attributes>", xslt);
        Assert.Contains("</Root>", xslt);
    }
}
