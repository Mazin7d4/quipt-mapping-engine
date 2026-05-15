using Xunit;
using QuiptMappingEngine.Services;

namespace Tests.Integration;

public class QuiptSchemaParserTests
{
    private readonly QuiptSchemaParser _parser = new();

    private static string GetProjectRoot()
    {
        var dir = Directory.GetCurrentDirectory();
        while (dir != null && !File.Exists(Path.Combine(dir, "QuiptMappingEngine.csproj")))
            dir = Directory.GetParent(dir)?.FullName;
        return dir ?? Directory.GetCurrentDirectory();
    }

    [Fact]
    public void ParseFields_LaptopsXml_ReturnsNonEmptyList()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptData/Laptops.xml");
        if (!File.Exists(path)) return;

        var fields = _parser.ParseFields(path);

        Assert.NotEmpty(fields);
    }

    [Fact]
    public void ParseFields_LaptopsXml_ContainsAttributePaths()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptData/Laptops.xml");
        if (!File.Exists(path)) return;

        var fields = _parser.ParseFields(path);

        var attributeFields = fields.Where(f => f.Path.Contains("Attribute[q:Code=")).ToList();
        Assert.NotEmpty(attributeFields);
    }

    [Fact]
    public void ParseFields_LaptopsXml_ContainsKnownCodes()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptData/Laptops.xml");
        if (!File.Exists(path)) return;

        var fields = _parser.ParseFields(path);
        var paths = fields.Select(f => f.Path).ToList();

        Assert.Contains(paths, p => p.Contains("Code='GENERICCOLOR'") || p.Contains("Code='SCRNSIZE'") || p.Contains("Code='RAMSIZE'"));
    }

    [Fact]
    public void ParseFields_LaptopsXml_ContainsBrandPath()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptData/Laptops.xml");
        if (!File.Exists(path)) return;

        var fields = _parser.ParseFields(path);

        Assert.Contains(fields, f => f.Path.Contains("q:Brand/q:Name"));
    }

    [Fact]
    public void ParseFields_LaptopsXml_ContainsWeightPath()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptData/Laptops.xml");
        if (!File.Exists(path)) return;

        var fields = _parser.ParseFields(path);

        Assert.Contains(fields, f => f.Path.Contains("q:Weight"));
    }

    [Fact]
    public void ParseFields_LaptopsXml_ContainsDimensionPaths()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptData/Laptops.xml");
        if (!File.Exists(path)) return;

        var fields = _parser.ParseFields(path);

        Assert.Contains(fields, f => f.Path.Contains("q:Dimensions"));
    }

    [Fact]
    public void ParseFields_LaptopsXml_ContainsSKUPaths()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptData/Laptops.xml");
        if (!File.Exists(path)) return;

        var fields = _parser.ParseFields(path);

        Assert.Contains(fields, f => f.Path.Contains("q:SKU") || f.Path.Contains("q:SKUs"));
    }

    [Fact]
    public void ParseFields_DesktopsXml_ReturnsNonEmptyList()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptData/Desktops.xml");
        if (!File.Exists(path)) return;

        var fields = _parser.ParseFields(path);

        Assert.NotEmpty(fields);
    }

    [Fact]
    public void ParseFields_SmartphonesXml_ReturnsNonEmptyList()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptData/Smartphones.xml");
        if (!File.Exists(path)) return;

        var fields = _parser.ParseFields(path);

        Assert.NotEmpty(fields);
    }

    [Fact]
    public void ParseFields_NonExistentFile_ThrowsException()
    {
        Assert.ThrowsAny<Exception>(() => _parser.ParseFields("nonexistent_file.xml"));
    }

    [Fact]
    public void ParseFields_LaptopsXml_FieldsHaveDataTypes()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptData/Laptops.xml");
        if (!File.Exists(path)) return;

        var fields = _parser.ParseFields(path);

        var fieldsWithTypes = fields.Where(f => !string.IsNullOrWhiteSpace(f.DataType)).ToList();
        Assert.NotEmpty(fieldsWithTypes);
    }

    [Fact]
    public void ParseFields_LaptopsXml_SomeFieldsHaveEnumValues()
    {
        var path = Path.Combine(GetProjectRoot(), "QuiptData/Laptops.xml");
        if (!File.Exists(path)) return;

        var fields = _parser.ParseFields(path);

        var fieldsWithEnums = fields.Where(f => f.EnumValues != null && f.EnumValues.Count > 0).ToList();
        Assert.NotEmpty(fieldsWithEnums);
    }
}
