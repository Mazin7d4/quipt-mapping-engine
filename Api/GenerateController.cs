using Microsoft.AspNetCore.Mvc;
using QuiptMappingEngine.Models;
using QuiptMappingEngine.Services;
using QuiptMappingEngine.Xslt;
using QuiptMappingEngine.Evaluation;

namespace QuiptMappingEngine.Api
{
    [ApiController]
    [Route("generate")]
    public class GenerateController : ControllerBase
    {
        [HttpPost]
        public IActionResult Generate([FromBody] GenerateRequest request)
        {
            // 1) Parse Amazon schema fields (Mariya module)
            var amazonParser = new AmazonFieldParser();

            var amazonPath = $"AmazonTaxonomy/amazon-{request.Category.ToLower()}-attributes.json";
            if (!System.IO.File.Exists(amazonPath))
                return BadRequest($"Amazon schema not found: {amazonPath}");

            List<Field> amazonFields;
            try
            {
                amazonFields = amazonParser.Parse(amazonPath);
            }
            catch (Exception ex)
            {
                return BadRequest($"Amazon parse failed: {ex.Message}");
            }

            // 2) Quipt parser (Srushti module)
            var quiptParser = new QuiptSchemaParser();

            var quiptPath = $"QuiptData/{request.Category}.xml";
            if (!System.IO.File.Exists(quiptPath))
                return BadRequest($"Quipt XML not found: {quiptPath}");

            List<Field> quiptFields;
            try
            {
                quiptFields = quiptParser.ParseFields(quiptPath);
            }
            catch (Exception ex)
            {
                return BadRequest($"Quipt parse failed: {ex.Message}");
            }

            // 3) Matching engine (Purvika module) - will plug in when ready
            var matcher = new MatchingEngine();
            var mappings = matcher.Match(quiptFields, amazonFields);

            // 4) Evaluation (Lamiya module) - will plug in when ready
            var groundTruth = new Dictionary<string, string>();
            var evaluatedMappings = mappings.Select(m => new EvaluatedMapping
            {
                AmazonFieldName = m.AmazonField,
                MatchedQuiptXPath = m.QuiptPath,
                IsRequired = m.IsRequired
            }).ToList();

            var report = EvaluationService.Evaluate(
                request.Category,
                evaluatedMappings,
                groundTruth
            );

            var accuracy = report.AccuracyPercent;
            var requiredCoverage = report.RequiredCoveragePercent;

            // 5) XSLT generation (your module) - will plug in when you implement
            var xsltBuilder = new XsltBuilder();
            var xslt = xsltBuilder.Build(request.Category, mappings);
            

            // Response model (keep it simple for now)
            var response = new ApiResponseModel
            {
                Category = request.Category,
                AmazonFieldCount = amazonFields.Count,
                QuiptFieldCount = quiptFields.Count,
                MappingCount = mappings.Count,
                Accuracy = accuracy,
                RequiredFieldCoverage = requiredCoverage,
                GeneratedXslt = xslt,
                Mappings = mappings
            };

            return Ok(response);
        }
    }

    public class GenerateRequest
    {
        public string Category { get; set; } = "laptops";
    }
}