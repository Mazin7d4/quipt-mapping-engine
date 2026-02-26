using System.Text.Json;

namespace QuiptMappingEngine.Evaluation;

public static class PurvikaResultsLoader
{
    public static IEnumerable<dynamic> LoadFromJson(string path)
    {
        if (!File.Exists(path))
            throw new FileNotFoundException(path);

        var json = File.ReadAllText(path);
        // use JsonDocument or deserialize into dynamic objects
        using var doc = JsonDocument.Parse(json);
        foreach (var el in doc.RootElement.EnumerateArray())
        {
            // create a lightweight dynamic-ish object
            yield return new
            {
                AmazonField = el.GetProperty("AmazonField").GetString() ?? "",
                IsRequired = el.GetProperty("IsRequired").GetBoolean(),
                MatchedQuiptPath = el.TryGetProperty("MatchedQuiptPath", out var p) ? p.GetString() : null
            };
        }
    }
}