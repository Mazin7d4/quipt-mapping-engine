using Microsoft.AspNetCore.Mvc;
using QuiptMappingEngine.Models;
using QuiptMappingEngine.Services;
using QuiptMappingEngine.Xslt;

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

            // 2) Quipt parser (Srushti module) - will plug in when ready
            // TODO: var quiptParser = new QuiptFieldParser();
            // TODO: var quiptFields = quiptParser.Parse($"QuiptData/{request.Category}.xml");
            var quiptFields = new List<Field>(); // placeholder until Srushti PR merges

            // 3) Matching engine (Purvika module) - will plug in when ready
            // TODO: var matcher = new MatchingEngine();
            // TODO: var mappings = matcher.Match(amazonFields, quiptFields);
            var mappings = new List<MappingResult>(); // placeholder until Purvika PR merges

            // 4) Evaluation (Lamiya module) - will plug in when ready
            // TODO: var evaluator = new Evaluator();
            // TODO: var eval = evaluator.Evaluate(mappings, request.Category);
            var accuracy = 0.0;
            var requiredCoverage = 0.0;

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