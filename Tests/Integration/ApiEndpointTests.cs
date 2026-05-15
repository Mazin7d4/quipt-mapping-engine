using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace Tests.Integration;

public class ApiEndpointTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly HttpClient _client;

    private static string GetProjectRoot()
    {
        var dir = Directory.GetCurrentDirectory();
        while (dir != null && !File.Exists(Path.Combine(dir, "QuiptMappingEngine.csproj")))
            dir = Directory.GetParent(dir)?.FullName;
        return dir ?? Directory.GetCurrentDirectory();
    }

    public ApiEndpointTests(WebApplicationFactory<Program> factory)
    {
        var root = GetProjectRoot();
        Directory.SetCurrentDirectory(root);
        _client = factory.WithWebHostBuilder(builder =>
        {
            builder.UseContentRoot(root);
        }).CreateClient();
    }

    [Fact]
    public async Task PostGenerate_Laptops_Returns200()
    {
        var response = await _client.PostAsJsonAsync("/generate", new { category = "laptops" });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task PostGenerate_Desktops_Returns200()
    {
        var response = await _client.PostAsJsonAsync("/generate", new { category = "desktops" });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task PostGenerate_Smartphones_Returns200()
    {
        var response = await _client.PostAsJsonAsync("/generate", new { category = "smartphones" });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task PostGenerate_InvalidCategory_ReturnsBadRequest()
    {
        var response = await _client.PostAsJsonAsync("/generate", new { category = "tablets" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task PostGenerate_Laptops_ResponseContainsRequiredFields()
    {
        var response = await _client.PostAsJsonAsync("/generate", new { category = "laptops" });
        var content = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(content);
        var root = json.RootElement;

        Assert.True(root.TryGetProperty("accuracy", out _), "Response missing 'accuracy' field");
        Assert.True(root.TryGetProperty("requiredFieldCoverage", out _), "Response missing 'requiredFieldCoverage' field");
        Assert.True(root.TryGetProperty("generatedXslt", out _), "Response missing 'generatedXslt' field");
        Assert.True(root.TryGetProperty("mappings", out _), "Response missing 'mappings' field");
    }

    [Fact]
    public async Task PostGenerate_Laptops_MarketplaceFieldCountGreaterThanZero()
    {
        var response = await _client.PostAsJsonAsync("/generate", new { category = "laptops" });
        var content = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(content);
        var root = json.RootElement;

        var fieldCount = root.GetProperty("marketplaceFieldCount").GetInt32();
        Assert.True(fieldCount > 0, $"Expected marketplaceFieldCount > 0, got {fieldCount}");
    }

    [Fact]
    public async Task PostGenerate_Laptops_QuiptFieldCountGreaterThanZero()
    {
        var response = await _client.PostAsJsonAsync("/generate", new { category = "laptops" });
        var content = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(content);
        var root = json.RootElement;

        var fieldCount = root.GetProperty("quiptFieldCount").GetInt32();
        Assert.True(fieldCount > 0, $"Expected quiptFieldCount > 0, got {fieldCount}");
    }

    [Fact]
    public async Task PostGenerate_Laptops_GeneratedXsltIsValidXml()
    {
        var response = await _client.PostAsJsonAsync("/generate", new { category = "laptops" });
        var content = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(content);
        var root = json.RootElement;

        var xslt = root.GetProperty("generatedXslt").GetString();
        Assert.NotNull(xslt);
        Assert.NotEmpty(xslt);

        var doc = System.Xml.Linq.XDocument.Parse(xslt);
        Assert.NotNull(doc);
    }

    [Fact]
    public async Task PostGenerate_Laptops_AccuracyInValidRange()
    {
        var response = await _client.PostAsJsonAsync("/generate", new { category = "laptops" });
        var content = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(content);
        var root = json.RootElement;

        var accuracy = root.GetProperty("accuracy").GetDouble();
        Assert.True(accuracy >= 0 && accuracy <= 100, $"Accuracy {accuracy} outside valid range [0,100]");
    }

    [Fact]
    public async Task PostGenerate_Laptops_RequiredFieldCoverageInValidRange()
    {
        var response = await _client.PostAsJsonAsync("/generate", new { category = "laptops" });
        var content = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(content);
        var root = json.RootElement;

        var coverage = root.GetProperty("requiredFieldCoverage").GetDouble();
        Assert.True(coverage >= 0 && coverage <= 100, $"RequiredFieldCoverage {coverage} outside valid range [0,100]");
    }

    [Fact]
    public async Task PostGenerate_Laptops_MappingsArrayPopulated()
    {
        var response = await _client.PostAsJsonAsync("/generate", new { category = "laptops" });
        var content = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(content);
        var root = json.RootElement;

        var mappings = root.GetProperty("mappings");
        Assert.True(mappings.GetArrayLength() > 0, "Mappings array is empty");
    }

    [Fact]
    public async Task PostGenerate_Laptops_EvaluationDetailsPresent()
    {
        var response = await _client.PostAsJsonAsync("/generate", new { category = "laptops" });
        var content = await response.Content.ReadAsStringAsync();
        var json = JsonDocument.Parse(content);
        var root = json.RootElement;

        var details = root.GetProperty("evaluationDetails");
        Assert.True(details.GetArrayLength() > 0, "EvaluationDetails array is empty");
    }

    [Fact]
    public async Task Ping_ReturnsOk()
    {
        var response = await _client.GetAsync("/ping");
        var content = await response.Content.ReadAsStringAsync();

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("pong", content);
    }
}
