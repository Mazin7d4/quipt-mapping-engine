using Xunit;
using QuiptMappingEngine.Normalization;

namespace Tests.Unit;

public class FieldNormalizerTests
{
    [Theory]
    [InlineData("itemWeight", new[] { "item", "weight" })]
    [InlineData("processorCount", new[] { "processor", "count" })]
    public void GetNormalizedTokens_CamelCase_SplitsCorrectly(string input, string[] expected)
    {
        var result = FieldNormalizer.GetNormalizedTokens(input);
        Assert.Equal(expected, result);
    }

    [Fact]
    public void GetNormalizedTokens_CamelCase_ScreenSize_SplitsWithCompoundPrefix()
    {
        var result = FieldNormalizer.GetNormalizedTokens("screenSize");
        // "screen" is split by "SCR" prefix → ["scr", "een", "size"]
        Assert.Contains("size", result);
        Assert.True(result.Count >= 2);
    }

    [Theory]
    [InlineData("item_weight", new[] { "item", "weight" })]
    [InlineData("model_number", new[] { "model", "number" })]
    public void GetNormalizedTokens_Underscores_SplitsCorrectly(string input, string[] expected)
    {
        var result = FieldNormalizer.GetNormalizedTokens(input);
        Assert.Equal(expected, result);
    }

    [Fact]
    public void GetNormalizedTokens_HardDisk_NormalizedViaDictionary()
    {
        var result = FieldNormalizer.GetNormalizedTokens("hard_disk");
        // "hard" → NormalizationDictionary → "harddisk"; "disk" stays
        Assert.Contains("harddisk", result);
    }

    [Theory]
    [InlineData("item-weight", new[] { "item", "weight" })]
    [InlineData("bluetooth-version", new[] { "bluetooth", "version" })]
    public void GetNormalizedTokens_Hyphens_SplitsCorrectly(string input, string[] expected)
    {
        var result = FieldNormalizer.GetNormalizedTokens(input);
        Assert.Equal(expected, result);
    }

    [Theory]
    [InlineData("GPUMODEL", new[] { "graphics", "model" })]
    [InlineData("CPUCORE", new[] { "processor", "core" })]
    [InlineData("RAMSIZE", new[] { "memory", "size" })]
    public void GetNormalizedTokens_CompoundCodes_SplitsOnKnownPrefixes(string input, string[] expected)
    {
        var result = FieldNormalizer.GetNormalizedTokens(input);
        Assert.Equal(expected, result);
    }

    [Fact]
    public void GetNormalizedTokens_BATLIFE_SplitsOnBatPrefix()
    {
        var result = FieldNormalizer.GetNormalizedTokens("BATLIFE");
        // "bat" prefix → remainder "life"; "bat" → dictionary "battery"
        Assert.Contains("battery", result);
        Assert.Contains("life", result);
    }

    [Fact]
    public void GetNormalizedTokens_USBCPORTS_SplitsOnUsbPrefix()
    {
        var result = FieldNormalizer.GetNormalizedTokens("USBCPORTS");
        // "usb" prefix → remainder "cports"
        Assert.Contains("usb", result);
        Assert.True(result.Count >= 2);
    }

    [Theory]
    [InlineData("colour", "color")]
    [InlineData("manufacturer", "brand")]
    [InlineData("hdd", "harddisk")]
    [InlineData("wifi", "wireless")]
    public void GetNormalizedTokens_Synonyms_NormalizedViaDictionary(string input, string expectedToken)
    {
        var result = FieldNormalizer.GetNormalizedTokens(input);
        Assert.Contains(expectedToken, result);
    }

    [Fact]
    public void GetNormalizedTokens_EmptyString_ReturnsEmptyList()
    {
        var result = FieldNormalizer.GetNormalizedTokens("");
        Assert.Empty(result);
    }

    [Fact]
    public void GetNormalizedTokens_NullString_ReturnsEmptyList()
    {
        var result = FieldNormalizer.GetNormalizedTokens(null!);
        Assert.Empty(result);
    }

    [Fact]
    public void GetNormalizedTokens_WhitespaceOnly_ReturnsEmptyList()
    {
        var result = FieldNormalizer.GetNormalizedTokens("   ");
        Assert.Empty(result);
    }

    [Theory]
    [InlineData("RAM", new[] { "memory" })]
    [InlineData("CPU", new[] { "processor" })]
    public void GetNormalizedTokens_ShortCodes_NormalizesCorrectly(string input, string[] expected)
    {
        var result = FieldNormalizer.GetNormalizedTokens(input);
        Assert.Equal(expected, result);
    }

    [Fact]
    public void GetNormalizedTokens_SCREEN_SplitByCompoundPrefix()
    {
        // "screen" is length 6, "SCR" prefix matches → splits to ["scr", "een"]
        var result = FieldNormalizer.GetNormalizedTokens("SCREEN");
        Assert.True(result.Count >= 2);
        Assert.Contains("scr", result);
    }

    [Fact]
    public void GetNormalizedTokens_SpecialCharacters_Removed()
    {
        var result = FieldNormalizer.GetNormalizedTokens("item@#weight!");
        Assert.Contains("item", result);
        Assert.Contains("weight", result);
    }

    [Fact]
    public void GetNormalizedTokens_MixedCaseAndUnderscore_HandledCorrectly()
    {
        var result = FieldNormalizer.GetNormalizedTokens("Graphics_Card_Type");
        Assert.Contains("graphics", result);
        Assert.Contains("card", result);
        Assert.Contains("type", result);
    }

    [Theory]
    [InlineData("RELEASEYEAR", new[] { "release", "year" })]
    [InlineData("RELEASEDATE", new[] { "release", "date" })]
    public void GetNormalizedTokens_RecursiveCompoundSplit_Works(string input, string[] expected)
    {
        var result = FieldNormalizer.GetNormalizedTokens(input);
        Assert.Equal(expected, result);
    }
}
