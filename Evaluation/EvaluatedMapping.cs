namespace QuiptMappingEngine.Evaluation;

public class EvaluatedMapping
{
    public string AmazonFieldName { get; set; } = "";
    public bool IsRequired { get; set; }

    // If Purvika couldn't match it, this will be null
    public string? MatchedQuiptXPath { get; set; }
}