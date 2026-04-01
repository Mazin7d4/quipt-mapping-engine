public class MappingResult
{
    public string AmazonField { get; set; } = "";
    public string? QuiptPath { get; set; }
    public double Score { get; set; }
    public bool IsRequired { get; set; }
    public bool IsUnmatched { get; set; }
}