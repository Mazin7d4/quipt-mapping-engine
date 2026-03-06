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
        public string GeneratedXslt { get; set; } = "";
        public List<MappingResult> Mappings { get; set; } = new();
    }
}