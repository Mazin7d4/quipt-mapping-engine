using QuiptMappingEngine.Normalization;
using QuiptMappingEngine.Evaluation;

namespace QuiptMappingEngine.Member4TestHarness;

public static class Member4QuickTest
{
    public static void Run()
    {
        // ----------------------------
        // NORMALIZATION TEST
        // ----------------------------
        var tests = new[]
        {
            "Screen_Size",
            "RAMSize",
            "ColourName",
            "item-weight",
            "ManufacturerName"
        };

        foreach (var t in tests)
        {
            var tokens = FieldNormalizer.GetNormalizedTokens(t);
            Console.WriteLine($"{t}  =>  [{string.Join(", ", tokens)}]");
        }

        // ----------------------------
        // ENUM OVERLAP TEST
        // ----------------------------
        Console.WriteLine("\n--- ENUM OVERLAP TEST ---");

        var amazonEnums = new List<string> { "Red", "Blue", "Black" };
        var quiptEnums = new List<string> { "Black", "White", "Silver" };

        var score = EnumOverlapScorer.ScoreOverlap(amazonEnums, quiptEnums);
        Console.WriteLine($"Overlap score should be 0.333... and is: {score:F3}");

        // ----------------------------
        // EVALUATION TEST (USING REAL GROUND TRUTH)
        // ----------------------------
        Console.WriteLine("\n--- EVALUATION TEST (REAL GROUND TRUTH) ---");

        var category = "Laptops";
        var gtLaptop = GroundTruthLoader.LoadAmazonGroundTruth(category);

        // Pretend we matched perfectly => should give 100% accuracy
        var autoMappings = gtLaptop.Keys
            .Select(k => new EvaluatedMapping
            {
                AmazonFieldName = k,
                IsRequired = false,
                MatchedQuiptXPath = gtLaptop[k]
            })
            .ToList();

        var report = EvaluationService.Evaluate(category, autoMappings, gtLaptop);

        Console.WriteLine($"Category: {report.Category}");
        Console.WriteLine($"Accuracy: {report.AccuracyPercent:F2}% ({report.CorrectMatches}/{report.TotalAmazonFields})");
        Console.WriteLine($"Required Coverage: {report.RequiredCoveragePercent:F2}% ({report.MatchedRequiredFields}/{report.TotalRequiredFields})");
        Console.WriteLine("Unmatched Required Fields: " + string.Join(", ", report.UnmatchedRequiredFields));

        // ----------------------------
        // GROUND TRUTH EXTRACTION TEST (RAW + FILTERED SAMPLE)
        // ----------------------------
        Console.WriteLine("\n--- GROUND TRUTH EXTRACTION TEST ---");

        var xsltPath = "QuiptToAmazonTemplates/CatalogExportTransform.Laptops.xslt";

        try
        {
            var extracted = GroundTruthXsltExtractor.ExtractFromFile(xsltPath);

            var quiptOnly = extracted
                .Where(kvp => kvp.Value.StartsWith("q:", StringComparison.OrdinalIgnoreCase))
                .ToDictionary(kvp => kvp.Key, kvp => kvp.Value, StringComparer.OrdinalIgnoreCase);

            Console.WriteLine($"Extracted {extracted.Count} mappings, Quipt-only: {quiptOnly.Count} from: {xsltPath}");

            foreach (var kvp in quiptOnly.Take(5))
            {
                Console.WriteLine($"{kvp.Key}  ->  {kvp.Value}");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Ground truth extraction failed: {ex.Message}");
        }

        // ----------------------------
        // GROUND TRUTH COUNTS (ALL CATEGORIES)
        // ----------------------------
        Console.WriteLine("\n--- GROUND TRUTH COUNTS (ALL CATEGORIES) ---");

        foreach (var c in new[] { "Laptops", "Desktops", "SmartPhones" })
        {
            try
            {
                var gt = GroundTruthLoader.LoadAmazonGroundTruth(c);
                Console.WriteLine($"{c}: Quipt-only ground truth mappings = {gt.Count}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"{c}: FAILED to load ground truth ({ex.Message})");
            }
        }

        // ----------------------------
        // PURVIKA REAL RESULTS EVALUATION (ALL CATEGORIES)
        // ----------------------------
        Console.WriteLine("\n--- PURVIKA REAL RESULTS EVALUATION ---");

        foreach (var c in new[] { "Laptops", "Desktops", "SmartPhones" })
        {
            var jsonPath = $"MemberResults/purvika-{c.ToLowerInvariant()}.json";

            if (!File.Exists(jsonPath))
            {
                Console.WriteLine($"{c}: No Purvika results found at {jsonPath}");
                continue;
            }

            try
            {
                var purvikaObjs = PurvikaResultsLoader.LoadFromJson(jsonPath).ToList();
                var evalList = PurvikaAdapter.ConvertFromPurvikaResults(purvikaObjs);

                var gt = GroundTruthLoader.LoadAmazonGroundTruth(c);
                var rep = EvaluationService.Evaluate(c, evalList, gt);

                Console.WriteLine($"\nCategory: {rep.Category}");
                Console.WriteLine($"Accuracy: {rep.AccuracyPercent:F2}% ({rep.CorrectMatches}/{rep.TotalAmazonFields})");
                Console.WriteLine($"Required Coverage: {rep.RequiredCoveragePercent:F2}% ({rep.MatchedRequiredFields}/{rep.TotalRequiredFields})");
                Console.WriteLine("Unmatched Required Fields: " + string.Join(", ", rep.UnmatchedRequiredFields));
            }
            catch (Exception ex)
            {
                Console.WriteLine($"{c}: FAILED to evaluate ({ex.Message})");
            }
        }
    }
}