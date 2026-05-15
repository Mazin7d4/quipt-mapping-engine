using Xunit;

namespace Tests.Unit;

public class SimilarityTests
{
    [Fact]
    public void Levenshtein_IdenticalStrings_ReturnsZero()
    {
        Assert.Equal(0, Similarity.Levenshtein("hello", "hello"));
    }

    [Fact]
    public void Levenshtein_OneCharDifference_ReturnsOne()
    {
        Assert.Equal(1, Similarity.Levenshtein("cat", "bat"));
    }

    [Fact]
    public void Levenshtein_EmptyFirstString_ReturnsLengthOfSecond()
    {
        Assert.Equal(5, Similarity.Levenshtein("", "hello"));
    }

    [Fact]
    public void Levenshtein_EmptySecondString_ReturnsLengthOfFirst()
    {
        Assert.Equal(5, Similarity.Levenshtein("hello", ""));
    }

    [Fact]
    public void Levenshtein_CompletelyDifferent_ReturnsMaxLength()
    {
        Assert.Equal(3, Similarity.Levenshtein("abc", "xyz"));
    }

    [Theory]
    [InlineData("kitten", "sitting", 3)]
    [InlineData("brand", "brand", 0)]
    [InlineData("color", "colour", 1)]
    public void Levenshtein_KnownPairs_ReturnsExpectedDistance(string a, string b, int expected)
    {
        Assert.Equal(expected, Similarity.Levenshtein(a, b));
    }

    [Fact]
    public void Levenshtein_NullFirst_ReturnsSecondLength()
    {
        Assert.Equal(4, Similarity.Levenshtein(null!, "test"));
    }

    [Fact]
    public void Levenshtein_NullSecond_ReturnsFirstLength()
    {
        Assert.Equal(4, Similarity.Levenshtein("test", null!));
    }

    [Fact]
    public void TokenOverlap_IdenticalTokens_ReturnsOne()
    {
        var score = Similarity.TokenOverlap("item weight", "item weight");
        Assert.Equal(1.0, score);
    }

    [Fact]
    public void TokenOverlap_NoCommonTokens_ReturnsZero()
    {
        var score = Similarity.TokenOverlap("brand name", "processor speed");
        Assert.Equal(0.0, score);
    }

    [Fact]
    public void TokenOverlap_PartialOverlap_ReturnsJaccardCoefficient()
    {
        // "item weight" -> {item, weight}
        // "item length" -> {item, length}
        // intersection = {item} = 1, union = {item, weight, length} = 3
        var score = Similarity.TokenOverlap("item weight", "item length");
        Assert.Equal(1.0 / 3.0, score, precision: 3);
    }

    [Fact]
    public void TokenOverlap_HyphenSeparated_SplitsCorrectly()
    {
        var score = Similarity.TokenOverlap("item-weight", "item-weight");
        Assert.Equal(1.0, score);
    }

    [Fact]
    public void TokenOverlap_UnderscoreSeparated_SplitsCorrectly()
    {
        var score = Similarity.TokenOverlap("item_weight", "item_weight");
        Assert.Equal(1.0, score);
    }

    [Fact]
    public void TokenOverlap_EmptyStrings_ReturnsZero()
    {
        var score = Similarity.TokenOverlap("", "");
        Assert.Equal(0.0, score);
    }
}
