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
        // Canonical keys so item_weight / itemWeight / Item Weight align; first wins on collisions.
        var truthByKey = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var kvp in groundTruth)
        {
            var k = CanonKey(kvp.Key);
            if (!truthByKey.ContainsKey(k))
                truthByKey[k] = kvp.Value;
        }

        int total = autoMappings.Count;

        int fieldsWithGt = 0;
        int correctGt = 0;
        int wrongGt = 0;
        int missingGt = 0;

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

            // Ground-truth slice: compare auto mapping to manual XSLT when we have an expected path
            if (truthByKey.TryGetValue(key, out var expectedPath))
            {
                fieldsWithGt++;

                if (string.IsNullOrWhiteSpace(m.MatchedQuiptXPath))
                {
                    missingGt++;
                }
                else if (PathsEqual(m.MatchedQuiptXPath!, expectedPath))
                {
                    correctGt++;
                }
                else
                {
                    wrongGt++;
                }
            }
        }

        // Sparse accuracy (all Amazon fields in denominator) — matches sprint "correct / total fields"
        var sparseAccuracy = total == 0 ? 0 : (double)correctGt / total * 100.0;

        // KPI when only a subset of fields have manual mappings: correct / fields we can grade
        var gtAccuracy = fieldsWithGt == 0 ? 0 : (double)correctGt / fieldsWithGt * 100.0;

        return new EvaluationReport
        {
            Category = category,

            TotalAmazonFields = total,
            CorrectMatches = correctGt,
            AccuracyPercent = sparseAccuracy,

            FieldsWithGroundTruth = fieldsWithGt,
            CorrectAmongGroundTruth = correctGt,
            WrongAmongGroundTruth = wrongGt,
            MissingAmongGroundTruth = missingGt,
            GroundTruthAccuracyPercent = gtAccuracy,

            TotalRequiredFields = totalRequired,
            MatchedRequiredFields = matchedRequired,
            RequiredCoveragePercent = totalRequired == 0 ? 0 : (double)matchedRequired / totalRequired * 100.0,

            UnmatchedRequiredFields = unmatchedRequired
        };
    }

    /// <summary>
    /// Indexes manual XSLT keys (tag names) by canonical token form so
    /// <c>item_weight</c>, <c>itemWeight</c>, and <c>Item Weight</c> align with Amazon JSON names.
    /// </summary>
    public static Dictionary<string, string> IndexGroundTruthByCanonKey(
        Dictionary<string, string> groundTruth
    )
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var kvp in groundTruth)
        {
            var k = ToCanonicalFieldKey(kvp.Key);
            if (!result.ContainsKey(k))
                result[k] = kvp.Value;
        }
        return result;
    }

    public static bool TryGetGroundTruthPath(
        IReadOnlyDictionary<string, string> truthByCanonKey,
        string amazonFieldName,
        out string? expectedPath
    )
    {
        return truthByCanonKey.TryGetValue(ToCanonicalFieldKey(amazonFieldName), out expectedPath);
    }

    /// <summary>Public alias for normalization used in evaluation keys (member 4 / API consumers).</summary>
    public static string ToCanonicalFieldKey(string name) => CanonKey(name);

    // Makes field names comparable even if styles differ: item_weight vs itemWeight
    private static string CanonKey(string name)
    {
        var tokens = FieldNormalizer.GetNormalizedTokens(name);
        return string.Join("", tokens); // "itemweight"
    }

    /// <summary>
    /// Compares paths flexibly:
    /// - Ground truth may be abbreviated (e.g. "q:Catalog/q:Brand/q:Name")
    ///   while auto-matched paths are fully qualified.
    /// - Ground truth may have XPath index predicates like [1] that auto paths don't.
    /// Returns true if either path ends with the other after stripping index predicates.
    /// </summary>
    public static bool PathsEqual(string a, string b)
    {
        a = NormalizePath(a);
        b = NormalizePath(b);

        if (string.Equals(a, b, StringComparison.OrdinalIgnoreCase))
            return true;

        // Check if one ends with the other (handles prefix differences)
        return a.EndsWith(b, StringComparison.OrdinalIgnoreCase)
            || b.EndsWith(a, StringComparison.OrdinalIgnoreCase);
    }

    /// <summary>
    /// Strips trailing index predicates like [1] from path segments.
    /// e.g. "a:string[1]" → "a:string"
    /// </summary>
    private static string NormalizePath(string path)
    {
        // Remove trailing [N] from each segment
        return System.Text.RegularExpressions.Regex.Replace(
            path.Trim(), @"\[\d+\]", "");
    }
}