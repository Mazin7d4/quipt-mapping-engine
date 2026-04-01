namespace QuiptMappingEngine.Normalization;

public static class EnumOverlapScorer
{
    // Returns value between 0 and 1
    // 0 = no overlap, 1 = full overlap
    public static double ScoreOverlap(List<string>? amazonEnums, List<string>? quiptEnums)
    {
        if (amazonEnums == null || quiptEnums == null) return 0.0;
        if (amazonEnums.Count == 0 || quiptEnums.Count == 0) return 0.0;

        var amazonSet = amazonEnums.Select(Norm).Where(s => s.Length > 0).ToHashSet();
        var quiptSet = quiptEnums.Select(Norm).Where(s => s.Length > 0).ToHashSet();

        if (amazonSet.Count == 0 || quiptSet.Count == 0) return 0.0;

        var overlapCount = amazonSet.Intersect(quiptSet).Count();
        var unionCount = amazonSet.Union(quiptSet).Count();
        return unionCount == 0 ? 0.0 : (double)overlapCount / unionCount;
    }

    private static string Norm(string s) => (s ?? "").Trim().ToLowerInvariant();
}