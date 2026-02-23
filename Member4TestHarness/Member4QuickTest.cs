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
        // EVALUATION TEST (MOCK DATA)
        // ----------------------------
        Console.WriteLine("\n--- EVALUATION TEST (MOCK DATA) ---");

        // Ground truth (manual mapping)
        // Amazon field -> correct Quipt XPath
        var groundTruth = new Dictionary<string, string>
        {
            ["brand"] = "q:Catalog/q:Brand/q:Name",
            ["item_weight"] = "q:Catalog/q:Weight",
            ["color"] = "q:Catalog/q:Color"
        };

        // Auto results (pretend this is what Purvika produced)
        var autoMappings = new List<EvaluatedMapping>
        {
            new() { AmazonFieldName = "brand", IsRequired = true, MatchedQuiptXPath = "q:Catalog/q:Brand/q:Name" }, // correct
            new() { AmazonFieldName = "itemWeight", IsRequired = true, MatchedQuiptXPath = null },                 // required but unmatched
            new() { AmazonFieldName = "color", IsRequired = false, MatchedQuiptXPath = "q:Catalog/q:Colour" }      // wrong
        };

        var report = EvaluationService.Evaluate("Laptops", autoMappings, groundTruth);

        Console.WriteLine($"Category: {report.Category}");
        Console.WriteLine($"Accuracy: {report.AccuracyPercent:F2}% ({report.CorrectMatches}/{report.TotalAmazonFields})");
        Console.WriteLine($"Required Coverage: {report.RequiredCoveragePercent:F2}% ({report.MatchedRequiredFields}/{report.TotalRequiredFields})");
        Console.WriteLine("Unmatched Required Fields: " + string.Join(", ", report.UnmatchedRequiredFields));
    }
}