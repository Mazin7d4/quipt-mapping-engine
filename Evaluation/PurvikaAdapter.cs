namespace QuiptMappingEngine.Evaluation;

public static class PurvikaAdapter
{
    // Later, replace "object" with Purvika's real MappingResult type
    public static List<EvaluatedMapping> ConvertFromPurvikaResults(IEnumerable<dynamic> purvikaResults)
    {
        var list = new List<EvaluatedMapping>();

        foreach (var r in purvikaResults)
        {
            string amazonName = r.AmazonField;
            bool isRequired = r.IsRequired;
            string? quiptPath = r.MatchedQuiptPath;  

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