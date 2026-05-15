using Xunit;
using QuiptMappingEngine.Normalization;

namespace Tests.Unit;

public class EnumOverlapScorerTests
{
    [Fact]
    public void ScoreOverlap_FullOverlap_ReturnsOne()
    {
        var amazon = new List<string> { "Red", "Blue", "Green" };
        var quipt = new List<string> { "Red", "Blue", "Green" };

        var score = EnumOverlapScorer.ScoreOverlap(amazon, quipt);

        Assert.Equal(1.0, score);
    }

    [Fact]
    public void ScoreOverlap_PartialOverlap_ReturnsCorrectFraction()
    {
        var amazon = new List<string> { "Red", "Blue", "Black" };
        var quipt = new List<string> { "Black", "White", "Silver" };

        var score = EnumOverlapScorer.ScoreOverlap(amazon, quipt);

        Assert.Equal(1.0 / 3.0, score, precision: 3);
    }

    [Fact]
    public void ScoreOverlap_NoOverlap_ReturnsZero()
    {
        var amazon = new List<string> { "Red", "Blue", "Green" };
        var quipt = new List<string> { "Black", "White", "Silver" };

        var score = EnumOverlapScorer.ScoreOverlap(amazon, quipt);

        Assert.Equal(0.0, score);
    }

    [Fact]
    public void ScoreOverlap_NullAmazonEnums_ReturnsZero()
    {
        var score = EnumOverlapScorer.ScoreOverlap(null, new List<string> { "Red" });
        Assert.Equal(0.0, score);
    }

    [Fact]
    public void ScoreOverlap_NullQuiptEnums_ReturnsZero()
    {
        var score = EnumOverlapScorer.ScoreOverlap(new List<string> { "Red" }, null);
        Assert.Equal(0.0, score);
    }

    [Fact]
    public void ScoreOverlap_BothNull_ReturnsZero()
    {
        var score = EnumOverlapScorer.ScoreOverlap(null, null);
        Assert.Equal(0.0, score);
    }

    [Fact]
    public void ScoreOverlap_EmptyAmazonList_ReturnsZero()
    {
        var score = EnumOverlapScorer.ScoreOverlap(new List<string>(), new List<string> { "Red" });
        Assert.Equal(0.0, score);
    }

    [Fact]
    public void ScoreOverlap_EmptyQuiptList_ReturnsZero()
    {
        var score = EnumOverlapScorer.ScoreOverlap(new List<string> { "Red" }, new List<string>());
        Assert.Equal(0.0, score);
    }

    [Fact]
    public void ScoreOverlap_CaseInsensitive_MatchesRegardlessOfCase()
    {
        var amazon = new List<string> { "RED", "BLUE" };
        var quipt = new List<string> { "red", "blue" };

        var score = EnumOverlapScorer.ScoreOverlap(amazon, quipt);

        Assert.Equal(1.0, score);
    }

    [Fact]
    public void ScoreOverlap_WhitespaceHandling_TrimsBeforeComparing()
    {
        var amazon = new List<string> { " Red ", "Blue" };
        var quipt = new List<string> { "Red", " Blue " };

        var score = EnumOverlapScorer.ScoreOverlap(amazon, quipt);

        Assert.Equal(1.0, score);
    }

    [Fact]
    public void ScoreOverlap_QuiptSupersetOfAmazon_ReturnsOne()
    {
        var amazon = new List<string> { "Red", "Blue" };
        var quipt = new List<string> { "Red", "Blue", "Green", "Yellow" };

        var score = EnumOverlapScorer.ScoreOverlap(amazon, quipt);

        Assert.Equal(1.0, score);
    }

    [Fact]
    public void ScoreOverlap_ScoreBasedOnAmazonCount_NotUnion()
    {
        var amazon = new List<string> { "Red", "Blue", "Green", "Yellow" };
        var quipt = new List<string> { "Red", "Blue" };

        var score = EnumOverlapScorer.ScoreOverlap(amazon, quipt);

        Assert.Equal(2.0 / 4.0, score, precision: 3);
    }
}
