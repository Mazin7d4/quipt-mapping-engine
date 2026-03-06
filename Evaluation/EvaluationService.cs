using QuiptMappingEngine.Normalization;

namespace QuiptMappingEngine.Evaluation;

public static class EvaluationService
{
    // We compare auto results vs ground truth (manual mapping)
    // Ground truth format: AmazonFieldName -> Correct QuiptXPath
    public static EvaluationReport Evaluate(
        string category,
        List<EvaluatedMapping> autoMappings,
        Dictionary<string, string> groundTruth
    )
    {
        // Build a version of ground truth with "cleaned keys"
        // so item_weight and itemWeight still match each other.
        var truthByKey = groundTruth.ToDictionary(
            kvp => CanonKey(kvp.Key),
            kvp => kvp.Value,
            StringComparer.OrdinalIgnoreCase
        );

        int total = autoMappings.Count;
        int correct = 0;

        int totalRequired = 0;
        int matchedRequired = 0;

        var unmatchedRequired = new List<string>();

        foreach (var m in autoMappings)
        {
            var key = CanonKey(m.AmazonFieldName);

            // Required coverage stats
            if (m.IsRequired)
            {
                totalRequired++;
                if (!string.IsNullOrWhiteSpace(m.MatchedQuiptXPath))
                    matchedRequired++;
                else
                    unmatchedRequired.Add(m.AmazonFieldName);
            }

            // Accuracy stats: only count as correct if it matches ground truth
            if (!string.IsNullOrWhiteSpace(m.MatchedQuiptXPath) && truthByKey.TryGetValue(key, out var correctPath))
            {
                if (PathsEqual(m.MatchedQuiptXPath!, correctPath))
                    correct++;
            }
        }

        return new EvaluationReport
        {
            Category = category,

            TotalAmazonFields = total,
            CorrectMatches = correct,
            AccuracyPercent = total == 0 ? 0 : (double)correct / total * 100.0,

            TotalRequiredFields = totalRequired,
            MatchedRequiredFields = matchedRequired,
            RequiredCoveragePercent = totalRequired == 0 ? 0 : (double)matchedRequired / totalRequired * 100.0,

            UnmatchedRequiredFields = unmatchedRequired
        };
    }

    // Makes field names comparable even if styles differ: item_weight vs itemWeight
    private static string CanonKey(string name)
    {
        var tokens = FieldNormalizer.GetNormalizedTokens(name);
        return string.Join("", tokens); // "itemweight"
    }

    private static bool PathsEqual(string a, string b)
        => string.Equals(a.Trim(), b.Trim(), StringComparison.OrdinalIgnoreCase);
}