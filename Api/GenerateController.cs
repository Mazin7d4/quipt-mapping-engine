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

            // 3) Matching engine (Purvika module)
            var matcher = new MatchingEngine();
            var mappings = matcher.Match(quiptFields, amazonFields);

            // 4) Evaluation — extract ground truth from manual XSLT
            var groundTruth = new Dictionary<string, string>();
            var xsltLookup = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
            {
                ["laptops"] = "QuiptToAmazonTemplates/CatalogExportTransform.Laptops.xslt",
                ["desktops"] = "QuiptToAmazonTemplates/CatalogExportTransform.Desktops.xslt",
                ["smartphones"] = "QuiptToAmazonTemplates/CatalogExportTransform.SmartPhones.xslt"
            };

            if (xsltLookup.TryGetValue(request.Category.ToLower(), out var xsltPath)
                && System.IO.File.Exists(xsltPath))
            {
                groundTruth = GroundTruthXsltExtractor.ExtractFromFile(xsltPath);
            }

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
            

            // Build per-field evaluation details
            var evalDetails = new List<MappingEvalDetail>();
            foreach (var m in mappings)
            {
                var detail = new MappingEvalDetail
                {
                    AmazonField = m.AmazonField,
                    IsRequired = m.IsRequired,
                    AutoMatchedPath = m.QuiptPath,
                    Score = Math.Round(m.Score, 4)
                };

                // Check against ground truth
                var key = m.AmazonField;
                if (groundTruth.TryGetValue(key, out var expected))
                {
                    detail.ExpectedPath = expected;
                    if (string.IsNullOrWhiteSpace(m.QuiptPath))
                        detail.Verdict = "MISSING";
                    else if (EvaluationService.PathsEqual(m.QuiptPath, expected))
                        detail.Verdict = "CORRECT";
                    else
                        detail.Verdict = "WRONG";
                }
                else
                {
                    detail.Verdict = string.IsNullOrWhiteSpace(m.QuiptPath) ? "UNMATCHED" : "NO_GROUND_TRUTH";
                }

                evalDetails.Add(detail);
            }

            // Response model
            var response = new ApiResponseModel
            {
                Category = request.Category,
                AmazonFieldCount = amazonFields.Count,
                QuiptFieldCount = quiptFields.Count,
                MappingCount = mappings.Count(m => !m.IsUnmatched),
                Accuracy = Math.Round(accuracy, 2),
                RequiredFieldCoverage = Math.Round(requiredCoverage, 2),
                GroundTruthCount = groundTruth.Count,
                CorrectMatches = report.CorrectMatches,
                UnmatchedRequiredFields = report.UnmatchedRequiredFields,
                GeneratedXslt = xslt,
                Mappings = mappings,
                EvaluationDetails = evalDetails
            };

            return Ok(response);
        }
    }

    public class GenerateRequest
    {
        public string Category { get; set; } = "laptops";
    }
}