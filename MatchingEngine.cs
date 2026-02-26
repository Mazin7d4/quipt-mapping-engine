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
            Field bestMatch = null;

            foreach (var quipt in quiptFields)
            {
                double score = 0;

                if (!IsTypeCompatible(amazon.DataType, quipt.DataType))
                    continue;

                string aNorm = Normalizer.Normalize(amazon.Name);
                string qNorm = Normalizer.Normalize(quipt.Name);

                int lev = Similarity.Levenshtein(aNorm, qNorm);
                double levScore = 1.0 - (double)lev / Math.Max(aNorm.Length, qNorm.Length);

                double tokenScore = Similarity.TokenOverlap(aNorm, qNorm);

                score += levScore * 0.6;
                score += tokenScore * 0.4;

                if (amazon.EnumValues?.Count > 0 && quipt.EnumValues?.Count > 0)
                {
                    int overlap = amazon.EnumValues.Intersect(quipt.EnumValues).Count();
                    if (overlap > 0) score += 0.2;
                }

                if (HasUnitSimilarity(amazon.Name, quipt.Name))
                    score += 0.1;

                if (score > bestScore)
                {
                    bestScore = score;
                    bestMatch = quipt;
                }
            }

            results.Add(new MappingResult
            {
                AmazonField = amazon.Name,
                QuiptField = bestMatch?.XPath,
                Score = bestScore,
                IsRequired = amazon.DataType == "required",
                IsUnmatched = bestMatch == null
            });
        }

        return results;
    }

    private bool IsTypeCompatible(string a, string b)
    {
        if (a == null || b == null) return true;
        return a.ToLower() == b.ToLower();
    }

    private bool HasUnitSimilarity(string a, string b)
    {
        string[] units = { "weight", "size", "length", "height" };
        return units.Any(u => a.ToLower().Contains(u) && b.ToLower().Contains(u));
    }
}
