namespace QuiptMappingEngine.Normalization;

public static class EnumOverlapScorer
{
    // Returns value between 0 and 1
    // 0 = no overlap, 1 = full overlap
    public static double ScoreOverlap(List<string>? amazonEnums, List<string>? quiptEnums)
    {
        if (amazonEnums == null || quiptEnums == null) return 0.0;
        if (amazonEnums.Count == 0 || quiptEnums.Count == 0) return 0.0;

        var amazonSet = amazonEnums.Select(Norm).ToHashSet();
        var quiptSet = quiptEnums.Select(Norm).ToHashSet();

        var overlapCount = amazonSet.Intersect(quiptSet).Count();

        return (double)overlapCount / amazonSet.Count;
    }

    private static string Norm(string s) => (s ?? "").Trim().ToLowerInvariant();
}