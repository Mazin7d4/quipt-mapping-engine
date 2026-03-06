using System.Text.RegularExpressions;

namespace QuiptMappingEngine.Normalization;

public static class FieldNormalizer
{
    // Main method you will use in matching
    public static List<string> GetNormalizedTokens(string input)
    {
        if (string.IsNullOrWhiteSpace(input))
            return new List<string>();

        // Step 1: Convert camelCase or PascalCase to spaced words
        var spaced = Regex.Replace(input, "([a-z0-9])([A-Z])", "$1 $2");
        spaced = Regex.Replace(spaced, "([A-Z]+)([A-Z][a-z])", "$1 $2");

        // Step 2: Replace underscores and hyphens with spaces
        spaced = spaced.Replace("_", " ").Replace("-", " ");

        // Step 3: Lowercase everything
        spaced = spaced.ToLowerInvariant();

        // Step 4: Remove special characters
        spaced = Regex.Replace(spaced, @"[^a-z0-9\s]", " ");

        // Step 5: Remove extra spaces
        spaced = Regex.Replace(spaced, @"\s+", " ").Trim();

        // Step 6: Split into tokens
        var tokens = spaced.Split(" ", StringSplitOptions.RemoveEmptyEntries);

        // Step 7: Normalize each token using dictionary
        var normalizedTokens = tokens
            .Select(t =>
            {
                if (NormalizationDictionary.Map.TryGetValue(t, out var normalized))
                    return normalized;
                return t;
            })
            .ToList();

        return normalizedTokens;
    }
}