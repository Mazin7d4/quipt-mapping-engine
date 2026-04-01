namespace QuiptMappingEngine.Evaluation;

public class EvaluationReport
{
    public string Category { get; set; } = "";

    // Overall (sparse): correct vs manual among ALL Amazon fields — denominator = total schema fields
    public int TotalAmazonFields { get; set; }
    public int CorrectMatches { get; set; }
    public double AccuracyPercent { get; set; }

    // Ground-truth slice (meaningful KPI): only fields present in manual XSLT
    public int FieldsWithGroundTruth { get; set; }
    public int CorrectAmongGroundTruth { get; set; }
    public int WrongAmongGroundTruth { get; set; }
    public int MissingAmongGroundTruth { get; set; }
    public double GroundTruthAccuracyPercent { get; set; }

    // Required-field coverage
    public int TotalRequiredFields { get; set; }
    public int MatchedRequiredFields { get; set; }
    public double RequiredCoveragePercent { get; set; }

    public List<string> UnmatchedRequiredFields { get; set; } = new();
}