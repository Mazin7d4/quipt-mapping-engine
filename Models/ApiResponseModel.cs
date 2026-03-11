using QuiptMappingEngine.Models;

namespace QuiptMappingEngine.Models
{
    public class ApiResponseModel
    {
        public string Category { get; set; } = "";
        public int AmazonFieldCount { get; set; }
        public int QuiptFieldCount { get; set; }
        public int MappingCount { get; set; }
        public double Accuracy { get; set; }
        public double RequiredFieldCoverage { get; set; }
        public int GroundTruthCount { get; set; }
        public int CorrectMatches { get; set; }
        public List<string> UnmatchedRequiredFields { get; set; } = new();
        public string GeneratedXslt { get; set; } = "";
        public List<MappingResult> Mappings { get; set; } = new();
        public List<MappingEvalDetail> EvaluationDetails { get; set; } = new();
    }

    public class MappingEvalDetail
    {
        public string AmazonField { get; set; } = "";
        public bool IsRequired { get; set; }
        public string? AutoMatchedPath { get; set; }
        public double Score { get; set; }
        public string? ExpectedPath { get; set; }
        public string Verdict { get; set; } = ""; // CORRECT, WRONG, MISSING, NO_GROUND_TRUTH
    }
}