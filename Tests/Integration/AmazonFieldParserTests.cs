using Xunit;
using QuiptMappingEngine.Services;

namespace Tests.Integration;

public class AmazonFieldParserTests
{
    private readonly AmazonFieldParser _parser = new();

    private static string GetProjectRoot()
    {
        var dir = Directory.GetCurrentDirectory();
        while (dir != null && !File.Exists(Path.Combine(dir, "QuiptMappingEngine.csproj")))
            dir = Directory.GetParent(dir)?.FullName;
        return dir ?? Directory.GetCurrentDirectory();
    }

    [Fact]
    public void Parse_LaptopsJson_ReturnsNonEmptyList()
    {
        var path = Path.Combine(GetProjectRoot(), "AmazonTaxonomy/amazon-laptops-attributes.json");
        if (!File.Exists(path)) return; // skip if data file not available in CI

        var fields = _parser.Parse(path);

        Assert.NotEmpty(fields);
    }

    [Fact]
    public void Parse_LaptopsJson_ContainsRequiredFields()
    {
        var path = Path.Combine(GetProjectRoot(), "AmazonTaxonomy/amazon-laptops-attributes.json");
        if (!File.Exists(path)) return;

        var fields = _parser.Parse(path);

        var requiredFields = fields.Where(f => f.IsRequired).Select(f => f.Name).ToList();
        Assert.Contains("brand", requiredFields);
        Assert.Contains("bullet_point", requiredFields);
        Assert.Contains("item_name", requiredFields);
        Assert.Contains("country_of_origin", requiredFields);
    }

    [Fact]
    public void Parse_LaptopsJson_HasCorrectRequiredCount()
    {
        var path = Path.Combine(GetProjectRoot(), "AmazonTaxonomy/amazon-laptops-attributes.json");
        if (!File.Exists(path)) return;

        var fields = _parser.Parse(path);
        var requiredCount = fields.Count(f => f.IsRequired);

        Assert.True(requiredCount >= 5, $"Expected at least 5 required fields, got {requiredCount}");
    }

    [Fact]
    public void Parse_LaptopsJson_FieldsHaveDataTypes()
    {
        var path = Path.Combine(GetProjectRoot(), "AmazonTaxonomy/amazon-laptops-attributes.json");
        if (!File.Exists(path)) return;

        var fields = _parser.Parse(path);

        var fieldsWithTypes = fields.Where(f => !string.IsNullOrWhiteSpace(f.DataType)).ToList();
        Assert.NotEmpty(fieldsWithTypes);
    }

    [Fact]
    public void Parse_DesktopsJson_ReturnsNonEmptyList()
    {
        var path = Path.Combine(GetProjectRoot(), "AmazonTaxonomy/amazon-desktops-attributes.json");
        if (!File.Exists(path)) return;

        var fields = _parser.Parse(path);

        Assert.NotEmpty(fields);
    }

    [Fact]
    public void Parse_SmartphonesJson_ReturnsNonEmptyList()
    {
        var path = Path.Combine(GetProjectRoot(), "AmazonTaxonomy/amazon-smartphones-attributes.json");
        if (!File.Exists(path)) return;

        var fields = _parser.Parse(path);

        Assert.NotEmpty(fields);
    }

    [Fact]
    public void Parse_LaptopsJson_FieldsHaveNames()
    {
        var path = Path.Combine(GetProjectRoot(), "AmazonTaxonomy/amazon-laptops-attributes.json");
        if (!File.Exists(path)) return;

        var fields = _parser.Parse(path);

        Assert.All(fields, f => Assert.False(string.IsNullOrWhiteSpace(f.Name)));
    }

    [Fact]
    public void Parse_LaptopsJson_FieldsHavePaths()
    {
        var path = Path.Combine(GetProjectRoot(), "AmazonTaxonomy/amazon-laptops-attributes.json");
        if (!File.Exists(path)) return;

        var fields = _parser.Parse(path);

        Assert.All(fields, f => Assert.False(string.IsNullOrWhiteSpace(f.Path)));
    }

    [Fact]
    public void Parse_NonExistentFile_ThrowsException()
    {
        Assert.ThrowsAny<Exception>(() => _parser.Parse("nonexistent_file.json"));
    }
}
