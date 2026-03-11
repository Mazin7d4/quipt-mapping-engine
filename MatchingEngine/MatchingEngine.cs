using QuiptMappingEngine.Models;
using QuiptMappingEngine.Normalization;
using System.Linq;
using System.Text.RegularExpressions;

namespace QuiptMappingEngine.Services;

public class MatchingEngine
{
    // Minimum score to accept a match (avoids garbage matches)
    private const double MinThreshold = 0.20;

    // Generic leaf names that should be penalized — they match too many things
    private static readonly HashSet<string> GenericLeaves = new(StringComparer.OrdinalIgnoreCase)
    {
        "Id", "Name", "Value", "Description", "Title", "Code", "Type",
        "Units", "URL", "Number", "ISO", "Resolution", "Status"
    };

    // Fields that should only match themselves (too generic to match broadly)
    private static readonly HashSet<string> PenalizedQuiptPaths = new(StringComparer.OrdinalIgnoreCase)
    {
        "Description", "Title", "CatalogStatusDisplayName", "MapId", "SKU", "VersionNumber"
    };

    public List<MappingResult> Match(
        List<Field> quiptFields,
        List<Field> amazonFields)
    {
        var results = new List<MappingResult>();
        var usedQuiptPaths = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        // Pre-compute normalized tokens for all Quipt fields (name + path context)
        var quiptTokensCache = quiptFields.ToDictionary(
            q => q,
            q => GetContextTokens(q));

        // Pre-compute specificity penalty for each Quipt field
        var quiptSpecificity = quiptFields.ToDictionary(
            q => q,
            q => ComputeSpecificity(q));

        // Sort Amazon fields: required first, then by name
        // This gives priority to required fields for best matches
        var sortedAmazon = amazonFields
            .OrderByDescending(a => a.IsRequired)
            .ThenBy(a => a.Name)
            .ToList();

        foreach (var amazon in sortedAmazon)
        {
            double bestScore = -1;
            Field? bestMatch = null;

            var aTokens = FieldNormalizer.GetNormalizedTokens(amazon.Name);

            foreach (var quipt in quiptFields)
            {
                // Skip already-used Quipt fields (1:1 matching)
                if (usedQuiptPaths.Contains(quipt.Path))
                    continue;

                var qTokens = quiptTokensCache[quipt];
                var specificity = quiptSpecificity[quipt];

                double score = ComputeScore(aTokens, qTokens, amazon, quipt, specificity);

                if (score > bestScore)
                {
                    bestScore = score;
                    bestMatch = quipt;
                }
            }

            bool isUnmatched = bestMatch == null || bestScore < MinThreshold;

            if (!isUnmatched)
                usedQuiptPaths.Add(bestMatch!.Path);

            results.Add(new MappingResult
            {
                AmazonField = amazon.Name,
                QuiptPath = isUnmatched ? null : bestMatch!.Path,
                Score = Math.Round(bestScore, 4),
                IsRequired = amazon.IsRequired,
                IsUnmatched = isUnmatched
            });
        }

        return results;
    }

    private double ComputeScore(List<string> aTokens, List<string> qTokens,
        Field amazon, Field quipt, double specificity)
    {
        double score = 0;

        // ── 1. Token overlap (Jaccard) ── primary signal, weight: 0.45
        var tokenOverlap = ComputeTokenOverlap(aTokens, qTokens);
        score += tokenOverlap * 0.45;

        // ── 2. Weighted token match ── bonus for matching MORE tokens (not just ratio)
        // This helps when amazon has 2 tokens and quipt has 5 — Jaccard is low but 2/2 match
        var matchCount = aTokens.Count(t => qTokens.Contains(t));
        var matchRatio = aTokens.Count > 0 ? (double)matchCount / aTokens.Count : 0;
        score += matchRatio * 0.20;

        // ── 3. Levenshtein similarity on collapsed normalized strings ── weight: 0.15
        var aNorm = string.Join("", aTokens);
        var qNorm = string.Join("", qTokens);

        if (aNorm.Length > 0 && qNorm.Length > 0)
        {
            int lev = Similarity.Levenshtein(aNorm, qNorm);
            double levScore = 1.0 - (double)lev / Math.Max(aNorm.Length, qNorm.Length);
            score += levScore * 0.15;
        }

        // ── 4. Substring / contains bonus ── weight: 0.10
        if (aNorm.Length > 0 && qNorm.Length > 0)
        {
            if (aNorm.Contains(qNorm) || qNorm.Contains(aNorm))
                score += 0.10;
        }

        // ── 5. Enum overlap ── weight: 0.05
        score += EnumOverlapScorer.ScoreOverlap(
            amazon.EnumValues,
            quipt.EnumValues
        ) * 0.05;

        // ── 6. Unit/dimension similarity bonus ── weight: 0.05
        if (HasUnitSimilarity(aTokens, qTokens))
            score += 0.05;

        // ── 7. Specificity adjustment ──
        // Penalize generic Quipt fields (Description, Title, Id) so they don't vacuum up everything
        score *= specificity;

        return score;
    }

    /// <summary>
    /// Returns a multiplier between 0.3 and 1.0 based on how specific the Quipt field is.
    /// Generic fields like "Description" or "Id" get penalized.
    /// Attribute-based fields (with Code) get a bonus.
    /// </summary>
    private double ComputeSpecificity(Field quipt)
    {
        var leafName = quipt.Name;
        var path = quipt.Path ?? "";

        // Attribute fields are highly specific — they have a code identifier
        if (path.Contains("Attribute[q:Code="))
            return 1.0;

        // Check if the leaf name is a generic term
        if (GenericLeaves.Contains(leafName))
            return 0.5; // halve the score for generic leaves

        // Check if this is a known overly-broad Quipt path
        var lastSegment = path.Split('/').LastOrDefault()?.Replace("q:", "") ?? "";
        if (PenalizedQuiptPaths.Contains(lastSegment))
            return 0.4;

        return 0.9; // slight penalty for non-attribute, non-generic fields
    }

    /// <summary>
    /// Extracts normalized tokens from both the field name AND its XPath context.
    /// For Attribute fields, also extracts tokens from the Code value.
    /// </summary>
    private List<string> GetContextTokens(Field field)
    {
        var tokens = new List<string>();

        // Add tokens from field name (e.g. "# of Processor Cores" → ["processor", "core"])
        tokens.AddRange(FieldNormalizer.GetNormalizedTokens(field.Name));

        // Add tokens from XPath
        if (!string.IsNullOrWhiteSpace(field.Path))
        {
            var segments = field.Path
                .Split('/')
                .Select(s => Regex.Replace(s, @"^q:", "", RegexOptions.IgnoreCase))
                .Where(s => !string.IsNullOrWhiteSpace(s))
                .ToList();

            var skipSegments = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                "ArrayOfInventoryVirtualResult",
                "InventoryVirtualResult",
                "Catalog",
                "properties",
                "Attributes",
                "Value",
                "a:string"
            };

            var meaningful = segments
                .Where(s => !skipSegments.Contains(s))
                .ToList();

            // Take last 3 meaningful path segments
            var contextSegments = meaningful
                .Skip(Math.Max(0, meaningful.Count - 3))
                .ToList();

            foreach (var seg in contextSegments)
            {
                // Extract attribute code from e.g. Attribute[q:Code='MODELNBR']
                var codeMatch = Regex.Match(seg, @"Code='([^']+)'");
                if (codeMatch.Success)
                {
                    var code = codeMatch.Groups[1].Value;
                    tokens.AddRange(FieldNormalizer.GetNormalizedTokens(code));
                }
                else
                {
                    var clean = Regex.Replace(seg, @"\[.*?\]", "");
                    if (!GenericLeaves.Contains(clean))
                        tokens.AddRange(FieldNormalizer.GetNormalizedTokens(clean));
                }
            }
        }

        return tokens.Distinct().ToList();
    }

    private double ComputeTokenOverlap(List<string> a, List<string> b)
    {
        if (a.Count == 0 || b.Count == 0) return 0;

        var setA = new HashSet<string>(a);
        var setB = new HashSet<string>(b);

        var overlap = setA.Intersect(setB).Count();
        var union = setA.Union(setB).Count();

        return (double)overlap / union;
    }

    private bool HasUnitSimilarity(List<string> a, List<string> b)
    {
        string[] units = { "weight", "size", "length", "height", "width", "depth", "dimension" };
        return units.Any(u => a.Contains(u) && b.Contains(u));
    }
}