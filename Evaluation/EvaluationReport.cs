namespace QuiptMappingEngine.Evaluation;

public class EvaluationReport
{
    public string Category { get; set; } = "";

    // Overall accuracy
    public int TotalAmazonFields { get; set; }
    public int CorrectMatches { get; set; }
    public double AccuracyPercent { get; set; }

    // Required-field coverage
    public int TotalRequiredFields { get; set; }
    public int MatchedRequiredFields { get; set; }
    public double RequiredCoveragePercent { get; set; }

    public List<string> UnmatchedRequiredFields { get; set; } = new();
}