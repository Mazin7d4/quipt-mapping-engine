using QuiptMappingEngine.Models;
using QuiptMappingEngine.Normalization;
using System.Linq;

namespace QuiptMappingEngine.Services;

public class MatchingEngine
{
    public List<MappingResult> Match(
        List<Field> quiptFields,
        List<Field> amazonFields)
    {
        var results = new List<MappingResult>();

        foreach (var amazon in amazonFields)
        {
            double bestScore = -1;
            Field? bestMatch = null;

            foreach (var quipt in quiptFields)
            {
                if (!IsTypeCompatible(amazon.DataType, quipt.DataType))
                    continue;

                double score = 0;

                // 1️ Normalized token comparison
                var aTokens = FieldNormalizer.GetNormalizedTokens(amazon.Name);
                var qTokens = FieldNormalizer.GetNormalizedTokens(quipt.Name);

                var tokenOverlap = ComputeTokenOverlap(aTokens, qTokens);
                score += tokenOverlap * 0.4;

                // 2️ Levenshtein similarity on collapsed tokens
                var aNorm = string.Join("", aTokens);
                var qNorm = string.Join("", qTokens);

                if (aNorm.Length > 0 && qNorm.Length > 0)
                {
                    int lev = Similarity.Levenshtein(aNorm, qNorm);
                    double levScore = 1.0 - (double)lev / Math.Max(aNorm.Length, qNorm.Length);
                    score += levScore * 0.4;
                }

                // 3️ Enum overlap
                score += EnumOverlapScorer.ScoreOverlap(
                    amazon.EnumValues,
                    quipt.EnumValues
                ) * 0.15;

                // 4️ Unit similarity bonus
                if (HasUnitSimilarity(aTokens, qTokens))
                    score += 0.05;

                if (score > bestScore)
                {
                    bestScore = score;
                    bestMatch = quipt;
                }
            }

            results.Add(new MappingResult
            {
                AmazonField = amazon.Name,
                QuiptPath = bestMatch?.Path,
                Score = bestScore,
                IsRequired = amazon.IsRequired,
                IsUnmatched = bestMatch == null
            });
        }

        return results;
    }

    private bool IsTypeCompatible(string? a, string? b)
    {
        if (string.IsNullOrWhiteSpace(a) || string.IsNullOrWhiteSpace(b))
            return true;

        return a.Equals(b, StringComparison.OrdinalIgnoreCase);
    }

    private double ComputeTokenOverlap(List<string> a, List<string> b)
    {
        if (a.Count == 0 || b.Count == 0) return 0;

        var overlap = a.Intersect(b).Count();
        var union = a.Union(b).Count();

        return (double)overlap / union;
    }

    private bool HasUnitSimilarity(List<string> a, List<string> b)
    {
        string[] units = { "weight", "size", "length", "height", "width", "depth" };
        return units.Any(u => a.Contains(u) && b.Contains(u));
    }
}