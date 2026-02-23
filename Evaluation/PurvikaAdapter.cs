namespace QuiptMappingEngine.Evaluation;

public static class PurvikaAdapter
{
    // Later, replace "object" with Purvika's real MappingResult type
    public static List<EvaluatedMapping> ConvertFromPurvikaResults(IEnumerable<dynamic> purvikaResults)
    {
        var list = new List<EvaluatedMapping>();

        foreach (var r in purvikaResults)
        {
            // ✅ You will adjust these 3 lines to match Purvika’s property names
            string amazonName = r.AmazonFieldName;      // OR r.AmazonField.Name
            bool isRequired   = r.IsRequired;          // OR r.AmazonField.IsRequired
            string? quiptPath = r.MatchedQuiptXPath;   // OR r.QuiptField?.Path

            list.Add(new EvaluatedMapping
            {
                AmazonFieldName = amazonName,
                IsRequired = isRequired,
                MatchedQuiptXPath = quiptPath
            });
        }

        return list;
    }
}